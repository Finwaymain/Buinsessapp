import 'package:cabme_driver/constant/show_toast_dialog.dart';
import 'package:cabme_driver/controller/auth_otp_controller.dart';
import 'package:cabme_driver/page/MainDashBoard/screen/main_dashboard.dart';

import 'package:cabme_driver/page/auth_screens/mpin_login_screen.dart';
import 'package:cabme_driver/themes/button_them.dart';
import 'package:cabme_driver/themes/constant_colors.dart';
import 'package:cabme_driver/utils/dark_theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';

class MpinSetupScreen extends StatefulWidget {
  final String mode; // 'signup' or 'reset_mpin'
  final String otp;

  const MpinSetupScreen({super.key, required this.mode, required this.otp});

  @override
  State<MpinSetupScreen> createState() => _MpinSetupScreenState();
}

class _MpinSetupScreenState extends State<MpinSetupScreen> {
  final pinController = TextEditingController();
  final confirmPinController = TextEditingController();
  final controller = Get.find<AuthOtpController>();

  @override
  void dispose() {
    pinController.dispose();
    confirmPinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final bool isDark = themeChange.getThem();

    final bgColor = isDark ? AppThemeData.surface50Dark : AppThemeData.surface50;
    final labelColor = isDark ? AppThemeData.grey50 : AppThemeData.grey50Dark;
    final hintColor = isDark ? AppThemeData.grey400 : AppThemeData.grey400Dark;

    final pinTheme = PinTheme(
      height: 50,
      width: 50,
      textStyle: TextStyle(
        fontSize: 20,
        fontFamily: AppThemeData.bold,
        color: isDark ? AppThemeData.grey50 : AppThemeData.grey50Dark,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppThemeData.grey100Dark : AppThemeData.primary50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? AppThemeData.grey200Dark : AppThemeData.grey200,
        ),
      ),
    );

    final focusedPinTheme = pinTheme.copyWith(
      decoration: pinTheme.decoration!.copyWith(
        border: Border.all(color: AppThemeData.primary200, width: 1.5),
      ),
    );

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: labelColor, size: 20),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                widget.mode == 'signup' ? 'Set up your MPIN'.tr : 'Reset your MPIN'.tr,
                style: TextStyle(
                  fontSize: 26,
                  fontFamily: AppThemeData.bold,
                  color: labelColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Create a 4-digit MPIN to secure your account and log in easily in the future.'.tr,
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: AppThemeData.regular,
                  color: hintColor,
                ),
              ),
              const SizedBox(height: 36),

              // Enter PIN
              Text(
                'Enter MPIN'.tr,
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: AppThemeData.medium,
                  color: labelColor,
                ),
              ),
              const SizedBox(height: 12),
              Pinput(
                controller: pinController,
                length: 4,
                obscureText: true,
                obscuringCharacter: '●',
                defaultPinTheme: pinTheme,
                focusedPinTheme: focusedPinTheme,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
              ),

              const SizedBox(height: 28),

              // Confirm PIN
              Text(
                'Confirm MPIN'.tr,
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: AppThemeData.medium,
                  color: labelColor,
                ),
              ),
              const SizedBox(height: 12),
              Pinput(
                controller: confirmPinController,
                length: 4,
                obscureText: true,
                obscuringCharacter: '●',
                defaultPinTheme: pinTheme,
                focusedPinTheme: focusedPinTheme,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
              ),

              const SizedBox(height: 48),

              Obx(() => ButtonThem.buildButton(
                    context, txtColor: Colors.white,
                    title: controller.isLoading.value ? 'Please wait...' : 'Continue'.tr,
                    onPress: controller.isLoading.value
                        ? () {}
                        : () async {
                            final pin = pinController.text.trim();
                            final confirmPin = confirmPinController.text.trim();

                            if (pin.length != 4 || confirmPin.length != 4) {
                              ShowToastDialog.showToast('Please enter both MPIN fields.'.tr);
                              return;
                            }

                            if (pin != confirmPin) {
                              ShowToastDialog.showToast('MPINs do not match.'.tr);
                              return;
                            }

                              Get.snackbar('Registration Restricted'.tr, 'Driver Registration must be completed on our web portal.'.tr);
                              // Reset MPIN
                              final success = await controller.resetMpin(
                                controller.phone.value,
                                widget.otp,
                                pin,
                                userCat: 'driver',
                              );
                              if (success) {
                                // Automatically log them in after reset
                                final user = await controller.loginByMpin(
                                  controller.phone.value,
                                  pin,
                                  userCat: 'driver',
                                );
                                if (user != null) {
                                  Get.offAll(() => const MainDashboard());
                                } else {
                                  Get.offAll(() => MpinLoginScreen(phone: controller.phone.value));
                                }
                              }
                            
                          },
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
