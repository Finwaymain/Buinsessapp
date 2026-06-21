import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cabme_driver/constant/logdata.dart';
import 'package:cabme_driver/constant/show_toast_dialog.dart';
import 'package:cabme_driver/model/onboarding_model.dart';
import 'package:cabme_driver/service/api.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class OnBoardingController extends GetxController {
  var selectedPageIndex = 0.obs;

  bool isLastPage = false;
  RxBool isLoading = true.obs;
  var pageController = PageController();

  Rx<OnboardingModel> onboardingModel = OnboardingModel().obs;
  RxList<String> localImage = ['assets/images/intro_1.png', 'assets/images/intro_3.png', 'assets/images/intro_2.png'].obs;

  @override
  void onInit() {
    getBoardingData();
    super.onInit();
  }

  Future<dynamic> getBoardingData() async {
    try {
      ShowToastDialog.showLoader("Please wait");
      isLoading.value = true;
      http.Response response = await http.get(Uri.parse(API.onBoarding), headers: API.header);
      showLog("API :: URL :: ${API.onBoarding}");
      showLog("API :: Request Header :: ${API.header.toString()}");
      showLog("API :: Response Status :: ${response.statusCode} ");
      showLog("API :: Response Body :: ${response.body} ");
      var decodedResponse = jsonDecode(response.body);
      if (decodedResponse['success'] == 'success') {
        onboardingModel.value = OnboardingModel.fromJson(decodedResponse as Map<String, dynamic>);
        isLastPage = selectedPageIndex.value == (onboardingModel.value.data?.length ?? 0) - 1;
        isLoading.value = false;
        ShowToastDialog.closeLoader();
        return decodedResponse;
      } else {
        ShowToastDialog.closeLoader();
        isLoading.value = false;
      }
    } on TimeoutException catch (e) {
      isLoading.value = false;
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.message.toString());
    } on SocketException catch (e) {
      isLoading.value = false;
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.message.toString());
    } on Error catch (e) {
      isLoading.value = false;
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.toString());
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.toString());
    }

    return null;
  }
}
