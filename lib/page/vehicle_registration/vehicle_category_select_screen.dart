import 'package:cabme_driver/controller/vehicle_registration_controller.dart';
import 'package:cabme_driver/model/get_vehicle_getegory.dart';
import 'package:cabme_driver/themes/constant_colors.dart';
import 'package:cabme_driver/utils/dark_theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import 'vehicle_details_screen.dart';
import 'vehicle_registration_style.dart';

/// First screen a driver sees after signup (and re-entry point from the
/// "Go Online" gate for anyone who hasn't registered a vehicle yet): picks
/// which vehicle they drive, then continues into the same registration
/// wizard regardless of category — trucks show a Load Capacity field
/// (VehicleDetailsScreen), everything else just skips it.
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
          "What do you drive?".tr,
          style: TextStyle(fontFamily: AppThemeData.bold, fontSize: 18, color: isDarkMode ? AppThemeData.grey900Dark : Colors.black),
        ),
      ),
      body: Obx(() {
        if (_controller.isLoadingTypes.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (_controller.vehicleTypes.isEmpty) {
          return Center(child: Text("No vehicle types available".tr, style: TextStyle(color: AppThemeData.grey500)));
        }
        return GridView.builder(
          padding: const EdgeInsets.all(16),
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
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(color: kVehicleRegAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                    child: Icon(vehicleTypeIcon(type.libelle), color: kVehicleRegAccent, size: 28),
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
            );
          },
        );
      }),
    );
  }
}
