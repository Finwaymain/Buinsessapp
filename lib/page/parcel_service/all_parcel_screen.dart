import 'package:cabme_driver/constant/constant.dart';
import 'package:cabme_driver/constant/show_toast_dialog.dart';
import 'package:cabme_driver/controller/parcel_order_controller.dart';
import 'package:cabme_driver/model/parcel_model.dart';
import 'package:cabme_driver/page/complaint/add_complaint_screen.dart';
import 'package:cabme_driver/page/parcel_service/parcel_details_screen.dart';
import 'package:cabme_driver/page/parcel_service/parcel_osm_route_view_screen.dart';
import 'package:cabme_driver/page/parcel_service/parcel_route_view_screen.dart';
import 'package:cabme_driver/page/parcel_service/search_parcel_screen.dart';
import 'package:cabme_driver/themes/app_bar_custom.dart';
import 'package:cabme_driver/themes/button_them.dart';
import 'package:cabme_driver/themes/constant_colors.dart';
import 'package:cabme_driver/themes/custom_alert_dialog.dart';
import 'package:cabme_driver/themes/custom_dialog_box.dart';
import 'package:cabme_driver/themes/custom_widget.dart';
import 'package:cabme_driver/utils/Preferences.dart';
import 'package:cabme_driver/utils/dark_theme_provider.dart';
import 'package:cabme_driver/widget/StarRating.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';
import 'package:text_scroll/text_scroll.dart';

