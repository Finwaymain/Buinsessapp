import 'package:cabme_driver/controller/driver_category_controller.dart';
import 'package:cabme_driver/themes/button_them.dart';
import 'package:cabme_driver/themes/constant_colors.dart';
import 'package:cabme_driver/utils/dark_theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class DriverCategorySelectionScreen extends StatelessWidget {
  const DriverCategorySelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final bool isDark = themeChange.getThem();
    final bgColor = isDark ? AppThemeData.surface50Dark : AppThemeData.surface50;
    final labelColor = isDark ? AppThemeData.grey50 : AppThemeData.grey50Dark;
    final hintColor = isDark ? AppThemeData.grey400 : AppThemeData.grey400Dark;

    return GetX<DriverCategoryController>(
        init: DriverCategoryController(),
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
              child: controller.isLoading.value
                  ? Center(
                      child: CircularProgressIndicator(color: AppThemeData.primary200),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          Text(
                            'Select Your Profession'.tr,
                            style: TextStyle(
                              fontSize: 26,
                              fontFamily: AppThemeData.bold,
                              color: labelColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Choose the category that best describes the type of service you provide.'.tr,
                            style: TextStyle(fontSize: 14, color: hintColor, fontFamily: AppThemeData.regular),
                          ),
                          const SizedBox(height: 36),

                          // Parent Category Selection
                          Text(
                            'Category'.tr,
                            style: TextStyle(fontSize: 16, fontFamily: AppThemeData.semiBold, color: labelColor),
                          ),
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: () => _categoryDialog(context, controller),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              decoration: BoxDecoration(
                                color: isDark ? AppThemeData.grey100Dark : AppThemeData.primary50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: isDark ? AppThemeData.grey200Dark : AppThemeData.grey200),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    controller.selectedParentCategory.value?.title ?? 'Select Category'.tr,
                                    style: TextStyle(
                                      color: controller.selectedParentCategory.value == null ? hintColor : labelColor,
                                      fontFamily: AppThemeData.medium,
                                    ),
                                  ),
                                  Icon(Icons.arrow_drop_down_rounded, color: hintColor),
                                ],
                              ),
                            ),
                          ),

                          // Subcategory Selection (if available)
                          Obx(() => controller.subCategories.isNotEmpty
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 24),
                                    Text(
                                      'Subcategory'.tr,
                                      style: TextStyle(fontSize: 16, fontFamily: AppThemeData.semiBold, color: labelColor),
                                    ),
                                    const SizedBox(height: 12),
                                    InkWell(
                                      onTap: () => _subCategoryDialog(context, controller),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                        decoration: BoxDecoration(
                                          color: isDark ? AppThemeData.grey100Dark : AppThemeData.primary50,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: isDark ? AppThemeData.grey200Dark : AppThemeData.grey200),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              controller.selectedSubCategory.value?.title ?? 'Select Subcategory'.tr,
                                              style: TextStyle(
                                                color: controller.selectedSubCategory.value == null ? hintColor : labelColor,
                                                fontFamily: AppThemeData.medium,
                                              ),
                                            ),
                                            Icon(Icons.arrow_drop_down_rounded, color: hintColor),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : const SizedBox()),

                          const Spacer(),
                          ButtonThem.buildButton(
                            context,
                            title: 'Continue'.tr,
                            btnHeight: 50,
                            btnColor: AppThemeData.primary200,
                            txtColor: Colors.white,
                            onPress: () {
                              controller.saveCategory();
                            },
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
            ),
          );
        });
  }

  void _categoryDialog(BuildContext context, DriverCategoryController controller) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Category'.tr),
          content: Obx(
            () => SizedBox(
              height: 300.0,
              width: 300.0,
              child: controller.parentCategories.isEmpty
                  ? Center(child: Text("No categories found".tr))
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: controller.parentCategories.length,
                      itemBuilder: (BuildContext context, int index) {
                        return ListTile(
                          onTap: () {
                            controller.selectParentCategory(controller.parentCategories[index]);
                            Get.back();
                          },
                          title: Text(controller.parentCategories[index].title.toString()),
                        );
                      },
                    ),
            ),
          ),
        );
      },
    );
  }

  void _subCategoryDialog(BuildContext context, DriverCategoryController controller) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Subcategory'.tr),
          content: Obx(
            () => SizedBox(
              height: 300.0,
              width: 300.0,
              child: controller.subCategories.isEmpty
                  ? Center(child: Text("No subcategories found".tr))
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: controller.subCategories.length,
                      itemBuilder: (BuildContext context, int index) {
                        return ListTile(
                          onTap: () {
                            controller.selectSubCategory(controller.subCategories[index]);
                            Get.back();
                          },
                          title: Text(controller.subCategories[index].title.toString()),
                        );
                      },
                    ),
            ),
          ),
        );
      },
    );
  }
}
