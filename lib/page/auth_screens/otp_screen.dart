// ignore_for_file: must_be_immutable

import 'dart:convert';

import 'package:cabme_driver/constant/constant.dart';
import 'package:cabme_driver/constant/show_toast_dialog.dart';
import 'package:cabme_driver/controller/phone_number_controller.dart';
import 'package:cabme_driver/model/user_model.dart';
import 'package:cabme_driver/page/MainDashBoard/screen/main_dashboard.dart';
import 'package:cabme_driver/page/auth_screens/phone_entry_screen.dart';
import 'package:cabme_driver/page/subscription_plan_screen/subscription_plan_screen.dart';
import 'package:cabme_driver/service/api.dart';
import 'package:cabme_driver/themes/button_them.dart';
import 'package:cabme_driver/themes/responsive.dart';
import 'package:cabme_driver/utils/Preferences.dart';
import 'package:cabme_driver/utils/dark_theme_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';

import '../../themes/constant_colors.dart';
import 'phone_entry_screen.dart';

class OtpScreen extends StatelessWidget {
  String? phoneNumber;
  String? verificationId;

  OtpScreen({super.key, required this.phoneNumber, required this.verificationId});

  final controller = Get.put(PhoneNumberController());
  final otpController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    bool isDarkMode = themeChange.getThem();
    return Scaffold(
      backgroundColor: AppThemeData.primary200,
      bottomNavigationBar: Container(
        color: isDarkMode ? AppThemeData.surface50Dark : AppThemeData.surface50,
        child: Stack(
          alignment: AlignmentDirectional.bottomCenter,
          children: [
            Image.asset(
              isDarkMode ? 'assets/images/ic_bg_signup_dark.png' : 'assets/images/ic_bg_signup_light.png',
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text.rich(
                textAlign: TextAlign.center,
                TextSpan(
                  text: 'Already book rides?'.tr,
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: AppThemeData.regular,
                    color: isDarkMode ? AppThemeData.grey800Dark : AppThemeData.grey800,
                  ),
                  children: <TextSpan>[
                    TextSpan(
                      text: ' '.tr,
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: AppThemeData.medium,
                        color: AppThemeData.primary200,
                      ),
                    ),
                    TextSpan(
                      recognizer: TapGestureRecognizer()..onTap = () => Get.offAll(PhoneEntryScreen(mode: 'signup')),
                      text: 'Log in'.tr,
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: AppThemeData.medium,
                        color: AppThemeData.primary200,
                        decoration: TextDecoration.underline,
                        decorationColor: AppThemeData.primary200,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Stack(
          alignment: AlignmentDirectional.topStart,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      Text(
                        "Verify Your OTP".tr,
                        style: TextStyle(
                          fontSize: 24,
                          fontFamily: AppThemeData.semiBold,
                          color: themeChange.getThem() ? AppThemeData.grey50Dark : AppThemeData.grey50,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Enter the one-time password sent to your mobile number to verify your account.".tr,
                        textAlign: TextAlign.start,
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: AppThemeData.regular,
                          color: themeChange.getThem() ? AppThemeData.grey50Dark : AppThemeData.grey50,
                        ),
                      ),
                      const SizedBox(height: 60),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    width: Responsive.width(100, context),
                    color: themeChange.getThem() ? AppThemeData.surface50Dark : AppThemeData.surface50,
                  ),
                ),
              ],
            ),
            Positioned(
              top: 140,
              left: 20,
              right: 20,
              child: SizedBox(
                height: Responsive.height(80, context),
                width: Responsive.width(85, context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Pinput(
                      scrollPadding: EdgeInsets.zero,
                      controller: otpController,
                      defaultPinTheme: PinTheme(
                        margin: EdgeInsets.zero,
                        padding: EdgeInsets.zero,
                        height: 50,
                        width: 55,
                        textStyle: TextStyle(
                            letterSpacing: 0.60, fontSize: 16, color: themeChange.getThem() ? AppThemeData.grey900Dark : AppThemeData.grey900, fontWeight: FontWeight.w600),
                        decoration: BoxDecoration(
                          shape: BoxShape.rectangle,
                          color: themeChange.getThem() ? AppThemeData.surface50Dark : AppThemeData.surface50,
                          border: Border.all(color: themeChange.getThem() ? AppThemeData.grey200Dark : AppThemeData.grey200, width: 0.8),
                        ),
                      ),
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.done,
                      length: 6,
                    ),
                    const SizedBox(height: 20),
                    Padding(
                        padding: const EdgeInsets.only(top: 50),
                        child: ButtonThem.buildButton(
                          context,
                          title: 'Verify OTP'.tr,
                          btnHeight: 50,
                          btnColor: AppThemeData.primary200,
                          txtColor: themeChange.getThem() ? AppThemeData.grey50Dark : AppThemeData.grey50,
                          onPress: () async {
                            FocusScope.of(context).unfocus();

                            if (otpController.text.length == 6) {
                              ShowToastDialog.showLoader("Verify OTP");
                              PhoneAuthCredential credential = PhoneAuthProvider.credential(verificationId: verificationId.toString(), smsCode: otpController.value.text);
                              await FirebaseAuth.instance.signInWithCredential(credential).then((value) async {
                                Map<String, String> bodyParams = {
                                  'phone': controller.phoneNumber.value,
                                  'user_cat': "driver",
                                  'login_type': "phoneNumber",
                                };
                                await controller.phoneNumberIsExit(bodyParams).then((value) async {
                                  if (value == true) {
                                    Map<String, String> bodyParams = {
                                      'phone': controller.phoneNumber.value,
                                      'user_cat': "driver",
                                      'login_type': "phoneNumber",
                                    };
                                    await controller.getDataByPhoneNumber(bodyParams).then((value) {
                                      if (value != null) {
                                        if (value.success == "success") {
                                          ShowToastDialog.closeLoader();
                                          Preferences.setString(Preferences.user, jsonEncode(value));
                                          UserData? userData = value.userData;
                                          Preferences.setInt(Preferences.userId, int.parse(userData!.id.toString()));
                                          Preferences.setString(Preferences.accesstoken, value.userData!.accesstoken.toString());
                                          API.header['accesstoken'] = Preferences.getString(Preferences.accesstoken);

                                          ShowToastDialog.closeLoader();
                                          Preferences.setBoolean(Preferences.isLogin, true);

                                          bool isPlanExpire = false;
                                          if (value.userData!.subscriptionPlan?.id != null) {
                                            if (value.userData!.subscriptionExpiryDate == null) {
                                              if (value.userData!.subscriptionPlan?.expiryDay == '-1') {
                                                isPlanExpire = false;
                                              } else {
                                                isPlanExpire = true;
                                              }
                                            } else {
                                              DateTime expiryDate = DateTime.parse(value.userData!.subscriptionExpiryDate!);
                                              isPlanExpire = expiryDate.isBefore(DateTime.now());
                                            }
                                          } else {
                                            isPlanExpire = true;
                                          }
                                          if (value.userData!.subscriptionPlanId == null || isPlanExpire == true) {
                                            Get.offAll(MainDashboard(), duration: const Duration(milliseconds: 400), transition: Transition.rightToLeft);
                                          } else {
                                            Get.offAll(MainDashboard(), duration: const Duration(milliseconds: 400), transition: Transition.rightToLeft);
                                          }
                                        } else {
                                          ShowToastDialog.showToast(value.error);
                                        }
                                      }
                                    });
                                  } else if (value == false) {
                                    ShowToastDialog.closeLoader();
                                    Get.off(PhoneEntryScreen(mode: 'signup'), arguments: {'phoneNumber': controller.phoneNumber.value, 'login_type': "phoneNumber"});
                                  }
                                });
                              }).catchError((error) {
                                ShowToastDialog.closeLoader();
                                ShowToastDialog.showToast("Code is Invalid");
                              });
                            } else {
                              ShowToastDialog.showToast("Please Enter OTP");
                            }
                          },
                        )),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
