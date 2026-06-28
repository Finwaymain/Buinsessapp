import 'dart:io';
import 'dart:math';
import 'dart:async';

import 'package:cabme_driver/constant/constant.dart';
import 'package:cabme_driver/constant/show_toast_dialog.dart';
import 'package:cabme_driver/controller/dash_board_controller.dart';
import 'package:cabme_driver/controller/parcel_details_controller.dart';
import 'package:cabme_driver/model/driver_location_update.dart';
import 'package:cabme_driver/model/parcel_model.dart';
import 'package:cabme_driver/model/parcel_details_model.dart';
import 'package:cabme_driver/themes/button_them.dart';
import 'package:cabme_driver/themes/constant_colors.dart';
import 'package:cabme_driver/themes/custom_alert_dialog.dart';
import 'package:cabme_driver/themes/custom_dialog_box.dart';
import 'package:cabme_driver/utils/Preferences.dart';
import 'package:cabme_driver/utils/dark_theme_provider.dart';
import 'package:cabme_driver/widget/StarRating.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cabme_driver/service/api.dart';

class ParcelOsmRouteViewScreen extends StatefulWidget {
  const ParcelOsmRouteViewScreen({super.key});

  @override
  State<ParcelOsmRouteViewScreen> createState() => _ParcelOsmRouteViewScreenState();
}

class _ParcelOsmRouteViewScreenState extends State<ParcelOsmRouteViewScreen> {
  dynamic argumentData = Get.arguments;

  late MapController mapController;

  Map<String, GeoPoint> markers = <String, GeoPoint>{};

  Widget? departureIcon;
  Widget? destinationIcon;
  Widget? taxiIcon;
  Widget? stopIcon;

  GeoPoint? departureLatLong;
  GeoPoint? destinationLatLong;

  RoadInfo roadInfo = RoadInfo();

  String? type;
  ParcelData? parcelData;
  double rotation = 0.0;
  String driverEstimateArrivalTime = '';
  Timer? _driverLocationTimer;

  @override
  void initState() {
    if (argumentData != null) {
      type = argumentData['type'];
      parcelData = argumentData['data'];
    }
    ShowToastDialog.showLoader("Please wait".tr);
    mapController = MapController(initPosition: GeoPoint(latitude: double.parse(parcelData!.latSource!), longitude: double.parse(parcelData!.lngSource!)));
    setIcons();

    super.initState();
  }

