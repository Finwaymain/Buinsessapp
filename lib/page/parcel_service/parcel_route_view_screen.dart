import 'dart:async';
import 'package:cabme_driver/constant/constant.dart';
import 'package:cabme_driver/constant/show_toast_dialog.dart';
import 'package:cabme_driver/controller/dash_board_controller.dart';
import 'package:cabme_driver/controller/parcel_details_controller.dart';
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
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cabme_driver/service/api.dart';

class ParcelRouteViewScreen extends StatefulWidget {
  const ParcelRouteViewScreen({super.key});

  @override
  State<ParcelRouteViewScreen> createState() => _ParcelRouteViewScreenState();
}

class _ParcelRouteViewScreenState extends State<ParcelRouteViewScreen> {
  dynamic argumentData = Get.arguments;

  GoogleMapController? _mapcontroller;

  Map<PolylineId, Polyline> polyLines = {};

  // PolylinePoints polylinePoints = PolylinePoints();
  PolylinePoints polylinePoints = PolylinePoints(apiKey: Constant.kGoogleApiKey.toString());


  BitmapDescriptor? departureIcon;
  BitmapDescriptor? destinationIcon;
  BitmapDescriptor? taxiIcon;
  BitmapDescriptor? stopIcon;

  late LatLng departureLatLong;
  late LatLng destinationLatLong;

  final Map<String, Marker> _markers = {};

  String? type;
  ParcelData? parcelData;
  double rotation = 0.0;
  String driverEstimateArrivalTime = '';
  Timer? _driverLocationTimer;

