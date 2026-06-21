import 'package:cabme_driver/constant/constant.dart';
import 'package:cabme_driver/constant/show_toast_dialog.dart';
import 'package:cabme_driver/controller/add_complaint_controller.dart';
import 'package:cabme_driver/themes/app_bar_custom.dart';
import 'package:cabme_driver/themes/button_them.dart';
import 'package:cabme_driver/themes/constant_colors.dart';
import 'package:cabme_driver/themes/text_field_them.dart';
import 'package:cabme_driver/utils/dark_theme_provider.dart';
import 'package:cabme_driver/widget/StarRating.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class AddComplaintScreen extends StatelessWidget {
  AddComplaintScreen({super.key});

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);

    return GetX<AddComplaintController>(
      init: AddComplaintController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: AppThemeData.primary200,
          appBar: AppbarCustom(title: "Complaint".tr, bgColor: AppThemeData.primary200),
          body: Padding(
            padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 20),
            child: Container(
              decoration: BoxDecoration(color: themeChange.getThem() ? AppThemeData.grey50Dark : AppThemeData.grey50, borderRadius: BorderRadius.circular(10)),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: [
                      const SizedBox(
                        height: 20,
                      ),
                      Align(
                        alignment: Alignment.topCenter,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(60),
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withValues(alpha: 0.15),
                                blurRadius: 8,
                                spreadRadius: 6,
                                offset: const Offset(0, 0),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(60),
                            child: CachedNetworkImage(
                              imageUrl: controller.rideType.value == "ride" ? controller.rideData.value.photoPath.toString() : controller.parcelData.value.userPhoto.toString(),
                              height: 100,
                              width: 100,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Constant.loader(context, isDarkMode: themeChange.getThem()),
                              errorWidget: (context, url, error) => Image.asset("assets/images/appIcon.png"),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          controller.rideType.value.toString() == "ride"
                              ? '${controller.rideData.value.prenom.toString()} ${controller.rideData.value.nom.toString()}'
                              : "${controller.parcelData.value.userName}",
                          style: TextStyle(
                            color: themeChange.getThem() ? AppThemeData.grey900Dark : AppThemeData.grey900,
                            fontSize: 18,
                            fontFamily: AppThemeData.semiBold,
                          ),
                        ),
                      ),
                      if (controller.rideType.value == 'ride')
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            StarRating(size: 18, rating: double.parse(controller.rideData.value.moyenneDriver.toString()), color: AppThemeData.warning200),
                          ],
                        ),
                      if (controller.complaintStatus.value.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Status : '.tr,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: themeChange.getThem() ? AppThemeData.grey900Dark : AppThemeData.grey900,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                controller.complaintStatus.value,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: themeChange.getThem() ? AppThemeData.grey900Dark : AppThemeData.grey900,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(top: 30),
                        child: Text(
                          controller.isReviewScreen.value == false ? 'Submit a Complaint Against a Customer'.tr : 'Review Customer'.tr,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: themeChange.getThem() ? AppThemeData.grey900Dark : AppThemeData.grey900,
                            fontSize: 18,
                            fontFamily: AppThemeData.semiBold,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Text(
                          controller.isReviewScreen.value == false
                              ? 'Facing any inconvenience with a customer? File a complaint, and we’ll address the issue to help improve your driving experience.'.tr
                              : 'Your feedback helps us improve and provide a better experience. Rate your customer and leave a comment!'.tr,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: themeChange.getThem() ? AppThemeData.grey900Dark : AppThemeData.grey900,
                            fontSize: 14,
                            fontFamily: AppThemeData.regular,
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 30,
                      ),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Padding(
                          padding: const EdgeInsets.all(2.0),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                TextFieldWidget(
                                  hintText: 'Complain Title'.tr,
                                  controller: controller.complaintTitleController,
                                  textInputType: TextInputType.emailAddress,
                                  radius: const BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  validators: (String? value) {
                                    if (value!.isNotEmpty) {
                                      return null;
                                    } else {
                                      return 'Title is required'.tr;
                                    }
                                  },
                                ),
                                TextFieldWidget(
                                  hintText: 'Description'.tr,
                                  controller: controller.complaintDiscriptionController,
                                  textInputType: TextInputType.emailAddress,
                                  maxLine: 5,
                                  radius: const BorderRadius.only(bottomLeft: Radius.circular(10), bottomRight: Radius.circular(10)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  validators: (String? value) {
                                    if (value!.isNotEmpty) {
                                      return null;
                                    } else {
                                      return 'Description is required'.tr;
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 20, bottom: 20),
                        child: ButtonThem.buildButton(
                          context,
                          title: "Submit Complaint".tr,
                          btnColor: AppThemeData.primary200,
                          txtColor: Colors.black,
                          onPress: () async {
                            if (_formKey.currentState!.validate()) {
                              Map<String, String> bodyParams = {};
                              if (controller.rideType.value.toString() == "ride") {
                                bodyParams = {
                                  'id_user_app': controller.rideData.value.idUserApp.toString(),
                                  'id_conducteur': controller.rideData.value.idConducteur.toString(),
                                  'user_type': 'driver',
                                  'description': controller.complaintDiscriptionController.text.toString(),
                                  'title': controller.complaintTitleController.text.toString(),
                                  'order_id': controller.rideData.value.id.toString(),
                                };
                              } else {
                                bodyParams = {
                                  'id_user_app': controller.parcelData.value.idUserApp.toString(),
                                  'id_conducteur': controller.parcelData.value.idConducteur.toString(),
                                  'user_type': 'driver',
                                  'description': controller.complaintDiscriptionController.text.toString(),
                                  'title': controller.complaintTitleController.text.toString(),
                                  'order_id': controller.parcelData.value.id.toString(),
                                  'ride_type': 'parcel'
                                };
                              }

                              await controller.addComplaint(bodyParams).then((value) {
                                if (value != null) {
                                  if (value == true) {
                                    ShowToastDialog.showToast("Complaint added successfully!");
                                    Get.back();
                                  } else {
                                    ShowToastDialog.showToast("Something went wrong.");
                                  }
                                }
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
