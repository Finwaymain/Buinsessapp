import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart' show SearchInfo;

import 'package:cabme_driver/constant/show_toast_dialog.dart';
import 'package:cabme_driver/controller/all_services_controller.dart';
import 'package:cabme_driver/page/search_location_screen.dart';
import 'package:cabme_driver/themes/button_them.dart';
import 'package:cabme_driver/themes/constant_colors.dart';
import 'package:cabme_driver/utils/dark_theme_provider.dart';
import 'service_style.dart';

/// Generic request/management form for any leaf service in the "All Services" catalog
class ServiceRequestScreen extends StatefulWidget {
  final String serviceName;
  final String categoryName;

  const ServiceRequestScreen({super.key, required this.serviceName, required this.categoryName});

  @override
  State<ServiceRequestScreen> createState() => _ServiceRequestScreenState();
}

class _ServiceRequestScreenState extends State<ServiceRequestScreen> {
  final _controller = Get.put(AllServicesController(), tag: UniqueKey().toString());
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();

  double? _lat;
  double? _lng;
  String _addressType = 'Home';
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickAddress() async {
    final result = await Get.to(() => AddressSearchScreen());
    if (result != null && result is SearchInfo) {
      setState(() {
        _lat = result.point!.latitude;
        _lng = result.point!.longitude;
        _addressController.text = result.address.toString();
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _submit() async {
    if (_addressController.text.isEmpty || _lat == null) {
      ShowToastDialog.showToast("Please select your service address".tr);
      return;
    }
    if (_selectedDate == null) {
      ShowToastDialog.showToast("Please select a preferred date".tr);
      return;
    }

    setState(() => _isSubmitting = true);

    final dateStr = "${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}";
    final timeStr = _selectedTime != null ? _selectedTime!.format(context) : '';

    final success = await _controller.bookService({
      'user_id': _controller.currentUserId?.toString() ?? '',
      'service_name': widget.serviceName,
      'address_type': _addressType,
      'lat': _lat.toString(),
      'lng': _lng.toString(),
      'date': dateStr,
      'time': timeStr,
      'description': _descriptionController.text,
    });

    if (mounted) setState(() => _isSubmitting = false);
    if (success && mounted) Get.back();
  }

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final bool isDarkMode = themeChange.getThem();
    final style = categoryStyleFor(widget.categoryName);

    return Scaffold(
      backgroundColor: isDarkMode ? AppThemeData.surface50Dark : const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: isDarkMode ? AppThemeData.surface50Dark : Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: isDarkMode ? AppThemeData.grey900Dark : Colors.black),
        title: Text(
          "Request Service".tr,
          style: TextStyle(fontFamily: AppThemeData.bold, fontSize: 18, color: isDarkMode ? AppThemeData.grey900Dark : Colors.black),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: style.bg, borderRadius: BorderRadius.circular(14)),
              child: Row(
                children: [
                  Icon(leafIconFor(widget.serviceName, fallback: style.icon), color: style.color, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.serviceName,
                      style: TextStyle(fontFamily: AppThemeData.bold, fontSize: 16, color: style.color),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text("Service Address".tr, style: TextStyle(fontFamily: AppThemeData.semiBold, fontSize: 13, color: isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900)),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickAddress,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDarkMode ? AppThemeData.grey100Dark : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.location_on_outlined, color: AppThemeData.primary200, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _addressController.text.isEmpty ? "Select address".tr : _addressController.text,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppThemeData.regular,
                          fontSize: 13,
                          color: _addressController.text.isEmpty ? Colors.grey : (isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: ['Home', 'Work', 'Other'].map((type) {
                final selected = _addressType == type;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(type.tr),
                    selected: selected,
                    onSelected: (_) => setState(() => _addressType = type),
                    selectedColor: style.color.withValues(alpha: 0.15),
                    labelStyle: TextStyle(color: selected ? style.color : Colors.grey, fontFamily: AppThemeData.medium, fontSize: 12),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Text("Preferred Date & Time".tr, style: TextStyle(fontFamily: AppThemeData.semiBold, fontSize: 13, color: isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDarkMode ? AppThemeData.grey100Dark : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(
                            _selectedDate == null ? "Date".tr : "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}",
                            style: TextStyle(fontSize: 12.5, color: isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: _pickTime,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDarkMode ? AppThemeData.grey100Dark : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time_rounded, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(
                            _selectedTime == null ? "Time".tr : _selectedTime!.format(context),
                            style: TextStyle(fontSize: 12.5, color: isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text("Description (Optional)".tr, style: TextStyle(fontFamily: AppThemeData.semiBold, fontSize: 13, color: isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: isDarkMode ? AppThemeData.grey100Dark : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              child: TextField(
                controller: _descriptionController,
                maxLines: 3,
                style: TextStyle(fontSize: 13, color: isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900),
                decoration: InputDecoration(
                  hintText: "Any specific requirements...".tr,
                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
            ),
            const SizedBox(height: 28),
            ButtonThem.buildButton(
              context,
              title: _isSubmitting ? "Submitting...".tr : "Submit Request".tr,
              btnColor: style.color,
              txtColor: Colors.white,
              radius: 10,
              onPress: _isSubmitting ? () {} : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
