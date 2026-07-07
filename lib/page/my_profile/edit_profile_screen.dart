// ignore_for_file: must_be_immutable

import 'dart:convert';
import 'package:cabme_driver/constant/constant.dart';
import 'package:cabme_driver/constant/show_toast_dialog.dart';
import 'package:cabme_driver/controller/dash_board_controller.dart';
import 'package:cabme_driver/controller/my_profile_controller.dart';
import 'package:cabme_driver/model/user_model.dart';
import 'package:cabme_driver/themes/app_bar_custom.dart';
import 'package:cabme_driver/themes/button_them.dart';
import 'package:cabme_driver/themes/constant_colors.dart';
import 'package:cabme_driver/themes/custom_widget.dart';
import 'package:cabme_driver/themes/text_field_them.dart';
import 'package:cabme_driver/utils/Preferences.dart';
import 'package:cabme_driver/utils/dark_theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/countries.dart';
import 'package:provider/provider.dart';

class EditProfileScreen extends StatelessWidget {
  EditProfileScreen({super.key});

  final GlobalKey<FormState> passwordKey = GlobalKey();

  /// For Profile Information

  final dashboardController = Get.put(DashBoardController());

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return GetX<MyProfileController>(
        init: MyProfileController(),
        builder: (myProfileController) {
          return Scaffold(
            appBar: AppbarCustom(title: 'My Profile'.tr),
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
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextFieldWidget(
                                  isBorderEnable: false,
                                  prefix: IconButton(
                                    onPressed: () {},
                                    icon: SvgPicture.asset(
                                      'assets/icons/ic_user.svg',
                                      width: 20,
                                      height: 20,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  controller: myProfileController.nameController.value,
                                  hintText: 'First Name'.tr,
                                  validators: (String? value) {
                                    if (value != null || value!.isNotEmpty) {
                                      return null;
                                    } else {
                                      return "required".tr;
                                    }
                                  },
                                  onSubmitBtn: (v) {
                                    if (myProfileController.nameController.value.text.isNotEmpty) {
                                      myProfileController.updateFirstName({
                                        "id_user": myProfileController.userID.value,
                                        "prenom": myProfileController.nameController.value.text,
                                        "user_cat": "driver",
                                      }).then((value) {
                                        if (value != null) {
                                          if (value["success"] == "success") {
                                            UserModel userModel = Constant.getUserData();
                                            userModel.userData!.prenom = value['data']['prenom'];
                                            Preferences.setString(Preferences.user, jsonEncode(userModel.toJson()));
                                            myProfileController.getUsrData();
                                            dashboardController.getUsrData();
                                            ShowToastDialog.showToast(value['message']);
                                            Get.back();
                                          }
                                        } else {
                                          ShowToastDialog.showToast(value['error']);
                                          Get.back();
                                        }
                                      });
                                    }
                                    return null;
                                    //
                                  },
                                ),
                              ),
                              SizedBox(
                                height: 50,
                                width: 1,
                                child: dividerCust(
                                  isDarkMode: themeChange.getThem(),
                                ),
                              ),
                              Expanded(
                                child: TextFieldWidget(
                                    isBorderEnable: false,
                                    prefix: IconButton(
                                      onPressed: () {},
                                      icon: SvgPicture.asset(
                                        'assets/icons/ic_user.svg',
                                        width: 20,
                                        height: 20,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    controller: myProfileController.lastNameController.value,
                                    hintText: 'Last Name'.tr,
                                    validators: (String? value) {
                                      if (value != null || value!.isNotEmpty) {
                                        return null;
                                      } else {
                                        return "required".tr;
                                      }
                                    },
                                    onSubmitBtn: (v) {
                                      if (myProfileController.lastNameController.value.text.isNotEmpty) {
                                        myProfileController.updateLastName({
                                          "id_user": myProfileController.userID.value,
                                          "nom": myProfileController.lastNameController.value.text,
                                          "user_cat": "driver",
                                        }).then((value) {
                                          if (value != null) {
                                            if (value["success"] == "success") {
                                              UserModel userModel = Constant.getUserData();
                                              userModel.userData!.nom = value['data']['nom'];
                                              Preferences.setString(Preferences.user, jsonEncode(userModel.toJson()));
                                              myProfileController.getUsrData();
                                              dashboardController.getUsrData();
                                              ShowToastDialog.showToast(value['message']);
                                              Get.back();
                                            } else {
                                              ShowToastDialog.showToast(value['error']);
                                              Get.back();
                                            }
                                          }
                                        });
                                      }
                                      return null;
                                    }),
                              ),
                            ],
                          ),
                          dividerCust(
                            isDarkMode: themeChange.getThem(),
                          ),
                          IntlPhoneField(
                            countries: countries.where((country) => country.code == 'IN').toList(),
                            initialCountryCode: 'IN',
                            textAlign: TextAlign.start,
                            flagsButtonPadding: const EdgeInsets.symmetric(horizontal: 8),
                            readOnly: true,
                            initialValue: myProfileController.phoneController.value.text,
                            onChanged: (phone) {
                              myProfileController.phoneController.value.text = phone.completeNumber;
                            },
                            invalidNumberMessage: "number invalid".tr,
                            showDropdownIcon: false,
                            disableLengthCheck: true,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              focusedBorder: UnderlineInputBorder(
                                borderRadius: const BorderRadius.only(),
                                borderSide: BorderSide(
                                  color: AppThemeData.primary200,
                                  width: 0.8,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                              hintText: 'Phone Number'.tr,
                              isDense: true,
                            ),
                          ),
                          dividerCust(
                            isDarkMode: themeChange.getThem(),
                          ),
                          TextFieldWidget(
                              isReadOnly: true,
                              isBorderEnable: false,
                              prefix: IconButton(
                                onPressed: () {},
                                icon: SvgPicture.asset(
                                  'assets/icons/ic_email.svg',
                                  width: 20,
                                  height: 20,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              suffix: IconButton(
                                onPressed: () {
                                  buildAlertChangeData(
                                    context,
                                    title: 'email'.tr,
                                    controller: myProfileController.emailController.value,
                                    validators: (String? value) {
                                      if (value != null && value.isNotEmpty) {
                                        return null;
                                      } else {
                                        return "required".tr;
                                      }
                                    },
                                    onSubmitBtn: () {
                                      if (myProfileController.emailController.value.text.isNotEmpty) {
                                        myProfileController.updateEmail({
                                          "id_user": myProfileController.userID.value,
                                          "email": myProfileController.emailController.value.text,
                                          "user_cat": "driver",
                                        }).then((value) {
                                          if (value != null) {
                                            if (value["success"] == "success") {
                                              UserModel userModel = Constant.getUserData();
                                              userModel.userData!.email = value['data']['email'];
                                              Preferences.setString(Preferences.user, jsonEncode(userModel.toJson()));
                                              myProfileController.getUsrData();
                                              dashboardController.getUsrData();
                                              ShowToastDialog.showToast(value['message']);
                                              Get.back(); // close dialog
                                            } else {
                                              ShowToastDialog.showToast(value['error']);
                                              Get.back(); // close dialog
                                            }
                                          }
                                        });
                                      }
                                    },
                                  );
                                },
                                icon: Icon(
                                  Icons.edit,
                                  color: themeChange.getThem() ? AppThemeData.grey500Dark : AppThemeData.grey300Dark,
                                  size: 20,
                                ),
                              ),
                              controller: myProfileController.emailController.value,
                              hintText: 'email'.tr,
                              validators: (String? value) {
                                return null;
                              },
                              onSubmitBtn: (v) {
                                return null;
                              }),
                          dividerCust(
                            isDarkMode: themeChange.getThem(),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextFieldWidget(
                                    isBorderEnable: false,
                                    prefix: IconButton(
                                      onPressed: () {},
                                      icon: Icon(
                                        Icons.phone_android,
                                        color: themeChange.getThem() ? AppThemeData.grey500Dark : AppThemeData.grey300Dark,
                                      ),
                                    ),
                                    controller: myProfileController.alternatePhoneController.value,
                                    hintText: 'Alternate Phone Number'.tr,
                                    validators: (String? value) {
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () {
                                    String phoneVal = myProfileController.alternatePhoneController.value.text.trim();
                                    if (phoneVal.isEmpty) {
                                      ShowToastDialog.showToast("Please enter alternate phone number".tr);
                                      return;
                                    }
                                    myProfileController.showOtpVerificationDialog(context, phoneVal);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppThemeData.primary200,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: Text("Verify".tr),
                                ),
                              ],
                            ),
                          ),
                          dividerCust(
                            isDarkMode: themeChange.getThem(),
                          ),
                          Obx(() => SwitchListTile(
                            title: Text(
                              'Marketplace Visibility'.tr,
                              style: TextStyle(
                                color: themeChange.getThem() ? Colors.white : Colors.black,
                              ),
                            ),
                            subtitle: Text(
                              myProfileController.marketplaceEnabled.value
                                  ? 'Marketplace is active'.tr
                                  : 'Marketplace is disabled'.tr,
                              style: TextStyle(
                                color: themeChange.getThem() ? Colors.white70 : Colors.black54,
                                fontSize: 12,
                              ),
                            ),
                            value: myProfileController.marketplaceEnabled.value,
                            activeColor: AppThemeData.primary200,
                            onChanged: (bool value) {
                              myProfileController.toggleMarketplace(value);
                            },
                          )),
                        ],
                      ),
                    ),
                  ),
                ],
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

  Future<dynamic> buildAlertChangeData(
    BuildContext context, {
    required String title,
    required TextEditingController controller,
    required String? Function(String?) validators,
    required Function() onSubmitBtn,
  }) {
    final GlobalKey<FormState> formKey = GlobalKey();
    return Get.defaultDialog(
      titlePadding: const EdgeInsets.only(top: 20),
      radius: 6,
      title: "Change Information".tr,
      titleStyle: const TextStyle(
        fontSize: 20,
      ),
      content: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Form(
          key: formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFieldThem.boxBuildTextField(hintText: title, controller: controller, validators: validators),
              const SizedBox(
                height: 20,
              ),
              Row(
                children: [
                  ButtonThem.buildButton(context,
                      title: "Save".tr, btnColor: AppThemeData.primary200, txtColor: Colors.white, onPress: onSubmitBtn, btnHeight: 40, btnWidthRatio: 0.3),
                  const SizedBox(
                    width: 15,
                  ),
                  ButtonThem.buildBorderButton(context,
                      title: "cancel".tr,
                      btnHeight: 40,
                      btnWidthRatio: 0.3,
                      btnColor: Colors.white,
                      txtColor: AppThemeData.primary200,
                      onPress: () => Get.back(),
                      btnBorderColor: AppThemeData.primary200),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
