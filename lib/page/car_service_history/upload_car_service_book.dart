import 'dart:io';

import 'package:cabme_driver/constant/show_toast_dialog.dart';
import 'package:cabme_driver/controller/car_service_history_controller.dart';
import 'package:cabme_driver/themes/app_bar_custom.dart';
import 'package:cabme_driver/themes/button_them.dart';
import 'package:cabme_driver/themes/constant_colors.dart';
import 'package:cabme_driver/themes/responsive.dart';
import 'package:cabme_driver/themes/text_field_them.dart';
import 'package:cabme_driver/utils/dark_theme_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:syncfusion_flutter_core/theme.dart';

class AddCarServiceBookHistory extends StatelessWidget {
  const AddCarServiceBookHistory({super.key});

  static final GlobalKey<FormState> _formKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return GetX<CarServiceHistoryController>(
      init: CarServiceHistoryController(),
      builder: (controller) {
        return Scaffold(
          appBar: AppbarCustom(title: 'Upload Car Service Book'.tr),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(
                    height: 10,
                  ),
                  const SizedBox(height: 15),
                  controller.carServiceBook.isNotEmpty
                      ? Obx(
                          () => Center(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: SizedBox(
                                height: 300,
                                child: SfPdfViewerTheme(
                                  data: SfPdfViewerThemeData(
                                    progressBarColor: AppThemeData.primary200,
                                    backgroundColor: themeChange.getThem() ? AppThemeData.surface50Dark : AppThemeData.surface50, //<----
                                  ),
                                  child: SfPdfViewer.file(
                                    File(controller.carServiceBook.value),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 24,
                            horizontal: 20,
                          ),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                              color: themeChange.getThem() ? AppThemeData.surface50Dark : AppThemeData.surface50,
                              borderRadius: const BorderRadius.all(
                                Radius.circular(15),
                              )),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SvgPicture.asset(
                                'assets/icons/ic_upload_image.svg',
                                width: 35,
                                height: 35,
                                fit: BoxFit.cover,
                              ),
                              const SizedBox(
                                height: 16,
                              ),
                              Text(
                                'Upload File'.tr,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontFamily: AppThemeData.semiBold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Take a clear picture of your file or choose an pdf from your gallery to ensure service details.'.tr,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontFamily: AppThemeData.regular,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Max. 5MB, Accepted: pdf'.tr,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontFamily: AppThemeData.medium,
                                ),
                              ),
                              const SizedBox(height: 24),
                              ButtonThem.buildButton(
                                btnWidthRatio: 0.4,
                                context,
                                title: 'Click to Upload'.tr,
                                btnHeight: 50,
                                btnColor: AppThemeData.secondary300,
                                txtColor: themeChange.getThem() ? AppThemeData.grey50 : AppThemeData.grey50,
                                onPress: () async {
                                  pickDoc(controller);
                                },
                              ),
                            ],
                          ),
                        ),
                  const SizedBox(height: 12),
                  Form(
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    key: _formKey,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: TextFieldWidget(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        borderColor: themeChange.getThem() ? AppThemeData.surface50Dark : AppThemeData.surface50,
                        radius: BorderRadius.circular(10),
                        hintText: 'ADD KM'.tr,
                        controller: controller.kmDrivenController.value,
                        textInputType: TextInputType.phone,
                        maxLength: 10,
                        validators: (String? value) {
                          if (value!.isNotEmpty) {
                            return null;
                          } else {
                            return 'required'.tr;
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                ],
              ),
            ),
          ),
          bottomNavigationBar: SizedBox(
            height: 80,
            width: Responsive.width(100, context),
            child: Center(
              child: ButtonThem.buildButton(
                context,
                title: 'Save Details'.tr,
                btnWidthRatio: 0.7,
                btnColor: AppThemeData.primary200,
                txtColor: themeChange.getThem() ? AppThemeData.grey50Dark : AppThemeData.grey50,
                onPress: () {
                  if (controller.carServiceBook.isNotEmpty && _formKey.currentState!.validate()) {
                    controller.userCarServiceBook(kmDriven: controller.kmDrivenController.value.text).then((value) {
                      if (value != null) {
                        if (value["success"] == "Success") {
                          controller.getCarServiceBooks();
                          Get.back();
                        } else {
                          ShowToastDialog.showToast(value['error']);
                        }
                      }
                    });
                  } else {
                    if (controller.carServiceBook.isEmpty) {
                      ShowToastDialog.showToast("Please Choose Image");
                    }
                  }
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> pickDoc(
    CarServiceHistoryController controller,
  ) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc'],
        allowMultiple: false,
      );
      if (result!.files.isEmpty) return;
      PlatformFile file = result.files.last;
      controller.carServiceBook.value = file.path!;
    } on PlatformException catch (e) {
      ShowToastDialog.showToast("${"Failed to Pick".tr}: \n $e");
    }
  }
}