class AllParcelScreen extends StatelessWidget {
  const AllParcelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return GetX<ParcelOrderController>(
        init: ParcelOrderController(),
        builder: (controller) {
          return RefreshIndicator(
            onRefresh: () => controller.getParcel(),
            child: Scaffold(
              appBar: AppbarCustom(title: 'All Parcel'.tr),
              body: controller.isLoading.value
                  ? SizedBox()
                  : controller.parcelList.isEmpty
                      ? Constant.emptyView("You don't have any parcel confirmed.")
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          itemCount: controller.parcelList.length,
                          shrinkWrap: true,
                          itemBuilder: (context, index) {
                            return buildHistory(context, controller.parcelList[index], controller, themeChange.getThem());
                          },
                        ),
            ),
          );
        });
  }

  GestureDetector buildHistory(context, ParcelData data, ParcelOrderController controller, bool isDarkMode) {
    return GestureDetector(
      onTap: () async {
        if (data.status == "completed") {
          var isDone = await Get.to(const ParcelDetailsScreen(), arguments: {
            "parcelData": data,
          });
          if (isDone != null) {
            controller.getParcel();
          }
        } else {
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
        }
      },
      child: Container(
        margin: const EdgeInsets.only(left: 16, right: 16, top: 16),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isDarkMode ? AppThemeData.surface50Dark : AppThemeData.surface50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: Container(
                    margin: EdgeInsets.only(right: 16, left: 16),
                    width: 110,
                    height: 34,
                    decoration: BoxDecoration(color: Constant.statusParcelColor(data), borderRadius: BorderRadius.circular(6)),
                    child: Center(
                      child: Text(
                        Constant().capitalizeWords(data.status.toString()),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Constant.statusParcelTextColor(data),
                          fontSize: 14,
                          fontFamily: AppThemeData.medium,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 16, left: 16),
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
                dividerCust(isDarkMode: isDarkMode),
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
                                color: AppThemeData.new200,
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
                                  color: AppThemeData.new200,
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
                                  color: AppThemeData.new200,
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
                  padding: const EdgeInsets.symmetric(horizontal: 16),
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
                            StarRating(
                              size: 18,
                              rating: data.moyenneDriver != null ? double.parse(data.moyenneDriver.toString()) : 0.0,
                              color: AppThemeData.warning200,
                            ),
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
                                  color: AppThemeData.primary400,
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const SizedBox(
                    height: 10,
                  ),
                  Visibility(
                    visible: data.status.toString() == "confirmed",
                    child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  bottom: 20,
                                  left: 10,
                                ),
                                child: ButtonThem.buildButton(
                                  context,
                                  title: 'REJECT'.tr,
                                  btnHeight: 45,
                                  btnWidthRatio: 1,
                                  btnColor: AppThemeData.warning200,
                                  txtColor: isDarkMode ? AppThemeData.grey900 : AppThemeData.grey900Dark,
                                  onPress: () async {
                                    buildShowBottomSheet(context, data, controller, isDarkMode);
                                  },
                                ),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 20, left: 10),
                                child: ButtonThem.buildButton(
                                  context,
                                  title: 'On Ride'.tr,
                                  btnHeight: 45,
                                  btnWidthRatio: 0.8,
                                  btnColor: AppThemeData.primary200,
                                  txtColor: isDarkMode ? AppThemeData.grey900 : AppThemeData.grey900Dark,
                                  onPress: () async {
                                    showDialog(
                                      barrierColor: const Color.fromARGB(66, 20, 14, 14),
                                      context: context,
                                      builder: (context) {
                                        return CustomAlertDialog(
                                          title: "Do you want to on ride this parcel?".tr,
                                          negativeButtonText: 'No'.tr,
                                          positiveButtonText: 'Yes'.tr,
                                          onPressNegative: () {
                                            Get.back();
                                          },
                                          onPressPositive: () {
                                            // Get.back();

                                            if (Constant.rideOtp.toString() != 'yes') {
                                              Map<String, String> bodyParams = {
                                                'id_parcel': data.id.toString(),
                                                'id_user': data.idUserApp.toString(),
                                                'driver_name': '${data.driverName}',
                                                'driver_id': Preferences.getInt(Preferences.userId).toString(),
                                              };
                                              controller.onRideParcel(bodyParams).then((value) {
                                                if (value != null) {
                                                  Get.back();
                                                  showDialog(
                                                      context: context,
                                                      builder: (BuildContext context) {
                                                        return CustomDialogBox(
                                                          title: "On ride Successfully".tr,
                                                          descriptions: "Parcel Successfully On ride.".tr,
                                                          text: "Ok".tr,
                                                          onPress: () async {
                                                            ShowToastDialog.showLoader("Please wait");
                                                            await controller.getParcel().then((v) {
                                                              ShowToastDialog.closeLoader();
                                                              Get.back();
                                                            });
                                                          },
                                                          img: Image.asset('assets/images/green_checked.png'),
                                                        );
                                                      });
                                                }
                                              });
                                            } else {
                                              controller.otpController.value = TextEditingController();
                                              showDialog(
                                                barrierColor: Colors.black26,
                                                context: context,
                                                builder: (context) {
                                                  return Dialog(
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(20),
                                                    ),
                                                    elevation: 0,
                                                    backgroundColor: Colors.transparent,
                                                    child: Container(
                                                      height: 180,
                                                      padding: const EdgeInsets.only(left: 10, top: 20, right: 10, bottom: 10),
                                                      decoration: BoxDecoration(
                                                          shape: BoxShape.rectangle,
                                                          color: isDarkMode ? AppThemeData.surface50Dark : AppThemeData.surface50,
                                                          borderRadius: BorderRadius.circular(20),
                                                          boxShadow: const [
                                                            BoxShadow(color: Colors.black, offset: Offset(0, 10), blurRadius: 10),
                                                          ]),
                                                      child: Column(
                                                        children: [
                                                          Text(
                                                            "Enter OTP".tr,
                                                            style: const TextStyle(fontSize: 16),
                                                          ),
                                                          const SizedBox(
                                                            height: 20,
                                                          ),
                                                          Pinput(
                                                            controller: controller.otpController.value,
                                                            defaultPinTheme: PinTheme(
                                                              height: 50,
                                                              width: 50,
                                                              textStyle: const TextStyle(letterSpacing: 0.60, fontSize: 16, color: Colors.black, fontWeight: FontWeight.w600),
                                                              // margin: EdgeInsets.all(10),
                                                              decoration: BoxDecoration(
                                                                borderRadius: BorderRadius.circular(10),
                                                                shape: BoxShape.rectangle,
                                                                color: isDarkMode ? AppThemeData.surface50Dark : AppThemeData.surface50,
                                                                border: Border.all(color: AppThemeData.textFieldBoarderColor, width: 0.7),
                                                              ),
                                                            ),
                                                            keyboardType: TextInputType.phone,
                                                            textInputAction: TextInputAction.done,
                                                            length: 6,
                                                          ),
                                                          const SizedBox(
                                                            height: 16,
                                                          ),
                                                          Row(
                                                            children: [
                                                              Expanded(
                                                                child: ButtonThem.buildButton(
                                                                  context,
                                                                  title: 'done'.tr,
                                                                  btnHeight: 45,
                                                                  btnWidthRatio: 0.8,
                                                                  btnColor: AppThemeData.primary200,
                                                                  txtColor: isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900,
                                                                  onPress: () {
                                                                    if (controller.otpController.value.text.toString().length == 6) {
                                                                      controller
                                                                          .verifyOTP(
                                                                        userId: data.idUserApp!.toString(),
                                                                        rideId: data.id!.toString(),
                                                                      )
                                                                          .then((value) {
                                                                        if (value != null && value['success'] == "success") {
                                                                          Map<String, String> bodyParams = {
                                                                            'id_parcel': data.id.toString(),
                                                                            'id_user': data.idUserApp.toString(),
                                                                            'driver_name': '${data.driverName}',
                                                                            'driver_id': Preferences.getInt(Preferences.userId).toString(),
                                                                          };

                                                                          controller.onRideParcel(bodyParams).then((value) {
                                                                            if (value != null) {
                                                                              showDialog(
                                                                                  context: context,
                                                                                  builder: (BuildContext context) {
                                                                                    return CustomDialogBox(
                                                                                      title: "On ride Successfully".tr,
                                                                                      descriptions: "Parcel Successfully On ride.".tr,
                                                                                      text: "Ok".tr,
                                                                                      onPress: () {
                                                                                        Get.back();
                                                                                        controller.getParcel();
                                                                                      },
                                                                                      img: Image.asset('assets/images/green_checked.png'),
                                                                                    );
                                                                                  });
                                                                            }
                                                                          });
                                                                        }
                                                                      });
                                                                    } else {
                                                                      ShowToastDialog.showToast('Please Enter OTP');
                                                                    }
                                                                  },
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                width: 8,
                                                              ),
                                                              Expanded(
                                                                child: ButtonThem.buildBorderButton(
                                                                  context,
                                                                  title: 'cancel'.tr,
                                                                  btnHeight: 45,
                                                                  btnWidthRatio: 1,
                                                                  btnColor: isDarkMode ? AppThemeData.grey800 : AppThemeData.grey100,
                                                                  txtColor: isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900,
                                                                  btnBorderColor: isDarkMode ? AppThemeData.grey800 : AppThemeData.grey100,
                                                                  onPress: () {
                                                                    Get.back();
                                                                  },
                                                                ),
                                                              )
                                                            ],
                                                          ),
                                                          const SizedBox(
                                                            height: 16,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  );
                                                },
                                              );
                                            }
                                          },
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                            )
                          ],
                        )),
                  ),
                  Visibility(
                      visible: data.status.toString() == "onride",
                      child: ButtonThem.buildButton(
                        context,
                        title: 'COMPLETE'.tr,
                        btnHeight: 45,
                        btnWidthRatio: 0.8,
                        btnColor: AppThemeData.success300Light,
                        txtColor: AppThemeData.grey900,
                        onPress: () async {
                          Map<String, String> bodyParams = {
                            'id_parcel': data.id.toString(),
                            'id_user': data.idUserApp.toString(),
                            'driver_name': '${data.driverName}',
                            'from_id': Preferences.getInt(Preferences.userId).toString(),
                          };

                          controller.completeParcel(bodyParams).then((value) {
                            if (value != null) {
                              showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return CustomDialogBox(
                                      title: "Completed Successfully".tr,
                                      descriptions: "Parcel Successfully completed.".tr,
                                      text: "Ok".tr,
                                      onPress: () {
                                        Get.back();
                                        controller.getParcel();
                                      },
                                      img: Image.asset('assets/images/green_checked.png'),
                                    );
                                  });
                            }
                          });
                        },
                      )),
                  Visibility(
                    visible: data.status == "completed",
                    child: ButtonThem.buildButton(
                      context,
                      title: 'Add Complaint'.tr,
                      btnWidthRatio: 1,
                      btnHeight: 45,
                      btnColor: isDarkMode ? AppThemeData.grey800 : AppThemeData.grey800Dark,
                      txtColor: isDarkMode ? AppThemeData.grey500Dark : AppThemeData.grey300Dark,
                      onPress: () async {
                        Get.to(AddComplaintScreen(), arguments: {
                          "isReviewScreen": false,
                          "data": data,
                          "ride_type": "parcel",
                        });
                      },
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<dynamic> buildShowBottomSheet(BuildContext context, ParcelData data, ParcelOrderController controller, bool isDarkMode) {
    return showModalBottomSheet(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(topRight: Radius.circular(15), topLeft: Radius.circular(15))),
        context: context,
        isDismissible: true,
        isScrollControlled: true,
        builder: (context) {
          return StatefulBuilder(builder: (context, setState) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10),
              child: Padding(
                padding: MediaQuery.of(context).viewInsets,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        "Cancel Parcel".tr,
                        style: const TextStyle(
                          fontSize: 18,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        "Write a reason for Parcel cancellation".tr,
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: TextField(
                        controller: controller.resonController.value,
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey, width: 1.0),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey, width: 1.0),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 20, bottom: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(
                                bottom: 5,
                              ),
                              child: ButtonThem.buildButton(
                                context,
                                title: 'Cancel Trip'.tr,
                                btnHeight: 45,
                                btnWidthRatio: 0.8,
                                btnColor: AppThemeData.primary200,
                                txtColor: !isDarkMode ? AppThemeData.grey900 : AppThemeData.grey900Dark,
                                onPress: () async {
                                  if (controller.resonController.value.text.isNotEmpty) {
                                    showDialog(
                                      barrierColor: Colors.black26,
                                      context: context,
                                      builder: (context) {
                                        return CustomAlertDialog(
                                          title: "Do you want to reject this booking?".tr,
                                          onPressNegative: () {
                                            Get.back();
                                          },
                                          negativeButtonText: 'No'.tr,
                                          positiveButtonText: 'Yes'.tr,
                                          onPressPositive: () {
                                            Map<String, String> bodyParams = {
                                              'id_parcel': data.id.toString(),
                                              'id_user': data.idUserApp.toString(),
                                              'name': data.driverName.toString(),
                                              'from_id': Preferences.getInt(Preferences.userId).toString(),
                                              'user_cat': controller.userModel.value.userData!.userCat.toString(),
                                              'reason': controller.resonController.value.text.toString(),
                                            };
                                            controller.cancelParcel(bodyParams).then((value) {
                                              if (value != null) {
                                                Get.back();
                                                Get.back();
                                                showDialog(
                                                    context: context,
                                                    builder: (BuildContext context) {
                                                      return CustomDialogBox(
                                                        title: "Reject Successfully".tr,
                                                        descriptions: "Parcel Successfully rejected.".tr,
                                                        text: "Ok".tr,
                                                        onPress: () async {
                                                          ShowToastDialog.showLoader("Please wait");
                                                          await controller.getParcel().then((v) {
                                                            ShowToastDialog.closeLoader();
                                                            Get.back();
                                                          });
                                                        },
                                                        img: Image.asset('assets/images/green_checked.png'),
                                                      );
                                                    });
                                              }
                                            });
                                          },
                                        );
                                      },
                                    );
                                  } else {
                                    ShowToastDialog.showToast("Please enter a reason");
                                  }
                                },
                              ),
                            ),
                          ),
                          SizedBox(width: 5),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(
                                bottom: 5,
                                left: 10,
                              ),
                              child: ButtonThem.buildBorderButton(
                                context,
                                title: 'Close'.tr,
                                btnHeight: 45,
                                btnWidthRatio: 1,
                                btnColor: isDarkMode ? AppThemeData.grey900 : AppThemeData.grey900Dark,
                                txtColor: !isDarkMode ? AppThemeData.grey900 : AppThemeData.grey900Dark,
                                btnBorderColor: AppThemeData.primary200,
                                onPress: () async {
                                  Get.back();
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            );
          });
        });
  }
}

Widget statusTile({required String title, Color? bgColor, Color? txtColor}) {
  return Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(4),
      color: bgColor,
    ),
    alignment: Alignment.center,
    height: 32,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        title.tr,
        style: TextStyle(fontSize: 14, color: txtColor, fontFamily: AppThemeData.medium),
      ),
    ),
  );
}
