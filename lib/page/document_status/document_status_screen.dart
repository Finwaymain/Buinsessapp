import 'package:cabme_driver/constant/constant.dart';
import 'package:cabme_driver/constant/show_toast_dialog.dart';
import 'package:cabme_driver/controller/document_status_contoller.dart';
import 'package:cabme_driver/themes/app_bar_custom.dart';
import 'package:cabme_driver/themes/button_them.dart';
import 'package:cabme_driver/themes/constant_colors.dart';
import 'package:cabme_driver/themes/custom_alert_dialog.dart';
import 'package:cabme_driver/themes/responsive.dart';
import 'package:cabme_driver/utils/dark_theme_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class DocumentStatusScreen extends StatelessWidget {
  DocumentStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);

    return GetX<DocumentStatusController>(
      init: DocumentStatusController(),
      builder: (controller) {
        return Scaffold(
          appBar: const AppbarCustom(
            title: '',
            elevation: 0,
          ),
          backgroundColor: themeChange.getThem() ? AppThemeData.surface50Dark : AppThemeData.surface50,
          body: controller.isLoading.value
              ? SizedBox()
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Upload Your Documents".tr,
                        style: TextStyle(
                          fontSize: 24,
                          fontFamily: AppThemeData.semiBold,
                          color: themeChange.getThem() ? AppThemeData.grey900Dark : AppThemeData.grey900,
                        ),
                      ),
                      Text(
                        "Securely upload your driving license, vehicle registration, and insurance documents.",
                        textAlign: TextAlign.start,
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: AppThemeData.regular,
                          color: themeChange.getThem() ? AppThemeData.grey900Dark : AppThemeData.grey900,
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: () => controller.getCarServiceBooks(),
                          child: ListView.builder(
                            itemCount: controller.documentList.length,
                            shrinkWrap: true,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            controller.documentList[index].documentName.toString(),
                                            style: TextStyle(color: themeChange.getThem() ? Colors.white : Colors.black, fontSize: 16, fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                        controller.documentList[index].documentStatus == "Disapprove"
                                            ? InkWell(
                                                onTap: () {
                                                  showDialog(
                                                    barrierColor: Colors.black26,
                                                    context: context,
                                                    builder: (context) {
                                                      return CustomAlertDialog(
                                                        title:
                                                            "${"Reason :".tr} ${controller.documentList[index].comment!.isEmpty ? "Under Verification".tr : controller.documentList[index].comment.toString()}",
                                                        negativeButtonText: 'Ok'.tr,
                                                        positiveButtonText: 'Ok'.tr,
                                                        onPressPositive: () {
                                                          Get.back();
                                                        },
                                                      );
                                                    },
                                                  );
                                                },
                                                child: const Icon(Icons.remove_red_eye))
                                            : Container(),
                                        const SizedBox(
                                          width: 10,
                                        ),
                                        Text(
                                          controller.documentList[index].documentStatus.toString(),
                                          style: TextStyle(
                                              color: controller.documentList[index].documentStatus == "Disapprove" || controller.documentList[index].documentStatus == "Pending"
                                                  ? Colors.red
                                                  : Colors.green),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(
                                      height: 10,
                                    ),
                                    controller.documentList[index].documentPath!.isEmpty
                                        ? Container(
                                            decoration: ShapeDecoration(
                                              shape: RoundedRectangleBorder(
                                                side: BorderSide(width: 1, color: themeChange.getThem() ? AppThemeData.grey200Dark : AppThemeData.grey200),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
                                              child: Column(
                                                children: [
                                                  SvgPicture.asset(
                                                    "assets/icons/ic_upload.svg",
                                                    width: 35,
                                                    height: 35,
                                                    fit: BoxFit.cover,
                                                  ),
                                                  const SizedBox(
                                                    height: 10,
                                                  ),
                                                  Text(
                                                    "${"Upload".tr} ${controller.documentList[index].title} ${"Image".tr}",
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontFamily: AppThemeData.semiBold,
                                                      color: themeChange.getThem() ? AppThemeData.grey900Dark : AppThemeData.grey900,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 12),
                                                  Text(
                                                    "${"Take a clear picture of your".tr} ${controller.documentList[index].title} ${"or choose an image from your gallery to ensure document verify.".tr}",
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontFamily: AppThemeData.regular,
                                                      color: themeChange.getThem() ? AppThemeData.grey900Dark : AppThemeData.grey900,
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding: const EdgeInsets.only(top: 26),
                                                    child: ButtonThem.buildButton(
                                                      context,
                                                      title: 'Click to Upload'.tr,
                                                      btnWidthRatio: 0.40,
                                                      btnColor: AppThemeData.primary200,
                                                      txtColor: AppThemeData.surface50,
                                                      onPress: () async {
                                                        buildBottomSheet(context, controller, index, controller.documentList[index].id.toString(), themeChange.getThem());
                                                      },
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          )
                                        : ClipRRect(
                                            borderRadius: const BorderRadius.all(Radius.circular(10)),
                                            child: CachedNetworkImage(
                                              height: Responsive.height(25, context),
                                              width: Responsive.width(90, context),
                                              fit: BoxFit.cover,
                                              imageUrl: controller.documentList[index].documentPath!,
                                              placeholder: (context, url) => Constant.loader(context, isDarkMode: themeChange.getThem()),
                                            ),
                                          ),
                                    if (controller.documentList[index].documentStatus == "Pending" &&
                                        controller.documentList[index].documentPath!.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 10),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: Colors.amber.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.amber.shade700, width: 1),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(Icons.hourglass_top_rounded, color: Colors.amber.shade700, size: 18),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  "Pending verification by Fiinway team. We will notify you once approved.",
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontFamily: AppThemeData.regular,
                                                    color: Colors.amber.shade800,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    if (controller.documentList[index].documentStatus == "Disapprove")
                                      Padding(
                                        padding: const EdgeInsets.only(top: 10),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            ButtonThem.buildButton(
                                              context,
                                              title: 'Upload'.tr,
                                              btnHeight: 40,
                                              btnWidthRatio: 0.30,
                                              btnColor: AppThemeData.primary200,
                                              txtColor: AppThemeData.surface50,
                                              onPress: () async {
                                                buildBottomSheet(context, controller, index, controller.documentList[index].id.toString(), themeChange.getThem());
                                              },
                                            )
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Future<dynamic> buildBottomSheet(BuildContext context, DocumentStatusController controller, int index, String documentId, bool isDarkMode) {
    return showModalBottomSheet(
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (context, setState) {
            return Container(
              height: Responsive.height(22, context),
              color: isDarkMode ? AppThemeData.surface50Dark : AppThemeData.surface50,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 15, bottom: 10),
                    child: Text(
                      'Please Select'.tr,
                      style: TextStyle(
                        fontSize: 18,
                        fontFamily: AppThemeData.semiBold,
                        color: isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            IconButton(
                                onPressed: () => pickFile(controller, source: ImageSource.camera, index: index, documentId: documentId),
                                icon: Icon(
                                  Icons.camera_alt,
                                  size: 32,
                                  color: isDarkMode ? AppThemeData.grey50 : AppThemeData.grey50Dark,
                                )),
                            Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Text(
                                'camera'.tr,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontFamily: AppThemeData.medium,
                                  color: isDarkMode ? AppThemeData.grey50 : AppThemeData.grey50Dark,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            IconButton(
                                onPressed: () => pickFile(controller, source: ImageSource.gallery, index: index, documentId: documentId),
                                icon: Icon(
                                  Icons.photo_library_sharp,
                                  size: 32,
                                  color: isDarkMode ? AppThemeData.grey50 : AppThemeData.grey50Dark,
                                )),
                            Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Text(
                                'gallery'.tr,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontFamily: AppThemeData.medium,
                                  color: isDarkMode ? AppThemeData.grey50 : AppThemeData.grey50Dark,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ],
              ),
            );
          });
        });
  }

  final ImagePicker _imagePicker = ImagePicker();

  Future pickFile(DocumentStatusController controller, {required ImageSource source, required int index, required String documentId}) async {
    try {
      XFile? image = await _imagePicker.pickImage(source: source);
      if (image == null) return;

      Get.back(); // Close bottom sheet before async upload
      // updateDocument already calls getCarServiceBooks() on success
      await controller.updateDocument(documentId, image.path);
    } on PlatformException catch (e) {
      ShowToastDialog.showToast("${"Failed to Pick".tr}: \n $e");
    }
  }

  Future<dynamic> buildAlertSendInformation(
    BuildContext context,
  ) {
    return Get.defaultDialog(
      radius: 6,
      title: "",
      titleStyle: const TextStyle(fontSize: 0.0),
      content: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.asset(
                "assets/images/green_checked.png",
                height: 100,
                width: 100,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Text(
                "${"Your information send well. We will treat them and inform you after the treatment.".tr} ${"Your account will be active after validation of your information.".tr}",
                textAlign: TextAlign.center,
                softWrap: true,
                style: TextStyle(color: Provider.of<DarkThemeProvider>(context, listen: false).getThem() ? Colors.white70 : Colors.black54),
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            ButtonThem.buildButton(context,
                title: "Close".tr, btnHeight: 40, btnWidthRatio: 0.6, btnColor: AppThemeData.primary200, txtColor: Colors.white, onPress: () => Get.back()),
          ],
        ),
      ),
    );
  }
}
