import 'dart:convert';

import 'package:cabme_driver/constant/constant.dart';
import 'package:cabme_driver/constant/show_toast_dialog.dart';
import 'package:cabme_driver/controller/dash_board_controller.dart';
import 'package:cabme_driver/controller/new_ride_controller.dart';
import 'package:cabme_driver/model/ride_model.dart';
import 'package:cabme_driver/model/user_model.dart';
import 'package:cabme_driver/page/complaint/add_complaint_screen.dart';
import 'package:cabme_driver/page/completed/trip_history_screen.dart';
import 'package:cabme_driver/page/create_ride/create_osm_ride_screen.dart';
import 'package:cabme_driver/page/create_ride/create_ride_screen.dart';
import 'package:cabme_driver/page/features/Taxi/taxi_dashboard/taxi_dashboard.dart';
import 'package:cabme_driver/page/review_screens/add_review_screen.dart';
import 'package:cabme_driver/page/route_view_screen/route_osm_view_screen.dart';
import 'package:cabme_driver/page/route_view_screen/route_view_screen.dart';
import 'package:cabme_driver/themes/button_them.dart';
import 'package:cabme_driver/themes/constant_colors.dart';
import 'package:cabme_driver/themes/custom_alert_dialog.dart';
import 'package:cabme_driver/themes/custom_dialog_box.dart';
import 'package:cabme_driver/themes/custom_widget.dart';
import 'package:cabme_driver/themes/responsive.dart';
import 'package:cabme_driver/utils/Preferences.dart';
import 'package:cabme_driver/utils/dark_theme_provider.dart';
import 'package:cabme_driver/widget/StarRating.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';
import 'package:text_scroll/text_scroll.dart';
import 'package:url_launcher/url_launcher.dart';

class NewRideScreen extends StatelessWidget {
  final bool isTab;
  NewRideScreen({super.key, this.isTab = false});

