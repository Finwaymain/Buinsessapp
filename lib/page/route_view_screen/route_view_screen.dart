import 'dart:async';
import 'package:cabme_driver/constant/constant.dart';
import 'package:cabme_driver/constant/show_toast_dialog.dart';
import 'package:cabme_driver/controller/dash_board_controller.dart';
import 'package:cabme_driver/controller/ride_details_controller.dart';
import 'package:cabme_driver/model/ride_model.dart';
import 'package:cabme_driver/model/ride_details_model.dart';
import 'package:cabme_driver/page/chats_screen/conversation_screen.dart';
import 'package:cabme_driver/themes/button_them.dart';
import 'package:cabme_driver/themes/constant_colors.dart';
import 'package:cabme_driver/themes/custom_alert_dialog.dart';
import 'package:cabme_driver/themes/custom_dialog_box.dart';
import 'package:cabme_driver/utils/Preferences.dart';
import 'package:cabme_driver/utils/dark_theme_provider.dart';
import 'package:cabme_driver/widget/StarRating.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cabme_driver/page/new_ride_screens/payment_collection_screen.dart';
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

class RouteViewScreen extends StatefulWidget {
  const RouteViewScreen({super.key});

  @override
  State<RouteViewScreen> createState() => _RouteViewScreenState();
}

class _RouteViewScreenState extends State<RouteViewScreen> {
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
  RideData? rideData;
  double rotation = 0.0;
  String driverEstimateArrivalTime = '';
  Timer? _driverLocationTimer;

  @override
  void initState() {
    super.initState();
    setIcons().then((_) {
      getArgumentData();
    });
  }

