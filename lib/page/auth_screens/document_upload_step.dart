import 'dart:io';
import 'package:cabme_driver/constant/constant.dart';
import 'package:cabme_driver/constant/show_toast_dialog.dart';
import 'package:cabme_driver/controller/driver_onboarding_controller.dart';
import 'package:cabme_driver/model/uploaded_document_model.dart';
import 'package:cabme_driver/page/auth_screens/review_confirm_step.dart';
import 'package:cabme_driver/themes/button_them.dart';
import 'package:cabme_driver/themes/constant_colors.dart';
import 'package:cabme_driver/utils/dark_theme_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class DocumentUploadStep extends StatelessWidget {
  const DocumentUploadStep({super.key});

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
                ? Center(child: CircularProgressIndicator(color: AppThemeData.primary200))
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        Text(
                          'Upload Documents'.tr,
                          style: TextStyle(
                            fontSize: 26,
                            fontFamily: AppThemeData.bold,
                            color: labelColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Please provide the necessary documents for verification. We use secure storage to protect your data.'.tr,
                          style: TextStyle(fontSize: 14, color: hintColor, fontFamily: AppThemeData.regular),
                        ),
                        const SizedBox(height: 24),
                        
                        Expanded(
                          child: ListView.separated(
                            physics: const BouncingScrollPhysics(),
                            itemCount: controller.documentList.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              var doc = controller.documentList[index];
                              return _buildDocCard(context, controller, doc, isDark, labelColor, hintColor);
                            },
                          ),
                        ),

                        ButtonThem.buildButton(
                          context,
                          title: 'Review & Confirm'.tr,
                          btnHeight: 50,
                          btnColor: AppThemeData.primary200,
                          txtColor: Colors.white,
                          onPress: () {
                            bool allUploaded = controller.documentList.every((d) => 
                              d.documentPath != null && d.documentPath!.isNotEmpty
                            );
                            
                            if (allUploaded) {
                               Get.to(() => const ReviewConfirmStep(), transition: Transition.rightToLeft);
                            } else {
                               ShowToastDialog.showToast("Please upload all required documents to proceed.");
                            }
                          },
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
          ),
        );
      }
    );
  }

  Widget _buildDocCard(BuildContext context, DriverOnboardingController controller, UploadedDocumentData doc, bool isDark, Color labelColor, Color hintColor) {
    bool isUploaded = doc.documentPath != null && doc.documentPath!.isNotEmpty;
    bool isPending = doc.documentStatus == "Pending";
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppThemeData.grey100Dark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppThemeData.grey200Dark : AppThemeData.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doc.title ?? 'Document',
                      style: TextStyle(fontSize: 16, fontFamily: AppThemeData.semiBold, color: labelColor),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isUploaded ? (isPending ? "Pending Verification" : "Verified") : "Required",
                      style: TextStyle(
                        fontSize: 12, 
                        fontFamily: AppThemeData.medium,
                        color: isUploaded ? (isPending ? Colors.amber.shade700 : Colors.green) : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isUploaded)
                InkWell(
                  onTap: () => _showPicker(context, controller, doc),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppThemeData.primary50,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text('Upload', style: TextStyle(color: AppThemeData.primary200, fontFamily: AppThemeData.semiBold, fontSize: 13)),
                  ),
                ),
            ],
          ),
          
          if (isUploaded) ...[
            const SizedBox(height: 12),
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    imageUrl: doc.documentPath!,
                    placeholder: (context, url) => Container(color: isDark ? AppThemeData.grey200Dark : AppThemeData.grey100, height: 120),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: InkWell(
                    onTap: () => _showPicker(context, controller, doc),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.edit, color: Colors.white, size: 16),
                    ),
                  ),
                )
              ],
            )
          ]
        ],
      ),
    );
  }

  void _showPicker(BuildContext context, DriverOnboardingController controller, UploadedDocumentData doc) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text('Photo Library'.tr),
                onTap: () async {
                  Get.back();
                  final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 50);
                  if (pickedFile != null) {
                    controller.updateDocument(doc.id.toString(), pickedFile.path);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: Text('Camera'.tr),
                onTap: () async {
                  Get.back();
                  final pickedFile = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 50);
                  if (pickedFile != null) {
                    controller.updateDocument(doc.id.toString(), pickedFile.path);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
