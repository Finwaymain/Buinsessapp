import 'package:cabme_driver/controller/driver_onboarding_controller.dart';
import 'package:cabme_driver/page/auth_screens/vehicle_info_screen.dart';
import 'package:cabme_driver/themes/button_them.dart';
import 'package:cabme_driver/themes/constant_colors.dart';
import 'package:cabme_driver/utils/dark_theme_provider.dart';
import 'package:cabme_driver/utils/Preferences.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:cabme_driver/model/user_category_model.dart';

class DriverCategorySelectionScreen extends StatelessWidget {
  const DriverCategorySelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final bool isDark = themeChange.getThem();
    final bgColor = isDark ? AppThemeData.surface50Dark : AppThemeData.surface50;
    final labelColor = isDark ? AppThemeData.grey50 : AppThemeData.grey50Dark;
    final hintColor = isDark ? AppThemeData.grey400 : AppThemeData.grey400Dark;

    return GetX<DriverOnboardingController>(
        init: DriverOnboardingController(),
        builder: (controller) {
          // Find the transport parent category
          final transportParent = controller.parentCategories.firstWhereOrNull(
            (p) => p.title?.contains('Transport & Mobility') ?? false
          );

          final transportRoles = transportParent?.subcategories ?? <UserCategoryData>[];
          final availableDeliveries = controller.getAvailableDeliveryServices();

          // Find the marketplace parent category
          final marketplaceParent = controller.parentCategories.firstWhereOrNull(
            (p) => p.title?.contains('Marketplace & Sellers') ?? false
          );
          final marketplaceServices = marketplaceParent?.subcategories ?? <UserCategoryData>[];

          return Scaffold(
            backgroundColor: bgColor,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded, color: labelColor, size: 20),
                onPressed: () => Get.back(),
              ),
              title: Text(
                'Registration'.tr,
                style: TextStyle(color: labelColor, fontSize: 18, fontFamily: AppThemeData.semiBold),
              ),
              centerTitle: true,
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
                            'Choose Your Services'.tr,
                            style: TextStyle(
                              fontSize: 26,
                              fontFamily: AppThemeData.bold,
                              color: labelColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Select your primary role and add any compatible delivery services you want to provide.'.tr,
                            style: TextStyle(fontSize: 14, color: hintColor, fontFamily: AppThemeData.regular),
                          ),
                          const SizedBox(height: 24),

                          Expanded(
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // STEP 1: Transport & Mobility (Primary Role)
                                  Text(
                                    '1. Primary Transport Role (Select One)'.tr,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontFamily: AppThemeData.semiBold,
                                      color: labelColor,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  if (transportRoles.isEmpty)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      child: Text(
                                        'No transport roles available.'.tr,
                                        style: TextStyle(color: hintColor),
                                      ),
                                    )
                                  else
                                    Wrap(
                                      spacing: 10,
                                      runSpacing: 10,
                                      children: transportRoles.map((role) {
                                        final isSelected = controller.selectedPrimaryRole.value?.id == role.id;
                                        return InkWell(
                                          borderRadius: BorderRadius.circular(12),
                                          onTap: () => controller.selectPrimaryRole(role),
                                          child: AnimatedContainer(
                                            duration: const Duration(milliseconds: 200),
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? AppThemeData.primary200.withValues(alpha: 0.1)
                                                  : (isDark ? AppThemeData.grey100Dark : Colors.white),
                                              border: Border.all(
                                                color: isSelected
                                                    ? AppThemeData.primary200
                                                    : (isDark ? AppThemeData.grey200Dark : AppThemeData.grey200),
                                                width: isSelected ? 2.0 : 1.0,
                                              ),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                                                  color: isSelected ? AppThemeData.primary200 : hintColor,
                                                  size: 18,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  role.title ?? '',
                                                  style: TextStyle(
                                                    color: labelColor,
                                                    fontSize: 14,
                                                    fontFamily: isSelected ? AppThemeData.semiBold : AppThemeData.medium,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  
                                  if (marketplaceServices.isNotEmpty) ...[
                                    const SizedBox(height: 32),
                                    Text(
                                      'Marketplace & Sellers'.tr,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontFamily: AppThemeData.semiBold,
                                        color: labelColor,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 10,
                                      runSpacing: 10,
                                      children: marketplaceServices.map((sub) {
                                        final isSelected = controller.selectedMarketplaceServices.any((s) => s.id == sub.id);
                                        return InkWell(
                                          borderRadius: BorderRadius.circular(12),
                                          onTap: () => controller.toggleMarketplaceService(sub),
                                          child: AnimatedContainer(
                                            duration: const Duration(milliseconds: 200),
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? AppThemeData.primary200.withValues(alpha: 0.1)
                                                  : (isDark ? AppThemeData.grey100Dark : Colors.white),
                                              border: Border.all(
                                                color: isSelected
                                                    ? AppThemeData.primary200
                                                    : (isDark ? AppThemeData.grey200Dark : AppThemeData.grey200),
                                                width: isSelected ? 2.0 : 1.0,
                                              ),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                                                  color: isSelected ? AppThemeData.primary200 : hintColor,
                                                  size: 18,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  sub.title ?? '',
                                                  style: TextStyle(
                                                    color: labelColor,
                                                    fontSize: 14,
                                                    fontFamily: isSelected ? AppThemeData.semiBold : AppThemeData.medium,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],

                                  const SizedBox(height: 32),

                                  // STEP 2: Delivery & Logistics (Compatible Subcategories)
                                  Text(
                                    '2. Compatible Delivery Services (Optional)'.tr,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontFamily: AppThemeData.semiBold,
                                      color: labelColor,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  if (controller.selectedPrimaryRole.value == null)
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: isDark ? AppThemeData.grey100Dark : AppThemeData.grey100,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'Please select a primary transport role first to view compatible delivery services.'.tr,
                                        style: TextStyle(
                                          color: hintColor,
                                          fontSize: 13,
                                          fontFamily: AppThemeData.regular,
                                        ),
                                      ),
                                    )
                                  else if (availableDeliveries.isEmpty)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      child: Text(
                                        'No additional delivery services are compatible with this role.'.tr,
                                        style: TextStyle(color: hintColor, fontSize: 13),
                                      ),
                                    )
                                  else
                                    Wrap(
                                      spacing: 10,
                                      runSpacing: 10,
                                      children: availableDeliveries.map((sub) {
                                        final isSelected = controller.selectedDeliveryServices.any((d) => d.id == sub.id);
                                        return InkWell(
                                          borderRadius: BorderRadius.circular(12),
                                          onTap: () => controller.toggleDeliveryService(sub),
                                          child: AnimatedContainer(
                                            duration: const Duration(milliseconds: 200),
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? AppThemeData.secondary200.withValues(alpha: 0.1)
                                                  : (isDark ? AppThemeData.grey100Dark : Colors.white),
                                              border: Border.all(
                                                color: isSelected
                                                    ? AppThemeData.secondary200
                                                    : (isDark ? AppThemeData.grey200Dark : AppThemeData.grey200),
                                                width: isSelected ? 2.0 : 1.0,
                                              ),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                                                  color: isSelected ? AppThemeData.secondary200 : hintColor,
                                                  size: 18,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  sub.title ?? '',
                                                  style: TextStyle(
                                                    color: labelColor,
                                                    fontSize: 14,
                                                    fontFamily: isSelected ? AppThemeData.semiBold : AppThemeData.medium,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  const SizedBox(height: 32),
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
                              final success = await controller.saveCategory();
                              if (success) {
                                final role = controller.selectedPrimaryRole.value?.title ?? '';
                                if (role.isNotEmpty) {
                                  await Preferences.setString("selected_role", role);
                                }
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