  @override
  void initState() {
    getArgumentData();
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

            try {
              Dio dio = Dio();
              dynamic distRes = await dio.get(
                  "https://maps.googleapis.com/maps/api/distancematrix/json?units=imperial&origins=${parcelData!.latSource},${parcelData!.lngSource}&destinations=$dLat,$dLng&key=${Constant.kGoogleApiKey}");
              driverEstimateArrivalTime = distRes.data['rows'][0]['elements'][0]['duration']['text'].toString();
            } catch (distErr) {
              print("Distance matrix calculation error: $distErr");
            }

            if (mounted) {
              setState(() {
                departureLatLong = LatLng(dLat, dLng);
                _markers[parcelData!.id.toString()] = Marker(
                    markerId: MarkerId(parcelData!.id.toString()),
                    infoWindow: InfoWindow(title: parcelData!.prenomConducteur.toString()),
                    position: departureLatLong,
                    icon: taxiIcon!,
                    rotation: 0.0);
                getDirections(dLat: dLat, dLng: dLng);
              });
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

      departureLatLong = LatLng(double.parse(parcelData!.latSource.toString()), double.parse(parcelData!.lngSource.toString()));
      destinationLatLong = LatLng(double.parse(parcelData!.latDestination.toString()), double.parse(parcelData!.lngDestination.toString()));
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
    BitmapDescriptor.fromAssetImage(const ImageConfiguration(size: Size(10, 10)), "assets/icons/pickup.png").then((value) {
      departureIcon = value;
    });

    BitmapDescriptor.fromAssetImage(const ImageConfiguration(size: Size(10, 10)), "assets/icons/dropoff.png").then((value) {
      destinationIcon = value;
    });

    BitmapDescriptor.fromAssetImage(const ImageConfiguration(size: Size(10, 10)), "assets/images/ic_taxi.png").then((value) {
      taxiIcon = value;
    });
    BitmapDescriptor.fromAssetImage(const ImageConfiguration(size: Size(10, 10)), "assets/icons/location.png").then((value) {
      stopIcon = value;
    });
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
          GoogleMap(
            zoomControlsEnabled: true,
            myLocationButtonEnabled: false,
            initialCameraPosition: CameraPosition(
              target: LatLng(double.parse(parcelData!.latSource!), double.parse(parcelData!.lngSource!)),
              zoom: 14.0,
            ),
            onMapCreated: (GoogleMapController controller) {
              _mapcontroller = controller;
              _mapcontroller!.moveCamera(CameraUpdate.newLatLngZoom(departureLatLong, 12));
            },
            polylines: Set<Polyline>.of(polyLines.values),
            myLocationEnabled: false,
            markers: _markers.values.toSet(),
          ),
          Positioned(
            top: 10,
            left: 10,
            right: 5,
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
                    margin: const EdgeInsets.only(left: 4, right: 4, top: 16),
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
                                  borderRadius: BorderRadius.circular(80),
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
                                buildShowBottomSheet(context);
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
                                                                        'otp': controllerParcelDetails.otpController.text.toString(),
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
                                  _mapcontroller?.animateCamera(
                                    CameraUpdate.newCameraPosition(
                                      CameraPosition(
                                        target: LatLng(
                                          double.parse(parcelData!.latDestination.toString()),
                                          double.parse(parcelData!.lngDestination.toString()),
                                        ),
                                        zoom: 16.0,
                                      ),
                                    ),
                                  );
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

  Future<dynamic> buildShowBottomSheet(BuildContext context) {
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
                        style: const TextStyle(fontSize: 18, color: Colors.black),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        "Write a reason for trip cancellation".tr,
                        style: TextStyle(color: Colors.black.withValues(alpha: 0.50)),
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
                                txtColor: Colors.white,
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
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 5, left: 10),
                              child: ButtonThem.buildBorderButton(
                                context,
                                title: 'Close'.tr,
                                btnHeight: 45,
                                btnWidthRatio: 0.8,
                                btnColor: Colors.white,
                                txtColor: AppThemeData.primary200,
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
    List<LatLng> polylineCoordinates = [];
    PolylineResult result;

    if (parcelData!.status.toString() == "confirmed") {
      PolylineRequest resultdata = PolylineRequest(
        origin: PointLatLng(dLat, dLng),
        destination: PointLatLng(
          double.parse(parcelData!.latSource.toString()),
          double.parse(parcelData!.lngSource.toString()),
        ),
        mode: TravelMode.driving,
        optimizeWaypoints: true,
      );

      result = await polylinePoints.getRouteBetweenCoordinates(request: resultdata);
    } else if (parcelData!.status == "on ride") {
      PolylineRequest resultdata = PolylineRequest(
        origin: PointLatLng(dLat, dLng),
        destination: PointLatLng(destinationLatLong.latitude, destinationLatLong.longitude),
        mode: TravelMode.driving,
        optimizeWaypoints: true,
      );

      result = await polylinePoints.getRouteBetweenCoordinates(request: resultdata);
    } else {
      PolylineRequest resultdata = PolylineRequest(
        origin: PointLatLng(departureLatLong.latitude, departureLatLong.longitude),
        destination: PointLatLng(destinationLatLong.latitude, destinationLatLong.longitude),
        mode: TravelMode.driving,
        optimizeWaypoints: true,
      );

      result = await polylinePoints.getRouteBetweenCoordinates(request: resultdata);
    }

    _markers['Departure'] = Marker(
      markerId: const MarkerId('Departure'),
      infoWindow: const InfoWindow(title: "Departure"),
      position: LatLng(
        double.parse(parcelData!.latSource.toString()),
        double.parse(parcelData!.lngSource.toString()),
      ),
      icon: departureIcon!,
    );

    _markers['Destination'] = Marker(
      markerId: const MarkerId('Destination'),
      infoWindow: const InfoWindow(title: "Destination"),
      position: destinationLatLong,
      icon: destinationIcon!,
    );

    if (result.points.isNotEmpty) {
      for (var point in result.points) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      }
    }

    addPolyLine(polylineCoordinates);
  }

  // getDirections({required double dLat, required double dLng}) async {
  //   List<LatLng> polylineCoordinates = [];
  //   PolylineResult result;
  //
  //   if (parcelData!.status.toString() == "confirmed") {
  //     PolylineRequest resultdata = PolylineRequest(
  //       origin: PointLatLng(dLat, dLng),
  //       destination: PointLatLng(double.parse(parcelData!.latSource.toString()), double.parse(parcelData!.lngSource.toString())),
  //       mode: TravelMode.driving,
  //       optimizeWaypoints: true,
  //     );
  //     result = await polylinePoints.getRouteBetweenCoordinates(
  //       googleApiKey: Constant.kGoogleApiKey.toString(),
  //       request: resultdata,
  //     );
  //   } else if (parcelData!.status == "on ride") {
  //     PolylineRequest resultdata = PolylineRequest(
  //       origin: PointLatLng(dLat, dLng),
  //       destination: PointLatLng(destinationLatLong.latitude, destinationLatLong.longitude),
  //       mode: TravelMode.driving,
  //       optimizeWaypoints: true,
  //     );
  //     result = await polylinePoints.getRouteBetweenCoordinates(
  //       googleApiKey: Constant.kGoogleApiKey.toString(),
  //       request: resultdata,
  //     );
  //   } else {
  //     PolylineRequest resultdata = PolylineRequest(
  //       origin: PointLatLng(departureLatLong.latitude, departureLatLong.longitude),
  //       destination: PointLatLng(destinationLatLong.latitude, destinationLatLong.longitude),
  //       mode: TravelMode.driving,
  //       optimizeWaypoints: true,
  //     );
  //     result = await polylinePoints.getRouteBetweenCoordinates(
  //       googleApiKey: Constant.kGoogleApiKey.toString(),
  //       request: resultdata,
  //     );
  //   }
  //
  //   _markers['Departure'] = Marker(
  //     markerId: const MarkerId('Departure'),
  //     infoWindow: const InfoWindow(title: "Departure"),
  //     position: LatLng(double.parse(parcelData!.latSource.toString()), double.parse(parcelData!.lngSource.toString())),
  //     icon: departureIcon!,
  //   );
  //
  //   _markers['Destination'] = Marker(
  //     markerId: const MarkerId('Destination'),
  //     infoWindow: const InfoWindow(title: "Destination"),
  //     position: destinationLatLong,
  //     icon: destinationIcon!,
  //   );
  //
  //   if (result.points.isNotEmpty) {
  //     for (var point in result.points) {
  //       polylineCoordinates.add(LatLng(point.latitude, point.longitude));
  //     }
  //   }
  //
  //   addPolyLine(polylineCoordinates);
  // }

  void addPolyLine(List<LatLng> polylineCoordinates) {
    PolylineId id = const PolylineId("poly");
    Polyline polyline = Polyline(
      polylineId: id,
      color: AppThemeData.primary200,
      points: polylineCoordinates,
      width: 6,
      geodesic: true,
    );
    polyLines[id] = polyline;
    updateCameraLocation(polylineCoordinates.first, _mapcontroller);

    setState(() {});
  }

  Future<void> updateCameraLocation(
    LatLng source,
    GoogleMapController? mapController,
  ) async {
    mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: source,
          zoom: parcelData!.status == "on ride" || parcelData!.status == "confirmed" ? 20 : 16,
        ),
      ),
    );
  }
}
