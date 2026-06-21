import 'package:cabme_driver/constant/show_toast_dialog.dart';
import 'package:cabme_driver/controller/localization_controller.dart';
import 'package:cabme_driver/on_boarding_screen.dart';
import 'package:cabme_driver/service/localization_service.dart';
import 'package:cabme_driver/themes/app_bar_custom.dart';
import 'package:cabme_driver/themes/button_them.dart';
import 'package:cabme_driver/themes/constant_colors.dart';
import 'package:cabme_driver/utils/Preferences.dart';
import 'package:cabme_driver/utils/dark_theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class LocalizationScreens extends StatelessWidget {
  final String intentType;

  const LocalizationScreens({super.key, required this.intentType});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return GetX<LocalizationController>(
      init: LocalizationController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: themeChange.getThem() ? AppThemeData.surface50Dark : AppThemeData.surface50,
          appBar: AppbarCustom(
            title: '',
            elevation: 0,
            isLeadingIcon: intentType != "dashBoard",
            actions: [
              if (intentType != "dashBoard")
                InkWell(
                  splashColor: Colors.transparent,
                  onTap: () {
                    LocalizationService().changeLocale(controller.selectedLanguage.value);
                    Preferences.setString(Preferences.languageCodeKey, controller.selectedLanguage.toString());
                    if (intentType == "dashBoard") {
                      ShowToastDialog.showToast("Language change successfully");
                    } else {
                      Get.offAll(const OnBoardingScreen(), transition: Transition.rightToLeft);
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Text(
                      'Skip'.tr,
                      style: TextStyle(
                        fontSize: 16,
                        decoration: TextDecoration.underline,
                        decorationColor: AppThemeData.secondary200,
                        color: AppThemeData.secondary200,
                        fontFamily: AppThemeData.regular,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 20, bottom: 6),
                  child: Text(
                    'Select your language'.tr,
                    style: TextStyle(
                      fontSize: 22,
                      fontFamily: AppThemeData.semiBold,
                      color: themeChange.getThem() ? AppThemeData.grey900Dark : AppThemeData.grey900,
                    ),
                  ),
                ),
                Text(
                  'Choose a language to personalize your CabME experience.'.tr,
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: AppThemeData.regular,
                    color: themeChange.getThem() ? AppThemeData.grey900Dark : AppThemeData.grey900,
                  ),
                ),
                const SizedBox(height: 30),
                Expanded(
                  child: ListView.separated(
                    separatorBuilder: (context, index) {
                      return Container(
                        height: 0.6,
                        color: themeChange.getThem() ? AppThemeData.grey300Dark : AppThemeData.grey100,
                      );
                    },
                    itemCount: controller.languageList.length,
                    shrinkWrap: true,
                    itemBuilder: (context, index) {
                      return Obx(
                        () => InkWell(
                          splashColor: Colors.transparent,
                          onTap: () {
                            controller.selectedLanguage.value = controller.languageList[index].code.toString();
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 16,
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(6),
                                            child: Image.network(
                                              controller.languageList[index].flag.toString(),
                                              height: 35,
                                              width: 50,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Align(
                                              alignment: Alignment.bottomRight,
                                              child: Text(
                                                controller.languageList[index].language.toString(),
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontFamily: AppThemeData.medium,
                                                  color: themeChange.getThem() ? AppThemeData.grey900Dark : AppThemeData.grey900,
                                                ),
                                              ))
                                        ],
                                      ),
                                    ),
                                    controller.languageList[index].code == controller.selectedLanguage.value
                                        ? SvgPicture.asset(
                                            "assets/icons/ic_radio_selected.svg",
                                            // colorFilter: ColorFilter.mode(
                                            //   themeChange.getThem() ? AppThemeData.grey300 : AppThemeData.grey600,
                                            //   BlendMode.srcIn,
                                            // ),
                                          )
                                        : SvgPicture.asset(
                                            "assets/icons/ic_radio_unselected.svg",
                                            // colorFilter: ColorFilter.mode(
                                            //   themeChange.getThem() ? AppThemeData.grey300 : AppThemeData.grey600,
                                            //   BlendMode.srcIn,
                                            // ),
                                          )
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (intentType != "dashBoard")
                  Text(
                    'You can skip this steps and change it later in your profile settings.'.tr,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: AppThemeData.light,
                      color: themeChange.getThem() ? AppThemeData.grey400Dark : AppThemeData.grey400,
                    ),
                  ),
                const SizedBox(height: 5),
              ],
            ),
          ),
          bottomNavigationBar: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Center(
                heightFactor: 1,
                child: ButtonThem.buildButton(
                  context,
                  title: intentType == "dashBoard" ? "Update".tr : 'Continue'.tr,
                  btnWidthRatio: 0.6,
                  txtColor: themeChange.getThem() ? AppThemeData.grey50 : AppThemeData.grey50Dark,
                  onPress: () async {
                    LocalizationService().changeLocale(controller.selectedLanguage.value);
                    Preferences.setString(Preferences.languageCodeKey, controller.selectedLanguage.toString());
                    if (intentType == "dashBoard") {
                      ShowToastDialog.showToast("Language change successfully".tr);
                    } else {
                      Get.offAll(const OnBoardingScreen());
                    }
                  },
                ),
              )),
        );
      },
    );
  }
}