  @override
  void dispose() {
    _driverLocationTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchDriverLocation() async {
    try {
      final response = await Dio().get(
        "${API.rideDetails}?ride_id=${rideData!.id}",
        options: Options(headers: API.header),
      );
      if (response.statusCode == 200) {
        RideDetailsModel rideDetails = RideDetailsModel.fromJson(response.data);
        if (rideDetails.success == 'success' && rideDetails.rideDetailsdata != null) {
          var data = rideDetails.rideDetailsdata!;
          if (mounted) {
            setState(() {
              rideData!.statut = data.statut;
            });
            if (data.statut != 'confirmed' && data.statut != 'on ride') {
              _driverLocationTimer?.cancel();
              ShowToastDialog.showToast("Ride is ${data.statut}");
              Get.back();
              return;
            }
          }
          if (data.driverLatitude != null && data.driverLatitude!.isNotEmpty &&
              data.driverLongitude != null && data.driverLongitude!.isNotEmpty) {
            double dLat = double.parse(data.driverLatitude!);
            double dLng = double.parse(data.driverLongitude!);

            try {
              Dio dio = Dio();
              dynamic distRes = await dio.get(
                  "https://maps.googleapis.com/maps/api/distancematrix/json?units=imperial&origins=${rideData!.latitudeDepart},${rideData!.longitudeDepart}&destinations=$dLat,$dLng&key=${Constant.kGoogleApiKey}");
              driverEstimateArrivalTime = distRes.data['rows'][0]['elements'][0]['duration']['text'].toString();
            } catch (distErr) {
              print("Distance matrix calculation error: $distErr");
            }

            if (mounted) {
              setState(() {
                departureLatLong = LatLng(dLat, dLng);
                if (taxiIcon != null) {
                  _markers[rideData!.id.toString()] = Marker(
                      markerId: MarkerId(rideData!.id.toString()),
                      infoWindow: InfoWindow(title: rideData!.prenomConducteur.toString()),
                      position: departureLatLong,
                      icon: taxiIcon!,
                      rotation: 0.0);
                }
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
      rideData = argumentData['data'];

      departureLatLong = LatLng(double.parse(rideData!.latitudeDepart.toString()), double.parse(rideData!.longitudeDepart.toString()));
      destinationLatLong = LatLng(double.parse(rideData!.latitudeArrivee.toString()), double.parse(rideData!.longitudeArrivee.toString()));

      if (rideData!.statut == "on ride" || rideData!.statut == 'confirmed') {
        _fetchDriverLocation();
        _driverLocationTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
          _fetchDriverLocation();
        });
      } else {
        getDirections(dLat: departureLatLong.latitude, dLng: departureLatLong.longitude);
      }
    }
  }

  Future<void> setIcons() async {
    try {
      departureIcon = await BitmapDescriptor.fromAssetImage(const ImageConfiguration(size: Size(24, 24)), "assets/icons/pickup.png");
    } catch (_) {}
    try {
      destinationIcon = await BitmapDescriptor.fromAssetImage(const ImageConfiguration(size: Size(24, 24)), "assets/icons/location.png");
    } catch (_) {}
    try {
      taxiIcon = await BitmapDescriptor.fromAssetImage(const ImageConfiguration(size: Size(24, 24)), "assets/images/ic_taxi.png");
    } catch (_) {}
    try {
      stopIcon = await BitmapDescriptor.fromAssetImage(const ImageConfiguration(size: Size(24, 24)), "assets/icons/location.png");
    } catch (_) {}
  }


  // getDriver() async {
  //   String orderId = (rideData!.idUserApp! < rideData!.idConducteur!)
  //       ? '${rideData!.idUserApp}-${rideData!.id}-${rideData!.idConducteur}'
  //       : '${rideData!.idConducteur}-${rideData!.id}-${rideData!.idUserApp}';
  //   Constant.location_update.doc(orderId).get().then((value) {
  //     dynamic driverData = value.data();

  //     driverLatLong = LatLng(
  //         double.parse(driverData['driver_latitude'].toString()),
  //         double.parse(driverData['driver_longitude'].toString()));

  //     rotation = driverData['rotation'];
  //     print('\x1b[92m --------> ${value.data()}');
  //   });
  //   // driverStream.listen((event) {
  //   //   print("--->${event.location.latitude} ${event.location.longitude}");
  //   //   setState(() => _driverModel = event);
  //   //   setState(() => MyAppState.currentUser = _driverModel);

  //   //   getDirections();
  //   //   if (_driverModel!.isActive) {
  //   //     if (_driverModel!.orderRequestData != null) {
  //   //       showDriverBottomSheet(_driverModel!);
  //   //       startTimer(_driverModel!);
  //   //     }
  //   //   }
  //   //   if (_driverModel!.inProgressOrderID != null) {
  //   //     getCurrentOrder();
  //   //   }
  //   // });
  // }

  final controllerRideDetails = Get.put(RideDetailsController());
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
              target: LatLng(double.parse(rideData!.latitudeDepart!), double.parse(rideData!.longitudeDepart!)),
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
            left: 5,
            right: 5,
            child: Row(
              children: [
                SafeArea(
                  child: InkWell(
                    onTap: () {
                      Get.back();
                    },
                    child: const Padding(
                      padding: EdgeInsets.only(left: 8, top: 3, right: 8),
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
                    decoration: BoxDecoration(
                      color: themeChange.getThem() ? AppThemeData.surface50Dark : AppThemeData.surface50,
                      borderRadius: const BorderRadius.all(Radius.circular(8)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12),
                      child: Column(
                        children: [
                          if (rideData!.statut == 'confirmed')
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        const Icon(Icons.navigation, color: Colors.blue, size: 18),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            'Reach Customer: '.tr + (driverEstimateArrivalTime.isNotEmpty ? driverEstimateArrivalTime : 'Calculating...'),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(color: AppThemeData.primary200, fontWeight: FontWeight.bold, fontSize: 14),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () async {
                                      final pLat = double.parse(rideData!.latitudeDepart.toString());
                                      final pLng = double.parse(rideData!.longitudeDepart.toString());
                                      final url = Uri.parse("https://www.google.com/maps/dir/?api=1&destination=$pLat,$pLng&travelmode=driving");
                                      if (await canLaunchUrl(url)) {
                                        await launchUrl(url, mode: LaunchMode.externalApplication);
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AppThemeData.primary200.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: AppThemeData.primary200.withValues(alpha: 0.3)),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.directions, color: AppThemeData.primary200, size: 16),
                                          const SizedBox(width: 4),
                                          Text("Navigate".tr, style: TextStyle(color: AppThemeData.primary200, fontWeight: FontWeight.bold, fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else if (rideData!.statut == 'on ride')
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                children: [
                                  const Icon(Icons.flag_circle, color: Colors.green, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Heading to Dropoff'.tr,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.green),
                                        ),
                                        Text(
                                          rideData!.destinationName ?? '',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(60),
                                  child: CachedNetworkImage(
                                    imageUrl: rideData!.photoPath.toString(),
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
                                    child: rideData!.rideType! == 'driver' && rideData!.existingUserId.toString() == "null"
                                        ? Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('${rideData!.userInfo!.name}',
                                                  style: TextStyle(
                                                    color: themeChange.getThem() ? AppThemeData.grey900Dark : AppThemeData.grey900,
                                                    fontSize: 16,
                                                    fontFamily: AppThemeData.semiBold,
                                                  )),
                                              Text('${rideData!.userInfo!.email}',
                                                  style: TextStyle(
                                                    color: themeChange.getThem() ? AppThemeData.grey900Dark : AppThemeData.grey900,
                                                    fontSize: 14,
                                                    fontFamily: AppThemeData.regular,
                                                  )),
                                            ],
                                          )
                                        : Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('${rideData!.prenom.toString()} ${rideData!.nom.toString()}',
                                                  style: TextStyle(
                                                      fontSize: 16,
                                                      color: themeChange.getThem() ? AppThemeData.grey900Dark : AppThemeData.grey900,
                                                      fontFamily: AppThemeData.medium)),
                                              StarRating(size: 18, rating: double.parse(rideData!.moyenneDriver.toString()), color: AppThemeData.error100),
                                            ],
                                          ),
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Row(
                                      children: [
                                        Visibility(
                                          visible: rideData!.statut == "confirmed" && rideData!.existingUserId.toString() != "null" ? true : false,
                                          child: InkWell(
                                              onTap: () {
                                                Get.to(ConversationScreen(), arguments: {
                                                  'receiverId': int.parse(rideData!.idUserApp.toString()),
                                                  'orderId': int.parse(rideData!.id.toString()),
                                                  'receiverName': '${rideData!.prenom} ${rideData!.nom}',
                                                  'receiverPhoto': rideData!.photoPath
                                                });
                                              },
                                              child: Image.asset(
                                                'assets/icons/chat_icon.png',
                                                height: 40,
                                                width: 40,
                                                fit: BoxFit.cover,
                                              )),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.only(left: 10, right: 10),
                                          child: InkWell(
                                            onTap: () {
                                              if (rideData!.existingUserId.toString() != "null") {
                                                Constant.makePhoneCall(rideData!.phone.toString());
                                              } else {
                                                Constant.makePhoneCall(rideData!.userInfo!.phone.toString());
                                              }
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
                                      ],
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(top: 5.0),
                                      child: Text(
                                        rideData!.dateRetour.toString(),
                                      ),
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
                        visible: rideData!.statut == "new" || rideData!.statut == "confirmed" ? true : false,
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
                        visible: rideData!.statut == "new" ? true : false,
                        child: Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 5, left: 10),
                            child: ButtonThem.buildButton(
                              context,
                              title: 'ACCEPT'.tr,
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
                                      title: "Do you want to confirm this booking?".tr,
                                      onPressNegative: () {
                                        Get.back();
                                      },
                                      negativeButtonText: 'No'.tr,
                                      positiveButtonText: 'Yes'.tr,
                                      onPressPositive: () {
                                        Map<String, String> bodyParams = {
                                          'id_ride': rideData!.id.toString(),
                                          'id_user': rideData!.idUserApp.toString(),
                                          'driver_name': '${rideData!.prenomConducteur.toString()} ${rideData!.nomConducteur.toString()}',
                                          'lat_conducteur': rideData!.latitudeDepart.toString(),
                                          'lng_conducteur': rideData!.longitudeDepart.toString(),
                                          'lat_client': rideData!.latitudeArrivee.toString(),
                                          'lng_client': rideData!.longitudeArrivee.toString(),
                                          'from_id': Preferences.getInt(Preferences.userId).toString(),
                                        };

                                        controllerRideDetails.confirmedRide(bodyParams).then((value) {
                                          if (value != null) {
                                            rideData!.statut = "confirmed";
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
                      Visibility(
                        visible: rideData!.statut == "confirmed" ? true : false,
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
                                      title: "Do you want to on ride this ride?".tr,
                                      negativeButtonText: 'No'.tr,
                                      positiveButtonText: 'Yes'.tr,
                                      onPressNegative: () {
                                        Get.back();
                                      },
                                      onPressPositive: () {
                                        Get.back();
                                        if (Constant.rideOtp.toString() != 'yes' || rideData!.rideType! == 'driver') {
                                          Map<String, String> bodyParams = {
                                            'id_ride': rideData!.id.toString(),
                                            'id_user': rideData!.idUserApp.toString(),
                                            'use_name': '${rideData!.prenomConducteur.toString()} ${rideData!.nomConducteur.toString()}',
                                            'from_id': Preferences.getInt(Preferences.userId).toString(),
                                          };
                                          controllerRideDetails.setOnRideRequest(bodyParams).then((value) {
                                            if (value != null) {
                                              if (mounted) {
                                                setState(() {
                                                  rideData!.statut = "on ride";
                                                });
                                              }
                                              ShowToastDialog.showToast("Trip started! Navigating to destination.");
                                              getDirections(dLat: departureLatLong.latitude, dLng: departureLatLong.longitude);
                                            }
                                          });
                                        } else {
                                          controllerRideDetails.otpController = TextEditingController();
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
                                                  decoration:
                                                      BoxDecoration(shape: BoxShape.rectangle, color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: const [
                                                    BoxShadow(color: Colors.black, offset: Offset(0, 10), blurRadius: 10),
                                                  ]),
                                                  child: Column(
                                                    children: [
                                                      Text(
                                                        "Enter Start OTP".tr,
                                                        style: TextStyle(color: Colors.black.withValues(alpha: 0.80), fontWeight: FontWeight.bold, fontSize: 16),
                                                      ),
                                                      const SizedBox(height: 10),
                                                      Pinput(
                                                        controller: controllerRideDetails.otpController,
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
                                                      const SizedBox(height: 12),
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            child: ButtonThem.buildButton(
                                                              context,
                                                              title: 'VERIFY & START'.tr,
                                                              btnHeight: 45,
                                                              btnWidthRatio: 0.8,
                                                              btnColor: AppThemeData.primary200,
                                                              txtColor: Colors.white,
                                                              onPress: () {
                                                                if (controllerRideDetails.otpController.text.toString().length == 6) {
                                                                  controllerRideDetails
                                                                      .verifyOTP(
                                                                    userId: rideData!.idUserApp!.toString(),
                                                                    rideId: rideData!.id!.toString(),
                                                                  )
                                                                      .then((value) {
                                                                    if (value != null && value['success'] == "success") {
                                                                      Map<String, String> bodyParams = {
                                                                        'id_ride': rideData!.id.toString(),
                                                                        'id_user': rideData!.idUserApp.toString(),
                                                                        'use_name': '${rideData!.prenomConducteur.toString()} ${rideData!.nomConducteur.toString()}',
                                                                        'from_id': Preferences.getInt(Preferences.userId).toString(),
                                                                      };
                                                                      controllerRideDetails.setOnRideRequest(bodyParams).then((value) {
                                                                        if (value != null) {
                                                                          Get.back(); // close OTP dialog only
                                                                          if (mounted) {
                                                                            setState(() {
                                                                              rideData!.statut = "on ride";
                                                                            });
                                                                          }
                                                                          ShowToastDialog.showToast("Trip started! Navigating to destination.");
                                                                          getDirections(dLat: departureLatLong.latitude, dLng: departureLatLong.longitude);
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
                        visible: rideData!.statut == "on ride" ? true : false,
                        child: Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 5),
                            child: ButtonThem.buildBorderButton(
                              context,
                              title: 'NAVIGATE'.tr,
                              btnHeight: 45,
                              btnWidthRatio: 0.8,
                              btnColor: Colors.white,
                              txtColor: AppThemeData.primary200,
                              btnBorderColor: AppThemeData.primary200,
                              onPress: () async {
                                final destLat = destinationLatLong.latitude;
                                final destLng = destinationLatLong.longitude;
                                final url = Uri.parse("https://www.google.com/maps/dir/?api=1&destination=$destLat,$destLng&travelmode=driving");
                                if (await canLaunchUrl(url)) {
                                  await launchUrl(url, mode: LaunchMode.externalApplication);
                                } else {
                                  ShowToastDialog.showToast("Could not launch Google Maps");
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                      Visibility(
                        visible: rideData!.statut == "on ride" ? true : false,
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
                                Get.to(() => PaymentCollectionScreen(
                                  rideData: rideData!,
                                  onConfirm: (String paymethod) {
                                    Map<String, String> bodyParams = {
                                      'id_ride': rideData!.id.toString(),
                                      'id_user': rideData!.idUserApp.toString(),
                                      'driver_name': '${rideData!.prenomConducteur.toString()} ${rideData!.nomConducteur.toString()}',
                                      'from_id': Preferences.getInt(Preferences.userId).toString(),
                                    };
                                    controllerRideDetails.setCompletedRequest(bodyParams, rideData!, paymethod: paymethod).then((value) {
                                      if (value != null) {
                                        Get.back(); // close PaymentCollectionScreen
                                        showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return CustomDialogBox(
                                                title: "Completed Successfully".tr,
                                                descriptions: "Ride Successfully completed.".tr,
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
                                ));
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
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        "Write a reason for trip cancellation".tr,
                        style: TextStyle(fontSize: 16),
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
                                              'id_ride': rideData!.id.toString(),
                                              'id_user': rideData!.idUserApp.toString(),
                                              'name': '${rideData!.prenomConducteur.toString()} ${rideData!.nomConducteur.toString()}',
                                              'from_id': Preferences.getInt(Preferences.userId).toString(),
                                              'user_cat': controllerRideDetails.userModel!.userData!.userCat.toString(),
                                              'reason': resonController.text.toString(),
                                            };
                                            controllerRideDetails.canceledRide(bodyParams).then((value) {
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
    List<LatLng> polylineCoordinates = [];
    PolylineResult result;
    List<PolylineWayPoint> wayPointList = [];

    for (var i = 0; i < rideData!.stops!.length; i++) {
      wayPointList.add(
        PolylineWayPoint(location: rideData!.stops![i].location!),
      );
    }

    if (rideData!.statut == "confirmed") {
      PolylineRequest resultdata = PolylineRequest(
        origin: PointLatLng(dLat, dLng),
        destination: PointLatLng(
          double.parse(rideData!.latitudeDepart.toString()),
          double.parse(rideData!.longitudeDepart.toString()),
        ),
        mode: TravelMode.driving,
        optimizeWaypoints: true,
        // wayPoints: wayPointList,
      );

      result = await polylinePoints.getRouteBetweenCoordinates(request: resultdata);
    } else if (rideData!.statut == "on ride") {
      PolylineRequest resultdata = PolylineRequest(
        origin: PointLatLng(dLat, dLng),
        destination: PointLatLng(destinationLatLong.latitude, destinationLatLong.longitude),
        mode: TravelMode.driving,
        optimizeWaypoints: true,
        wayPoints: wayPointList,
      );

      result = await polylinePoints.getRouteBetweenCoordinates(request: resultdata);
    } else {
      PolylineRequest resultdata = PolylineRequest(
        origin: PointLatLng(departureLatLong.latitude, departureLatLong.longitude),
        destination: PointLatLng(destinationLatLong.latitude, destinationLatLong.longitude),
        mode: TravelMode.driving,
        optimizeWaypoints: true,
        wayPoints: wayPointList,
      );

      result = await polylinePoints.getRouteBetweenCoordinates(request: resultdata);
    }

    if (result.points.isNotEmpty) {
      for (var point in result.points) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      }
    }

    // Departure (Pickup) Marker
    final pLat = double.parse(rideData!.latitudeDepart.toString());
    final pLng = double.parse(rideData!.longitudeDepart.toString());
    _markers['Departure'] = Marker(
      markerId: const MarkerId('Departure'),
      infoWindow: InfoWindow(title: "Pickup Point".tr, snippet: rideData!.departName),
      position: LatLng(pLat, pLng),
      icon: departureIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
    );

    // Destination (Dropoff) Marker
    _markers['Destination'] = Marker(
      markerId: const MarkerId('Destination'),
      infoWindow: InfoWindow(title: "Destination".tr, snippet: rideData!.destinationName),
      position: destinationLatLong,
      icon: destinationIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
    );

    if (rideData!.stops != null) {
      for (var i = 0; i < rideData!.stops!.length; i++) {
        if (rideData!.stops![i].latitude != null && rideData!.stops![i].longitude != null) {
          _markers['stop_$i'] = Marker(
            markerId: MarkerId('stop_$i'),
            infoWindow: InfoWindow(title: rideData!.stops![i].location ?? "Stop"),
            position: LatLng(double.parse(rideData!.stops![i].latitude!), double.parse(rideData!.stops![i].longitude!)),
            icon: stopIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
          );
        }
      }
    }

    addPolyLine(polylineCoordinates);
  }

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
    if (polylineCoordinates.isNotEmpty) {
      updateCameraLocation(polylineCoordinates, _mapcontroller);
    }

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> updateCameraLocation(
    List<LatLng> coordinates,
    GoogleMapController? mapController,
  ) async {
    if (mapController == null || coordinates.isEmpty) return;

    try {
      if (coordinates.length == 1) {
        mapController.animateCamera(CameraUpdate.newLatLngZoom(coordinates.first, 15));
        return;
      }

      double minLat = coordinates.first.latitude;
      double maxLat = coordinates.first.latitude;
      double minLng = coordinates.first.longitude;
      double maxLng = coordinates.first.longitude;

      for (LatLng point in coordinates) {
        if (point.latitude < minLat) minLat = point.latitude;
        if (point.latitude > maxLat) maxLat = point.latitude;
        if (point.longitude < minLng) minLng = point.longitude;
        if (point.longitude > maxLng) maxLng = point.longitude;
      }

      LatLngBounds bounds = LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      );

      mapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, 70));
    } catch (_) {
      mapController.animateCamera(CameraUpdate.newLatLngZoom(coordinates.first, 14));
    }
  }
}

