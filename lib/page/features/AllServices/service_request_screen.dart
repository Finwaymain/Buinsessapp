import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import 'package:cabme_driver/constant/show_toast_dialog.dart';
import 'package:cabme_driver/controller/all_services_controller.dart';
import 'package:cabme_driver/themes/button_them.dart';
import 'package:cabme_driver/themes/constant_colors.dart';
import 'package:cabme_driver/utils/dark_theme_provider.dart';
import 'package:cabme_driver/utils/Preferences.dart';
import 'package:cabme_driver/utils/location_picker_helper.dart';
import 'service_history_screen.dart';
import 'service_booking_mode.dart';
import 'service_style.dart';

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

  late final ServiceBookingMode _bookingMode;
  late final bool _requiresHomeVisit;

  double? _lat;
  double? _lng;
  String _addressType = 'Home';
  String _contactMethod = 'Online';
  String _bookingFrequency = 'Hourly';
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isSubmitting = false;

  bool get _supportsFrequencySelection {
    final combined = "${widget.serviceName} ${widget.categoryName}".toLowerCase();
    return RegExp(r'\btutor\b|\btuition\b|\bnurs\b|\bphysio\b|\belderly\b|\bpatient care\b|\bmaid\b|\bcook\b|\bdriver\b|\bbabysitter\b|\bteacher\b').hasMatch(combined);
  }

  @override
  void initState() {
    super.initState();
    _bookingMode = bookingModeFor(serviceName: widget.serviceName, categoryName: widget.categoryName);
    _requiresHomeVisit = _bookingMode == ServiceBookingMode.homeVisit;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickAddress() async {
    final picked = await LocationPickerHelper.showPickerSheet(context);
    if (picked != null && mounted) {
      setState(() {
        _lat = picked.latitude;
        _lng = picked.longitude;
        _addressController.text = picked.address;
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
    if (Preferences.getInt(Preferences.userId) == 0) {
      ShowToastDialog.showToast("Please login to book a service".tr);
      return;
    }
    if (_requiresHomeVisit && (_addressController.text.isEmpty || _lat == null)) {
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

    final fullDescription = _supportsFrequencySelection
        ? "[Plan: $_bookingFrequency]\n${_descriptionController.text}"
        : _descriptionController.text;

    final success = await _controller.bookService({
      'service_name': widget.serviceName,
      'address_type': _requiresHomeVisit ? _addressType : _contactMethod,
      'service_address': _requiresHomeVisit ? _addressController.text.trim() : '',
      'lat': _requiresHomeVisit ? _lat.toString() : '',
      'lng': _requiresHomeVisit ? _lng.toString() : '',
      'date': dateStr,
      'time': timeStr,
      'description': fullDescription,
      'booking_frequency': _bookingFrequency,
      'booking_mode': _requiresHomeVisit ? 'home_visit' : 'remote',
    });

    if (mounted) setState(() => _isSubmitting = false);
    if (success && mounted) {
      Get.off(() => const ServiceHistoryScreen(initialTab: 0));
    }
  }

  Widget _sectionTitle(String text, bool isDarkMode) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: AppThemeData.semiBold,
        fontSize: 13,
        color: isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900,
      ),
    );
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cleanServiceName(widget.serviceName).tr,
                          style: TextStyle(fontFamily: AppThemeData.bold, fontSize: widget.serviceName.contains('\n') ? 13 : 16, color: style.color),
                          maxLines: widget.serviceName.contains('\n') ? 8 : 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _requiresHomeVisit
                              ? "A professional will visit your location".tr
                              : "This service can be done online — no address needed".tr,
                          style: TextStyle(
                            fontFamily: AppThemeData.regular,
                            fontSize: 11.5,
                            color: style.color.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (_requiresHomeVisit) ...[
              _sectionTitle("Service Address".tr, isDarkMode),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _pickAddress,
                      borderRadius: BorderRadius.circular(12),
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
                                _addressController.text.isEmpty ? "Tap to use GPS or search address".tr : _addressController.text,
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
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: isDarkMode ? AppThemeData.grey100Dark : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () async {
                        final picked = await LocationPickerHelper.fetchCurrentLocation();
                        if (picked != null && mounted) {
                          setState(() {
                            _lat = picked.latitude;
                            _lng = picked.longitude;
                            _addressController.text = picked.address;
                          });
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                        ),
                        child: Icon(Icons.my_location_rounded, color: AppThemeData.primary200, size: 22),
                      ),
                    ),
                  ),
                ],
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
            ] else ...[
              _sectionTitle("How would you like to connect?".tr, isDarkMode),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['Online', 'Video Call', 'Phone Call'].map((method) {
                  final selected = _contactMethod == method;
                  return ChoiceChip(
                    label: Text(method.tr),
                    selected: selected,
                    onSelected: (_) => setState(() => _contactMethod = method),
                    selectedColor: style.color.withValues(alpha: 0.15),
                    labelStyle: TextStyle(color: selected ? style.color : Colors.grey, fontFamily: AppThemeData.medium, fontSize: 12),
                  );
                }).toList(),
              ),
            ],
            if (_supportsFrequencySelection) ...[
              const SizedBox(height: 20),
              _sectionTitle("Booking Plan / Duration".tr, isDarkMode),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['Hourly', 'Daily', 'Monthly', 'Yearly / Course'].map((freq) {
                  final selected = _bookingFrequency == freq;
                  return ChoiceChip(
                    label: Text(freq.tr),
                    selected: selected,
                    onSelected: (_) => setState(() => _bookingFrequency = freq),
                    selectedColor: style.color.withValues(alpha: 0.15),
                    labelStyle: TextStyle(color: selected ? style.color : Colors.grey, fontFamily: AppThemeData.medium, fontSize: 12),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 20),
            _sectionTitle("Preferred Date & Time".tr, isDarkMode),
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
            _sectionTitle("Remarks (Optional)".tr, isDarkMode),
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
                  hintText: _requiresHomeVisit
                      ? "Any specific requirements for the visit...".tr
                      : "Share topic, goals, or how to reach you...".tr,
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
