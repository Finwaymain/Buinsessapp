import 'package:cabme_driver/constant/constant.dart';
import 'package:cabme_driver/constant/show_toast_dialog.dart';
import 'package:cabme_driver/controller/search_address_controller.dart';
import 'package:cabme_driver/themes/app_bar_custom.dart';
import 'package:cabme_driver/themes/text_field_them.dart';
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
                  child: Row(
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
