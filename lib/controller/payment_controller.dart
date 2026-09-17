import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cabme_driver/constant/logdata.dart';
import 'package:cabme_driver/constant/show_toast_dialog.dart';
import 'package:cabme_driver/model/ride_details_model.dart';
import 'package:cabme_driver/model/ride_model.dart';
import 'package:cabme_driver/model/tax_model.dart';
import 'package:cabme_driver/service/api.dart';
import 'package:cabme_driver/utils/Preferences.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class PaymentController extends GetxController {
  @override
  void onInit() {
    getArgument();
    super.onInit();
  }

  RxDouble subTotalAmount = 0.0.obs;
  RxDouble tipAmount = 0.0.obs;
  RxDouble taxAmount = 0.0.obs;
  RxDouble discountAmount = 0.0.obs;
  RxDouble adminCommission = 0.0.obs;

  var data = RideData().obs;

  Future<void> getArgument() async {
    dynamic argumentData = Get.arguments;
    if (argumentData != null) {
      data.value = argumentData["rideData"];
      subTotalAmount.value = data.value.trueBaseFare;
      tipAmount.value = double.tryParse(data.value.tipAmount?.toString() ?? '0') ?? 0.0;
      discountAmount.value = double.tryParse(data.value.discount?.toString() ?? '0') ?? 0.0;

      double taxableBase = (subTotalAmount.value - discountAmount.value) > 0 ? (subTotalAmount.value - discountAmount.value) : 0.0;
      taxAmount.value = 0.0;
      if (data.value.taxModel != null) {
        for (var i = 0; i < data.value.taxModel!.length; i++) {
          if (data.value.taxModel![i].statut == 'yes') {
            if (data.value.taxModel![i].type == "Fixed") {
              taxAmount.value += double.tryParse(data.value.taxModel![i].value.toString()) ?? 0.0;
            } else {
              taxAmount.value += (taxableBase * (double.tryParse(data.value.taxModel![i].value!.toString()) ?? 0.0)) / 100;
            }
          }
        }
      }
    }
    if (data.value.statutPaiement == "yes") {
      getRideDetailsData(data.value.id.toString());
      adminCommission.value = double.tryParse(data.value.adminCommission?.toString() ?? '0') ?? 0.0;
    } else {
      adminCommission.value = (Preferences.getString(Preferences.admincommissiontype).toString() == 'Percentage')
          ? ((subTotalAmount.value - discountAmount.value) * (double.tryParse(Preferences.getString(Preferences.admincommission).toString()) ?? 0.0)) / 100
          : (double.tryParse(Preferences.getString(Preferences.admincommission).toString()) ?? 0.0);
    }

    update();
  }

  Future<dynamic> getRideDetailsData(String id) async {
    try {
      final response = await http.get(Uri.parse("${API.rideDetails}?ride_id=$id"), headers: API.header);
      showLog("API :: URL :: ${API.rideDetails}?ride_id=$id");
      showLog("API :: Request Header :: ${API.header.toString()} ");
      showLog("API :: responseStatus :: ${response.statusCode} ");
      showLog("API :: responseBody :: ${response.body} ");

      Map<String, dynamic> responseBody = json.decode(response.body);

      if (response.statusCode == 200 && responseBody['success'] == "success") {
        RideDetailsModel parcelDetailsModel = RideDetailsModel.fromJson(responseBody);

        if (parcelDetailsModel.rideDetailsdata != null) {
          final rd = parcelDetailsModel.rideDetailsdata!;
          subTotalAmount.value = rd.trueBaseFare;
          tipAmount.value = double.tryParse(rd.tipAmount?.toString() ?? '0') ?? 0.0;
          discountAmount.value = double.tryParse(rd.discount?.toString() ?? '0') ?? 0.0;
          double taxableBase = (subTotalAmount.value - discountAmount.value) > 0 ? (subTotalAmount.value - discountAmount.value) : 0.0;
          taxAmount.value = 0.0;
          if (rd.taxModel != null) {
            for (var i = 0; i < rd.taxModel!.length; i++) {
              if (rd.taxModel![i].statut! == 'yes') {
                if (rd.taxModel![i].type == "Fixed") {
                  taxAmount.value += double.tryParse(rd.taxModel![i].value.toString()) ?? 0.0;
                } else {
                  taxAmount.value += (taxableBase * (double.tryParse(rd.taxModel![i].value!.toString()) ?? 0.0)) / 100;
                }
              }
            }
          }
        }
      } else if (response.statusCode == 200 && responseBody['success'] == "Failed") {
      } else {
        ShowToastDialog.showToast(responseBody['error'] ?? 'Something went wrong. Please try again later');
        throw Exception('Failed to load album');
      }
    } on TimeoutException catch (e) {
      ShowToastDialog.showToast(e.message.toString());
    } on SocketException catch (e) {
      ShowToastDialog.showToast(e.message.toString());
    } on Error catch (e) {
      ShowToastDialog.showToast(e.toString());
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.toString());
    }
    return null;
  }

  double calculateTax({TaxModel? taxModel}) {
    double tax = 0.0;
    if (taxModel != null && taxModel.statut == 'yes') {
      double taxableBase = (subTotalAmount.value - discountAmount.value) > 0 ? (subTotalAmount.value - discountAmount.value) : 0.0;
      if (taxModel.type.toString() == "Fixed") {
        tax = double.tryParse(taxModel.value.toString()) ?? 0.0;
      } else {
        tax = (taxableBase * (double.tryParse(taxModel.value!.toString()) ?? 0.0)) / 100;
      }
    }
    return tax;
  }

  double getTotalAmount() {
    // if (Constant.taxType == "Percentage") {
    //   taxAmount.value =
    //       Constant.taxValue != null && Constant.taxValue.toString() != "0"
    //           ? (subTotalAmount.value - discountAmount.value) *
    //               double.parse(Constant.taxValue.toString()) /
    //               100
    //           : 0.0;
    // } else {
    //   taxAmount.value = Constant.taxValue.toString() != "0"
    //       ? double.parse(Constant.taxValue.toString())
    //       : 0.0;
    // }
    // if (paymentSettingModel.value.tax!.taxType == "percentage") {
    //   taxAmount.value = paymentSettingModel.value.tax!.taxAmount != null
    //       ? (subTotalAmount.value - discountAmount.value) *
    //           double.parse(
    //               paymentSettingModel.value.tax!.taxAmount.toString()) /
    //           100
    //       : 0.0;
    // } else {
    //   taxAmount.value = paymentSettingModel.value.tax!.taxAmount != null
    //       ? double.parse(paymentSettingModel.value.tax!.taxAmount.toString())
    //       : 0.0;
    // }

    return (subTotalAmount.value - discountAmount.value) + tipAmount.value + taxAmount.value;
  }
}
