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
    super.onInit();
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
      // ShowToastDialog.showLoader("Please wait");
      final response = await http.get(
        Uri.parse(API.settings),
        headers: API.authheader,
      );
      showLog("API :: URL :: ${API.settings} ");
      showLog("API :: Request Header :: ${API.authheader.toString()} ");
      showLog("API :: responseStatus :: ${response.statusCode} ");
      showLog("API :: responseBody :: ${response.body} ");
      Map<String, dynamic> responseBody = json.decode(response.body);

      if (response.statusCode == 200 && responseBody['success'] == "success") {
        // ShowToastDialog.closeLoader();

        SettingsModel model = SettingsModel.fromJson(responseBody);
        Constant.adminCommission = model.data!.adminCommission!;
        Constant.subscriptionModel = bool.parse(model.data!.subscriptionModel!);
        Constant.liveTrackingMapType = "inappmap";
        if (Platform.isAndroid) {
          Constant.selectedMapType = 'google';
        } else {
          Constant.selectedMapType = model.data?.mapForApplication != null ? '${model.data?.mapForApplication?.toLowerCase()}' : '';
        }
        Constant.parcelActive = model.data!.parcelActive!;
        ConstantColors.primary = Color(int.parse(model.data!.driverappColor!.replaceFirst("#", "0xff")));
        // AppThemeData.primary200 = Color(int.parse(model.data!.driverappColor!.replaceFirst("#", "0xff")));
        Constant.distanceUnit = model.data!.deliveryDistance!;
        Constant.appVersion = model.data!.appVersion.toString();
        Constant.decimal = model.data!.decimalDigit!;

        // Constant.taxList = model.data!.taxModel!;
        // Constant.taxType = model.data!.taxType!;
        // Constant.taxName = model.data!.taxName!;

        // Constant.taxValue = model.data!.taxValue!;
        Constant.currency = model.data!.currency!;
        Constant.symbolAtRight = model.data!.symbolAtRight! == 'true' ? true : false;
        Constant.kGoogleApiKey = model.data!.googleMapApiKey!;
        Constant.contactUsEmail = model.data!.contactUsEmail!;
        Constant.contactUsAddress = model.data!.contactUsAddress!;
        Constant.minimumWalletBalance = model.data!.minimumDepositAmount!;
        Constant.contactUsPhone = model.data!.contactUsPhone!;
        Constant.rideOtp = model.data!.showRideOtp!;
        Constant.driverLocationUpdateUnit = model.data!.driverLocationUpdate!;
        Constant.minimumWithdrawalAmount = model.data!.minimumWithdrawalAmount!;
        Constant.deliveryChargeParcel = model.data!.deliveryChargeParcel!;

        Constant.parcelPerWeightCharge = model.data!.parcelPerWeightCharge!;
        Constant.allTaxList = model.data!.taxModel!;
        Constant.senderId = model.data!.senderId!;
        Constant.jsonNotificationFileURL = model.data!.serviceJson!;
        isLoading.value = false;
      } else if (response.statusCode == 200 && responseBody['success'] == "Failed") {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast(responseBody['error']);
        isLoading.value = false;
      } else {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast('Something want wrong. Please try again later');
        isLoading.value = false;
        throw Exception('Failed to load album');
      }
    } on TimeoutException catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.message.toString());
      isLoading.value = false;
    } on SocketException catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.message.toString());
      isLoading.value = false;
    } on Error catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.toString());
      isLoading.value = false;
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.toString());
      isLoading.value = false;
    }
    return null;
  }
}
