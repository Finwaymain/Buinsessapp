import 'package:bottom_picker/bottom_picker.dart';
import 'package:cabme_driver/constant/constant.dart';
import 'package:cabme_driver/constant/show_toast_dialog.dart';
import 'package:cabme_driver/controller/dash_board_controller.dart';
import 'package:cabme_driver/controller/parcel_service_controller.dart';
import 'package:cabme_driver/model/parcel_model.dart';
import 'package:cabme_driver/page/parcel_service/all_parcel_screen.dart';
import 'package:cabme_driver/page/parcel_service/parcel_osm_route_view_screen.dart';
import 'package:cabme_driver/page/parcel_service/parcel_route_view_screen.dart';
import 'package:cabme_driver/page/search_location_screen.dart';
import 'package:cabme_driver/themes/app_bar_custom.dart';
import 'package:cabme_driver/themes/button_them.dart';
import 'package:cabme_driver/themes/constant_colors.dart';
import 'package:cabme_driver/themes/custom_widget.dart';
import 'package:cabme_driver/themes/text_field_them.dart';
import 'package:cabme_driver/utils/Preferences.dart';
import 'package:cabme_driver/utils/dark_theme_provider.dart';
import 'package:cabme_driver/widget/StarRating.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:text_scroll/text_scroll.dart';

