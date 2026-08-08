import 'package:cabme_driver/controller/vehicle_registration_controller.dart';
import 'package:cabme_driver/model/get_vehicle_getegory.dart';
import 'package:cabme_driver/themes/constant_colors.dart';
import 'package:cabme_driver/utils/dark_theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import 'vehicle_details_screen.dart';
import 'vehicle_registration_style.dart';
import 'widgets/step_progress.dart';

/// Step 1: Business Category selection
class VehicleCategorySelectScreen extends StatefulWidget {
  const VehicleCategorySelectScreen({super.key});

  @override
  State<VehicleCategorySelectScreen> createState() => _VehicleCategorySelectScreenState();
}

class _VehicleCategorySelectScreenState extends State<VehicleCategorySelectScreen> {
  final _controller = Get.put(VehicleRegistrationController(), tag: UniqueKey().toString());

  @override
  void initState() {
    super.initState();
    _controller.fetchVehicleTypes();
  }

  void _onSelect(VehicleData type) {
    Get.to(() => VehicleDetailsScreen(vehicleTypeId: type.id ?? '', vehicleTypeName: type.libelle ?? ''));
  }

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDarkMode = themeChange.getThem();

    return Scaffold(
      backgroundColor: isDarkMode ? AppThemeData.surface50Dark : const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: isDarkMode ? AppThemeData.surface50Dark : Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: isDarkMode ? AppThemeData.grey900Dark : Colors.black),
        title: Text(
          "Business Category".tr,
          style: TextStyle(
            fontFamily: AppThemeData.bold,
            fontSize: 18,
            color: isDarkMode ? AppThemeData.grey900Dark : Colors.black,
          ),
        ),
      ),
      body: Obx(() {
        if (_controller.isLoadingTypes.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (_controller.vehicleTypes.isEmpty) {
          return Center(child: Text("No business categories available".tr, style: TextStyle(color: AppThemeData.grey500)));
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const StepProgress(currentStep: 1, totalSteps: 3),
              const SizedBox(height: 18),
              Text(
                "Select Your Business Category".tr,
                style: TextStyle(
                  fontFamily: AppThemeData.bold,
                  fontSize: 16,
                  color: isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Choose the category that matches your services".tr,
                style: TextStyle(
                  fontFamily: AppThemeData.regular,
                  fontSize: 12.5,
                  color: isDarkMode ? AppThemeData.grey400Dark : AppThemeData.grey500,
                ),
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _controller.vehicleTypes.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),
                itemBuilder: (context, index) {
                  final type = _controller.vehicleTypes[index];
                  return InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => _onSelect(type),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDarkMode ? AppThemeData.grey100Dark : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDarkMode ? AppThemeData.grey300Dark : const Color(0xFFF1F5F9),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.03),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: kVehicleRegAccent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(vehicleTypeIcon(type.libelle), color: kVehicleRegAccent, size: 26),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            type.libelle ?? '',
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: AppThemeData.medium,
                              fontSize: 11.5,
                              color: isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      }),
    );
  }
}
