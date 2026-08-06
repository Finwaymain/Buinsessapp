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
    final isDark = themeChange.getThem();

    return GetX<OnBoardingController>(
      init: OnBoardingController(),
      builder: (controller) {
        final dataLength = controller.onboardingModel.value.data?.length ?? 0;
        final isLastPage = dataLength > 0 && controller.selectedPageIndex.value == dataLength - 1;

        return Scaffold(
          backgroundColor: isDark ? AppThemeData.surface50Dark : AppThemeData.surface50,
          appBar: AppbarCustom(
            elevation: 0,
            bgColor: isDark ? AppThemeData.surface50Dark : AppThemeData.surface50,
            title: '',
            isLeadingIcon: controller.selectedPageIndex.value != 0,
            leading: IconButton(
              onPressed: () {
                if (controller.selectedPageIndex.value > 0) {
                  controller.selectedPageIndex.value = controller.selectedPageIndex.value - 1;
                  controller.pageController.animateToPage(
                    controller.selectedPageIndex.value,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              },
              icon: SvgPicture.asset(
                "assets/icons/ic_back_arrow.svg",
                colorFilter: ColorFilter.mode(
                  isDark ? AppThemeData.grey900Dark : AppThemeData.grey900,
                  BlendMode.srcIn,
                ),
              ),
            ),
            actions: [
              if (!controller.isLoading.value && !isLastPage)
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: AppThemeData.primary200.withOpacity(0.12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    onPressed: () {
                      Preferences.setBoolean(Preferences.isFinishOnBoardingKey, true);
                      Get.offAll(const MainDashboard());
                    },
                    child: Text(
                      'Skip'.tr,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppThemeData.primary200,
                        fontFamily: AppThemeData.medium,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          body: SafeArea(
            child: controller.isLoading.value
                ? Constant.loader(context, isDarkMode: isDark)
                : Column(
                    children: [
                      Expanded(
                        child: PageView.builder(
                          controller: controller.pageController,
                          onPageChanged: (index) {
                            controller.selectedPageIndex.value = index;
                          },
                          itemCount: dataLength,
                          itemBuilder: (context, index) {
                            final item = controller.onboardingModel.value.data?[index];
                            final imageUrl = item?.image ?? '';
                            final fallbackImage = controller.localImage[index % controller.localImage.length];

                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Center(
                                      child: Container(
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? Colors.white.withOpacity(0.04)
                                              : AppThemeData.primary200.withOpacity(0.05),
                                          shape: BoxShape.circle,
                                        ),
                                        child: imageUrl.startsWith('http')
                                            ? CachedNetworkImage(
                                                filterQuality: FilterQuality.high,
                                                fit: BoxFit.contain,
                                                width: Responsive.width(70, context),
                                                height: Responsive.width(70, context),
                                                imageUrl: imageUrl,
                                                placeholder: (context, url) => Constant.loader(context, isDarkMode: isDark),
                                                errorWidget: (context, url, error) => Image.asset(
                                                  fallbackImage,
                                                  fit: BoxFit.contain,
                                                  width: Responsive.width(70, context),
                                                  height: Responsive.width(70, context),
                                                ),
                                              )
                                            : Image.asset(
                                                fallbackImage,
                                                fit: BoxFit.contain,
                                                width: Responsive.width(70, context),
                                                height: Responsive.width(70, context),
                                              ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    item?.title ?? '',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 22,
                                      color: isDark ? AppThemeData.grey900Dark : AppThemeData.grey900,
                                      fontFamily: AppThemeData.bold,
                                      height: 1.3,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    item?.description ?? '',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isDark ? AppThemeData.grey500Dark : AppThemeData.grey500,
                                      height: 1.5,
                                      fontFamily: AppThemeData.regular,
                                    ),
                                  ),
                                  const SizedBox(height: 30),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      // Smooth Page Indicator
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          dataLength,
                          (index) {
                            final isSelected = controller.selectedPageIndex.value == index;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: isSelected ? 28 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: isSelected ? AppThemeData.primary200 : (isDark ? Colors.grey[700] : AppThemeData.grey200),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Action Button
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: ButtonThem.buildButton(
                          context,
                          title: isLastPage ? 'Start Your Journey'.tr : 'Next'.tr,
                          btnHeight: 52,
                          btnWidthRatio: 0.85,
                          btnColor: AppThemeData.primary200,
                          txtColor: Colors.white,
                          onPress: () async {
                            if (isLastPage) {
                              Preferences.setBoolean(Preferences.isFinishOnBoardingKey, true);
                              Get.offAll(const MainDashboard());
                            } else {
                              controller.selectedPageIndex.value = controller.selectedPageIndex.value + 1;
                              controller.pageController.animateToPage(
                                controller.selectedPageIndex.value,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 36),
                    ],
                  ),
          ),
        );
      },
    );
  }
}
