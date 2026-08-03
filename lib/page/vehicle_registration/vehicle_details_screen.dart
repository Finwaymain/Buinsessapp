import 'dart:io';

import 'package:cabme_driver/controller/vehicle_registration_controller.dart';
import 'package:cabme_driver/themes/button_them.dart';
import 'package:cabme_driver/themes/constant_colors.dart';
import 'package:cabme_driver/utils/dark_theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'vehicle_documents_screen.dart';
import 'vehicle_registration_style.dart';
import 'widgets/step_progress.dart';

class VehicleDetailsScreen extends StatefulWidget {
  final String vehicleTypeId;
  final String vehicleTypeName;

  const VehicleDetailsScreen({super.key, required this.vehicleTypeId, required this.vehicleTypeName});

  @override
  State<VehicleDetailsScreen> createState() => _VehicleDetailsScreenState();
}

class _VehicleDetailsScreenState extends State<VehicleDetailsScreen> {
  final _controller = Get.put(VehicleRegistrationController(), tag: UniqueKey().toString());
  final _numberPlateController = TextEditingController();
  final _picker = ImagePicker();

  String? _selectedTypeId;
  String? _selectedTypeName;
  File? _vehiclePhoto;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedTypeId = widget.vehicleTypeId;
    _selectedTypeName = widget.vehicleTypeName;
    _controller.fetchVehicleTypes();
  }

  @override
  void dispose() {
    _numberPlateController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image != null) setState(() => _vehiclePhoto = File(image.path));
  }

  Future<void> _next() async {
    if (_numberPlateController.text.trim().isEmpty) {
      Get.snackbar('', 'Please enter your vehicle number', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (_selectedTypeId == null) return;

    setState(() => _isSubmitting = true);

    final zoneId = await _controller.fetchDefaultZoneId();
    if (zoneId == null) {
      setState(() => _isSubmitting = false);
      Get.snackbar('', 'No operating zone configured yet. Please contact support.', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    final result = await _controller.registerVehicle(
      vehicleTypeId: _selectedTypeId!,
      vehicleTypeName: _selectedTypeName ?? widget.vehicleTypeName,
      numberPlate: _numberPlateController.text.trim(),
      zoneId: zoneId,
    );

    if (result != null && _vehiclePhoto != null) {
      // "Vehicle Photo" reuses the same generic document mechanism as
      // License/RC/Insurance/etc — no dedicated photo column exists on
      // tj_vehicule, and this keeps upload/status handling in one place.
      final docs = await _controller.fetchDocumentTypes();
      final photoDoc = docs.firstWhere(
        (d) => (d['title'] ?? '').toString() == 'Vehicle Photo',
        orElse: () => null,
      );
      if (photoDoc != null) {
        await _controller.uploadDocument(documentId: photoDoc['id'].toString(), file: _vehiclePhoto!);
      }
    }

    setState(() => _isSubmitting = false);

    if (result != null && mounted) {
      Get.to(() => VehicleDocumentsScreen(
            vehicleTypeName: _selectedTypeName ?? widget.vehicleTypeName,
            numberPlate: _numberPlateController.text.trim(),
          ));
    }
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
          "Register Your Vehicle".tr,
          style: TextStyle(fontFamily: AppThemeData.bold, fontSize: 17, color: isDarkMode ? AppThemeData.grey900Dark : Colors.black),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const StepProgress(currentStep: 1, totalSteps: 3),
            const SizedBox(height: 20),
            Text(
              "Vehicle Details".tr,
              style: TextStyle(fontFamily: AppThemeData.bold, fontSize: 16, color: isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900),
            ),
            const SizedBox(height: 16),
            _fieldLabel("Vehicle Type".tr, isDarkMode),
            const SizedBox(height: 6),
            Obx(() {
              final options = _controller.vehicleTypes;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: isDarkMode ? AppThemeData.grey100Dark : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedTypeId,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded),
                    items: options
                        .map((v) => DropdownMenuItem(value: v.id, child: Text(v.libelle ?? '')))
                        .toList(),
                    onChanged: (val) {
                      if (val == null) return;
                      final match = options.firstWhere((v) => v.id == val);
                      setState(() {
                        _selectedTypeId = val;
                        _selectedTypeName = match.libelle;
                      });
                    },
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),
            _fieldLabel("Vehicle Number".tr, isDarkMode),
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(
                color: isDarkMode ? AppThemeData.grey100Dark : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              child: TextField(
                controller: _numberPlateController,
                textCapitalization: TextCapitalization.characters,
                style: TextStyle(color: isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900),
                decoration: InputDecoration(
                  hintText: "e.g. HR 55 AB 1234".tr,
                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
            ),
            // Load capacity is only meaningful for the truck-family types —
            // passenger vehicles (Bike/Sedan/SUV/etc) skip this field entirely
            // rather than showing an empty/placeholder box.
            if (kVehicleCapacityLabel.containsKey(_selectedTypeName)) ...[
              const SizedBox(height: 16),
              _fieldLabel("Load Capacity".tr, isDarkMode),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDarkMode ? AppThemeData.grey100Dark : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                ),
                child: Text(
                  kVehicleCapacityLabel[_selectedTypeName] ?? '-',
                  style: TextStyle(fontFamily: AppThemeData.medium, fontSize: 13, color: isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900),
                ),
              ),
            ],
            const SizedBox(height: 16),
            _fieldLabel("Vehicle Photo".tr, isDarkMode),
            const SizedBox(height: 6),
            Row(
              children: [
                if (_vehiclePhoto != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(_vehiclePhoto!, width: 90, height: 90, fit: BoxFit.cover),
                  ),
                if (_vehiclePhoto != null) const SizedBox(width: 12),
                InkWell(
                  onTap: _pickPhoto,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: isDarkMode ? AppThemeData.grey100Dark : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                    ),
                    child: const Icon(Icons.add_a_photo_outlined, color: Colors.grey, size: 26),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            ButtonThem.buildButton(
              context,
              title: _isSubmitting ? "Please wait...".tr : "Next".tr,
              txtColor: Colors.white,
              btnColor: kVehicleRegAccent,
              radius: 10,
              onPress: _isSubmitting ? () {} : _next,
            ),
          ],
        ),
      ),
    );
  }

  Widget _fieldLabel(String text, bool isDarkMode) {
    return Text(
      text,
      style: TextStyle(fontFamily: AppThemeData.medium, fontSize: 12.5, color: isDarkMode ? AppThemeData.grey500Dark : AppThemeData.grey500),
    );
  }
}
