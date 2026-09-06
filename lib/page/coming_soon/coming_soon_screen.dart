import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../../themes/app_bar_custom.dart';
import '../../themes/button_them.dart';
import '../../themes/constant_colors.dart';
import '../../utils/dark_theme_provider.dart';

class ComingSoonScreen extends StatelessWidget {
  final String? title;

  const ComingSoonScreen({super.key, this.title});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.getThem();
    final displayTitle = (title != null && title!.isNotEmpty) ? title! : 'Coming Soon'.tr;

    return Scaffold(
      backgroundColor: isDark ? AppThemeData.grey50Dark : AppThemeData.grey50,
      appBar: AppbarCustom(
        title: displayTitle.tr,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icon Illustration Container
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppThemeData.primary200,
                        AppThemeData.primary200.withValues(alpha: 0.6),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppThemeData.primary200.withValues(alpha: 0.25),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.rocket_launch_rounded,
                      size: 58,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Coming Soon Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppThemeData.primary200.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppThemeData.primary200.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'COMING SOON'.tr,
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: AppThemeData.bold,
                      letterSpacing: 1.5,
                      color: AppThemeData.primary200,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Feature Title
                Text(
                  displayTitle.tr,
                  style: TextStyle(
                    fontSize: 24,
                    fontFamily: AppThemeData.bold,
                    color: isDark ? AppThemeData.grey900Dark : AppThemeData.grey900,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Subtitle Description
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    "We are actively working on this feature to bring you a better experience. It will be available soon in an upcoming release!".tr,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      fontFamily: AppThemeData.regular,
                      color: isDark ? AppThemeData.grey500Dark : AppThemeData.grey500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 40),

                // Back Button
                SizedBox(
                  width: double.infinity,
                  child: ButtonThem.buildButton(
                    context,
                    title: 'Back to Home'.tr,
                    btnHeight: 48,
                    btnWidthRatio: 0.85,
                    btnColor: AppThemeData.primary200,
                    txtColor: Colors.white,
                    onPress: () => Get.back(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
