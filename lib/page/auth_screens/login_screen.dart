import 'dart:convert';
import 'dart:io';

import 'package:cabme_driver/constant/constant.dart';
import 'package:cabme_driver/constant/show_toast_dialog.dart';
import 'package:cabme_driver/controller/login_conroller.dart';
import 'package:cabme_driver/model/user_model.dart';
import 'package:cabme_driver/page/MainDashBoard/screen/main_dashboard.dart';
import 'package:cabme_driver/page/auth_screens/forgot_password.dart';
import 'package:cabme_driver/page/auth_screens/mobile_number_screen.dart';
import 'package:cabme_driver/page/auth_screens/signup_screen.dart';
import 'package:cabme_driver/page/features/Taxi/taxi_dashboard/taxi_dashboard.dart';
import 'package:cabme_driver/page/subscription_plan_screen/subscription_plan_screen.dart';
import 'package:cabme_driver/themes/button_them.dart';
import 'package:cabme_driver/themes/constant_colors.dart';
import 'package:cabme_driver/themes/responsive.dart';
import 'package:cabme_driver/themes/text_field_them.dart';
import 'package:cabme_driver/utils/Preferences.dart';
import 'package:cabme_driver/utils/dark_theme_provider.dart';
import 'package:cabme_driver/widget/permission_dialog.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  static final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  static final _emailController = TextEditingController();
  static final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return GetBuilder(
        init: LoginController(),
        initState: (state) async {
          try {
            PermissionStatus location = await Location().hasPermission();
            print(location);
            if (PermissionStatus.granted != location) {
              showDialogPermission(context);
            }
          } on PlatformException catch (e) {
            ShowToastDialog.showToast("${e.message}");
          }
        },
        builder: (controller) {
          return Scaffold(
            resizeToAvoidBottomInset: false,
            backgroundColor: AppThemeData.primary200,
            body: SafeArea(
              child: Stack(
                children: [
                  Column(
                    children: [
                      Container(
                        color: AppThemeData.primary200,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 20),
                              Text(
                                "Welcome Back!".tr,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontFamily: AppThemeData.semiBold,
                                  color: themeChange.getThem() ? AppThemeData.grey50 : AppThemeData.grey50Dark,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                "Sign up for a personalized CabME experience. Start booking your rides in just a few taps.".tr,
                                textAlign: TextAlign.start,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontFamily: AppThemeData.regular,
                                  color: themeChange.getThem() ? AppThemeData.grey50 : AppThemeData.grey50Dark,
                                ),
                              ),
                              const SizedBox(height: 60),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        flex: Platform.isIOS ? 3 : 4,
                        child: Container(
                          color: themeChange.getThem() ? AppThemeData.surface50Dark : AppThemeData.surface50,
                          child: Image.asset(
                            themeChange.getThem() ? 'assets/images/ic_bg_signup_dark.png' : 'assets/images/ic_bg_signup_light.png',
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
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
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  TextFieldWidget(
                                    prefix: IconButton(
                                      onPressed: () {},
                                      icon: SvgPicture.asset(
                                        "assets/icons/ic_email.svg",
                                        colorFilter: ColorFilter.mode(
                                          themeChange.getThem() ? AppThemeData.grey500Dark : AppThemeData.grey500,
                                          BlendMode.srcIn,
                                        ),
                                      ),
                                    ),
                                    hintText: 'email address'.tr,
                                    controller: _emailController,
                                    textInputType: TextInputType.emailAddress,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                                    validators: (String? value) {
                                      if (value!.isNotEmpty) {
                                        return null;
                                      } else {
                                        return 'required'.tr;
                                      }
                                    },
                                  ),
                                  TextFieldWidget(
                                    prefix: IconButton(
                                      onPressed: () {},
                                      icon: SvgPicture.asset(
                                        'assets/icons/ic_lock.svg',
                                        colorFilter: ColorFilter.mode(
                                          themeChange.getThem() ? AppThemeData.grey500Dark : AppThemeData.grey500,
                                          BlendMode.srcIn,
                                        ),
                                      ),
                                    ),
                                    hintText: 'enter password'.tr,
                                    controller: _passwordController,
                                    textInputType: TextInputType.text,
                                    obscureText: false,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                                    validators: (String? value) {
                                      if (value!.isNotEmpty) {
                                        return null;
                                      } else {
                                        return 'required'.tr;
                                      }
                                    },
                                  ),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: GestureDetector(
                                      onTap: () {
                                        Get.to(
                                          ForgotPasswordScreen(),
                                          duration: const Duration(milliseconds: 400),
                                          transition: Transition.rightToLeft,
                                        );
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.only(top: 10),
                                        child: Text(
                                          "forgot password".tr,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: AppThemeData.secondary200,
                                            fontFamily: AppThemeData.regular,
                                            decorationColor: AppThemeData.secondary200,
                                            decoration: TextDecoration.underline,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 50),
                                    child: ButtonThem.buildButton(
                                      context,
                                      title: 'Log in'.tr,
                                      btnHeight: 50,
                                      btnColor: AppThemeData.primary200,
                                      txtColor: AppThemeData.surface50,
                                      onPress: () async {
                                        FocusScope.of(context).unfocus();
                                        if (_formKey.currentState!.validate()) {
                                          _formKey.currentState!.save();
                                          Map<String, String> bodyParams = {
                                            'email': _emailController.text.trim(),
                                            'mdp': _passwordController.text,
                                            'user_cat': "driver",
                                            'login_type': 'email'
                                          };
                                          await controller.loginAPI(bodyParams).then((value) async {
                                            if (value != null) {
                                              if (value.success == "success") {
                                                await Preferences.setString(Preferences.user, jsonEncode(value));
                                                await Preferences.setBoolean(Preferences.isLogin, true);
                                                UserData? userData = value.userData;
                                                await Preferences.setInt(Preferences.userId, int.parse(userData!.id.toString()));

                                                bool isPlanExpire = false;
                                                if (Constant.adminCommission?.statut == "no" && Constant.subscriptionModel == false) {
                                                  Get.offAll(TaxiDashBoard(), duration: const Duration(milliseconds: 400), transition: Transition.rightToLeft);
                                                } else {
                                                  if (userData.subscriptionPlan?.id != null) {
                                                    if (userData.subscriptionExpiryDate == null) {
                                                      if (userData.subscriptionPlan?.expiryDay == '-1') {
                                                        isPlanExpire = false;
                                                      } else {
                                                        isPlanExpire = true;
                                                      }
                                                    } else {
                                                      DateTime expiryDate = DateTime.parse(userData.subscriptionExpiryDate!);
                                                      isPlanExpire = expiryDate.isBefore(DateTime.now());
                                                    }
                                                  } else {
                                                    isPlanExpire = true;
                                                  }
                                                  if (userData.subscriptionPlanId == null || isPlanExpire == true) {
                                                    Get.to(
                                                        SubscriptionPlanScreen(
                                                          isbackButton: false,
                                                        ),
                                                        arguments: {'islogin': true});
                                                  } else {
                                                    // Get.offAll(DashBoard(), duration: const Duration(milliseconds: 400), transition: Transition.rightToLeft);
                                                    Get.offAll(MainDashboard(), duration: const Duration(milliseconds: 400), transition: Transition.rightToLeft);
                                                  }
                                                }
                                              } else {
                                                ShowToastDialog.showToast(value.error);
                                              }
                                            }
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                  Align(
                                    alignment: Alignment.center,
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 20),
                                      child: Text(
                                        "or continue with".tr,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: themeChange.getThem() ? AppThemeData.grey400Dark : AppThemeData.grey400,
                                          fontFamily: AppThemeData.regular,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 40),
                                    child: ButtonThem.buildIconButtonWidget(
                                      context,
                                      title: 'Mobile Number'.tr,
                                      btnHeight: 50,
                                      btnColor: themeChange.getThem() ? AppThemeData.grey300Dark : AppThemeData.grey300,
                                      txtColor: themeChange.getThem() ? AppThemeData.grey900Dark : AppThemeData.grey900,
                                      iconColor: themeChange.getThem() ? AppThemeData.grey900Dark : AppThemeData.grey900,
                                      icon: SvgPicture.asset("assets/icons/ic_phone_line.svg"),
                                      onPress: () {
                                        FocusScope.of(context).unfocus();
                                        Get.to(MobileNumberScreen(isLogin: true),
                                            duration: const Duration(milliseconds: 400), //duration of transitions, default 1 sec
                                            transition: Transition.rightToLeft);
                                      },
                                    ),
                                  ),
                                  SizedBox(
                                    height: 10,
                                  ),
                                  Platform.isAndroid
                                      ? ButtonThem.buildIconButtonWidget(
                                          context,
                                          title: 'Google'.tr,
                                          btnColor: themeChange.getThem() ? AppThemeData.grey300Dark : AppThemeData.grey300,
                                          txtColor: themeChange.getThem() ? AppThemeData.grey900Dark : AppThemeData.grey900,
                                          onPress: () {
                                            FocusScope.of(context).unfocus();
                                            controller.loginWithGoogle();
                                          },
                                          iconColor: themeChange.getThem() ? AppThemeData.grey900Dark : AppThemeData.grey900,
                                          icon: SvgPicture.asset("assets/icons/ic_google.svg"),
                                        )
                                      : Row(
                                          children: [
                                            Expanded(
                                              child: ButtonThem.buildIconButtonWidget(
                                                context,
                                                title: 'Google'.tr,
                                                btnColor: themeChange.getThem() ? AppThemeData.grey300Dark : AppThemeData.grey300,
                                                txtColor: themeChange.getThem() ? AppThemeData.grey900Dark : AppThemeData.grey900,
                                                onPress: () {
                                                  FocusScope.of(context).unfocus();
                                                  controller.loginWithGoogle();
                                                },
                                                iconColor: themeChange.getThem() ? AppThemeData.grey900Dark : AppThemeData.grey900,
                                                icon: SvgPicture.asset("assets/icons/ic_google.svg"),
                                              ),
                                            ),
                                            SizedBox(
                                              width: 10,
                                            ),
                                            Expanded(
                                              child: ButtonThem.buildIconButtonWidget(
                                                context,
                                                title: 'Apple'.tr,
                                                btnColor: themeChange.getThem() ? AppThemeData.grey300Dark : AppThemeData.grey300,
                                                txtColor: themeChange.getThem() ? AppThemeData.grey900Dark : AppThemeData.grey900,
                                                iconColor: themeChange.getThem() ? AppThemeData.grey900Dark : AppThemeData.grey900,
                                                icon: SvgPicture.asset("assets/icons/ic_apple.svg"),
                                                onPress: () {
                                                  FocusScope.of(context).unfocus();
                                                  controller.loginWithApple();
                                                },
                                              ),
                                            )
                                          ],
                                        )
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 30),
                              child: Text.rich(
                                textAlign: TextAlign.center,
                                TextSpan(
                                  text: 'First time in CabMe?'.tr,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontFamily: AppThemeData.regular,
                                    color: themeChange.getThem() ? AppThemeData.grey800Dark : AppThemeData.grey800,
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
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () => Get.to(
                                            // MobileNumberScreen(
                                            //   isLogin: false,
                                            // ),
                                          SignupScreen(),
                                            duration: const Duration(milliseconds: 400), //duration of transitions, default 1 sec
                                            transition: Transition.rightToLeft), //transition effect);,
                                      text: 'Create an account'.tr,
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
                    ),
                  ),
                ],
              ),
            ),
          );
        });
  }

  void showDialogPermission(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const LocationPermissionDisclosureDialog(),
    );
  }
}
