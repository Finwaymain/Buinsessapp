import 'package:cabme_driver/controller/driver_category_controller.dart';
import 'package:cabme_driver/page/auth_screens/vehicle_info_screen.dart';
import 'package:cabme_driver/page/MainDashBoard/screen/main_dashboard.dart' as cabme;
import 'package:cabme_driver/themes/button_them.dart';
import 'package:cabme_driver/themes/constant_colors.dart';
import 'package:cabme_driver/utils/dark_theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class ReviewConfirmStep extends StatelessWidget {
  const ReviewConfirmStep({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final bool isDark = themeChange.getThem();
    final bgColor = isDark ? AppThemeData.surface50Dark : AppThemeData.surface50;
    final labelColor = isDark ? AppThemeData.grey50 : AppThemeData.grey50Dark;
    final hintColor = isDark ? AppThemeData.grey400 : AppThemeData.grey400Dark;

    return GetX<DriverCategoryController>(
      init: Get.find<DriverCategoryController>(),
      builder: (controller) {
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Text(
                    'Review & Confirm'.tr,
                    style: TextStyle(
                      fontSize: 26,
                      fontFamily: AppThemeData.bold,
                      color: labelColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please review your selected roles and ensure your documents are uploaded. You can add vehicle details on the next step if required.'.tr,
                    style: TextStyle(fontSize: 14, color: hintColor, fontFamily: AppThemeData.regular),
                  ),
                  const SizedBox(height: 32),
                  
                  Text(
                    'Your Selected Roles'.tr,
                    style: TextStyle(fontSize: 16, fontFamily: AppThemeData.semiBold, color: labelColor),
                  ),
                  const SizedBox(height: 16),
                  
                  Expanded(
                    child: ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      itemCount: controller.selectedParentCategories.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        var parent = controller.selectedParentCategories[index];
                        var sub = controller.selectedSubCategories[parent.id.toString()];
                        
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? AppThemeData.grey100Dark : AppThemeData.primary50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppThemeData.primary200.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppThemeData.primary200,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.check, color: Colors.white, size: 20),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      parent.title ?? '',
                                      style: TextStyle(fontSize: 16, fontFamily: AppThemeData.semiBold, color: labelColor),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      sub?.title ?? 'Not specified',
                                      style: TextStyle(fontSize: 14, fontFamily: AppThemeData.medium, color: hintColor),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  ButtonThem.buildButton(
                    context,
                    title: 'Confirm & Finish'.tr,
                    btnHeight: 50,
                    btnColor: AppThemeData.primary200,
                    txtColor: Colors.white,
                    onPress: () async {
                       // 1. Submit categories to backend using the controller
                       await controller.saveCategory();
                       // 2. Navigate to dashboard
                       Get.offAll(() => cabme.MainDashboard());
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      }
    );
  }
}
