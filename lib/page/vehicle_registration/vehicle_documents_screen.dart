import 'dart:io';

import 'package:cabme_driver/controller/vehicle_registration_controller.dart';
import 'package:cabme_driver/themes/button_them.dart';
import 'package:cabme_driver/themes/constant_colors.dart';
import 'package:cabme_driver/utils/dark_theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'vehicle_registration_complete_screen.dart';
import 'vehicle_registration_style.dart';
import 'widgets/step_progress.dart';

const List<String> _kRequiredDocKeywords = ['licence', 'license', 'rc book', 'registration', 'insurance', 'pollution', 'aadhaar'];

class VehicleDocumentsScreen extends StatefulWidget {
  final String vehicleTypeName;
  final String numberPlate;

  const VehicleDocumentsScreen({super.key, required this.vehicleTypeName, required this.numberPlate});

  @override
  State<VehicleDocumentsScreen> createState() => _VehicleDocumentsScreenState();
}

class _VehicleDocumentsScreenState extends State<VehicleDocumentsScreen> {
  final _controller = Get.put(VehicleRegistrationController(), tag: UniqueKey().toString());
  final _picker = ImagePicker();

  bool _isLoading = true;
  List<Map<String, dynamic>> _documents = []; // {id, title, uploaded}
  final Set<String> _uploadingIds = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final types = await _controller.fetchDocumentTypes();
    final uploaded = await _controller.fetchDriverDocuments();

    final relevant = types.where((d) {
      final title = (d['title'] ?? '').toString().toLowerCase();
      return _kRequiredDocKeywords.any((k) => title.contains(k));
    }).toList();

    final uploadedIds = uploaded
        .where((d) => (d['document_status'] ?? '') != '' && (d['document_path'] ?? '').toString().isNotEmpty)
        .map((d) => d['id'].toString())
        .toSet();

    if (mounted) {
      setState(() {
        _documents = relevant
            .map((d) => {'id': d['id'].toString(), 'title': d['title'].toString(), 'uploaded': uploadedIds.contains(d['id'].toString())})
            .toList();
        _isLoading = false;
      });
    }
  }

  Future<void> _uploadDoc(Map<String, dynamic> doc) async {
    final image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image == null) return;

    setState(() => _uploadingIds.add(doc['id']));
    final success = await _controller.uploadDocument(documentId: doc['id'], file: File(image.path));
    if (mounted) {
      setState(() {
        _uploadingIds.remove(doc['id']);
        if (success) doc['uploaded'] = true;
      });
    }
  }

  bool get _allUploaded => _documents.isNotEmpty && _documents.every((d) => d['uploaded'] == true);

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
          "Documents & Verification".tr,
          style: TextStyle(fontFamily: AppThemeData.bold, fontSize: 17, color: isDarkMode ? AppThemeData.grey900Dark : Colors.black),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const StepProgress(currentStep: 2, totalSteps: 3),
                  const SizedBox(height: 20),
                  ..._documents.map((doc) => _documentRow(doc, isDarkMode)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: kVehicleRegAccent.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14)),
                    child: Row(
                      children: [
                        Icon(Icons.shield_rounded, color: kVehicleRegAccent, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Verified & Trusted".tr, style: TextStyle(fontFamily: AppThemeData.semiBold, fontSize: 13, color: kVehicleRegAccent)),
                              Text("Your details are safe & secure".tr, style: TextStyle(fontFamily: AppThemeData.regular, fontSize: 11, color: kVehicleRegAccent.withValues(alpha: 0.8))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ButtonThem.buildButton(
                    context,
                    title: "Next".tr,
                    txtColor: Colors.white,
                    btnColor: kVehicleRegAccent,
                    radius: 10,
                    onPress: () {
                      if (!_allUploaded) {
                        Get.snackbar('', 'Please upload all documents to continue'.tr, snackPosition: SnackPosition.BOTTOM);
                        return;
                      }
                      Get.to(() => VehicleRegistrationCompleteScreen(
                            vehicleTypeName: widget.vehicleTypeName,
                            numberPlate: widget.numberPlate,
                          ));
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _documentRow(Map<String, dynamic> doc, bool isDarkMode) {
    final uploaded = doc['uploaded'] == true;
    final uploading = _uploadingIds.contains(doc['id']);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDarkMode ? AppThemeData.grey100Dark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.description_outlined, color: kVehicleRegAccent, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              doc['title'],
              style: TextStyle(fontFamily: AppThemeData.medium, fontSize: 13, color: isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900),
            ),
          ),
          if (uploading)
            const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
          else if (uploaded)
            Row(
              children: [
                Icon(Icons.check_circle_rounded, color: kVehicleRegAccent, size: 16),
                const SizedBox(width: 4),
                Text("Uploaded".tr, style: TextStyle(fontFamily: AppThemeData.medium, fontSize: 12, color: kVehicleRegAccent)),
              ],
            )
          else
            InkWell(
              onTap: () => _uploadDoc(doc),
              child: Text("Upload".tr, style: TextStyle(fontFamily: AppThemeData.semiBold, fontSize: 12.5, color: kVehicleRegAccent)),
            ),
        ],
      ),
    );
  }
}
