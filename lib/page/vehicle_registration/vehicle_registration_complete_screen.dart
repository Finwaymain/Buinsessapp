import 'package:cabme_driver/controller/dash_board_controller.dart';
import 'package:cabme_driver/page/MainDashBoard/screen/main_dashboard.dart';
import 'package:cabme_driver/themes/button_them.dart';
import 'package:cabme_driver/themes/constant_colors.dart';
import 'package:cabme_driver/utils/dark_theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import 'vehicle_registration_style.dart';

class VehicleRegistrationCompleteScreen extends StatefulWidget {
  final String vehicleTypeName;
  final String numberPlate;

  const VehicleRegistrationCompleteScreen({super.key, required this.vehicleTypeName, required this.numberPlate});

  @override
  State<VehicleRegistrationCompleteScreen> createState() => _VehicleRegistrationCompleteScreenState();
}

class _VehicleRegistrationCompleteScreenState extends State<VehicleRegistrationCompleteScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh cached driver profile so statut_vehicule/isVerified reflect the
    // registration we just submitted, without requiring an app restart.
    if (Get.isRegistered<DashBoardController>()) {
      Get.find<DashBoardController>().getUsrData();
    }
  }

  void _goToDashboard() => Get.offAll(() => MainDashboard());

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDarkMode = themeChange.getThem();

    return Scaffold(
      backgroundColor: isDarkMode ? AppThemeData.surface50Dark : const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: isDarkMode ? AppThemeData.surface50Dark : Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        iconTheme: IconThemeData(color: isDarkMode ? AppThemeData.grey900Dark : Colors.black),
        title: Text(
          "Registration Complete".tr,
          style: TextStyle(fontFamily: AppThemeData.bold, fontSize: 17, color: isDarkMode ? AppThemeData.grey900Dark : Colors.black),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(shape: BoxShape.circle, color: kVehicleRegAccent.withValues(alpha: 0.12)),
              child: Icon(Icons.check_circle_rounded, color: kVehicleRegAccent, size: 56),
            ),
            const SizedBox(height: 20),
            Text(
              "Your Vehicle is\nSuccessfully Registered".tr,
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: AppThemeData.bold, fontSize: 19, color: isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900),
            ),
            const SizedBox(height: 28),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode ? AppThemeData.grey100Dark : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(color: kVehicleRegAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                    child: Icon(vehicleTypeIcon(widget.vehicleTypeName), color: kVehicleRegAccent, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.vehicleTypeName, style: TextStyle(fontFamily: AppThemeData.semiBold, fontSize: 14, color: isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900)),
                        Text(widget.numberPlate, style: TextStyle(fontFamily: AppThemeData.regular, fontSize: 12, color: isDarkMode ? AppThemeData.grey500Dark : AppThemeData.grey500)),
                      ],
                    ),
                  ),
                  if (kVehicleCapacityLabel.containsKey(widget.vehicleTypeName))
                    Text(
                      kVehicleCapacityLabel[widget.vehicleTypeName]!,
                      style: TextStyle(fontFamily: AppThemeData.medium, fontSize: 12, color: kVehicleRegAccent),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _quickLink(Icons.assignment_turned_in_outlined, "Get Bookings", isDarkMode),
                _quickLink(Icons.currency_rupee_rounded, "Earn Money", isDarkMode),
                _quickLink(Icons.map_outlined, "Track Trips", isDarkMode),
              ],
            ),
            const SizedBox(height: 32),
            ButtonThem.buildButton(
              context,
              title: "Go to Dashboard".tr,
              txtColor: Colors.white,
              btnColor: kVehicleRegAccent,
              radius: 10,
              onPress: _goToDashboard,
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickLink(IconData icon, String label, bool isDarkMode) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(color: kVehicleRegAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
          child: Icon(icon, color: kVehicleRegAccent, size: 22),
        ),
        const SizedBox(height: 6),
        Text(label.tr, style: TextStyle(fontFamily: AppThemeData.medium, fontSize: 10.5, color: isDarkMode ? AppThemeData.grey500Dark : AppThemeData.grey500)),
      ],
    );
  }
}
