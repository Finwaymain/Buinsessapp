import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cabme_driver/constant/constant.dart';
import 'package:cabme_driver/constant/logdata.dart';
import 'package:cabme_driver/constant/show_toast_dialog.dart';
import 'package:cabme_driver/model/settings_model.dart';
import 'package:cabme_driver/model/user_model.dart';
import 'package:cabme_driver/service/api.dart';
import 'package:cabme_driver/themes/constant_colors.dart';
import 'package:cabme_driver/utils/Preferences.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class SettingsController extends GetxController {
  @override
  void onInit() {
    API.header['accesstoken'] = Preferences.getString(Preferences.accesstoken);
    getSettingsData();
    fetchPaymentSettings();
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (isLoading.value) {
        isLoading.value = false;
      }
    });
    super.onInit();
  }

  bool _parseBool(dynamic val) {
    if (val == null) return false;
    final s = val.toString().toLowerCase().trim();
    return s == 'true' || s == '1' || s == 'yes';
  }

  Future<void> fetchPaymentSettings() async {
    try {
      final response = await http
          .get(Uri.parse(API.paymentSetting), headers: API.header)
          .timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body['success'] == 'success') {
          Preferences.setString(Preferences.paymentSetting, jsonEncode(body));
        }
      }
    } catch (_) {}
  }

  RxBool isLoading = true.obs;
  bool checkStatus() {
    UserModel userData = Constant.getUserData();
    if (userData.userData == null) {
      return false;
    }
    bool isPlanExpire = false;
    if (userData.userData!.subscriptionPlan?.id != null) {
      if (userData.userData!.subscriptionExpiryDate == null) {
        if (userData.userData!.subscriptionPlan?.expiryDay == '-1') {
          isPlanExpire = false;
        } else {
          isPlanExpire = true;
        }
      } else {
        DateTime expiryDate = DateTime.parse(userData.userData!.subscriptionExpiryDate!);
        isPlanExpire = expiryDate.isBefore(DateTime.now());
      }
    } else {
      isPlanExpire = true;
    }

    if (userData.userData!.subscriptionPlanId == null || isPlanExpire == true) {
      if (Constant.adminCommission?.statut == "no" && Constant.subscriptionModel == false) {
        return true;
      } else {
        return false;
      }
    } else {
      return true;
    }
  }

  Future<SettingsModel?> getSettingsData() async {
    try {
      isLoading.value = true;
      final response = await http.get(
        Uri.parse(API.settings),
        headers: API.authheader,
      ).timeout(const Duration(seconds: 8));

      showLog("API :: URL :: ${API.settings} ");
      showLog("API :: Request Header :: ${API.authheader.toString()} ");
      showLog("API :: responseStatus :: ${response.statusCode} ");
      showLog("API :: responseBody :: ${response.body} ");
      Map<String, dynamic> responseBody = json.decode(response.body);

      if (response.statusCode == 200 && responseBody['success'] == "success") {
        SettingsModel model = SettingsModel.fromJson(responseBody);
        if (model.data != null) {
          if (model.data!.adminCommission != null) {
            Constant.adminCommission = model.data!.adminCommission!;
          }
          Constant.subscriptionModel = _parseBool(model.data?.subscriptionModel);
          Constant.liveTrackingMapType = "inappmap";
          if (Platform.isAndroid) {
            Constant.selectedMapType = 'google';
          } else {
            Constant.selectedMapType = model.data?.mapForApplication != null ? '${model.data?.mapForApplication?.toLowerCase()}' : '';
          }
          Constant.parcelActive = model.data?.parcelActive ?? "yes";
          if (model.data?.driverappColor != null && model.data!.driverappColor!.isNotEmpty) {
            try {
              ConstantColors.primary = Color(int.parse(model.data!.driverappColor!.replaceFirst("#", "0xff")));
            } catch (_) {}
          }
          Constant.distanceUnit = model.data?.deliveryDistance ?? "km";
          Constant.appVersion = model.data?.appVersion?.toString() ?? "1.0.0";
          Constant.decimal = model.data?.decimalDigit ?? "2";
          Constant.currency = model.data?.currency ?? "₹";
          Constant.symbolAtRight = _parseBool(model.data?.symbolAtRight);
          Constant.kGoogleApiKey = model.data?.googleMapApiKey ?? "";
          Constant.contactUsEmail = model.data?.contactUsEmail ?? "";
          Constant.contactUsAddress = model.data?.contactUsAddress ?? "";
          Constant.minimumWalletBalance = model.data?.minimumDepositAmount ?? "0";
          Constant.contactUsPhone = model.data?.contactUsPhone ?? "";
          Constant.rideOtp = model.data?.showRideOtp ?? "yes";
          Constant.driverLocationUpdateUnit = model.data?.driverLocationUpdate ?? "10";
          Constant.minimumWithdrawalAmount = model.data?.minimumWithdrawalAmount ?? "0";
          Constant.deliveryChargeParcel = model.data?.deliveryChargeParcel ?? "0";
          Constant.parcelPerWeightCharge = model.data?.parcelPerWeightCharge ?? "0";
          if (model.data?.taxModel != null) {
            Constant.allTaxList = model.data!.taxModel!;
          }
          Constant.senderId = model.data?.senderId ?? "";
          Constant.jsonNotificationFileURL = model.data?.serviceJson ?? "";
        }
      } else if (response.statusCode == 200 && responseBody['success'] == "Failed") {
        ShowToastDialog.showToast(responseBody['error'] ?? 'Failed to load settings');
      } else {
        ShowToastDialog.showToast(responseBody['error'] ?? 'Something went wrong. Please try again later');
      }
    } on TimeoutException catch (e) {
      showLog("SettingsController TimeoutException: $e");
    } on SocketException catch (e) {
      showLog("SettingsController SocketException: $e");
    } catch (e) {
      showLog("SettingsController error: $e");
    } finally {
      isLoading.value = false;
    }
    return null;
  }
}
