// ignore_for_file: must_be_immutable

import 'dart:convert';
import 'dart:io';

import 'package:cabme_driver/constant/constant.dart';
import 'package:cabme_driver/constant/show_toast_dialog.dart';
import 'package:cabme_driver/controller/dash_board_controller.dart';
import 'package:cabme_driver/controller/my_profile_controller.dart';
import 'package:cabme_driver/model/user_model.dart';
import 'package:cabme_driver/page/auth_screens/login_screen.dart';
import 'package:cabme_driver/page/my_profile/change_password_screen.dart';
import 'package:cabme_driver/page/my_profile/edit_profile_screen.dart';
import 'package:cabme_driver/themes/app_bar_custom.dart';
import 'package:cabme_driver/themes/button_them.dart';
import 'package:cabme_driver/themes/constant_colors.dart';
import 'package:cabme_driver/themes/custom_widget.dart';
import 'package:cabme_driver/themes/responsive.dart';
import 'package:cabme_driver/themes/text_field_them.dart';
import 'package:cabme_driver/utils/Preferences.dart';
import 'package:cabme_driver/utils/dark_theme_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class MyProfileScreen extends StatelessWidget {
  MyProfileScreen({super.key});

  final GlobalKey<FormState> _passwordKey = GlobalKey();

  TextEditingController vColorController = TextEditingController();
  TextEditingController vCarRegistrationController = TextEditingController();

  final dashboardController = Get.put(DashBoardController());

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return GetX<MyProfileController>(
        init: MyProfileController(),
        builder: (myProfileController) {
          return Scaffold(
            bottomNavigationBar: SizedBox(
              height: 80,
              child: Column(
                children: [
                  buildShowDetails(
                    isTrailingShow: false,
                    textIconColor: AppThemeData.error50,
                    isDarkMode: themeChange.getThem(),
                    title: "Delete Account".tr,
                    icon: 'assets/icons/ic_delete.svg',
                    onPress: () async {
                      await showDialog(
                          context: context,
                          useSafeArea: true,
                          builder: (context) {
                            return AlertDialog(
                              title: Text(
                                'Are you sure you want to delete account?'.tr,
                                style: const TextStyle(fontSize: 16),
                              ),
                              actions: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: ButtonThem.buildButton(
                                        context,
                                        title: 'No'.tr,
                                        btnColor: Colors.red,
                                        txtColor: Colors.white,
                                        onPress: () {
                                          Get.back();
                                        },
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 10,
                                    ),
                                    Expanded(
                                      child: ButtonThem.buildButton(
                                        context,
                                        title: 'Yes'.tr,
                                        btnColor: AppThemeData.primary200,
                                        txtColor: Colors.white,
                                        onPress: () {
                                          myProfileController.deleteAccount(myProfileController.userID.toString()).then((value) {
                                            if (value != null) {
                                              if (value["success"] == "success") {
                                                ShowToastDialog.showToast(value['message']);
                                                Get.back();
                                                Preferences.clearSharPreference();
                                                Get.offAll(const LoginScreen());
                                              }
                                            }
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                )
                              ],
                            );
                          });
                    },
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                ],
              ),
            ),
            appBar: AppbarCustom(title: 'My Profile'.tr),
            body: Column(
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    padding: const EdgeInsets.only(top: 30),
                    height: 180,
                    width: 160,
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        Center(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(100),
                            child: myProfileController.profileImage.isEmpty
                                ? CachedNetworkImage(
                                    imageUrl: "https://cabme.siswebapp.com/assets/images/placeholder_image.jpg",
                                    height: 130,
                                    width: 130,
                                    fit: BoxFit.cover,
                                    progressIndicatorBuilder: (context, url, downloadProgress) => Constant.loader(context, isDarkMode: themeChange.getThem()),
                                    errorWidget: (context, url, error) => Image.asset(
                                      "assets/images/appIcon.png",
                                    ),
                                  )
                                : CachedNetworkImage(
                                    imageUrl: myProfileController.profileImage.toString(),
                                    height: 130,
                                    width: 130,
                                    fit: BoxFit.cover,
                                    progressIndicatorBuilder: (context, url, downloadProgress) => Constant.loader(context, isDarkMode: themeChange.getThem()),
                                    errorWidget: (context, url, error) => Image.asset(
                                      "assets/images/appIcon.png",
                                    ),
                                  ),
                          ),
                        ),
                        Positioned(
                          bottom: 10,
                          right: 20,
                          child: InkWell(
                            onTap: () => buildBottomSheet(context, myProfileController, themeChange.getThem()),
                            child: Image.asset(
                              themeChange.getThem() ? 'assets/icons/ic_edit_dark.png' : 'assets/icons/ic_edit_light.png',
                              fit: BoxFit.cover,
                              width: 35,
                              height: 35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: themeChange.getThem() ? AppThemeData.surface50Dark : AppThemeData.surface50,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      buildShowDetails(
                        isDarkMode: themeChange.getThem(),
                        title: "Edit Profile".tr,
                        icon: 'assets/icons/ic_profile.svg',
                        onPress: () {
                          Get.to(EditProfileScreen());
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: dividerCust(isDarkMode: themeChange.getThem()),
                      ),
                      buildShowDetails(
                        isDarkMode: themeChange.getThem(),
                        title: "Change Password".tr,
                        icon: 'assets/icons/ic_lock.svg',
                        onPress: () {
                          Get.to(ChangePasswordScreen());
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        });
  }

  ListTile buildShowDetails({
    required String title,
    required String icon,
    required Function()? onPress,
    required bool isDarkMode,
    Color? textIconColor,
    bool? isTrailingShow = true,
  }) {
    return ListTile(
      splashColor: Colors.transparent,
      leading: SvgPicture.asset(
        icon,
        width: 20,
        height: 20,
        colorFilter: ColorFilter.mode(
          textIconColor ?? (isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900),
          BlendMode.srcIn,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontFamily: AppThemeData.medium,
          color: textIconColor ?? (isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900),
        ),
      ),
      onTap: onPress,
      trailing: isTrailingShow == false
          ? null
          : SvgPicture.asset(
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

  Future<dynamic> buildAlertChangePassword(
    BuildContext context, {
    required MyProfileController myProfileController,
  }) {
    return Get.defaultDialog(
      titlePadding: const EdgeInsets.only(top: 20),
      radius: 6,
      title: "change password".tr,
      titleStyle: const TextStyle(
        fontSize: 20,
      ),
      content: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Form(
          key: _passwordKey,
          autovalidateMode: AutovalidateMode.disabled,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFieldThem.boxBuildTextField(
                hintText: "Current Password".tr,
                obscureText: false,
                controller: myProfileController.currentPasswordController.value,
                validators: (valve) {
                  if (valve!.isNotEmpty) {
                    return null;
                  } else {
                    return "required".tr;
                  }
                },
              ),
              const SizedBox(
                height: 10,
              ),
              TextFieldThem.boxBuildTextField(
                hintText: "New Password".tr,
                obscureText: false,
                controller: myProfileController.newPasswordController.value,
                validators: (valve) {
                  if (valve!.isNotEmpty) {
                    return null;
                  } else {
                    return "required".tr;
                  }
                },
              ),
              const SizedBox(
                height: 10,
              ),
              TextFieldThem.boxBuildTextField(
                hintText: "Confirm Password".tr,
                obscureText: false,
                controller: myProfileController.confirmPasswordController.value,
                validators: (valve) {
                  if (valve!.isNotEmpty) {
                    if (valve == myProfileController.newPasswordController.value.text) {
                      return null;
                    } else {
                      return "Password Field do not match  !!".tr;
                    }
                  } else {
                    return "required".tr;
                  }
                },
              ),
              const SizedBox(
                height: 20,
              ),
              Row(
                children: [
                  ButtonThem.buildButton(
                    context,
                    title: "Save".tr,
                    btnColor: AppThemeData.primary200,
                    txtColor: Colors.white,
                    btnHeight: 40,
                    btnWidthRatio: 0.3,
                    onPress: () {
                      if (_passwordKey.currentState!.validate()) {
                        myProfileController.updatePassword({
                          "id_driver": myProfileController.userID.value,
                          "anc_mdp": myProfileController.currentPasswordController.value.text,
                          "new_mdp": myProfileController.newPasswordController.value.text,
                          "user_cat": "driver",
                        }).then((value) {
                          Get.back();
                          if (value == true) {
                            ShowToastDialog.showToast("Password Updated!!");
                          } else {
                            ShowToastDialog.showToast(value.toString());
                          }
                        });
                      }
                    },
                  ),
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

  Future<dynamic> buildBottomSheet(BuildContext context, MyProfileController controller, bool isDarkMode) {
    return showModalBottomSheet(
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (context, setState) {
            return Container(
              height: Responsive.height(22, context),
              color: isDarkMode ? AppThemeData.surface50Dark : AppThemeData.surface50,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 15),
                    child: Text(
                      "Please Select".tr,
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: AppThemeData.semiBold,
                        color: isDarkMode ? AppThemeData.grey50 : AppThemeData.grey50Dark,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            IconButton(
                                onPressed: () => pickFile1(controller, source: ImageSource.camera),
                                icon: Icon(
                                  Icons.camera_alt,
                                  size: 32,
                                  color: isDarkMode ? AppThemeData.grey50 : AppThemeData.grey50Dark,
                                )),
                            Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Text(
                                "camera".tr,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontFamily: AppThemeData.medium,
                                  color: isDarkMode ? AppThemeData.grey50 : AppThemeData.grey50Dark,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            IconButton(
                                onPressed: () => pickFile1(controller, source: ImageSource.gallery),
                                icon: Icon(
                                  Icons.photo_library_sharp,
                                  size: 32,
                                  color: isDarkMode ? AppThemeData.grey50 : AppThemeData.grey50Dark,
                                )),
                            Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Text(
                                "gallery".tr,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontFamily: AppThemeData.medium,
                                  color: isDarkMode ? AppThemeData.grey50 : AppThemeData.grey50Dark,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ],
              ),
            );
          });
        });
  }

  String? requiredValidator(String? value) {
    if (value != null || value!.isNotEmpty) {
      return null;
    } else {
      return "required".tr;
    }
  }

  final ImagePicker _imagePicker = ImagePicker();

  Future pickFile1(MyProfileController controller, {required ImageSource source}) async {
    try {
      XFile? image = await _imagePicker.pickImage(source: source);
      if (image == null) return;
      Get.back();
      controller.uploadPhoto(File(image.path)).then((value) async {
        if (value != null) {
          if (value["success"] == "Success") {
            UserModel userModel = Constant.getUserData();
            userModel.userData!.photoPath = value['data']['photo_path'];
            Preferences.setString(Preferences.user, jsonEncode(userModel.toJson()));
            controller.getUsrData();
            dashboardController.getUsrData();
            ShowToastDialog.showToast("Upload successfully!");
          } else {
            ShowToastDialog.showToast(value['error']);
          }
        }
      });
    } on PlatformException catch (e) {
      ShowToastDialog.showToast("${"Failed to Pick".tr} : \n $e");
    }
  }
}
