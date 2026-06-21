import 'package:cabme_driver/controller/car_service_history_controller.dart';
import 'package:cabme_driver/model/car_service_book_model.dart';
import 'package:cabme_driver/page/car_service_history/show_service_doc_screen.dart';
import 'package:cabme_driver/page/car_service_history/upload_car_service_book.dart';
import 'package:cabme_driver/themes/app_bar_custom.dart';
import 'package:cabme_driver/utils/dark_theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../../themes/constant_colors.dart';

class CarServiceBookHistory extends StatelessWidget {
  const CarServiceBookHistory({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return GetX<CarServiceHistoryController>(
        init: CarServiceHistoryController(),
        builder: (controller) {
          return RefreshIndicator(
            onRefresh: () => controller.getCarServiceBooks(),
            child: Scaffold(
              floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
              floatingActionButton: FloatingActionButton.extended(
                onPressed: () {
                  controller.carServiceBook.value = '';
                  controller.kmDrivenController.value.text = '';
                  Get.to(() => const AddCarServiceBookHistory());
                },
                backgroundColor: ConstantColors.yellow,
                label: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add,
                      color: themeChange.getThem() ? AppThemeData.grey900 : AppThemeData.grey900Dark,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Add Service History'.tr,
                      style: TextStyle(
                        color: themeChange.getThem() ? AppThemeData.grey900 : AppThemeData.grey900Dark,
                        fontSize: 16,
                        fontFamily: AppThemeData.medium,
                      ),
                    )
                  ],
                ),
              ),
              appBar: AppbarCustom(title: 'Car Service'.tr),
              body: controller.isLoading.value
                  ? SizedBox()
                  : controller.serviceList.isEmpty
                      ? Center(child: Text('No car service history not available'.tr))
                      : ListView.builder(
                          itemCount: controller.serviceList.length,
                          itemBuilder: (context, index) {
                            return showServiceBookDetails(serviceData: controller.serviceList[index], isDarkMode: themeChange.getThem());
                          }),
            ),
          );
        });
  }

  Padding showServiceBookDetails({required ServiceData serviceData, required bool isDarkMode}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10),
      child: GestureDetector(
        onTap: () => Get.to(() => ShowServiceDocScreen(
              serviceData: serviceData,
            )),
        child: Container(
          decoration: BoxDecoration(
            color: isDarkMode ? AppThemeData.surface50Dark : AppThemeData.surface50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: SvgPicture.asset(
                            'assets/icons/ic_calendar.svg',
                            colorFilter: ColorFilter.mode(
                              isDarkMode ? AppThemeData.success300 : AppThemeData.success300,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                        Text(
                          serviceData.modifier.toString(),
                          style: TextStyle(
                            fontSize: 16,
                            color: isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900,
                            fontFamily: AppThemeData.medium,
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: SvgPicture.asset(
                              'assets/icons/ic_speepmetter.svg',
                              // colorFilter: ColorFilter.mode(
                              //   isDarkMode ? AppThemeData.grey500Dark : AppThemeData.grey500,
                              //   BlendMode.srcIn,
                              // ),
                            ),
                          ),
                          Text(
                            serviceData.km.toString() + "KM".tr,
                            style: TextStyle(
                              fontSize: 16,
                              color: AppThemeData.primary200,
                              fontFamily: AppThemeData.medium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 15,
                ),
                Row(
                  children: [
                    Text(
                      serviceData.fileName.toString(),
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        color: AppThemeData.new200,
                        fontFamily: AppThemeData.medium,
                        decorationColor: AppThemeData.new200,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