  @override
  void dispose() {
    _driverLocationTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchDriverLocation() async {
    try {
      final response = await Dio().get(
        "${API.getParcelDetails}?parcel_id=${parcelData!.id}",
        options: Options(headers: API.header),
      );
      if (response.statusCode == 200) {
        ParcelDetailsModel parcelDetails = ParcelDetailsModel.fromJson(response.data);
        if (parcelDetails.success == 'success' && parcelDetails.rideDetailsdata != null) {
          var data = parcelDetails.rideDetailsdata!;
          if (data.driverLatitude != null && data.driverLatitude!.isNotEmpty &&
              data.driverLongitude != null && data.driverLongitude!.isNotEmpty) {
            double dLat = double.parse(data.driverLatitude!);
            double dLng = double.parse(data.driverLongitude!);

            departureLatLong = GeoPoint(latitude: dLat, longitude: dLng);

            getDirections(dLat: dLat, dLng: dLng);
            if (mounted) {
              setState(() {});
            }
          }
        }
      }
    } catch (e) {
      print("Error fetching driver location: $e");
    }
  }

  Future<void> getArgumentData() async {
    if (argumentData != null) {
      type = argumentData['type'];
      parcelData = argumentData['data'];

      departureLatLong = GeoPoint(latitude: double.parse(parcelData!.latSource.toString()), longitude: double.parse(parcelData!.lngSource.toString()));
      destinationLatLong = GeoPoint(latitude: double.parse(parcelData!.latDestination.toString()), longitude: double.parse(parcelData!.lngDestination.toString()));
      // await getDriver();

      if (parcelData!.status == "onride" || parcelData!.status == 'confirmed') {
        _fetchDriverLocation();
        _driverLocationTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
          _fetchDriverLocation();
        });
      } else {
        getDirections(dLat: 0.0, dLng: 0.0);
      }
    }
  }

  Future<void> setIcons() async {
    departureIcon = Image.asset("assets/icons/pickup.png", width: 30, height: 30);
    destinationIcon = Image.asset("assets/icons/dropoff.png", width: 30, height: 30);
    taxiIcon = Image.asset("assets/images/ic_taxi.png", width: Platform.isIOS ? 30 : 40, height: Platform.isIOS ? 30 : 80, fit: BoxFit.cover);
    stopIcon = Image.asset("assets/icons/location.png", width: 30, height: 30);
  }

  final controllerParcelDetails = Get.put(ParcelDetailsController());
  final controllerDashBoard = Get.put(DashBoardController());

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return Scaffold(
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          OSMFlutter(
              controller: mapController,
              osmOption: OSMOption(
                userLocationMarker: UserLocationMaker(
                  directionArrowMarker: MarkerIcon(
                    iconWidget: taxiIcon,
                  ),
                  personMarker: MarkerIcon(
                    iconWidget: taxiIcon,
                  ),
                ),
                userTrackingOption: const UserTrackingOption(
                  enableTracking: true,
                  unFollowUser: false,
                ),
                zoomOption: const ZoomOption(
                  initZoom: 14,
                  minZoomLevel: 2,
                  maxZoomLevel: 19,
                  stepZoom: 1.0,
                ),
                roadConfiguration: RoadOption(
                  roadWidth: Platform.isIOS ? 50 : 10,
                  roadColor: Colors.blue,
                  roadBorderWidth: Platform.isIOS ? 15 : 10, // Set the road border width (outline)
                  roadBorderColor: Colors.black, // Border color
                  zoomInto: true,
                ),
              ),
              onMapIsReady: (active) async {
                if (active) {
                  getArgumentData();
                  ShowToastDialog.closeLoader();
                }
              }),
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Row(
              children: [
                SafeArea(
                  child: InkWell(
                    onTap: () {
                      Get.back();
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(4.0),
                      child: Icon(Icons.arrow_back_ios_outlined, color: Colors.black),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 10,
                  ),
                  child: Container(
                    margin: const EdgeInsets.only(left: 16, right: 16, top: 16),
                    decoration: BoxDecoration(
                      color: themeChange.getThem() ? AppThemeData.surface50Dark : AppThemeData.surface50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(50),
                                  child: CachedNetworkImage(
                                    imageUrl: parcelData!.userPhoto.toString(),
                                    height: 60,
                                    width: 60,
                                    fit: BoxFit.cover,
                                    errorWidget: (context, url, error) => Image.asset(
                                      "assets/images/appIcon.png",
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 8.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(parcelData!.userName.toString(),
                                            style: TextStyle(
                                              fontFamily: AppThemeData.semiBold,
                                              color: themeChange.getThem() ? AppThemeData.grey900Dark : AppThemeData.grey900,
                                              fontSize: 16,
                                            )),
                                        StarRating(
                                            size: 18,
                                            rating: parcelData!.moyenneDriver != null ? double.parse(parcelData!.moyenneDriver.toString()) : 0.0,
                                            color: AppThemeData.primary200),
                                      ],
                                    ),
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(left: 10),
                                      child: InkWell(
                                        onTap: () {
                                          Constant.makePhoneCall(parcelData!.userPhone.toString());
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                          decoration: BoxDecoration(
                                            color: AppThemeData.primary200,
                                            borderRadius: BorderRadius.circular(40),
                                          ),
                                          child: SvgPicture.asset(
                                            'assets/icons/call_icon.svg',
                                            height: 20,
                                            width: 20,
                                            colorFilter: ColorFilter.mode(
                                              themeChange.getThem() ? AppThemeData.surface50Dark : AppThemeData.surface50,
                                              BlendMode.srcIn,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(top: 5.0),
                                      child: Text(parcelData!.parcelDate.toString(),
                                          style: TextStyle(
                                            fontFamily: AppThemeData.medium,
                                            color: themeChange.getThem() ? AppThemeData.grey900Dark : AppThemeData.grey900,
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
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    children: [
                      Visibility(
                        visible: parcelData!.status.toString() == "confirmed" ? true : false,
                        child: Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 5),
                            child: ButtonThem.buildBorderButton(
                              context,
                              title: 'REJECT'.tr,
                              btnHeight: 45,
                              btnWidthRatio: 0.8,
                              btnColor: Colors.white,
                              txtColor: Colors.black.withValues(alpha: 0.60),
                              btnBorderColor: Colors.black.withValues(alpha: 0.20),
                              onPress: () async {
                                buildShowBottomSheet(context, themeChange.getThem());
                              },
                            ),
                          ),
                        ),
                      ),
                      Visibility(
                        visible: parcelData!.status == "confirmed" ? true : false,
                        child: Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 5, left: 10),
                            child: ButtonThem.buildButton(
                              context,
                              title: 'On Ride'.tr,
                              btnHeight: 45,
                              btnWidthRatio: 0.8,
                              btnColor: AppThemeData.primary200,
                              txtColor: Colors.black,
                              onPress: () async {
                                showDialog(
                                  barrierColor: Colors.black26,
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
                                        Get.back();
                                        if (Constant.rideOtp.toString() != 'yes') {
                                          Map<String, String> bodyParams = {
                                            'id_parcel': parcelData!.id.toString(),
                                            'id_user': parcelData!.idUserApp.toString(),
                                            'driver_name': '${parcelData!.driverName}',
                                            'driver_id': Preferences.getInt(Preferences.userId).toString(),
                                          };
                                          controllerParcelDetails.onRideParcel(bodyParams).then((value) {
                                            if (value != null) {
                                              Get.back();
                                              showDialog(
                                                  context: context,
                                                  builder: (BuildContext context) {
                                                    return CustomDialogBox(
                                                      title: "On ride Successfully".tr,
                                                      descriptions: "Parcel Successfully On ride.".tr,
                                                      text: "Ok".tr,
                                                      onPress: () {
                                                        Get.back();
                                                        Get.back();
                                                      },
                                                      img: Image.asset('assets/images/green_checked.png'),
                                                    );
                                                  });
                                            }
                                          });
                                        } else {
                                          controllerParcelDetails.otpController = TextEditingController();
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
                                                  decoration:
                                                      BoxDecoration(shape: BoxShape.rectangle, color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: const [
                                                    BoxShadow(color: Colors.black, offset: Offset(0, 10), blurRadius: 10),
                                                  ]),
                                                  child: Column(
                                                    children: [
                                                      Text(
                                                        "Enter OTP".tr,
                                                        style: TextStyle(color: Colors.black.withValues(alpha: 0.60)),
                                                      ),
                                                      Pinput(
                                                        controller: controllerParcelDetails.otpController,
                                                        defaultPinTheme: PinTheme(
                                                          height: 50,
                                                          width: 50,
                                                          textStyle: const TextStyle(letterSpacing: 0.60, fontSize: 16, color: Colors.black, fontWeight: FontWeight.w600),
                                                          // margin: EdgeInsets.all(10),
                                                          decoration: BoxDecoration(
                                                            borderRadius: BorderRadius.circular(10),
                                                            shape: BoxShape.rectangle,
                                                            color: Colors.white,
                                                            border: Border.all(color: ConstantColors.textFieldBoarderColor, width: 0.7),
                                                          ),
                                                        ),
                                                        keyboardType: TextInputType.phone,
                                                        textInputAction: TextInputAction.done,
                                                        length: 6,
                                                      ),
                                                      // ignore: prefer_const_constructors
                                                      SizedBox(
                                                        height: 8,
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
                                                              txtColor: Colors.white,
                                                              onPress: () {
                                                                if (controllerParcelDetails.otpController.text.toString().length == 6) {
                                                                  controllerParcelDetails
                                                                      .verifyOTP(
                                                                    userId: parcelData!.idUserApp!.toString(),
                                                                    rideId: parcelData!.id!.toString(),
                                                                  )
                                                                      .then((value) {
                                                                    if (value != null && value['success'] == "success") {
                                                                      Map<String, String> bodyParams = {
                                                                        'id_parcel': parcelData!.id.toString(),
                                                                        'id_user': parcelData!.idUserApp.toString(),
                                                                        'driver_name': '${parcelData!.driverName}',
                                                                        'driver_id': Preferences.getInt(Preferences.userId).toString(),
                                                                      };
                                                                      controllerParcelDetails.onRideParcel(bodyParams).then((value) {
                                                                        if (value != null) {
                                                                          Get.back();
                                                                          showDialog(
                                                                              context: context,
                                                                              builder: (BuildContext context) {
                                                                                return CustomDialogBox(
                                                                                  title: "On ride Successfully".tr,
                                                                                  descriptions: "Parcel Successfully On ride.".tr,
                                                                                  text: "Ok".tr,
                                                                                  onPress: () {
                                                                                    Get.back();
                                                                                    Get.back();
                                                                                  },
                                                                                  img: Image.asset('assets/images/green_checked.png'),
                                                                                );
                                                                              });
                                                                        }
                                                                      });
                                                                    }
                                                                  });
                                                                } else {
                                                                  ShowToastDialog.showToast('Please Enter OTP'.tr);
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
                                                              btnWidthRatio: 0.8,
                                                              btnColor: Colors.white,
                                                              txtColor: Colors.black.withValues(alpha: 0.60),
                                                              btnBorderColor: Colors.black.withValues(alpha: 0.20),
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
                                        // if (parcelData!.carDriverConfirmed == 1) {
                                        //
                                        // } else if (parcelData!.carDriverConfirmed == 2) {
                                        //   Get.back();
                                        //   ShowToastDialog.showToast("Customer decline the confirmation of driver and car information.");
                                        // } else if (parcelData!.carDriverConfirmed == 0) {
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
                        visible: parcelData!.status == "on ride" ? true : false,
                        child: Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 5),
                            child: ButtonThem.buildBorderButton(
                              context,
                              title: 'START RIDE'.tr,
                              btnHeight: 45,
                              btnWidthRatio: 0.8,
                              btnColor: Colors.white,
                              txtColor: Colors.black.withValues(alpha: 0.60),
                              btnBorderColor: Colors.black.withValues(alpha: 0.20),
                              onPress: () async {
                                if (Constant.liveTrackingMapType == "inappmap") {
                                  if (destinationLatLong != null) {
                                    await mapController.moveTo(
                                      destinationLatLong!,
                                      animate: true,
                                    );
                                  }
                                  ShowToastDialog.showToast('Navigating to destination');
                                } else {
                                  String googleUrl =
                                      'https://www.google.com/maps/search/?api=1&query=${double.parse(parcelData!.latDestination.toString())},${double.parse(parcelData!.lngDestination.toString())}';
                                  if (await canLaunch(googleUrl)) {
                                    await launch(googleUrl);
                                  } else {
                                    throw 'Could not open the map.';
                                  }
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                      Visibility(
                        visible: parcelData!.status == "on ride" ? true : false,
                        child: Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 5, left: 10),
                            child: ButtonThem.buildButton(
                              context,
                              title: 'COMPLETE'.tr,
                              btnHeight: 45,
                              btnWidthRatio: 0.8,
                              btnColor: AppThemeData.primary200,
                              txtColor: Colors.black,
                              onPress: () async {
                                showDialog(
                                  barrierColor: Colors.black26,
                                  context: context,
                                  builder: (context) {
                                    return CustomAlertDialog(
                                      title: "Do you want to complete this parcel?".tr,
                                      onPressNegative: () {
                                        Get.back();
                                      },
                                      negativeButtonText: 'No'.tr,
                                      positiveButtonText: 'Yes'.tr,
                                      onPressPositive: () {
                                        Map<String, String> bodyParams = {
                                          'id_pracel': parcelData!.id.toString(),
                                          'id_user': parcelData!.idUserApp.toString(),
                                          'driver_name': '${parcelData!.prenomConducteur.toString()} ${parcelData!.nomConducteur.toString()}',
                                          'from_id': Preferences.getInt(Preferences.userId).toString(),
                                        };
                                        controllerParcelDetails.setCompletedRequest(bodyParams, parcelData!).then((value) {
                                          if (value != null) {
                                            Get.back();
                                            showDialog(
                                                context: context,
                                                builder: (BuildContext context) {
                                                  return CustomDialogBox(
                                                    title: "Completed Successfully".tr,
                                                    descriptions: "Parcel Successfully completed.".tr,
                                                    text: "Ok".tr,
                                                    onPress: () {
                                                      Get.back();
                                                      Get.back();
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
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  final resonController = TextEditingController();

  Future<dynamic> buildShowBottomSheet(BuildContext context, bool isDarkMode) {
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
                                              'id_parcel': parcelData!.id.toString(),
                                              'id_user': parcelData!.idUserApp.toString(),
                                              'name': parcelData!.driverName.toString(),
                                              'from_id': Preferences.getInt(Preferences.userId).toString(),
                                              'user_cat': controllerParcelDetails.userModel!.userData!.userCat.toString(),
                                              'reason': resonController.text.toString(),
                                            };
                                            controllerParcelDetails.canceledParcel(bodyParams).then((value) {
                                              Get.back();
                                              if (value != null) {
                                                showDialog(
                                                    context: context,
                                                    builder: (BuildContext context) {
                                                      return CustomDialogBox(
                                                        title: "Reject Successfully".tr,
                                                        descriptions: "Parcel Successfully rejected.".tr,
                                                        text: "Ok".tr,
                                                        onPress: () {
                                                          Get.back();
                                                          Get.back();
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

  Future<void> getDirections({required double dLat, required double dLng}) async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (markers.containsKey('Departure')) {
        await mapController.removeMarker(markers['Departure']!);
      }
      await mapController
          .addMarker(
              GeoPoint(
                latitude: double.parse(parcelData!.latSource.toString()),
                longitude: double.parse(parcelData!.lngSource.toString()),
              ),
              markerIcon: MarkerIcon(iconWidget: departureIcon),
              angle: pi / 3,
              iconAnchor: IconAnchor(
                anchor: Anchor.top,
              ))
          .then((v) {
        markers['Departure'] = GeoPoint(
          latitude: double.parse(parcelData!.latSource.toString()),
          longitude: double.parse(parcelData!.lngSource.toString()),
        );
      });

      if (markers.containsKey('Destination')) {
        await mapController.removeMarker(markers['Destination']!);
      }
      await mapController
          .addMarker(destinationLatLong!,
              markerIcon: MarkerIcon(iconWidget: destinationIcon),
              angle: pi / 3,
              iconAnchor: IconAnchor(
                anchor: Anchor.top,
              ))
          .then((v) {
        markers['Destination'] = destinationLatLong!;
      });

      if (parcelData!.status.toString() == "confirmed") {
        drawRoad(
          startPoint: GeoPoint(latitude: dLat, longitude: dLng),
          lastPoint: GeoPoint(
            latitude: double.parse(parcelData!.latSource.toString()),
            longitude: double.parse(parcelData!.lngSource.toString()),
          ),
        );
      } else if (parcelData!.status == "on ride") {
        drawRoad(
          startPoint: GeoPoint(latitude: dLat, longitude: dLng),
          lastPoint: GeoPoint(
            latitude: destinationLatLong!.latitude,
            longitude: destinationLatLong!.longitude,
          ),
        );
      } else {
        drawRoad(
          startPoint: GeoPoint(
            latitude: departureLatLong!.latitude,
            longitude: departureLatLong!.longitude,
          ),
          lastPoint: GeoPoint(
            latitude: destinationLatLong!.latitude,
            longitude: destinationLatLong!.longitude,
          ),
        );
      }
    });
  }

  Future<void> drawRoad({required GeoPoint startPoint, required GeoPoint lastPoint}) async {
    await mapController.removeLastRoad();
    roadInfo = await mapController.drawRoad(
      startPoint,
      lastPoint,
      roadType: RoadType.car,
      roadOption: RoadOption(
        roadWidth: Platform.isIOS ? 50 : 10,
        roadColor: Colors.blue,
        roadBorderWidth: Platform.isIOS ? 15 : 10, // Set the road border width (outline)
        roadBorderColor: Colors.black, // Border color
        zoomInto: true,
      ),
    );

    int hours = (roadInfo.duration! ~/ 3600);
    int minutes = ((roadInfo.duration! % 3600) / 60).round();
    setState(() {
      driverEstimateArrivalTime = '$hours hours $minutes minutes';
    });
  }

  // Future<void> updateCameraLocation(
  //   LatLng source,
  //   GoogleMapController? mapController,
  // ) async {
  //   mapController!.animateCamera(
  //     CameraUpdate.newCameraPosition(
  //       CameraPosition(
  //         target: source,
  //         zoom: parcelData!.status == "on ride" || parcelData!.status == "confirmed" ? 20 : 16,
  //       ),
  //     ),
  //   );
  // }
}