class SearchParcelScreen extends StatelessWidget {
  SearchParcelScreen({super.key});
  final dashboardController = Get.put(DashBoardController());
  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return GetX<ParcelServiceController>(
        init: ParcelServiceController(),
        builder: (controller) {
          return Scaffold(
            appBar: AppbarCustom(title: 'Parcel Service'.tr),
            body: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(4.0),
                  margin: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  decoration: BoxDecoration(
                      color: themeChange.getThem() ? AppThemeData.surface50Dark : AppThemeData.surface50,
                      border: Border.all(color: themeChange.getThem() ? AppThemeData.grey200Dark : AppThemeData.grey200, width: 1),
                      borderRadius: const BorderRadius.all(Radius.circular(12))),
                  child: Column(
                    children: [
                      if (double.parse(controller.totalEarn.value.toString()) < double.parse(Constant.minimumWalletBalance!) && controller.iswalletLoading.value == false)
                        Container(
                          padding: const EdgeInsets.all(5),
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: AppThemeData.primary200),
                          child: Text(
                            "${"Your wallet balance must be".tr} ${Constant().amountShow(amount: Constant.minimumWalletBalance!.toString())} ${"to get parcel.".tr}",
                          ),
                        ),
                      InkWell(
                          onTap: () async {
                            if (Constant.selectedMapType == 'osm') {
                              Get.to(const AddressSearchScreen())?.then((value) {
                                if (value != null) {
                                  SearchInfo searchInfoData = value;
                                  controller.sourceLatLng = LatLng(searchInfoData.point!.latitude, searchInfoData.point!.longitude);
                                  controller.sourceCityController.value.text = searchInfoData.address?.city ?? searchInfoData.address?.name ?? '';
                                }
                              });
                            } else {
                              await Constant().handlePressButton(context).then((value) {
                                if (value != null) {
                                  controller.sourceLatLng = LatLng(value.result.geometry!.location.lat, value.result.geometry!.location.lng);
                                  controller.sourceCityController.value.text = value.result.vicinity.toString();
                                }
                              });
                            }
                          },
                          child: TextFieldWidget(
                            contentPadding: const EdgeInsets.all(14),
                            suffix: IconButton(
                              onPressed: () {},
                              icon: SvgPicture.asset(
                                'assets/icons/ic_map.svg',
                                width: 25,
                                height: 25,
                                fit: BoxFit.cover,
                                colorFilter: ColorFilter.mode(
                                  themeChange.getThem() ? AppThemeData.grey200 : AppThemeData.grey500Dark,
                                  BlendMode.srcIn,
                                ),
                              ),
                            ),
                            isBorderEnable: false,
                            hintText: 'From'.tr,
                            controller: controller.sourceCityController.value,
                            enabled: false,
                          )),
                      dividerCust(isDarkMode: themeChange.getThem()),
                      InkWell(
                          onTap: () async {
                            if (Constant.selectedMapType == 'osm') {
                              Get.to(const AddressSearchScreen())?.then((value) {
                                if (value != null) {
                                  SearchInfo data = value;
                                  controller.destinationLatLng = LatLng(data.point!.latitude, data.point!.longitude);
                                  controller.destinationCityController.value.text = data.address?.city ?? data.address?.name ?? '';
                                }
                              });
                            } else {
                              await Constant().handlePressButton(context).then((value) {
                                if (value != null) {
                                  controller.destinationLatLng = LatLng(value.result.geometry!.location.lat, value.result.geometry!.location.lng);
                                  controller.destinationCityController.value.text = value.result.vicinity.toString();
                                }
                              });
                            }
                          },
                          child: TextFieldWidget(
                            contentPadding: const EdgeInsets.all(14),
                            suffix: IconButton(
                              onPressed: () {},
                              icon: SvgPicture.asset(
                                'assets/icons/ic_map.svg',
                                width: 25,
                                height: 25,
                                fit: BoxFit.cover,
                                colorFilter: ColorFilter.mode(
                                  themeChange.getThem() ? AppThemeData.grey200 : AppThemeData.grey500Dark,
                                  BlendMode.srcIn,
                                ),
                              ),
                            ),
                            isBorderEnable: false,
                            hintText: 'To'.tr,
                            controller: controller.destinationCityController.value,
                            enabled: false,
                          )),
                      dividerCust(isDarkMode: themeChange.getThem()),
                      InkWell(
                          onTap: () async {
                            BottomPicker.date(
                              onSubmit: (index) {
                                controller.dateAndTime = index;
                                DateFormat dateFormat = DateFormat("dd-MMM-yyyy");
                                String string = dateFormat.format(index);

                                controller.whenController.value.text = string;
                              },
                              minDateTime: DateTime.now(),
                              buttonAlignment: MainAxisAlignment.center,
                              displaySubmitButton: true,
                              pickerTitle: const Text(""),
                              buttonSingleColor: AppThemeData.primary200,
                            ).show(context);
                          },
                          child: TextFieldWidget(
                            contentPadding: const EdgeInsets.all(14),
                            suffix: IconButton(
                              onPressed: () {},
                              icon: SvgPicture.asset(
                                'assets/icons/ic_calender.svg',
                                width: 25,
                                height: 25,
                                fit: BoxFit.cover,
                                colorFilter: ColorFilter.mode(
                                  themeChange.getThem() ? AppThemeData.grey200 : AppThemeData.grey500Dark,
                                  BlendMode.srcIn,
                                ),
                              ),
                            ),
                            isBorderEnable: false,
                            hintText: 'Select date'.tr,
                            controller: controller.whenController.value,
                            enabled: false,
                          )),
                    ],
                  ),
                ),
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ButtonThem.buildButton(context,
                        title: "Search".tr,
                        btnHeight: 48,
                        btnColor: AppThemeData.primary200,
                        txtColor: themeChange.getThem() ? AppThemeData.grey900 : AppThemeData.grey900Dark, onPress: () {
                      if (controller.sourceCityController.value.text.isNotEmpty && controller.whenController.value.text.isNotEmpty) {
                        if (double.parse(controller.totalEarn.value.toString()) < double.parse(Constant.minimumWalletBalance!)) {
                          ShowToastDialog.showToast(
                              "${"Your wallet balance must be".tr} ${Constant().amountShow(amount: Constant.minimumWalletBalance!.toString())} ${"to get parcel.".tr}");
                        } else {
                          String url =
                              "?source_lat=${controller.sourceLatLng!.latitude.toString()}&source_lng=${controller.sourceLatLng!.longitude.toString()}&destination_lat=${controller.destinationLatLng != null ? controller.destinationLatLng!.latitude.toString() : ""}&destination_lng=${controller.destinationLatLng != null ? controller.destinationLatLng!.longitude.toString() : ""}&date=${controller.whenController.value.text}&source_city=${controller.sourceCityController.value.text}&destination_city=${controller.destinationCityController.value.text}&driver_id=${Preferences.getInt(Preferences.userId).toString()}";

                          controller.searchParcel(url);
                        }
                      } else {
                        ShowToastDialog.showToast("Please enter source city and date.");
                      }
                    })),
                Expanded(
                    child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: controller.searchParcelList.length,
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    return buildHistory(context, controller.searchParcelList[index], controller, themeChange.getThem());
                  },
                ))
              ],
            ),
          );
        });
  }

  GestureDetector buildHistory(context, ParcelData data, ParcelServiceController controller, bool isDarkMode) {
    return GestureDetector(
      onTap: () async {
        // var isDone = await Get.to(const ParcelDetailsScreen(), arguments: {
        //   "parcelData": data,
        // });

        var argumentData = {'type': data.status, 'data': data};

        if (Constant.liveTrackingMapType == "inappmap") {
          if (Constant.selectedMapType == "osm") {
            Get.to(const ParcelOsmRouteViewScreen(), arguments: argumentData);
          } else {
            Get.to(const ParcelRouteViewScreen(), arguments: argumentData);
          }
        } else {
          Constant.redirectMap(
            latitude: double.parse(data.latDestination!),
            longLatitude: double.parse(data.lngDestination!),
            name: data.destination!,
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(left: 16, right: 16, top: 16),
        decoration: BoxDecoration(
          color: isDarkMode ? AppThemeData.surface50Dark : AppThemeData.surface50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        buildLine(isDarkMode: isDarkMode),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              buildUsersDetails(
                                context,
                                data,
                                isDarkMode: isDarkMode,
                                isSender: true,
                              ),
                              const SizedBox(
                                height: 10,
                              ),
                              buildUsersDetails(
                                context,
                                data,
                                isDarkMode: isDarkMode,
                                isSender: false,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextScroll("${double.parse(data.distance.toString()).toStringAsFixed(int.parse(Constant.decimal!))} ${data.distanceUnit}",
                                mode: TextScrollMode.bouncing,
                                pauseBetween: const Duration(seconds: 2),
                                style: TextStyle(
                                  fontFamily: AppThemeData.semiBold,
                                  color: AppThemeData.primary200,
                                  fontSize: 18,
                                )),
                            const SizedBox(
                              height: 2,
                            ),
                            Text('Distance'.tr,
                                maxLines: 1,
                                style: TextStyle(
                                  fontFamily: AppThemeData.regular,
                                  color: isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900,
                                  fontSize: 12,
                                )),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextScroll(data.duration.toString(),
                                  mode: TextScrollMode.bouncing,
                                  pauseBetween: const Duration(seconds: 2),
                                  style: TextStyle(
                                    fontFamily: AppThemeData.semiBold,
                                    color: AppThemeData.primary200,
                                    fontSize: 18,
                                  )),
                              const SizedBox(
                                height: 2,
                              ),
                              Text('Duration'.tr,
                                  maxLines: 1,
                                  style: TextStyle(
                                    fontFamily: AppThemeData.regular,
                                    color: isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900,
                                    fontSize: 12,
                                  )),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(Constant().amountShow(amount: data.amount.toString()),
                                  maxLines: 1,
                                  style: TextStyle(
                                    fontFamily: AppThemeData.semiBold,
                                    color: AppThemeData.primary200,
                                    fontSize: 18,
                                  )),
                              const SizedBox(
                                height: 2,
                              ),
                              Text("Amount".tr,
                                  style: TextStyle(
                                    fontFamily: AppThemeData.regular,
                                    color: isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900,
                                    fontSize: 12,
                                  )),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(60),
                          child: CachedNetworkImage(
                            imageUrl: data.userPhoto.toString(),
                            height: 60,
                            width: 60,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Constant.loader(context, isDarkMode: isDarkMode),
                            errorWidget: (context, url, error) => Image.asset(
                              "assets/images/appIcon.png",
                              height: 60,
                              width: 60,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                  padding: const EdgeInsets.only(left: 6),
                                  child: Text(data.userName.toString(),
                                      style: TextStyle(
                                        fontFamily: AppThemeData.semiBold,
                                        color: isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900,
                                        fontSize: 16,
                                      ))),
                              StarRating(size: 18, rating: data.moyenneDriver != null ? double.parse(data.moyenneDriver.toString()) : 0.0, color: AppThemeData.primary200),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 10),
                              child: InkWell(
                                onTap: () {
                                  Constant.makePhoneCall("${data.userPhone}");
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: AppThemeData.new200,
                                    borderRadius: BorderRadius.circular(40),
                                  ),
                                  child: SvgPicture.asset(
                                    'assets/icons/call_icon.svg',
                                    height: 20,
                                    width: 20,
                                    colorFilter: ColorFilter.mode(
                                      isDarkMode ? AppThemeData.surface50Dark : AppThemeData.surface50,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 5.0,
                              ),
                              child: Text(data.parcelDate.toString(),
                                  style: TextStyle(
                                    fontFamily: AppThemeData.medium,
                                    color: isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900,
                                    fontSize: 14,
                                  )),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0),
              child: ButtonThem.buildBorderButton(
                context,
                title: 'Accept'.tr,
                btnHeight: 50,
                btnColor: AppThemeData.primary200,
                txtColor: isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900,
                btnBorderColor: AppThemeData.primary200,
                onPress: () async {
                  Map<String, String> bodyParams = {
                    "id_parcel": data.id.toString(),
                    "id_user": data.idUserApp.toString(),
                    "driver_name": "${controller.userModel!.userData!.prenom} ${controller.userModel!.userData!.nom}",
                    "driver_id": Preferences.getInt(Preferences.userId).toString(),
                  };
                  controller.confirmedParcel(bodyParams).then((value) {
                    if (value != null) {
                      ShowToastDialog.showToast(value['message']);
                      Get.off(const AllParcelScreen());
                    }
                  });
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}

Padding buildUsersDetails(context, ParcelData data, {required bool isDarkMode, bool isSender = false}) {
  return Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: 8.0,
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    isSender ? data.senderName.toString() : data.receiverName.toString(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: AppThemeData.medium,
                      color: isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900,
                    ),
                  ),
                ],
              ),
              Text(
                isSender ? data.senderPhone.toString() : data.receiverPhone.toString(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: AppThemeData.regular,
                  color: isDarkMode ? AppThemeData.grey400 : AppThemeData.grey300Dark,
                ),
              ),
              Text(
                isSender ? data.source.toString() : data.destination.toString(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: AppThemeData.regular,
                  color: isDarkMode ? AppThemeData.grey400 : AppThemeData.grey300Dark,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Column buildLine({required bool isDarkMode}) {
  return Column(
    children: [
      const SizedBox(
        height: 6,
      ),
      Column(
        children: [
          SvgPicture.asset(
            'assets/icons/ic_location.svg',
            colorFilter: ColorFilter.mode(
              AppThemeData.success300,
              BlendMode.srcIn,
            ),
          ),
        ],
      ),
      Container(
        width: 2,
        height: 50,
        color: isDarkMode ? AppThemeData.grey200Dark : AppThemeData.grey200,
      ),
      SvgPicture.asset(
        'assets/icons/ic_location.svg',
        colorFilter: ColorFilter.mode(
          AppThemeData.warning200,
          BlendMode.srcIn,
        ),
      ),
    ],
  );
}
