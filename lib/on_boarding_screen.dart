// ignore_for_file: deprecated_member_use, implicit_call_tearoffs

import 'package:cabme_driver/constant/constant.dart';
import 'package:cabme_driver/controller/on_boarding_controller.dart';
import 'package:cabme_driver/page/MainDashBoard/screen/main_dashboard.dart';
import 'package:cabme_driver/themes/app_bar_custom.dart';
import 'package:cabme_driver/themes/button_them.dart';
import 'package:cabme_driver/themes/constant_colors.dart';
import 'package:cabme_driver/themes/responsive.dart';
import 'package:cabme_driver/utils/dark_theme_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import 'utils/Preferences.dart';

class OnBoardingScreen extends StatelessWidget {
  const OnBoardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return GetX<OnBoardingController>(
      init: OnBoardingController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: themeChange.getThem() ? AppThemeData.surface50Dark : AppThemeData.surface50,
          appBar: AppbarCustom(
            elevation: 0,
            bgColor: themeChange.getThem() ? AppThemeData.surface50Dark : AppThemeData.surface50,
            title: '',
            isLeadingIcon: controller.selectedPageIndex.value != 0,
            leading: IconButton(
                onPressed: () {
                  controller.selectedPageIndex.value = controller.selectedPageIndex.value - 1;
                  controller.pageController.jumpToPage(controller.selectedPageIndex.value);
                  controller.update();
                },
                icon: SvgPicture.asset(
                  "assets/icons/ic_back_arrow.svg",
                  colorFilter: ColorFilter.mode(
                    themeChange.getThem() ? AppThemeData.grey900Dark : AppThemeData.grey900,
                    BlendMode.srcIn,
                  ),
                )),
            actions: [
              if (controller.isLoading.value == false && controller.selectedPageIndex.value != ((controller.onboardingModel.value.data?.length ?? 2) - 1))
                InkWell(
                  splashColor: Colors.transparent,
                  onTap: () {
                    Preferences.setBoolean(Preferences.isFinishOnBoardingKey, true);
                    // Get.offAll(const LoginScreen());
                    Get.offAll(const MainDashboard());
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(right: 20),
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
          body: SafeArea(
            child: controller.isLoading.value == true
                ? SizedBox()
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: PageView.builder(
                            controller: controller.pageController,
                            onPageChanged: controller.selectedPageIndex,
                            itemCount: controller.onboardingModel.value.data?.length,
                            itemBuilder: (context, index) {
                              return Column(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Center(
                                      child: CachedNetworkImage(
                                        filterQuality: FilterQuality.high,
                                        fit: BoxFit.cover,
                                        width: Responsive.width(75, context),
                                        height: Responsive.width(75, context),
                                        imageUrl: controller.onboardingModel.value.data?[index].image ?? '',
                                        placeholder: (context, url) => Constant.loader(context, isDarkMode: themeChange.getThem()),
                                        errorWidget: (context, url, error) => Image.asset(
                                          controller.localImage[index],
                                          fit: BoxFit.cover,
                                          width: Responsive.width(75, context),
                                          height: Responsive.width(75, context),
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Expanded(
                                  //   flex: 2,
                                  //   child: Center(
                                  //     child: Image.asset(
                                  //       controller.localImage[index],
                                  //       fit: BoxFit.cover,
                                  //       width: Responsive.width(75, context),
                                  //       height: Responsive.width(75, context),
                                  //     ),
                                  //   ),
                                  // ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 10, bottom: 50),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: List.generate(
                                        controller.onboardingModel.value.data?.length ?? 0,
                                        (index) => Container(
                                          margin: const EdgeInsets.symmetric(horizontal: 4),
                                          width: controller.selectedPageIndex.value == index ? 38 : 10,
                                          height: 10,
                                          decoration: BoxDecoration(
                                            color: controller.selectedPageIndex.value == index
                                                ? themeChange.getThem()
                                                    ? AppThemeData.primary200
                                                    : AppThemeData.primary200
                                                : AppThemeData.grey200,
                                            borderRadius: const BorderRadius.all(Radius.circular(20.0)),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 40),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Text(
                                          controller.onboardingModel.value.data?[index].title ?? '',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              fontSize: 24,
                                              color: themeChange.getThem() ? AppThemeData.grey900Dark : AppThemeData.grey900,
                                              fontFamily: AppThemeData.semiBold,
                                              letterSpacing: 1.5),
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          controller.onboardingModel.value.data?[index].description ?? '',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: themeChange.getThem() ? AppThemeData.grey900Dark : AppThemeData.grey900,
                                            letterSpacing: 1.5,
                                            fontFamily: AppThemeData.regular,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }),
                      ),
                      const SizedBox(
                        height: 40,
                      ),
                      if (controller.onboardingModel.value.data != null && controller.selectedPageIndex.value == (controller.onboardingModel.value.data!.length - 1))
                        Center(
                          heightFactor: 1,
                          child: ButtonThem.buildButton(
                            context,
                            title: 'Start Your Journey'.tr,
                            btnHeight: 55,
                            btnWidthRatio: 0.6,
                            txtColor: AppThemeData.grey900,
                            onPress: () async {
                              Preferences.setBoolean(Preferences.isFinishOnBoardingKey, true);
                              Get.offAll(const MainDashboard());
                              // Get.offAll(const LoginScreen());
                            },
                          ),
                        ),
                      if (controller.onboardingModel.value.data != null && controller.selectedPageIndex.value != (controller.onboardingModel.value.data!.length - 1))
                        Center(
                          heightFactor: 1,
                          child: ButtonThem.buildButton(
                            context,
                            title: 'Next'.tr,
                            btnHeight: 55,
                            btnWidthRatio: 0.6,
                            txtColor: AppThemeData.grey900,
                            onPress: () async {
                              controller.selectedPageIndex.value = controller.selectedPageIndex.value + 1;
                              controller.pageController.jumpToPage(controller.selectedPageIndex.value);
                            },
                          ),
                        ),
                      const SizedBox(height: 40),
                    ],
                  ),
          ),
        );
      },
    );
  }

  BorderRadiusGeometry borderRadius(int index, int currentIndex) {
    if (index == 0 && currentIndex == 0) {
      return const BorderRadius.all(Radius.circular(10.0));
    }
    if (index == 0 && currentIndex == 1) {
      return const BorderRadius.only(topLeft: Radius.circular(40.0), bottomLeft: Radius.circular(40.0));
    }
    if (index == 0 && currentIndex == 2) {
      return const BorderRadius.only(topRight: Radius.circular(40.0), bottomRight: Radius.circular(40.0));
    }
    if (index == 1 && currentIndex == 1) {
      return const BorderRadius.all(Radius.circular(10.0));
    }
    if (index == 1 && currentIndex == 1) {
      return const BorderRadius.all(Radius.circular(10.0));
    }
    if (index == 1 && currentIndex == 2) {
      return const BorderRadius.all(Radius.circular(10.0));
    }
    if (index == 2 && currentIndex == 2) {
      return const BorderRadius.all(Radius.circular(10.0));
    }
    if (index == 2 && currentIndex == 0) {
      return const BorderRadius.only(topLeft: Radius.circular(40.0), bottomLeft: Radius.circular(40.0));
    }
    if (index == 2 && currentIndex == 1) {
      return const BorderRadius.only(topRight: Radius.circular(40.0), bottomRight: Radius.circular(40.0));
    }
    return const BorderRadius.all(Radius.circular(10.0));
  }
}
