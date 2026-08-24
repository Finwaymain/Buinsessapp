// ignore_for_file: must_be_immutable
import 'package:cabme_driver/constant/show_toast_dialog.dart';
import 'package:cabme_driver/controller/dash_board_controller.dart';
import 'package:cabme_driver/controller/my_profile_controller.dart';
import 'package:cabme_driver/themes/app_bar_custom.dart';
import 'package:cabme_driver/themes/button_them.dart';
import 'package:cabme_driver/themes/constant_colors.dart';
import 'package:cabme_driver/themes/custom_widget.dart';
import 'package:cabme_driver/themes/responsive.dart';
import 'package:cabme_driver/themes/text_field_them.dart';
import 'package:cabme_driver/utils/dark_theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class ChangePasswordScreen extends StatelessWidget {
  ChangePasswordScreen({super.key});

  final GlobalKey<FormState> _passwordKey = GlobalKey();

  /// For Profile Information

  final dashboardController = Get.put(DashBoardController());

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return GetX<MyProfileController>(
        init: MyProfileController(),
        builder: (myProfileController) {
          return Scaffold(
            appBar: AppbarCustom(title: 'Change Password'.tr),
            body: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(
                    height: 20,
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: themeChange.getThem() ? AppThemeData.surface50Dark : AppThemeData.surface50,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Form(
                        key: _passwordKey,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            TextFieldWidget(
                              contentPadding: const EdgeInsets.symmetric(vertical: 14),
                              isBorderEnable: false,
                              prefix: IconButton(
                                onPressed: () {},
                                icon: SvgPicture.asset(
                                  'assets/icons/ic_lock.svg',
                                  width: 20,
                                  height: 20,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              controller: myProfileController.currentPasswordController.value,
                              hintText: 'Current Password'.tr,
                              validators: (String? value) {
                                if (value!.isNotEmpty) {
                                  return null;
                                } else {
                                  return "required".tr;
                                }
                              },
                            ),
                            dividerCust(
                              isDarkMode: themeChange.getThem(),
                            ),
                            TextFieldWidget(
                              contentPadding: const EdgeInsets.symmetric(vertical: 14),
                              isBorderEnable: false,
                              prefix: IconButton(
                                onPressed: () {},
                                icon: SvgPicture.asset(
                                  'assets/icons/ic_lock.svg',
                                  width: 20,
                                  height: 20,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              controller: myProfileController.newPasswordController.value,
                              hintText: 'New Password'.tr,
                              validators: (String? value) {
                                if (value!.isNotEmpty) {
                                  return null;
                                } else {
                                  return "required".tr;
                                }
                              },
                            ),
                            dividerCust(
                              isDarkMode: themeChange.getThem(),
                            ),
                            TextFieldWidget(
                                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                                isBorderEnable: false,
                                prefix: IconButton(
                                  onPressed: () {},
                                  icon: SvgPicture.asset(
                                    'assets/icons/ic_lock.svg',
                                    width: 20,
                                    height: 20,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                controller: myProfileController.confirmPasswordController.value,
                                hintText: 'Confirm Password'.tr,
                                validators: (String? value) {
                                  if (value!.isNotEmpty) {
                                    if (value == myProfileController.newPasswordController.value.text) {
                                      return null;
                                    } else {
                                      return "Password Field do not match  !!".tr;
                                    }
                                  } else {
                                    return "required".tr;
                                  }
                                })
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            bottomNavigationBar: SizedBox(
              height: 80,
              width: Responsive.width(100, context),
              child: Center(
                child: ButtonThem.buildButton(context,
                    title: 'Save Password'.tr,
                    btnWidthRatio: 0.7,
                    btnColor: AppThemeData.primary200,
                    txtColor: themeChange.getThem() ? AppThemeData.grey50Dark : AppThemeData.grey50, onPress: () {
                  if (_passwordKey.currentState!.validate()) {
                    myProfileController.updatePassword({
                      "id_driver": myProfileController.userID.value,
                      "anc_mdp": myProfileController.currentPasswordController.value.text,
                      "new_mdp": myProfileController.newPasswordController.value.text,
                      "user_cat": "driver",
                    }).then((value) {
                      if (value == true) {
                        myProfileController.currentPasswordController.value.clear();
                        myProfileController.newPasswordController.value.clear();
                        myProfileController.confirmPasswordController.value.clear();
                        Get.back();
                        ShowToastDialog.showToast("MPIN Updated Successfully!");
                      }
                    });
                  }
                }),
              ),
            ),
          );
        });
  }

  ListTile buildShowDetails({
    required String title,
    required String icon,
    required Function()? onPress,
    required bool isDarkMode,
  }) {
    return ListTile(
      leading: SvgPicture.asset(
        icon,
        width: 20,
        height: 20,
        colorFilter: ColorFilter.mode(
          isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900,
          BlendMode.srcIn,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontFamily: AppThemeData.medium,
          color: isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900,
        ),
      ),
      onTap: onPress,
      trailing: SvgPicture.asset(
        'assets/icons/ic_right_arrow.svg',
        width: 20,
        height: 20,
        colorFilter: ColorFilter.mode(
          isDarkMode ? AppThemeData.grey300Dark : AppThemeData.grey400,
          BlendMode.srcIn,
        ),
      ),
    );
  }
}
