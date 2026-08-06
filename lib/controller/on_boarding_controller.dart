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

  void _setupFallbackData() {
    if (onboardingModel.value.data == null || onboardingModel.value.data!.isEmpty) {
      onboardingModel.value = OnboardingModel(
        success: "success",
        data: [
          OnboardingData(
            id: "1",
            title: "Accept Rides Easily".tr,
            description: "Receive instant ride requests nearby and manage your trips effortlessly.".tr,
            image: "assets/images/intro_1.png",
          ),
          OnboardingData(
            id: "2",
            title: "Flexible Earnings".tr,
            description: "Drive on your own schedule and earn competitive fares with daily payouts.".tr,
            image: "assets/images/intro_3.png",
          ),
          OnboardingData(
            id: "3",
            title: "Live GPS Navigation".tr,
            description: "Turn-by-turn navigation and optimal routes for hassle-free journeys.".tr,
            image: "assets/images/intro_2.png",
          ),
        ],
      );
    }
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
      
      if (response.statusCode == 200) {
        var decodedResponse = jsonDecode(response.body);
        if (decodedResponse is Map<String, dynamic> && decodedResponse['success'] == 'success') {
          onboardingModel.value = OnboardingModel.fromJson(decodedResponse);
        }
      }
    } catch (e) {
      showLog("OnBoarding Exception: $e");
    } finally {
      _setupFallbackData();
      isLastPage = selectedPageIndex.value == (onboardingModel.value.data?.length ?? 0) - 1;
      isLoading.value = false;
      ShowToastDialog.closeLoader();
    }

    return null;
  }
}