  final controllerDashBoard = Get.put(DashBoardController());
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return GetX<NewRideController>(
      init: NewRideController(),
      builder: (controller) {
        return Scaffold(
            key: _scaffoldKey,
            appBar: isTab ? null : AppBar(
              backgroundColor: themeChange.getThem() ? AppThemeData.surface50Dark : AppThemeData.surface50,
              elevation: 0,
              centerTitle: true,
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${Constant.appName}'.tr,
                    style: TextStyle(
                      color: themeChange.getThem() ? AppThemeData.grey900Dark : AppThemeData.grey900,
                      fontSize: 18,
                      fontFamily: AppThemeData.semiBold,
                    ),
                  ),
                  // Row(
                  //   children: [
                  //     Text(
                  //       "Status".tr,
                  //       style: TextStyle(
                  //         color: themeChange.getThem() ? AppThemeData.grey500Dark : AppThemeData.grey500,
                  //         fontFamily: AppThemeData.regular,
                  //         fontSize: 16,
                  //       ),
                  //     ),
                  //     const SizedBox(
                  //       width: 4,
                  //     ),
                  //     Transform.scale(
                  //       scale: 0.8,
                  //       child: Switch(
                  //         value: controllerDashBoard.isActive.value,
                  //         activeColor: AppThemeData.success300,
                  //         inactiveTrackColor: AppThemeData.warning200,
                  //         onChanged: (value) async {
                  //           await controllerDashBoard.getUsrData();
                  //           if (controllerDashBoard.userModel.value.userData!.statutVehicule == "no") {
                  //             showAlertDialog(context, "vehicleInformation");
                  //           } else if (controllerDashBoard.userModel.value.userData!.isVerified == "no" || controllerDashBoard.userModel.value.userData!.isVerified!.isEmpty) {
                  //             showAlertDialog(context, "document");
                  //           } else {
                  //             ShowToastDialog.showLoader("Please wait");
                  //
                  //             Map<String, dynamic> bodyParams = {
                  //               'id_driver': Preferences.getInt(Preferences.userId),
                  //               'online': controllerDashBoard.isActive.value ? 'no' : 'yes',
                  //             };
                  //
                  //             await controllerDashBoard.changeOnlineStatus(bodyParams).then((value) {
                  //               if (value != null) {
                  //                 if (value['success'] == "success") {
                  //                   UserModel userModel = Constant.getUserData();
                  //                   userModel.userData!.online = value['data']['online'];
                  //                   controller.userModel.value = userModel;
                  //                   Preferences.setString(Preferences.user, jsonEncode(userModel.toJson()));
                  //                   controllerDashBoard.isActive.value = userModel.userData!.online == 'no' ? false : true;
                  //                   ShowToastDialog.showToast(value['message']);
                  //                 } else {
                  //                   ShowToastDialog.showToast(value['error']);
                  //                 }
                  //               }
                  //             });
                  //
                  //             ShowToastDialog.closeLoader();
                  //           }
                  //         },
                  //       ),
                  //     ),
                  //   ],
                  // ),
                ],
              ),
              titleSpacing: 12,
              // leading: Builder(builder: (context) {
              //   return Padding(
              //     padding: const EdgeInsets.all(8.0),
              //     child: GestureDetector(
              //       onTap: () {
              //         _scaffoldKey.currentState?.openDrawer();
              //         // Scaffold.of(context).openDrawer();
              //       },
              //       child: Image.asset(
              //         "assets/icons/ic_side_menu.png",
              //         color: themeChange.getThem() ? AppThemeData.grey900Dark : AppThemeData.grey900,
              //       ),
              //     ),
              //   );
              // }),
            ),
            backgroundColor: themeChange.getThem() ? AppThemeData.grey50Dark : AppThemeData.grey50,
            floatingActionButtonLocation: isTab ? const CustomFabLocation(80) : FloatingActionButtonLocation.centerFloat,
            floatingActionButton: SizedBox(
              width: Responsive.width(50, context),
              height: 50,
              child: FloatingActionButton.extended(
                backgroundColor: AppThemeData.primary200,
                foregroundColor: Colors.black,
                onPressed: () {
                  if (controller.userModel.value.userData?.isVerified == "yes") {
                    if (Constant.selectedMapType == 'osm') {
                      Get.to(() => const CreateOsmRideScreen())?.then((v) {
                        controller.getNewRide();
                      });
                    } else {
                      Get.to(() => const CreateRideScreen())?.then((v) {
                        controller.getNewRide();
                      });
                    }
                  } else {
                    ShowToastDialog.showToast('Your document is not verified by admin');
                  }
                },
                icon: const Icon(Icons.add),
                label: Text(
                  'Create Ride'.tr,
                  style: TextStyle(fontSize: 14, fontFamily: AppThemeData.medium),
                ),
              ),
            ),
            // floatingActionButton: FloatingActionButton(
            //   backgroundColor: AppThemeData.primary200,
            //   onPressed: () {
            //     if (controller.userModel.value.userData!.isVerified == "yes") {
            //       if (Constant.selectedMapType == 'osm') {
            //         Get.to(() => const CreateOsmRideScreen());
            //       } else {
            //         Get.to(() => const CreateRideScreen());
            //       }
            //     } else {
            //       ShowToastDialog.showToast('Your document is not verified by admin'.tr);
            //     }
            //   },
            //   child: const Icon(
            //     Icons.add,
            //     size: 35,
            //   ),
            // ),
            drawer: isTab ? null : buildAppDrawer(context, controllerDashBoard),
            body: RefreshIndicator(
              onRefresh: () => controller.getNewRide(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Column(
                  children: [
                    // if (double.parse(controller.userModel.value.userData!.amount.toString()) < double.parse(Constant.minimumWalletBalance!))
                    //   Container(
                    //     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    //     decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: AppThemeData.primary200),
                    //     child: Text(
                    //       "${"Your wallet balance must be".tr} ${Constant().amountShow(amount: Constant.minimumWalletBalance!.toString())} ${"to get ride.".tr}",
                    //     ),
                    //   ),
                    Expanded(
                      child: controller.isLoading.value
                          ? SizedBox()
                          : controller.rideList.isEmpty
                              ? Constant.emptyView("Your don't have any ride booked.")
                              : ListView.builder(
                                  padding: EdgeInsets.only(bottom: isTab ? 150 : 50),
                                  itemCount: controller.rideList.length,
                                  shrinkWrap: true,
                                  itemBuilder: (context, index) {
                                    return newRideWidgets(context, controller.rideList[index], controller, themeChange.getThem());
                                  }),
                    ),
                  ],
                ),
              ),
            ));
      },
    );
  }

  Widget newRideWidgets(BuildContext context, RideData data, NewRideController controller, bool isDarkMode) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return InkWell(
      onTap: () async {
        if (data.statut == "completed") {
          var isDone = await Get.to(const TripHistoryScreen(), arguments: {
            "rideData": data,
          });
          if (isDone != null) {
            controller.getNewRide();
          }
        } else {
          var argumentData = {'type': data.statut, 'data': data};

          if (Constant.liveTrackingMapType == "inappmap") {
            if (Constant.selectedMapType == 'osm') {
              Get.to(const RouteOsmViewScreen(), arguments: argumentData);
            } else {
              Get.to(const RouteViewScreen(), arguments: argumentData);
            }
          } else {
            Constant.redirectMap(
              latitude: double.parse(data.latitudeArrivee!), //orderModel.destinationLocationLAtLng!.latitude!,
              longLatitude: double.parse(data.longitudeArrivee!), //orderModel.destinationLocationLAtLng!.longitude!,
              name: data.destinationName!,
            ); //orderModel.destinationLocationName.toString());
          }
        }
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Container(
          decoration: BoxDecoration(
            color: themeChange.getThem() ? AppThemeData.surface50Dark : AppThemeData.surface50,
            borderRadius: const BorderRadius.all(Radius.circular(15.0)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          SvgPicture.asset(
                            "assets/icons/ic_source.svg",
                            height: 24,
                          ),
                          Image.asset(
                            "assets/icons/line.png",
                            height: 30,
                            color: AppThemeData.grey400,
                          ),
                        ],
                      ),
                      const SizedBox(
                        width: 5,
                      ),
                      Expanded(
                        child: Text(
                          data.departName.toString(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(
                        width: 8,
                      ),
                      Container(
                        width: 100,
                        height: 34,
                        decoration: BoxDecoration(color: Constant.statusColor(data), borderRadius: BorderRadius.circular(10)),
                        child: Center(
                          child: Text(
                            Constant().capitalizeWords(data.statut.toString()),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Constant.statusTextColor(data),
                              fontSize: 14,
                              fontFamily: AppThemeData.medium,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    left: 18.0,
                  ),
                  child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: data.stops!.length,
                      itemBuilder: (context, int index) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              children: [
                                Text(
                                  String.fromCharCode(index + 65),
                                  style: const TextStyle(
                                    fontSize: 16,
                                  ),
                                ),
                                Image.asset(
                                  "assets/icons/line.png",
                                  height: 30,
                                  color: ConstantColors.hintTextColor,
                                ),
                              ],
                            ),
                            const SizedBox(
                              width: 5,
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(left: 10),
                                child: Text(
                                  data.stops![index].location.toString(),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SvgPicture.asset(
                        "assets/icons/ic_destenation.svg",
                        height: 24,
                      ),
                      const SizedBox(
                        width: 5,
                      ),
                      Expanded(
                        child: Text(
                          data.destinationName.toString(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: dividerCust(isDarkMode: themeChange.getThem()),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            TextScroll(
                              '${double.parse(data.distance.toString()).toStringAsFixed(int.parse(Constant.decimal!))} ${Constant.distanceUnit}',
                              mode: TextScrollMode.bouncing,
                              pauseBetween: const Duration(seconds: 2),
                              style: TextStyle(color: AppThemeData.primary400, fontSize: 18, fontFamily: AppThemeData.semiBold),
                            ),
                            Text("Distance".tr,
                                style: TextStyle(color: themeChange.getThem() ? AppThemeData.grey900Dark : AppThemeData.grey900, fontSize: 12, fontFamily: AppThemeData.regular)),
                          ],
                        ),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              data.numberPoeple.toString(),
                              style: TextStyle(color: AppThemeData.primary400, fontSize: 18, fontFamily: AppThemeData.semiBold),
                            ),
                            Text("Passangers".tr,
                                style: TextStyle(color: themeChange.getThem() ? AppThemeData.grey900Dark : AppThemeData.grey900, fontSize: 12, fontFamily: AppThemeData.regular)),
                          ],
                        ),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            TextScroll(
                              data.duree.toString(),
                              mode: TextScrollMode.bouncing,
                              pauseBetween: const Duration(seconds: 2),
                              style: TextStyle(color: AppThemeData.primary400, fontSize: 18, fontFamily: AppThemeData.semiBold),
                            ),
                            Text("Duration".tr,
                                style: TextStyle(color: themeChange.getThem() ? AppThemeData.grey900Dark : AppThemeData.grey900, fontSize: 12, fontFamily: AppThemeData.regular)),
                          ],
                        ),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              Constant().amountShow(amount: data.montant.toString()),
                              style: TextStyle(color: AppThemeData.primary400, fontSize: 18, fontFamily: AppThemeData.semiBold),
                            ),
                            Text("Trip Price".tr,
                                style: TextStyle(color: themeChange.getThem() ? AppThemeData.grey900Dark : AppThemeData.grey900, fontSize: 12, fontFamily: AppThemeData.regular)),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    left: 12,
                    right: 12,
                  ),
                  child: Row(
                    children: [
                      ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: data.photoPath.toString(),
                          height: 45,
                          width: 45,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Constant.loader(context, isDarkMode: themeChange.getThem()),
                          errorWidget: (context, url, error) => Image.asset(
                            "assets/images/appIcon.png",
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 12.0),
                          child: data.rideType! == 'driver' && data.existingUserId.toString() == "null"
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('${data.userInfo!.name}',
                                        style: TextStyle(
                                          color: themeChange.getThem() ? AppThemeData.grey900Dark : AppThemeData.grey900,
                                          fontSize: 16,
                                          fontFamily: AppThemeData.semiBold,
                                        )),
                                    Text('${data.userInfo!.email}', style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w400)),
                                  ],
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('${data.prenom.toString()} ${data.nom.toString()}',
                                        style: TextStyle(
                                          color: themeChange.getThem() ? AppThemeData.grey900Dark : AppThemeData.grey900,
                                          fontSize: 16,
                                          fontFamily: AppThemeData.semiBold,
                                        )),
                                    StarRating(size: 18, rating: double.parse(data.moyenneDriver.toString()), color: AppThemeData.warning200),
                                  ],
                                ),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              if (data.rideType! == 'driver' && data.existingUserId.toString() == "null") {
                                Constant.makePhoneCall(data.userInfo!.phone.toString());
                              } else {
                                Constant.makePhoneCall(data.phone.toString());
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.blue,
                              shape: const CircleBorder(),
                              backgroundColor: Colors.blue,
                              padding: const EdgeInsets.all(6), // <-- Splash color
                            ),
                            child: const Icon(
                              Icons.call,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          Text(
                            data.dateRetour.toString(),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                  ),
                  child: Column(
                    children: [
                      Visibility(
                        visible: data.statut == "completed",
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Row(
                            children: [
                              Expanded(
                                  child: ButtonThem.buildButton(context,
                                      btnHeight: 45,
                                      btnWidthRatio: 1,
                                      title: data.statutPaiement == "yes" ? "paid".tr : "Not paid".tr,
                                      btnColor: data.statutPaiement == "yes" ? AppThemeData.success300 : AppThemeData.success300,
                                      txtColor: themeChange.getThem() ? AppThemeData.grey900 : AppThemeData.grey900Dark,
                                      onPress: () {})),
                              if (data.existingUserId.toString() != "null") SizedBox(width: 10),
                              if (data.existingUserId.toString() != "null")
                                Expanded(
                                  child: ButtonThem.buildButton(
                                    context,
                                    title: 'Add Review'.tr,
                                    btnWidthRatio: 1,
                                    btnHeight: 45,
                                    btnColor: AppThemeData.primary200,
                                    txtColor: AppThemeData.grey900,
                                    onPress: () async {
                                      Get.to(const AddReviewScreen(), arguments: {
                                        'rideData': data,
                                      });
                                    },
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Visibility(
                        visible: data.statut == "completed" && data.existingUserId.toString() != "null",
                        child: ButtonThem.buildButton(
                          context,
                          title: 'Add Complaint'.tr,
                          btnHeight: 45,
                          btnColor: themeChange.getThem() ? AppThemeData.grey900 : AppThemeData.grey900Dark,
                          txtColor: themeChange.getThem() ? AppThemeData.grey500Dark : AppThemeData.grey300Dark,
                          onPress: () async {
                            Get.to(AddComplaintScreen(), arguments: {
                              "isReviewScreen": false,
                              "data": data,
                              "ride_type": "ride",
                            });
                          },
                        ),
                      ),
                      Row(
                        children: [
                          Visibility(
                            visible: data.statut == "new" || data.statut == "confirmed" ? true : false,
                            child: Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 5, left: 8, right: 8),
                                child: ButtonThem.buildButton(
                                  context,
                                  title: 'REJECT'.tr,
                                  btnHeight: 45,
                                  btnWidthRatio: 1,
                                  btnColor: AppThemeData.warning200,
                                  txtColor: themeChange.getThem() ? AppThemeData.grey900 : AppThemeData.grey900Dark,
                                  onPress: () async {
                                    buildShowBottomSheet(context, data, controller, isDarkMode);
                                  },
                                ),
                              ),
                            ),
                          ),
                          Visibility(
                            visible: data.statut == "new" ? true : false,
                            child: Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 5, left: 8, right: 8),
                                child: ButtonThem.buildButton(
                                  context,
                                  title: 'ACCEPT'.tr,
                                  btnHeight: 45,
                                  btnWidthRatio: 1,
                                  btnColor: AppThemeData.success300,
                                  txtColor: themeChange.getThem() ? AppThemeData.grey900 : AppThemeData.grey900Dark,
                                  onPress: () async {
                                    showDialog(
                                      barrierColor: Colors.black26,
                                      context: context,
                                      builder: (context) {
                                        return CustomAlertDialog(
                                          title: "Do you want to confirm this booking?".tr,
                                          onPressNegative: () {
                                            Get.back();
                                          },
                                          negativeButtonText: 'No'.tr,
                                          positiveButtonText: 'Yes'.tr,
                                          onPressPositive: () {
                                            Map<String, String> bodyParams = {
                                              'id_ride': data.id.toString(),
                                              'id_user': data.idUserApp.toString(),
                                              'driver_name': '${data.prenomConducteur.toString()} ${data.nomConducteur.toString()}',
                                              'lat_conducteur': data.latitudeDepart.toString(),
                                              'lng_conducteur': data.longitudeDepart.toString(),
                                              'lat_client': data.latitudeArrivee.toString(),
                                              'lng_client': data.longitudeArrivee.toString(),
                                              'from_id': Preferences.getInt(Preferences.userId).toString(),
                                            };

                                            controller.confirmedRide(bodyParams).then((value) {
                                              if (value != null) {
                                                data.statut = "confirmed";
                                                Get.back();
                                                showDialog(
                                                    context: context,
                                                    builder: (BuildContext context) {
                                                      return CustomDialogBox(
                                                        title: "Confirmed Successfully".tr,
                                                        descriptions: "Ride Successfully confirmed.".tr,
                                                        text: "Ok".tr,
                                                        onPress: () {
                                                          Get.back();
                                                          controller.getNewRide();
                                                        },
                                                        img: Image.asset('assets/images/green_checked.png'),
                                                      );
                                                    });
                                              } else {
                                                controller.getNewRide();
                                              }
                                            });
                                          },
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                          Visibility(
                            visible: data.statut == "confirmed" ? true : false,
                            child: Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 5, left: 8, right: 8),
                                child: ButtonThem.buildButton(
                                  context,
                                  title: 'On Ride'.tr,
                                  btnHeight: 45,
                                  btnWidthRatio: 1,
                                  btnColor: AppThemeData.primary200,
                                  txtColor: themeChange.getThem() ? AppThemeData.grey900 : AppThemeData.grey900Dark,
                                  onPress: () async {
                                    showDialog(
                                      barrierColor: const Color.fromARGB(66, 20, 14, 14),
                                      context: context,
                                      builder: (context) {
                                        return CustomAlertDialog(
                                          title: "Do you want to on ride this ride?".tr,
                                          negativeButtonText: 'No'.tr,
                                          positiveButtonText: 'Yes'.tr,
                                          onPressNegative: () {
                                            Get.back();
                                          },
                                          onPressPositive: () {
                                            Get.back();

                                            if (Constant.rideOtp.toString() != 'yes' || data.rideType! == 'driver') {
                                              Map<String, String> bodyParams = {
                                                'id_ride': data.id.toString(),
                                                'id_user': data.idUserApp.toString(),
                                                'use_name': '${data.prenomConducteur.toString()} ${data.nomConducteur.toString()}',
                                                'from_id': Preferences.getInt(Preferences.userId).toString(),
                                              };
                                              controller.setOnRideRequest(bodyParams).then((value) {
                                                if (value != null) {
                                                  Get.back();
                                                  showDialog(
                                                      context: context,
                                                      builder: (BuildContext context) {
                                                        return CustomDialogBox(
                                                          title: "On ride Successfully".tr,
                                                          descriptions: "Ride Successfully On ride.".tr,
                                                          text: "Ok".tr,
                                                          onPress: () {
                                                            controller.getNewRide();
                                                          },
                                                          img: Image.asset('assets/images/green_checked.png'),
                                                        );
                                                      });
                                                }
                                              });
                                            } else {
                                              controller.otpController = TextEditingController();
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
                                                      height: 200,
                                                      padding: const EdgeInsets.only(left: 10, top: 20, right: 10, bottom: 20),
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
                                                            style: TextStyle(fontSize: 16),
                                                          ),
                                                          const SizedBox(
                                                            height: 20,
                                                          ),
                                                          Pinput(
                                                            controller: controller.otpController,
                                                            defaultPinTheme: PinTheme(
                                                              height: 50,
                                                              width: 50,
                                                              textStyle: const TextStyle(
                                                                letterSpacing: 0.60,
                                                                fontSize: 16,
                                                              ),
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
                                                                  btnWidthRatio: 1,
                                                                  btnColor: AppThemeData.primary200,
                                                                  txtColor: isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900,
                                                                  onPress: () {
                                                                    if (controller.otpController.text.toString().length == 6) {
                                                                      controller
                                                                          .verifyOTP(
                                                                        userId: data.idUserApp!.toString(),
                                                                        rideId: data.id!.toString(),
                                                                      )
                                                                          .then((value) {
                                                                        if (value != null && value['success'] == "success") {
                                                                          Map<String, String> bodyParams = {
                                                                            'id_ride': data.id.toString(),
                                                                            'id_user': data.idUserApp.toString(),
                                                                            'use_name': '${data.prenomConducteur.toString()} ${data.nomConducteur.toString()}',
                                                                            'from_id': Preferences.getInt(Preferences.userId).toString(),
                                                                          };
                                                                          controller.setOnRideRequest(bodyParams).then((value) {
                                                                            if (value != null) {
                                                                              Get.back();
                                                                              showDialog(
                                                                                  context: context,
                                                                                  builder: (BuildContext context) {
                                                                                    return CustomDialogBox(
                                                                                      title: "On ride Successfully".tr,
                                                                                      descriptions: "Ride Successfully On ride.".tr,
                                                                                      text: "Ok".tr,
                                                                                      onPress: () {
                                                                                        Get.back();
                                                                                        controller.getNewRide();
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
                                                        ],
                                                      ),
                                                    ),
                                                  );
                                                },
                                              );
                                            }
                                            // if (data.carDriverConfirmed == 1) {
                                            //
                                            // } else if (data.carDriverConfirmed == 2) {
                                            //   Get.back();
                                            //   ShowToastDialog.showToast("Customer decline the confirmation of driver and car information.");
                                            // } else if (data.carDriverConfirmed == 0) {
                                            //   Get.back();
                                            //   ShowToastDialog.showToast("Customer needs to verify driver and car before you can start trip.");
                                            // }
                                          },
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                          Visibility(
                            visible: data.statut == "on ride" ? true : false,
                            child: Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 5, left: 8, right: 8),
                                child: ButtonThem.buildButton(
                                  context,
                                  title: 'START RIDE'.tr,
                                  btnHeight: 45,
                                  btnWidthRatio: 1,
                                  btnColor: AppThemeData.secondary200,
                                  txtColor: isDarkMode ? AppThemeData.grey900 : AppThemeData.grey900,
                                  onPress: () async {
                                    String googleUrl =
                                        'https://www.google.com/maps/search/?api=1&query=${double.parse(data.latitudeArrivee.toString())},${double.parse(data.longitudeArrivee.toString())}';
                                    if (await canLaunch(googleUrl)) {
                                      await launch(googleUrl);
                                    } else {
                                      throw 'Could not open the map.';
                                    }
                                  },
                                ),
                              ),
                            ),
                          ),
                          Visibility(
                            visible: data.statut == "on ride" ? true : false,
                            child: Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  bottom: 5,
                                  left: 8,
                                  right: 8,
                                ),
                                child: ButtonThem.buildButton(
                                  context,
                                  title: 'COMPLETE'.tr,
                                  btnHeight: 45,
                                  btnWidthRatio: 1,
                                  btnColor: AppThemeData.success300,
                                  txtColor: isDarkMode ? AppThemeData.surface50 : AppThemeData.surface50,
                                  onPress: () async {
                                    showDialog(
                                      barrierColor: Colors.black26,
                                      context: context,
                                      builder: (context) {
                                        return CustomAlertDialog(
                                          title: "Do you want to complete this ride?".tr,
                                          onPressNegative: () {
                                            Get.back();
                                          },
                                          negativeButtonText: 'No'.tr,
                                          positiveButtonText: 'Yes'.tr,
                                          onPressPositive: () {
                                            Map<String, String> bodyParams = {
                                              'id_ride': data.id.toString(),
                                              'id_user': data.idUserApp.toString(),
                                              'driver_name': '${data.prenomConducteur.toString()} ${data.nomConducteur.toString()}',
                                              'from_id': Preferences.getInt(Preferences.userId).toString(),
                                            };
                                            controller.setCompletedRequest(bodyParams, data).then((value) {
                                              if (value != null) {
                                                Get.back();
                                                showDialog(
                                                    context: context,
                                                    builder: (BuildContext context) {
                                                      return CustomDialogBox(
                                                        title: "Completed Successfully".tr,
                                                        descriptions: "Ride Successfully completed.".tr,
                                                        text: "Ok".tr,
                                                        onPress: () {
                                                          Get.back();
                                                          controller.getNewRide();
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
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  final resonController = TextEditingController();

  Future<dynamic> buildShowBottomSheet(BuildContext context, RideData data, NewRideController controller, bool isDarkMode) {
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
                        "Cancel Trip".tr,
                        style: const TextStyle(
                          fontSize: 18,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        "Write a reason for trip cancellation".tr,
                        style: TextStyle(
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: TextField(
                        controller: resonController,
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
                      padding: const EdgeInsets.only(top: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 5),
                              child: ButtonThem.buildButton(
                                context,
                                title: 'Cancel Trip'.tr,
                                btnHeight: 45,
                                btnWidthRatio: 0.8,
                                btnColor: AppThemeData.primary200,
                                txtColor: !isDarkMode ? AppThemeData.grey900 : AppThemeData.grey900Dark,
                                onPress: () async {
                                  if (resonController.text.isNotEmpty) {
                                    Get.back();
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
                                              'id_ride': data.id.toString(),
                                              'id_user': data.idUserApp.toString(),
                                              'name': '${data.prenomConducteur.toString()} ${data.nomConducteur.toString()}',
                                              'from_id': Preferences.getInt(Preferences.userId).toString(),
                                              'user_cat': controller.userModel.value.userData!.userCat.toString(),
                                              'reason': resonController.text.toString(),
                                            };
                                            controller.canceledRide(bodyParams).then((value) {
                                              Get.back();
                                              if (value != null) {
                                                showDialog(
                                                    context: context,
                                                    builder: (BuildContext context) {
                                                      return CustomDialogBox(
                                                        title: "Reject Successfully".tr,
                                                        descriptions: "Ride Successfully rejected.".tr,
                                                        text: "Ok".tr,
                                                        onPress: () {
                                                          Get.back();
                                                          controller.getNewRide();
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
                              padding: const EdgeInsets.only(bottom: 5, left: 10),
                              child: ButtonThem.buildBorderButton(
                                context,
                                title: 'Close'.tr,
                                btnHeight: 45,
                                btnWidthRatio: 0.8,
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

class CustomFabLocation extends FloatingActionButtonLocation {
  final double offsetY;
  const CustomFabLocation(this.offsetY);

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    final double fabX = (scaffoldGeometry.scaffoldSize.width - scaffoldGeometry.floatingActionButtonSize.width) / 2.0;
    final double fabY = scaffoldGeometry.scaffoldSize.height - scaffoldGeometry.floatingActionButtonSize.height - 16.0 - offsetY;
    return Offset(fabX, fabY);
  }
}

