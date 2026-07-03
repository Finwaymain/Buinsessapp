import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cabme_driver/constant/constant.dart';
import 'package:cabme_driver/constant/logdata.dart';
import 'package:cabme_driver/model/parcel_model.dart';
import 'package:cabme_driver/model/trancation_model.dart';
import 'package:cabme_driver/model/user_model.dart';
import 'package:cabme_driver/utils/Preferences.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:cabme_driver/constant/show_toast_dialog.dart';
import 'package:cabme_driver/service/api.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ParcelServiceController extends GetxController {
  var searchParcelList = <ParcelData>[].obs;
  var isLoading = true.obs;

  Rx<TextEditingController> sourceCityController = TextEditingController().obs;
  Rx<TextEditingController> destinationCityController = TextEditingController().obs;
  Rx<TextEditingController> whenController = TextEditingController().obs;

  DateTime? dateAndTime = DateTime.now();
  LatLng? sourceLatLng;
  LatLng? destinationLatLng;
  UserModel? userModel;
  RxString totalEarn = "0".obs;
  @override
  void onInit() {
    searchParcelList.clear();
    getUsrData();
    super.onInit();
  }

  RxBool iswalletLoading = true.obs;
  Future<void> getUsrData() async {
    iswalletLoading.value = true;
    userModel = Constant.getUserData();
    final response = await http.get(Uri.parse("${API.walletHistory}?id_diver=${Preferences.getInt(Preferences.userId)}"), headers: API.header);
    showLog("API :: URL :: ${API.walletHistory}?id_diver=${Preferences.getInt(Preferences.userId)}");
    showLog("API :: Request Header :: ${API.header.toString()} ");
    showLog("API :: responseStatus :: ${response.statusCode} ");
    showLog("API :: responseBody :: ${response.body} ");
    Map<String, dynamic> responseBody = json.decode(response.body);

    if (response.statusCode == 200 && responseBody['success'] == "success") {
      TruncationModel model = TruncationModel.fromJson(responseBody);

      totalEarn.value = model.totalEarnings!.toString();
      iswalletLoading.value = false;
    } else if (response.statusCode == 200 && responseBody['success'] == "Failed") {
      iswalletLoading.value = false;
    } else {
      iswalletLoading.value = false;
    }
  }

  Future<dynamic> searchParcel(String bodyParams) async {
    try {
      ShowToastDialog.showLoader("Please wait");
      final response = await http.get(
        Uri.parse("${API.parcelSearch}$bodyParams"),
        headers: API.header,
      );
      showLog("API :: URL :: ${API.parcelSearch}$bodyParams}");
      showLog("API :: Request Header :: ${API.header.toString()} ");
      showLog("API :: responseStatus :: ${response.statusCode} ");
      showLog("API :: responseBody :: ${response.body} ");
      Map<String, dynamic> responseBody = json.decode(response.body);

      if (response.statusCode == 200 && responseBody['success'] == "success") {
        ShowToastDialog.closeLoader();
        ParcelModel model = ParcelModel.fromJson(responseBody);
        searchParcelList.value = model.data!;

        return responseBody;
      } else if (response.statusCode == 200 && responseBody['success'] == "Failed") {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast(responseBody['error']);
      } else {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast(responseBody['error'] ?? 'Something went wrong. Please try again later');
        throw Exception('Failed to load album');
      }
    } on TimeoutException catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.message.toString());
    } on SocketException catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.message.toString());
    } on Error catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.toString());
    }
    ShowToastDialog.closeLoader();
    return null;
  }

  Future<dynamic> confirmedParcel(Map<String, String> bodyParams) async {
    try {
      ShowToastDialog.showLoader("Please wait");
      final response = await http.post(Uri.parse(API.parcelContirm), headers: API.header, body: jsonEncode(bodyParams));
      showLog("API :: URL :: ${API.parcelContirm}");
      showLog("API :: Request Body :: ${jsonEncode(bodyParams)}");
      showLog("API :: Request Header :: ${API.header.toString()} ");
      showLog("API :: responseStatus :: ${response.statusCode} ");
      showLog("API :: responseBody :: ${response.body} ");
      Map<String, dynamic> responseBody = json.decode(response.body);

      if (response.statusCode == 200 && responseBody['success'] == "success") {
        ShowToastDialog.closeLoader();
        return responseBody;
      } else if (response.statusCode == 200 && responseBody['success'] == "Failed") {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast(responseBody['error']);
      } else {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast(responseBody['error'] ?? 'Something went wrong. Please try again later');
        throw Exception('Failed to load album');
      }
    } on TimeoutException catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.message.toString());
    } on SocketException catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.message.toString());
    } on Error catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.toString());
    }
    ShowToastDialog.closeLoader();
    return null;
  }
}
