import 'package:cabme_driver/controller/driver_category_controller.dart';
import 'package:cabme_driver/page/auth_screens/document_upload_step.dart';
import 'package:cabme_driver/page/auth_screens/vehicle_info_screen.dart';
import 'package:cabme_driver/constant/show_toast_dialog.dart';
import 'package:cabme_driver/themes/button_them.dart';
import 'package:cabme_driver/themes/constant_colors.dart';
import 'package:cabme_driver/utils/dark_theme_provider.dart';
import 'package:cabme_driver/utils/Preferences.dart';
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
    final ScrollController scrollController = ScrollController();

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
                            'What are you passionate about?'.tr,
                            style: TextStyle(
                              fontSize: 26,
                              fontFamily: AppThemeData.bold,
                              color: labelColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Select the services you want to provide. You can choose multiple options!'.tr,
                            style: TextStyle(fontSize: 14, color: hintColor, fontFamily: AppThemeData.regular),
                          ),
                          const SizedBox(height: 24),

                          Expanded(
                            child: SingleChildScrollView(
                              controller: scrollController,
                              physics: const BouncingScrollPhysics(),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Parent Categories Wrap
                                  Wrap(
                                    spacing: 8.0,
                                    runSpacing: 12.0,
                                    children: controller.parentCategories.map((parent) {
                                      bool isSelected = controller.selectedParentCategories.contains(parent);
                                      bool isActive = controller.isActiveCategory(parent.title);

                                      return InkWell(
                                        borderRadius: BorderRadius.circular(30),
                                        onTap: () {
                                          controller.toggleParentCategory(parent);
                                          if (controller.selectedParentCategories.contains(parent)) {
                                            Future.delayed(const Duration(milliseconds: 300), () {
                                              if (scrollController.hasClients) {
                                                scrollController.animateTo(
                                                  scrollController.position.maxScrollExtent,
                                                  duration: const Duration(milliseconds: 400),
                                                  curve: Curves.easeOut,
                                                );
                                              }
                                            });
                                          }
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                          decoration: BoxDecoration(
                                            color: isSelected ? AppThemeData.primary200 : (isDark ? AppThemeData.grey100Dark : Colors.white),
                                            border: Border.all(
                                              color: isSelected
                                                  ? AppThemeData.primary200
                                                  : (isActive ? (isDark ? AppThemeData.grey200Dark : AppThemeData.grey200) : AppThemeData.grey400.withValues(alpha: 0.3)),
                                            ),
                                            borderRadius: BorderRadius.circular(30),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                parent.title ?? '',
                                                style: TextStyle(
                                                  color: isSelected
                                                      ? Colors.white
                                                      : (isActive ? labelColor : hintColor.withValues(alpha: 0.5)),
                                                  fontFamily: isSelected ? AppThemeData.semiBold : AppThemeData.medium,
                                                ),
                                              ),
                                              if (!isActive) ...[
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: isDark ? AppThemeData.grey300Dark : AppThemeData.grey100,
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                  child: Text(
                                                    'Soon',
                                                    style: TextStyle(fontSize: 10, color: hintColor, fontFamily: AppThemeData.bold),
                                                  ),
                                                )
                                              ]
                                            ],
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                  const SizedBox(height: 32),

                                  // Subcategories for Selected Parents
                                  ...controller.selectedParentCategories.map((parent) {
                                    if (parent.subcategories == null || parent.subcategories!.isEmpty) {
                                      return const SizedBox();
                                    }
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Select your specific role in ${parent.title}'.tr,
                                          style: TextStyle(fontSize: 16, fontFamily: AppThemeData.semiBold, color: labelColor),
                                        ),
                                        const SizedBox(height: 12),
                                        Wrap(
                                          spacing: 8.0,
                                          runSpacing: 12.0,
                                          children: parent.subcategories!.map((sub) {
                                            bool isSubSelected = controller.selectedSubCategories[parent.id.toString()] == sub;

                                            return InkWell(
                                              borderRadius: BorderRadius.circular(30),
                                              onTap: () => controller.selectSubCategory(parent.id.toString(), sub),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                decoration: BoxDecoration(
                                                  color: isSubSelected ? AppThemeData.secondary200 : (isDark ? AppThemeData.grey100Dark : Colors.white),
                                                  border: Border.all(
                                                    color: isSubSelected
                                                        ? AppThemeData.secondary200
                                                        : (isDark ? AppThemeData.grey200Dark : AppThemeData.grey200),
                                                  ),
                                                  borderRadius: BorderRadius.circular(30),
                                                ),
                                                child: Text(
                                                  sub.title ?? '',
                                                  style: TextStyle(
                                                    color: isSubSelected ? Colors.white : labelColor,
                                                    fontFamily: isSubSelected ? AppThemeData.semiBold : AppThemeData.medium,
                                                  ),
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                        const SizedBox(height: 24),
                                      ],
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ),

                          ButtonThem.buildButton(
                            context,
                            title: 'Continue'.tr,
                            btnHeight: 50,
                            btnColor: AppThemeData.primary200,
                            txtColor: Colors.white,
                            onPress: () async {
                              if (controller.selectedParentCategories.isEmpty) {
                                ShowToastDialog.showToast("Please select at least one Category");
                                return;
                              }
                              for (var parent in controller.selectedParentCategories) {
                                if (parent.subcategories != null && parent.subcategories!.isNotEmpty) {
                                  if (!controller.selectedSubCategories.containsKey(parent.id.toString())) {
                                    ShowToastDialog.showToast("Please select a subcategory for ${parent.title}");
                                    return;
                                  }
                                }
                              }
                              String role = "";
                              for (var parent in controller.selectedParentCategories) {
                                final sub = controller.selectedSubCategories[parent.id.toString()];
                                if (sub != null && sub.title != null) {
                                  role = sub.title!;
                                  break;
                                }
                              }
                              if (role.isNotEmpty) {
                                await Preferences.setString("selected_role", role);
                              }
                              ShowToastDialog.showLoader("Saving categories...".tr);
                              bool success = await controller.saveCategory();
                              ShowToastDialog.closeLoader();
                              if (success) {
                                Get.to(() => const VehicleInfoScreen(), transition: Transition.rightToLeft);
                              }
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
}
