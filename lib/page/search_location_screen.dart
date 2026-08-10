import 'package:cabme_driver/constant/constant.dart';
import 'package:cabme_driver/constant/show_toast_dialog.dart';
import 'package:cabme_driver/controller/search_address_controller.dart';
import 'package:cabme_driver/themes/app_bar_custom.dart';
import 'package:cabme_driver/themes/constant_colors.dart';
import 'package:cabme_driver/themes/text_field_them.dart';
import 'package:cabme_driver/utils/location_picker_helper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddressSearchScreen extends StatelessWidget {
  final bool isTab;
  const AddressSearchScreen({super.key, this.isTab = false});

  @override
  Widget build(BuildContext context) {
    return GetX(
        init: SearchAddressController(),
        builder: (controller) {
          return Scaffold(
            appBar: isTab
                ? null
                : AppbarCustom(
                    title: 'Search Address'.tr,
                    elevation: 0,
                  ),
            body: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFieldWidget(
                                onChanged: (v) {
                                  controller.debouncer(() => controller.fetchAddress(v ?? ''));
                                  return null;
                                },
                                radius: BorderRadius.circular(8.0),
                                hintText: 'Enter address or location'.tr,
                                controller: controller.searchTxtController.value),
                          ),
                          const SizedBox(width: 8),
                          Material(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            child: InkWell(
                              onTap: () async {
                                final picked = await LocationPickerHelper.fetchCurrentLocation();
                                if (picked != null) {
                                  Get.back(result: picked.toSearchInfo());
                                }
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                width: 48,
                                height: 48,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.withValues(alpha: 0.25)),
                                ),
                                child: Icon(Icons.my_location_rounded, color: AppThemeData.primary200, size: 22),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      InkWell(
                        onTap: () async {
                          final picked = await LocationPickerHelper.fetchCurrentLocation();
                          if (picked != null) {
                            Get.back(result: picked.toSearchInfo());
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppThemeData.primary200.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppThemeData.primary200.withValues(alpha: 0.25)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.my_location_rounded, color: AppThemeData.primary200, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Use my current location (GPS)'.tr,
                                  style: TextStyle(
                                    fontFamily: AppThemeData.semiBold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    primary: true,
                    itemCount: controller.suggestionsList.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(controller.suggestionsList[index].address.toString()),
                        onTap: () async {
                          if (Constant.selectedMapType == 'google') {
                            ShowToastDialog.showLoader("Resolving location...".tr);
                            final resolved = await controller.resolvePlaceDetails(controller.suggestionsList[index]);
                            ShowToastDialog.closeLoader();
                            if (resolved != null) {
                              Get.back(result: resolved);
                            } else {
                              ShowToastDialog.showToast("Failed to resolve address.".tr);
                            }
                          } else {
                            Get.back(result: controller.suggestionsList[index]);
                          }
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        });
  }
}
