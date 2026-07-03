import 'dart:developer';

import 'package:cabme_driver/constant/show_toast_dialog.dart';
import 'package:cabme_driver/controller/vehicle_info_controller.dart';
import 'package:cabme_driver/page/auth_screens/document_upload_step.dart' as cabme_doc;
import 'package:cabme_driver/model/brand_model.dart';
import 'package:cabme_driver/model/model.dart';
import 'package:cabme_driver/themes/app_bar_custom.dart';
import 'package:cabme_driver/themes/button_them.dart';
import 'package:cabme_driver/themes/constant_colors.dart';
import 'package:cabme_driver/themes/custom_widget.dart';
import 'package:cabme_driver/themes/responsive.dart';
import 'package:cabme_driver/themes/text_field_them.dart';
import 'package:cabme_driver/utils/dark_theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class VehicleInfoScreen extends StatelessWidget {
  const VehicleInfoScreen({super.key});

  static final GlobalKey<FormState> _formKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return GetX(
        init: VehicleInfoController(),
        builder: (vehicleInfoController) {
          return Scaffold(
            appBar: const AppbarCustom(
              title: '',
              elevation: 0,
            ),
            backgroundColor: themeChange.getThem()
                ? AppThemeData.surface50Dark
                : AppThemeData.surface50,
            body: vehicleInfoController.isLoading.value
                ? SizedBox()
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Enter Vehicle Information".tr,
                            style: TextStyle(
                              fontSize: 24,
                              fontFamily: AppThemeData.semiBold,
                              color: themeChange.getThem()
                                  ? AppThemeData.grey900Dark
                                  : AppThemeData.grey900,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              "Accurate information helps match you with the right ride requests and ensures a smooth driving experience."
                                  .tr,
                              textAlign: TextAlign.start,
                              style: TextStyle(
                                fontSize: 16,
                                fontFamily: AppThemeData.regular,
                                color: themeChange.getThem()
                                    ? AppThemeData.grey900Dark
                                    : AppThemeData.grey900,
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 16,
                          ),
                          Container(
                            decoration: BoxDecoration(
                                border: Border.all(
                                    color: themeChange.getThem()
                                        ? AppThemeData.grey800Dark
                                        : AppThemeData.grey800,
                                    width: 1),
                                borderRadius: const BorderRadius.all(
                                    Radius.circular(10))),
                            child: Padding(
                              padding: const EdgeInsets.all(2.0),
                              child: Column(
                                children: [
                                  const SizedBox(
                                    height: 10,
                                  ),

                                  Form(
                                    key: _formKey,
                                    autovalidateMode: AutovalidateMode.disabled,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: InkWell(
                                                onTap: () {
                                                  vehicleInfoController
                                                      .getBrand()
                                                      .then((value) {
                                                    if (value != null &&
                                                        value.isNotEmpty) {
                                                      brandDialog(
                                                          context,
                                                          value,
                                                          vehicleInfoController);
                                                    } else {
                                                      ShowToastDialog.showToast(
                                                          "Please contact administrator");
                                                    }
                                                  });
                                                },
                                                child: TextFieldWidget(
                                                  isBorderEnable: false,
                                                  hintText: 'Brand'.tr,
                                                  controller:
                                                      vehicleInfoController
                                                          .brandController
                                                          .value,
                                                  textInputType:
                                                      TextInputType.text,
                                                  enabled: false,
                                                  contentPadding:
                                                      const EdgeInsets
                                                          .symmetric(
                                                          vertical: 16,
                                                          horizontal: 16),
                                                ),
                                              ),
                                            ),
                                            dividerCustHeight(
                                                isDarkMode:
                                                    themeChange.getThem()),
                                            Expanded(
                                              child: InkWell(
                                                onTap: () {
                                                  if (vehicleInfoController
                                                      .validCategoryIds
                                                      .value
                                                      .isNotEmpty) {
                                                    if (vehicleInfoController
                                                        .brandController
                                                        .value
                                                        .text
                                                        .isNotEmpty) {
                                                      Map<String, String>
                                                          bodyParams = {
                                                        'brand':
                                                            vehicleInfoController
                                                                .brandController
                                                                .value
                                                                .text,
                                                        'vehicle_type':
                                                            vehicleInfoController
                                                                .validCategoryIds
                                                                .value,
                                                      };
                                                      vehicleInfoController
                                                          .getModel(bodyParams)
                                                          .then((value) {
                                                        if (value != null &&
                                                            value.isNotEmpty) {
                                                          modelDialog(
                                                              context,
                                                              value,
                                                              vehicleInfoController);
                                                        } else {
                                                          ShowToastDialog.showToast(
                                                              "Car Model not Found.");
                                                        }
                                                      });
                                                    } else {
                                                      ShowToastDialog.showToast(
                                                          "Please select brand");
                                                    }
                                                  } else {
                                                    ShowToastDialog.showToast(
                                                        'Please select Vehicle Type');
                                                  }
                                                },
                                                child: TextFieldWidget(
                                                  isBorderEnable: false,
                                                  hintText: 'Model'.tr,
                                                  controller:
                                                      vehicleInfoController
                                                          .modelController
                                                          .value,
                                                  textInputType:
                                                      TextInputType.text,
                                                  enabled: false,
                                                  contentPadding:
                                                      const EdgeInsets
                                                          .symmetric(
                                                          vertical: 16,
                                                          horizontal: 16),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        dividerCust(
                                            isDarkMode: themeChange.getThem()),
                                        InkWell(
                                          onTap: () {
                                            vehicleInfoController
                                                .getZone()
                                                .then((value) {
                                              if (value != null &&
                                                  value.isNotEmpty) {
                                                vehicleInfoController
                                                    .zoneList.value = value;
                                                zoneDialog(context,
                                                    vehicleInfoController);
                                              } else {
                                                ShowToastDialog.showToast(
                                                    "Please contact Fiinway Support Team");
                                              }
                                            });
                                          },
                                          child: TextFieldWidget(
                                            isBorderEnable: false,
                                            hintText: 'Select Zone'.tr,
                                            controller: vehicleInfoController
                                                .zoneNameController.value,
                                            textInputType: TextInputType.text,
                                            maxLength: 20,
                                            enabled: false,
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                    vertical: 16,
                                                    horizontal: 16),
                                            suffix: IconButton(
                                                onPressed: () {},
                                                icon: SvgPicture.asset(
                                                    'assets/icons/ic_down_arrow.svg')),
                                          ),
                                        ),
                                        dividerCust(
                                            isDarkMode: themeChange.getThem()),
                                        TextFieldWidget(
                                          isBorderEnable: false,
                                          hintText: 'Color'.tr,
                                          controller: vehicleInfoController
                                              .colorController.value,
                                          textInputType:
                                              TextInputType.emailAddress,
                                          maxLength: 20,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  vertical: 16, horizontal: 16),
                                          validators: (String? value) {
                                            if (value != null &&
                                                value.isNotEmpty) {
                                              return null;
                                            } else {
                                              return 'required'.tr;
                                            }
                                          },
                                        ),
                                        dividerCust(
                                            isDarkMode: themeChange.getThem()),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: InkWell(
                                                onTap: () {
                                                  showDialog(
                                                    context: context,
                                                    builder:
                                                        (BuildContext context) {
                                                      return AlertDialog(
                                                        title: Text(
                                                            "Select Year".tr),
                                                        content: SizedBox(
                                                          // Need to use container to add size constraint.
                                                          width: 300,
                                                          height: 300,
                                                          child: YearPicker(
                                                            firstDate: DateTime(
                                                                DateTime.now()
                                                                        .year -
                                                                    30,
                                                                1),
                                                            lastDate: DateTime(
                                                                DateTime.now()
                                                                    .year,
                                                                1),
                                                            initialDate: DateTime(
                                                                DateTime.now()
                                                                    .year,
                                                                1),
                                                            selectedDate:
                                                                DateTime(
                                                                    DateTime.now()
                                                                        .year,
                                                                    1),
                                                            onChanged: (DateTime
                                                                dateTime) {
                                                              // close the dialog when year is selected.
                                                              vehicleInfoController
                                                                      .carMakeController
                                                                      .value
                                                                      .text =
                                                                  dateTime.year
                                                                      .toString();
                                                              Get.back();
                                                            },
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                  );
                                                },
                                                child: TextFieldWidget(
                                                  isBorderEnable: false,
                                                  hintText:
                                                      'Vehicle Registration year'
                                                          .tr,
                                                  controller:
                                                      vehicleInfoController
                                                          .carMakeController
                                                          .value,
                                                  textInputType:
                                                      TextInputType.number,
                                                  maxLength: 40,
                                                  enabled: false,
                                                  contentPadding:
                                                      const EdgeInsets
                                                          .symmetric(
                                                          vertical: 16,
                                                          horizontal: 16),
                                                  // validators: (String? value) {
                                                  //   if (value!.isNotEmpty) {
                                                  //     return null;
                                                  //   } else {
                                                  //     return 'required'.tr;
                                                  //   }
                                                  // },
                                                ),
                                              ),
                                            ),
                                            dividerCustHeight(
                                                isDarkMode:
                                                    themeChange.getThem()),
                                            Expanded(
                                              child: TextFieldWidget(
                                                isBorderEnable: false,
                                                hintText: 'Number Plate'.tr,
                                                controller:
                                                    vehicleInfoController
                                                        .numberPlateController
                                                        .value,
                                                textInputType:
                                                    TextInputType.text,
                                                maxLength: 15,
                                                inputFormatters: [
                                                  FilteringTextInputFormatter.allow(
                                                      RegExp(r'[a-zA-Z0-9-]')),
                                                ],
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 16,
                                                        horizontal: 16),
                                              ),
                                            )
                                          ],
                                        ),
                                        dividerCust(
                                            isDarkMode: themeChange.getThem()),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: TextFieldWidget(
                                                isBorderEnable: false,
                                                hintText: 'Millage'.tr,
                                                controller:
                                                    vehicleInfoController
                                                        .millageController
                                                        .value,
                                                textInputType:
                                                    TextInputType.number,
                                                maxLength: 5,
                                                inputFormatters: [
                                                  FilteringTextInputFormatter.allow(
                                                      RegExp(r'[0-9.]')),
                                                ],
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 16,
                                                        horizontal: 16),
                                              ),
                                            ),
                                            dividerCustHeight(
                                                isDarkMode:
                                                    themeChange.getThem()),
                                            Expanded(
                                              child: TextFieldWidget(
                                                isBorderEnable: false,
                                                hintText: 'KM Driven'.tr,
                                                controller:
                                                    vehicleInfoController
                                                        .kmDrivenController
                                                        .value,
                                                textInputType:
                                                    TextInputType.number,
                                                maxLength: 7,
                                                inputFormatters: [
                                                  FilteringTextInputFormatter.digitsOnly,
                                                ],
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 16,
                                                        horizontal: 16),
                                              ),
                                            )
                                          ],
                                        ),
                                        dividerCust(
                                            isDarkMode: themeChange.getThem()),
                                        TextFieldWidget(
                                          isBorderEnable: false,
                                          hintText: 'Number Of Passengers'.tr,
                                          controller: vehicleInfoController
                                              .numberOfPassengersController
                                              .value,
                                          textInputType: TextInputType.number,
                                          maxLength: 2,
                                          inputFormatters: [
                                            FilteringTextInputFormatter.digitsOnly,
                                          ],
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  vertical: 16, horizontal: 16),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          Center(
                            child: ButtonThem.buildButton(
                              context,
                              title: 'Continue'.tr,
                              btnHeight: 50,
                              btnWidthRatio: 1,
                              btnColor: AppThemeData.primary200,
                              txtColor: themeChange.getThem()
                                  ? AppThemeData.grey900
                                  : AppThemeData.grey900Dark,
                              onPress: () async {
                                if (_formKey.currentState!.validate()) {
                                  if (vehicleInfoController
                                      .selectedCategoryID.value.isEmpty) {
                                    ShowToastDialog.showToast(
                                        "Please select vehicle type");
                                  } else if (vehicleInfoController
                                      .selectedBrandID.value.isEmpty) {
                                    ShowToastDialog.showToast(
                                        "Please select vehicle brand");
                                  } else if (vehicleInfoController
                                      .selectedModelID.value.isEmpty) {
                                    ShowToastDialog.showToast(
                                        "Please select vehicle model");
                                  } else if (vehicleInfoController
                                      .zoneList.isEmpty) {
                                    ShowToastDialog.showToast(
                                        "Please select Zone");
                                  } else if (vehicleInfoController
                                      .numberPlateController
                                      .value
                                      .text
                                      .isEmpty) {
                                    ShowToastDialog.showToast(
                                        "Please enter number plate");
                                  } else if (vehicleInfoController
                                      .millageController.value.text.isEmpty) {
                                    ShowToastDialog.showToast(
                                        "Please enter millage");
                                  } else if (vehicleInfoController
                                      .kmDrivenController.value.text.isEmpty) {
                                    ShowToastDialog.showToast(
                                        "Please enter Kilometer driven");
                                  } else if (vehicleInfoController
                                      .numberOfPassengersController
                                      .value
                                      .text
                                      .isEmpty) {
                                    ShowToastDialog.showToast(
                                        "Please enter number of passenger");
                                  } else {
                                    ShowToastDialog.showLoader("Please wait");
                                    Map<String, String> bodyParams1 = {
                                      "brand": vehicleInfoController
                                          .selectedBrandID.value,
                                      "model": vehicleInfoController
                                          .selectedModelID.value,
                                      "color": vehicleInfoController
                                          .colorController.value.text,
                                      "carregistration": vehicleInfoController
                                          .numberPlateController.value.text
                                          .toUpperCase(),
                                      "passenger": vehicleInfoController
                                          .numberOfPassengersController
                                          .value
                                          .text,
                                      "id_driver": vehicleInfoController
                                          .userModel!.userData!.id
                                          .toString(),
                                      "id_categorie_vehicle":
                                          vehicleInfoController
                                              .selectedCategoryID.value,
                                      "car_make": vehicleInfoController
                                          .carMakeController.value.text,
                                      "milage": vehicleInfoController
                                          .millageController.value.text,
                                      "km_driven": vehicleInfoController
                                          .kmDrivenController.value.text,
                                      "zone_id": vehicleInfoController
                                          .selectedZone
                                          .join(",")
                                    };
                                    log(bodyParams1.toString());
                                    await vehicleInfoController
                                        .vehicleRegister(bodyParams1)
                                        .then((value) {
                                      if (value != null) {
                                        if (value.success == "Success" ||
                                            value.success == "success") {
                                          ShowToastDialog.closeLoader();
                                          Get.to(() => const cabme_doc.DocumentUploadStep(), transition: Transition.rightToLeft);
                                        } else {
                                          ShowToastDialog.closeLoader();
                                          ShowToastDialog.showToast(
                                              value.error);
                                        }
                                      }
                                    });
                                  }
                                }
                              },
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
          );
        });
  }

  void brandDialog(BuildContext context, List<BrandData>? brandList,
      VehicleInfoController vehicleInfoController) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Brand list'.tr),
            content: SizedBox(
              height: 300.0, // Change as per your requirement
              width: 300.0, // Change as per your requirement
              child: brandList!.isEmpty
                  ? Container()
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: brandList.length,
                      itemBuilder: (BuildContext context, int index) {
                        return ListTile(
                          title: InkWell(
                              onTap: () {
                                vehicleInfoController.brandController.value
                                    .text = brandList[index].name.toString();
                                vehicleInfoController.selectedBrandID.value =
                                    brandList[index].id.toString();
                                vehicleInfoController.modelController.value.clear();
                                vehicleInfoController.selectedModelID.value = "";
                                Get.back();
                              },
                              child: Text(brandList[index].name.toString())),
                        );
                      },
                    ),
            ),
          );
        });
  }

  void modelDialog(BuildContext context, List<ModelData>? brandList,
      VehicleInfoController vehicleInfoController) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Model list'.tr),
            content: SizedBox(
              height: 300.0, // Change as per your requirement
              width: 300.0, // Change as per your requirement
              child: brandList!.isEmpty
                  ? Container()
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: brandList.length,
                      itemBuilder: (BuildContext context, int index) {
                        return ListTile(
                          title: InkWell(
                              onTap: () {
                                vehicleInfoController.modelController.value
                                    .text = brandList[index].name.toString();
                                vehicleInfoController.selectedCategoryID.value =
                                    brandList[index].vehicleTypeId ?? vehicleInfoController.validCategoryIds.value.split(',').first ?? "";
                                vehicleInfoController.selectedModelID.value =
                                    brandList[index].id ?? "";

                                Get.back();
                              },
                              child: Text(brandList[index].name.toString())),
                        );
                      },
                    ),
            ),
          );
        });
  }

  void zoneDialog(
      BuildContext context, VehicleInfoController vehicleInfoController) {
    Widget cancelButton = TextButton(
      child: Text(
        "Cancel".tr,
        style: TextStyle(color: AppThemeData.primary200),
      ),
      onPressed: () {
        Get.back();
      },
    );
    Widget continueButton = TextButton(
      child: Text("Continue".tr),
      onPressed: () {
        if (vehicleInfoController.selectedZone.isEmpty) {
          ShowToastDialog.showToast("Please select zone");
        } else {
          String nameValue = "";
          for (var element in vehicleInfoController.selectedZone) {
            nameValue =
                "$nameValue${nameValue.isEmpty ? "" : ","} ${vehicleInfoController.zoneList.where((p0) => p0.id == element).first.name}";
          }
          vehicleInfoController.zoneNameController.value.text = nameValue;
          Get.back();
        }
      },
    );
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Zone list'.tr),
            content: SizedBox(
              width: Responsive.width(
                  90, context), // Change as per your requirement
              child: vehicleInfoController.zoneList.isEmpty
                  ? Container()
                  : Obx(
                      () => ListView.builder(
                        shrinkWrap: true,
                        itemCount: vehicleInfoController.zoneList.length,
                        itemBuilder: (BuildContext context, int index) {
                          return Obx(
                            () => CheckboxListTile(
                              value: vehicleInfoController.selectedZone
                                  .contains(
                                      vehicleInfoController.zoneList[index].id),
                              onChanged: (value) {
                                if (vehicleInfoController.selectedZone.contains(
                                    vehicleInfoController.zoneList[index].id)) {
                                  vehicleInfoController.selectedZone.remove(
                                      vehicleInfoController
                                          .zoneList[index].id); // unselect
                                } else {
                                  vehicleInfoController.selectedZone.add(
                                      vehicleInfoController
                                          .zoneList[index].id); // select
                                }
                              },
                              title: Text(vehicleInfoController
                                  .zoneList[index].name
                                  .toString()),
                            ),
                          );
                        },
                      ),
                    ),
            ),
            actions: [
              cancelButton,
              continueButton,
            ],
          );
        });
  }
}
