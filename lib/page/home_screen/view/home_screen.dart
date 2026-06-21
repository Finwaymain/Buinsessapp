import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../constant/constant.dart';
import '../../../constant/show_toast_dialog.dart';
import '../../../controller/dash_board_controller.dart';
import '../../../controller/new_ride_controller.dart';
import '../../../controller/payStackURLModel.dart';
import '../../../controller/wallet_controller.dart';
import '../../../model/payment_setting_model.dart';
import '../../../model/razorpay_gen_userid_model.dart';
import '../../../model/stripe_failed_model.dart';
import '../../../model/user_model.dart';
import '../../../model/xenditModel.dart';
import '../../../service/api.dart';
import '../../../themes/constant_colors.dart';
import '../../../themes/custom_base_widget.dart';
import '../../../themes/responsive.dart';
import '../../../themes/text_field_them.dart';
import '../../../utils/dark_theme_provider.dart';
import '../../MainDashBoard/widget/animated_feature_card.dart';
import '../../MainDashBoard/widget/service_card.dart';
import '../../features/SmartValue/MPinChange/view/mpin_change_screen.dart';
import '../../features/SmartValue/MyQR/view/my_qr_view.dart';
import '../../features/SmartValue/Payout/view/payout_screen.dart';
import '../../features/SmartValue/ScanAndTransfer/view/scanner_and_transfer_screen.dart';
import '../../in_progress_screen.dart';
import '../../parcel_service/all_parcel_screen.dart';
import '../../features/SmartValue/AccountDetails/view/account_details.dart';
import '../../features/SmartValue/AddPerson/view/add_user_screen.dart';
import '../../referral_screen/referral_screen.dart';
import '../../wallet/mercadopago_screen.dart';
import '../../wallet/midtrans_screen.dart';
import '../../wallet/orangePayScreen.dart';
import '../../wallet/payStackScreen.dart';
import '../../wallet/payfast_screen.dart';
import '../../wallet/paystack_url_generator.dart';
import '../../wallet/wallet_sucess_screen.dart';
import '../../features/Taxi/taxi_dashboard/taxi_dashboard.dart';
import '../../wallet/xenditScreen.dart';
import '../controller/main_home_controller.dart';
import '../widget/vertical_icon_with_text.dart';
import '../widget/vertical_line_section.dart';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:math' as maths;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_paypal/flutter_paypal.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import '../../features/Taxi/taxi_dashboard/taxi_dashboard.dart';

import '../../wallet/wallet_screen.dart';

class MainHomeScreen extends StatelessWidget {
  MainHomeScreen({super.key});

  DateTime backPress = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.getThem();

    return GetBuilder<DashBoardController>(
      init: DashBoardController(),
      builder: (controller) {
        controller.getDrawerItems();
        return GetBuilder<MainHomeController>(
          init: MainHomeController(),
          builder: (homeController) {
            final activeFeatureEntries = homeController.featureCards
                .asMap()
                .entries
                .where((entry) => entry.value['status'] == 1)
                .toList();

            final activeServiceEntries = homeController.serviceCards
                .asMap()
                .entries
                .where((entry) => entry.value['status'] == 1)
                .toList();

            return WillPopScope(
              onWillPop: () async {
                final timeGap = DateTime.now().difference(backPress);
                final cantExit = timeGap >= const Duration(seconds: 2);
                backPress = DateTime.now();
                if (cantExit) {
                  var snack = SnackBar(
                    content: Text(
                      'Press Back button again to Exit'.tr,
                      style: const TextStyle(color: Colors.white),
                    ),
                    duration: const Duration(seconds: 2),
                    backgroundColor: Colors.black,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(snack);
                  return false; // false will do nothing when back press
                } else {
                  return true; // true will exit the app
                }
              },
              child: Scaffold(
                backgroundColor: isDark
                    ? AppThemeData.surface50Dark
                    : AppThemeData.surface50,
                body: Column(
                  children: [
                    GetX<NewRideController>(
                      init: NewRideController(),
                      builder: (rideController) {
                        // Add null safety checks
                        if (rideController.userModel.value.userData == null ||
                            Constant.minimumWalletBalance == null) {
                          return const SizedBox(); // Return empty widget if data is not ready
                        }

                        // Safely parse the amount with null checks
                        double userAmount = 0.0;
                        try {
                          userAmount = double.parse(
                              rideController.userModel.value.userData!.amount.toString()
                          );
                        } catch (e) {
                          return const SizedBox();
                        }

                        double minBalance = 0.0;
                        try {
                          minBalance = double.parse(Constant.minimumWalletBalance!);
                        } catch (e) {
                          return const SizedBox();
                        }

                        bool isShow = userAmount < minBalance;

                        return isShow
                            ? Container(
                          margin: const EdgeInsets.only(top: 10, left: 16, right: 16),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10
                          ),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: AppThemeData.warning200
                          ),
                          child: Text(
                            "${"Your wallet balance must be".tr} ${Constant().amountShow(amount: Constant.minimumWalletBalance!.toString())} ${"to get ride.".tr}",
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        )
                            : const SizedBox();
                      },
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Premium welcoming header
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Welcome back, Captain".tr,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontFamily: AppThemeData.medium,
                                            color: AppThemeData.primary200,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          "${controller.userModel.value.userData?.prenom ?? 'Driver'} ${controller.userModel.value.userData?.nom ?? ''}",
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontFamily: AppThemeData.bold,
                                            color: isDark ? AppThemeData.grey900Dark : AppThemeData.grey900,
                                          ),
                                        ),
                                        if (controller.userModel.value.userData?.brand != null) ...[
                                          const SizedBox(height: 6),
                                          Text(
                                            "${controller.userModel.value.userData!.brand} ${controller.userModel.value.userData!.model ?? ''} • ${controller.userModel.value.userData!.numberplate ?? ''}",
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontFamily: AppThemeData.regular,
                                              color: isDark ? AppThemeData.grey500Dark : AppThemeData.grey500,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      Get.to(() => WalletScreen(), transition: Transition.rightToLeftWithFade);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF1E1C15) : const Color(0xFFFFF7D7),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: AppThemeData.primary200.withValues(alpha: 0.5),
                                          width: 1,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            "Wallet".tr,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontFamily: AppThemeData.medium,
                                              color: isDark ? AppThemeData.grey500Dark : AppThemeData.grey500,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            Constant().amountShow(amount: controller.userModel.value.userData?.amount?.toString() ?? "0.0"),
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontFamily: AppThemeData.bold,
                                              color: AppThemeData.primary200,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Interactive OSM Live Map
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: const DashboardMapWidget(),
                            ),

                            // Primary Hero Action CTA for receiving rides
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                              child: GestureDetector(
                                onTap: () {
                                  if (homeController.getLoginStatus(inProgress: false)) {
                                    Get.to(() => TaxiDashBoard(), transition: Transition.rightToLeftWithFade);
                                  }
                                },
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    gradient: LinearGradient(
                                      colors: isDark
                                          ? [const Color(0xFF201D16), const Color(0xFF151413)]
                                          : [const Color(0xFFFFF9E6), const Color(0XFFFFFFFF)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    border: Border.all(
                                      color: AppThemeData.primary200,
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppThemeData.primary200.withValues(alpha: isDark ? 0.08 : 0.15),
                                        blurRadius: 20,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: AppThemeData.primary200.withValues(alpha: 0.2),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.directions_car_filled_rounded,
                                          color: AppThemeData.primary200,
                                          size: 32,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Ride Console".tr,
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontFamily: AppThemeData.bold,
                                                color: isDark ? AppThemeData.grey900Dark : AppThemeData.grey900,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              "Go online, view requests, and track active bookings in real time.".tr,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontFamily: AppThemeData.regular,
                                                color: isDark ? AppThemeData.grey500Dark : AppThemeData.grey500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        Icons.chevron_right_rounded,
                                        color: AppThemeData.primary200,
                                        size: 28,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // Asymmetrical grid/row of actions and value programs
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Driver Actions
                                  Expanded(
                                    flex: 4,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Driver Actions".tr,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontFamily: AppThemeData.bold,
                                            color: isDark ? AppThemeData.grey500Dark : AppThemeData.grey500,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        ...activeFeatureEntries.map((entry) {
                                          final originalIndex = entry.key;
                                          final data = entry.value;
                                          return Container(
                                            margin: const EdgeInsets.only(bottom: 12),
                                            child: InkWell(
                                              onTap: () => homeController.onFeatureTap(originalIndex),
                                              borderRadius: BorderRadius.circular(16),
                                              child: Container(
                                                padding: const EdgeInsets.all(16),
                                                decoration: BoxDecoration(
                                                  color: isDark ? const Color(0xFF1A1917) : const Color(0xFFF9F7F2),
                                                  borderRadius: BorderRadius.circular(16),
                                                  border: Border.all(
                                                    color: isDark ? const Color(0xFF2C2A26) : const Color(0xFFE5DFD5),
                                                    width: 1,
                                                  ),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      data['icon'] as IconData,
                                                      color: AppThemeData.primary200,
                                                      size: 20,
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: Text(
                                                        (data['title'] as String).tr,
                                                        style: TextStyle(
                                                          fontSize: 13,
                                                          fontFamily: AppThemeData.bold,
                                                          color: isDark ? AppThemeData.grey900Dark : AppThemeData.grey900,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        }),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  // Value Programs
                                  Expanded(
                                    flex: 6,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Value Programs".tr,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontFamily: AppThemeData.bold,
                                            color: isDark ? AppThemeData.grey500Dark : AppThemeData.grey500,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        ...activeServiceEntries.map((entry) {
                                          final originalIndex = entry.key;
                                          final data = entry.value;
                                          return SlideTransition(
                                            position: homeController.slideAnimations[originalIndex],
                                            child: Container(
                                              margin: const EdgeInsets.only(bottom: 12),
                                              child: InkWell(
                                                onTap: () => homeController.onServiceTap(originalIndex),
                                                borderRadius: BorderRadius.circular(16),
                                                child: Container(
                                                  padding: const EdgeInsets.all(14),
                                                  decoration: BoxDecoration(
                                                    color: isDark ? const Color(0xFF1E1C18) : const Color(0xFFFAF9F5),
                                                    borderRadius: BorderRadius.circular(16),
                                                    border: Border.all(
                                                      color: AppThemeData.primary200.withValues(alpha: 0.15),
                                                      width: 1,
                                                    ),
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        (data['title'] as String).tr,
                                                        style: TextStyle(
                                                          fontSize: 13,
                                                          fontFamily: AppThemeData.bold,
                                                          color: AppThemeData.primary200,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        (data['subtitle'] as String).tr,
                                                        maxLines: 2,
                                                        overflow: TextOverflow.ellipsis,
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          fontFamily: AppThemeData.regular,
                                                          color: isDark ? AppThemeData.grey500Dark : AppThemeData.grey500,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        }),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Quick Access Section
                            VerticalLineSection(
                              text: "Quick Access",
                              margin: const EdgeInsets.only(top: 20),
                              cardChildren: [
                                VerticalIconWithText(
                                  icon: Icons.directions_car_outlined,
                                  text: 'Ride Booking',
                                  onTap: () {
                                    Get.to(() => TaxiDashBoard(),
                                        transition: Transition.rightToLeftWithFade);
                                  },
                                ),
                                VerticalIconWithText(
                                  icon: Icons.car_rental_outlined,
                                  text: 'Rental Vehicle',
                                  onTap: () {
                                    Get.to(() => const InProgressScreen(),
                                        transition: Transition.rightToLeftWithFade);
                                  },
                                ),
                                VerticalIconWithText(
                                  icon: Icons.local_shipping_outlined,
                                  text: 'Parcel Service',
                                  onTap: () {
                                    Get.to(() => const AllParcelScreen(),
                                        transition: Transition.rightToLeftWithFade);
                                  },
                                ),
                                VerticalIconWithText(
                                  icon: Icons.groups_outlined,
                                  text: 'Shared Ride',
                                  onTap: () {
                                    Get.to(() => const InProgressScreen(),
                                        transition: Transition.rightToLeftWithFade);
                                  },
                                ),
                              ],
                            ),

                            // Smart Value Section
                            VerticalLineSection(
                              text: "Smart Value",
                              margin: const EdgeInsets.only(top: 25),
                              cardChildren: [
                                VerticalIconWithText(
                                  icon: Icons.account_balance_wallet_outlined,
                                  text: 'Account Details',
                                  onTap: () {
                                    if (homeController.getLoginStatus(inProgress: false)) {
                                      Get.to(() => AccountDetails(),
                                          transition: Transition.rightToLeftWithFade);
                                    }
                                  },
                                ),
                                VerticalIconWithText(
                                  icon: Icons.person_add_alt_1_outlined,
                                  text: 'Add Person',
                                  onTap: () {
                                    if (homeController.getLoginStatus(inProgress: false)) {
                                      Get.to(() => AddUserScreen(),
                                          transition: Transition.rightToLeftWithFade);
                                    }
                                  },
                                ),
                                VerticalIconWithText(
                                  icon: Icons.swap_horiz_outlined,
                                  text: 'Transfer Money',
                                  onTap: () {
                                    if (homeController.getLoginStatus(inProgress: false)) {
                                      Get.to(() => ScannerAndTransferScreen(),
                                          transition: Transition.rightToLeftWithFade);
                                    }
                                  },
                                ),
                                VerticalIconWithText(
                                  icon: Icons.qr_code_2_outlined,
                                  text: 'My QR Code',
                                  onTap: () {
                                    if (homeController.getLoginStatus(inProgress: false)) {
                                      Get.to(() => MyQRScreen(),
                                          transition: Transition.rightToLeftWithFade);
                                    }
                                  },
                                ),
                                VerticalIconWithText(
                                  icon: Icons.lock_outline,
                                  text: 'Set M-PIN',
                                  onTap: () {
                                    if (homeController.getLoginStatus(inProgress: false)) {
                                      Get.to(() => MPinChangeScreen(),
                                          transition: Transition.rightToLeftWithFade);
                                    }
                                  },
                                ),
                                VerticalIconWithText(
                                  icon: Icons.account_balance_outlined,
                                  text: 'Payouts',
                                  onTap: () {
                                    if (homeController.getLoginStatus(inProgress: false)) {
                                      Get.to(() => PayoutScreen(),
                                          transition: Transition.rightToLeftWithFade);
                                    }
                                  },
                                ),
                                VerticalIconWithText(
                                  icon: Icons.group_add_outlined,
                                  text: 'Refer & Earn',
                                  onTap: () {
                                    if (homeController.getLoginStatus(inProgress: false)) {
                                      Get.to(() => ReferralScreen(),
                                          transition: Transition.rightToLeftWithFade);
                                    }
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}



class DashboardMapWidget extends StatefulWidget {
  const DashboardMapWidget({super.key});

  @override
  State<DashboardMapWidget> createState() => _DashboardMapWidgetState();
}

class _DashboardMapWidgetState extends State<DashboardMapWidget> {
  static GeoPoint? cachedPosition;
  MapController? mapController;
  GoogleMapController? googleMapController;
  double? currentLat;
  double? currentLng;
  bool isReady = false;

  @override
  void initState() {
    super.initState();
    _initMapController();
  }

  Future<void> _initMapController() async {
    double? lat;
    double? lng;

    if (Constant.currentLocation != null &&
        Constant.currentLocation!.latitude != null &&
        Constant.currentLocation!.longitude != null) {
      lat = Constant.currentLocation!.latitude;
      lng = Constant.currentLocation!.longitude;
    } else if (cachedPosition != null) {
      lat = cachedPosition!.latitude;
      lng = cachedPosition!.longitude;
    } else {
      try {
        final loc = await Location().getLocation();
        lat = loc.latitude;
        lng = loc.longitude;
        if (loc.latitude != null && loc.longitude != null) {
          Constant.currentLocation = loc;
        }
      } catch (e) {
        // ignore
      }
    }

    if (lat != null && lng != null) {
      cachedPosition = GeoPoint(latitude: lat, longitude: lng);
      currentLat = lat;
      currentLng = lng;
      if (mounted) {
        setState(() {
          mapController = MapController(
            initPosition: cachedPosition!,
          );
        });
      }
    }
  }

  @override
  void dispose() {
    mapController?.dispose();
    googleMapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.getThem();

    if (Constant.selectedMapType == 'google') {
      if (currentLat == null || currentLng == null) {
        return Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: isDark ? AppThemeData.surface50Dark : AppThemeData.surface50,
            border: Border.all(
              color: isDark
                  ? AppThemeData.primary200.withValues(alpha: 0.15)
                  : AppThemeData.primary200.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Center(
            child: CircularProgressIndicator(
              color: AppThemeData.primary200,
              strokeWidth: 2,
            ),
          ),
        );
      }

      return Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? AppThemeData.primary200.withValues(alpha: 0.15)
                : AppThemeData.primary200.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: GoogleMap(
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
            compassEnabled: false,
            initialCameraPosition: CameraPosition(
              target: LatLng(currentLat!, currentLng!),
              zoom: 14.0,
            ),
            onMapCreated: (GoogleMapController controller) {
              googleMapController = controller;
            },
            myLocationEnabled: true,
          ),
        ),
      );
    }

    if (mapController == null) {
      return Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isDark ? AppThemeData.surface50Dark : AppThemeData.surface50,
          border: Border.all(
            color: isDark
                ? AppThemeData.primary200.withValues(alpha: 0.15)
                : AppThemeData.primary200.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        child: Center(
          child: CircularProgressIndicator(
            color: AppThemeData.primary200,
            strokeWidth: 2,
          ),
        ),
      );
    }

    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? AppThemeData.primary200.withValues(alpha: 0.15)
              : AppThemeData.primary200.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          children: [
            OSMFlutter(
              controller: mapController!,
              osmOption: OSMOption(
                userLocationMarker: UserLocationMaker(
                  directionArrowMarker: MarkerIcon(
                    iconWidget: Image.asset(
                      "assets/images/ic_taxi.png",
                      width: 40,
                      height: 40,
                    ),
                  ),
                  personMarker: MarkerIcon(
                    iconWidget: Image.asset(
                      "assets/images/ic_taxi.png",
                      width: 40,
                      height: 40,
                    ),
                  ),
                ),
                userTrackingOption: const UserTrackingOption(
                  enableTracking: true,
                  unFollowUser: false,
                ),
                zoomOption: const ZoomOption(
                  initZoom: 14,
                  minZoomLevel: 3,
                  maxZoomLevel: 19,
                  stepZoom: 1.0,
                ),
                roadConfiguration: const RoadOption(
                  roadColor: Colors.blue,
                ),
              ),
              onMapIsReady: (ready) {
                if (mounted) {
                  setState(() {
                    isReady = ready;
                  });
                }
              },
            ),
            if (!isReady)
              Container(
                color: isDark ? AppThemeData.surface50Dark : AppThemeData.surface50,
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppThemeData.primary200,
                    strokeWidth: 2,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class AddFundScreen extends StatelessWidget {
  AddFundScreen({super.key});

  final walletController = Get.put(WalletController());
  final Razorpay razorPayController = Razorpay();

  static final GlobalKey<FormState> _walletFormKey = GlobalKey<FormState>();
  static final amountController = TextEditingController();

  Future<void> _refreshAPI() async {
    walletController.getAmount();
    walletController.getTrancation();
    amountController.clear();
    setRef();
  }

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.getThem();

    return CustomBaseWidget(
      showAppBar: true,
      appBarTitle: 'Add Fund',
      body: Column(
        children: [
          // Main Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(15.0),
              child: Column(
                children: [
                  // Balance Card
                  _buildBalanceCard(context, isDark),

                  const SizedBox(height: 32),

                  // Amount Input Section
                  _buildAmountInputSection(context, isDark),

                  const SizedBox(height: 20),

                  // Quick Amount Selection
                  _buildQuickAmountSelection(context, isDark),

                  const SizedBox(height: 40),

                  // Add Button
                  _buildAddButton(context, isDark),

                  const SizedBox(height: 140),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  AppThemeData.primary200.withValues(alpha: 0.8),
                  AppThemeData.primary200.withValues(alpha: 0.6),
                ]
              : [
                  AppThemeData.primary200,
                  AppThemeData.primary200.withValues(alpha: 0.8),
                ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppThemeData.primary200.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            "Current Balance".tr,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontFamily: AppThemeData.medium,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Obx(() => Text(
                "${Constant.currency}${walletController.userModel.value.userData?.amount ?? '0'}",
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: AppThemeData.bold,
                  fontSize: 32,
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildAmountInputSection(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppThemeData.grey800 : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? AppThemeData.grey800.withValues(alpha: 0.3)
              : Colors.grey.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppThemeData.primary200.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.account_balance_wallet_rounded,
                  color: AppThemeData.primary200,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "Enter Amount".tr,
                style: TextStyle(
                  color:
                      isDark ? AppThemeData.grey900Dark : AppThemeData.grey900,
                  fontFamily: AppThemeData.semiBold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Form(
            key: _walletFormKey,
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? AppThemeData.grey800.withValues(alpha: 0.5)
                    : AppThemeData.grey100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextFieldWidget(
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly
                ],
                hintText: '0',
                controller: amountController,
                textInputType: TextInputType.number,
                prefix: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Text(
                    Constant.currency.toString(),
                    style: TextStyle(
                      color: AppThemeData.primary200,
                      fontFamily: AppThemeData.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAmountSelection(BuildContext context, bool isDark) {
    final amounts = ["100", "500", "1000", "2000", "5000"];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Quick Select".tr,
          style: TextStyle(
            color: isDark ? AppThemeData.grey900Dark : AppThemeData.grey900,
            fontFamily: AppThemeData.semiBold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 15,
          runSpacing: 12,
          children: amounts
              .map((amount) => _buildQuickAmountChip(context, amount, isDark))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildQuickAmountChip(
      BuildContext context, String amount, bool isDark) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: amountController,
      builder: (context, value, child) {
        final isSelected = value.text == amount;

        return GestureDetector(
          onTap: () {
            amountController.text = amount;
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      colors: [
                        AppThemeData.primary200,
                        AppThemeData.primary200.withValues(alpha: 0.8),
                      ],
                    )
                  : null,
              color: isSelected
                  ? null
                  : isDark
                      ? AppThemeData.grey800
                      : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? AppThemeData.primary200
                    : isDark
                        ? AppThemeData.grey800.withValues(alpha: 0.3)
                        : Colors.grey.withValues(alpha: 0.2),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppThemeData.primary200.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Text(
              "${Constant.currency}$amount",
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : isDark
                        ? AppThemeData.grey900Dark
                        : AppThemeData.grey900,
                fontFamily: AppThemeData.semiBold,
                fontSize: 16,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAddButton(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            AppThemeData.primary200,
            AppThemeData.primary200.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppThemeData.primary200.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () {
          if (_walletFormKey.currentState!.validate()) {
            _showPaymentOptions(context, isDark);
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.add_circle_outline_rounded,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'Add Amount'.tr,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: AppThemeData.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<dynamic> _showPaymentOptions(BuildContext context, bool isDarkMode) {
    return showModalBottomSheet(
      isDismissible: true,
      isScrollControlled: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      context: context,
      builder: (context) {
        return Container(
          height: Get.height * 0.75,
          decoration: BoxDecoration(
            color: isDarkMode ? AppThemeData.surface50Dark : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: GetX<WalletController>(
            init: WalletController(),
            initState: (controller) {
              razorPayController.on(
                  Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
              razorPayController.on(
                  Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWaller);
              razorPayController.on(
                  Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
            },
            builder: (controller) {
              return Column(
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    height: 4,
                    width: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: isDarkMode
                          ? AppThemeData.grey800
                          : Colors.grey.withValues(alpha: 0.4),
                    ),
                  ),

                  // Header
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? AppThemeData.grey800.withValues(alpha: 0.5)
                                : AppThemeData.grey100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.payment_rounded,
                            color: AppThemeData.primary200,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            "Select Payment Method".tr,
                            style: TextStyle(
                              color: isDarkMode
                                  ? AppThemeData.grey900Dark
                                  : AppThemeData.grey900,
                              fontFamily: AppThemeData.bold,
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Amount Display
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppThemeData.primary200.withValues(alpha: 0.1),
                          AppThemeData.primary200.withValues(alpha: 0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppThemeData.primary200.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.account_balance_wallet_outlined,
                          color: AppThemeData.primary200,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "Amount: ",
                          style: TextStyle(
                            color: isDarkMode
                                ? AppThemeData.grey900Dark
                                : AppThemeData.grey900,
                            fontFamily: AppThemeData.medium,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          "${Constant.currency}${amountController.text}",
                          style: TextStyle(
                            color: AppThemeData.primary200,
                            fontFamily: AppThemeData.bold,
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Payment Options List
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          // Payment options grid
                          _buildPaymentMethodsGrid(
                              context, isDarkMode, controller),
                        ],
                      ),
                    ),
                  ),

                  // Proceed Button
                  Container(
                    padding: const EdgeInsets.all(24),
                    child: Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppThemeData.primary200,
                            AppThemeData.primary200.withValues(alpha: 0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppThemeData.primary200.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () async {
                          if (walletController.selectedRadioTile?.value == '' ||
                              walletController
                                      .selectedRadioTile?.value.isEmpty ==
                                  true) {
                            ShowToastDialog.showToast(
                                "Please select payment method");
                          } else {
                            Get.back();
                            showLoadingAlert(context);
                            await _processPayment(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Proceed to Pay'.tr,
                              style: const TextStyle(
                                color: Colors.white,
                                fontFamily: AppThemeData.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildPaymentMethodsGrid(
      BuildContext context, bool isDarkMode, WalletController controller) {
    final paymentMethods = [
      {
        'value': 'Stripe',
        'title': 'Stripe',
        'icon': 'assets/icons/stripe.png',
        'isVisible':
            walletController.paymentSettingModel.value.strip?.isEnabled ==
                "true",
      },
      {
        'value': 'PayStack',
        'title': 'PayStack',
        'icon': 'assets/icons/paystack.png',
        'isVisible':
            walletController.paymentSettingModel.value.payStack?.isEnabled ==
                "true",
      },
      {
        'value': 'FlutterWave',
        'title': 'FlutterWave',
        'icon': 'assets/icons/flutterwave.png',
        'isVisible':
            walletController.paymentSettingModel.value.flutterWave?.isEnabled ==
                "true",
      },
      {
        'value': 'RazorPay',
        'title': 'RazorPay',
        'icon': 'assets/icons/razorpay_@3x.png',
        'isVisible':
            walletController.paymentSettingModel.value.razorpay?.isEnabled ==
                "true",
      },
      {
        'value': 'PayFast',
        'title': 'Pay Fast',
        'icon': 'assets/icons/payfast.png',
        'isVisible':
            walletController.paymentSettingModel.value.payFast?.isEnabled ==
                "true",
      },
      {
        'value': 'MercadoPago',
        'title': 'Mercado Pago',
        'icon': 'assets/icons/mercadopago.png',
        'isVisible':
            walletController.paymentSettingModel.value.mercadopago?.isEnabled ==
                "true",
      },
      {
        'value': 'PayPal',
        'title': 'PayPal',
        'icon': 'assets/icons/paypal_@3x.png',
        'isVisible':
            walletController.paymentSettingModel.value.payPal?.isEnabled ==
                "true",
      },
      {
        'value': 'Xendit',
        'title': 'Xendit',
        'icon': 'assets/icons/xendit.png',
        'isVisible': walletController
                .paymentSettingModel.value.xendit?.isEnabled
                ?.toString() ==
            "true",
      },
    ];

    final visibleMethods =
        paymentMethods.where((method) => method['isVisible'] as bool).toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.5,
      ),
      itemCount: visibleMethods.length,
      itemBuilder: (context, index) {
        final method = visibleMethods[index];
        return _buildPaymentMethodCard(
          context: context,
          isDarkMode: isDarkMode,
          controller: controller,
          value: method['value'] as String,
          title: method['title'] as String,
          iconPath: method['icon'] as String,
          onChanged: () =>
              _setPaymentMethod(controller, method['value'] as String),
        );
      },
    );
  }

  Widget _buildPaymentMethodCard({
    required BuildContext context,
    required bool isDarkMode,
    required WalletController controller,
    required String value,
    required String title,
    required String iconPath,
    required VoidCallback onChanged,
  }) {
    return Obx(() {
      final isSelected = walletController.selectedRadioTile?.value == value;

      return GestureDetector(
        onTap: () {
          onChanged();
          walletController.selectedRadioTile?.value = value;
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? AppThemeData.primary200.withValues(alpha: 0.1)
                : isDarkMode
                    ? AppThemeData.grey800
                    : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? AppThemeData.primary200
                  : isDarkMode
                      ? AppThemeData.grey800.withValues(alpha: 0.3)
                      : Colors.grey.withValues(alpha: 0.2),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? AppThemeData.primary200.withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: isDarkMode ? 0.2 : 0.05),
                blurRadius: isSelected ? 12 : 8,
                offset: Offset(0, isSelected ? 4 : 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                iconPath,
                height: 32,
                width: 32,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 8),
              Text(
                title.tr,
                style: TextStyle(
                  color: isSelected
                      ? AppThemeData.primary200
                      : isDarkMode
                          ? AppThemeData.grey900Dark
                          : AppThemeData.grey900,
                  fontSize: 14,
                  fontFamily: AppThemeData.semiBold,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      );
    });
  }

  // Keep all existing payment processing methods unchanged
  void _setPaymentMethod(WalletController controller, String method) {
    // Reset all payment methods
    controller.stripe = false.obs;
    controller.razorPay = false.obs;
    controller.paypal = false.obs;
    controller.payStack = false.obs;
    controller.flutterWave = false.obs;
    controller.mercadoPago = false.obs;
    controller.payFast = false.obs;
    controller.xendit = false.obs;
    controller.orangePay = false.obs;
    controller.midtrans = false.obs;

    // Set the selected method
    switch (method) {
      case "Stripe":
        controller.stripe = true.obs;
        break;
      case "PayStack":
        controller.payStack = true.obs;
        break;
      case "FlutterWave":
        controller.flutterWave = true.obs;
        break;
      case "RazorPay":
        controller.razorPay = true.obs;
        break;
      case "PayFast":
        controller.payFast = true.obs;
        break;
      case "MercadoPago":
        controller.mercadoPago = true.obs;
        break;
      case "PayPal":
        controller.paypal = true.obs;
        break;
      case "Xendit":
        controller.xendit = true.obs;
        break;
      case "Orange Pay":
        controller.orangePay = true.obs;
        break;
      case "Midtrans":
        controller.midtrans = true.obs;
        break;
    }
  }

  Future<void> _processPayment(BuildContext context) async {
    if (walletController.selectedRadioTile!.value == "Stripe") {
      Stripe.publishableKey =
          walletController.paymentSettingModel.value.strip?.key ?? '';
      Stripe.merchantIdentifier = 'Cabme';
      await Stripe.instance.applySettings();
      log("Stripe :: publishableKey :: ${walletController.paymentSettingModel.value.strip?.clientpublishableKey ?? ''}");
      log("Stripe :: Secret Key ${walletController.paymentSettingModel.value.strip!.secretKey ?? ''}");
      stripeMakePayment(amount: amountController.text);
    } else if (walletController.selectedRadioTile!.value == "RazorPay") {
      startRazorpayPayment();
    } else if (walletController.selectedRadioTile!.value == "PayPal") {
      paypalPaymentSheet(
          double.parse(amountController.text).toString(), context);
    } else if (walletController.selectedRadioTile!.value == "PayStack") {
      payStackPayment(context);
    } else if (walletController.selectedRadioTile!.value == "FlutterWave") {
      flutterWaveInitiatePayment(
        context: context,
        amount: double.parse(amountController.text).toString(),
        user: walletController.userModel.value,
      );
    } else if (walletController.selectedRadioTile!.value == "PayFast") {
      payFastPayment(context);
    } else if (walletController.selectedRadioTile!.value == "MercadoPago") {
      mercadoPagoMakePayment(
        context: context,
        amount: double.parse(amountController.text).toString(),
        user: walletController.userModel.value,
        controller: walletController,
      );
    } else if (walletController.selectedRadioTile!.value == "Xendit") {
      xenditPayment(
          context, double.parse(amountController.text), walletController);
    } else if (walletController.selectedRadioTile!.value == "Orange Pay") {
      orangeMakePayment(
        amount: double.parse(amountController.text).toStringAsFixed(2),
        context: context,
        controller: walletController,
      );
    } else if (walletController.selectedRadioTile!.value == "Midtrans") {
      midtransMakePayment(
        amount: amountController.text.toString(),
        context: context,
        controller: walletController,
      );
    } else {
      ShowToastDialog.showToast("Please select payment method");
    }
  }

  // ... [Keep all existing payment method implementations exactly as they were]

  ///paypal
  void paypalPaymentSheet(String amount, context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (BuildContext context) => UsePaypal(
            sandboxMode:
                walletController.paymentSettingModel.value.payPal!.isLive ==
                        "true"
                    ? false
                    : true,
            clientId:
                walletController.paymentSettingModel.value.payPal!.appId ?? '',
            secretKey:
                walletController.paymentSettingModel.value.payPal!.secretKey ??
                    '',
            returnURL: "com.parkme://paypalpay",
            cancelURL: "com.parkme://paypalpay",
            transactions: [
              {
                "amount": {
                  "total": amount,
                  "currency": "USD",
                  "details": {"subtotal": amount}
                },
              }
            ],
            note: "Contact us for any questions on your order.",
            onSuccess: (Map params) async {
              walletController.setAmount(amountController.text).then((value) {
                if (value != null) {
                  _refreshAPI();
                  Get.to(const WalletSuccessScreen());
                }
              });
              ShowToastDialog.showToast("Payment Successful!!");
            },
            onError: (error) {
              Get.back();
              Get.back();
              ShowToastDialog.showToast("Payment UnSuccessful!!");
            },
            onCancel: (params) {
              Get.back();
              Get.back();
              ShowToastDialog.showToast("Payment UnSuccessful!!");
            }),
      ),
    );
  }

  /// RazorPay Payment Gateway
  void startRazorpayPayment() {
    try {
      walletController
          .createOrderRazorPay(
              amount: double.parse(amountController.text).round())
          .then((value) {
        if (value != null) {
          CreateRazorPayOrderModel result = value;
          openCheckout(
            amount: amountController.text,
            orderId: result.id,
          );
        } else {
          Get.back();
          showSnackBarAlert(
            message: "Something went wrong, please contact admin.".tr,
            color: Colors.red.shade400,
          );
        }
      });
    } catch (e) {
      Get.back();
      showSnackBarAlert(
        message: e.toString(),
        color: Colors.red.shade400,
      );
    }
  }

  void openCheckout({required amount, required orderId}) async {
    var options = {
      'key': walletController.paymentSettingModel.value.razorpay!.key,
      'amount': amount * 100,
      'name': 'Foodies',
      'order_id': orderId,
      "currency": "INR",
      'description': 'wallet Topup',
      'retry': {'enabled': true, 'max_count': 1},
      'send_sms_hash': true,
      'prefill': {'contact': "8888888888", 'email': "demo@demo.com"},
      'external': {
        'wallets': ['paytm']
      }
    };

    try {
      razorPayController.open(options);
    } catch (e) {
      log('Error: $e');
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    Get.back();
    walletController.setAmount(amountController.text).then((value) {
      if (value != null) {
        _refreshAPI();
        Get.to(const WalletSuccessScreen());
      }
    });
  }

  void _handleExternalWaller(ExternalWalletResponse response) {
    Get.back();
    showSnackBarAlert(
      message: "${"Payment Processing Via".tr}\n${response.walletName!}",
      color: Colors.blue.shade400,
    );
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    Get.back();
    showSnackBarAlert(
      message:
          "${"Payment Failed!!".tr}\n${jsonDecode(response.message!)['error']['description']}",
      color: Colors.red.shade400,
    );
  }

  /// Stripe Payment Gateway
  Map<String, dynamic>? paymentIntentData;

  Future<void> stripeMakePayment({required String amount}) async {
    try {
      paymentIntentData =
          await walletController.createStripeIntent(amount: amount);
      if (paymentIntentData!.containsKey("error")) {
        Get.back();
        showSnackBarAlert(
          message: "Something went wrong, please contact admin.".tr,
          color: Colors.red.shade400,
        );
      } else {
        await Stripe.instance
            .initPaymentSheet(
                paymentSheetParameters: SetupPaymentSheetParameters(
              paymentIntentClientSecret: paymentIntentData!['client_secret'],
              allowsDelayedPaymentMethods: false,
              googlePay: const PaymentSheetGooglePay(
                merchantCountryCode: 'US',
                testEnv: true,
                currencyCode: "USD",
              ),
              customFlow: true,
              style: ThemeMode.system,
              appearance: PaymentSheetAppearance(
                colors: PaymentSheetAppearanceColors(
                  primary: AppThemeData.primary200,
                ),
              ),
              merchantDisplayName: 'Cabme',
            ))
            .then((value) {});
        displayStripePaymentSheet();
      }
    } catch (e, s) {
      showSnackBarAlert(
        message: 'exception:$e \n$s',
        color: Colors.red,
      );
    }
  }

  Future<void> displayStripePaymentSheet() async {
    try {
      await Stripe.instance.presentPaymentSheet().then((value) {
        Get.back();
        walletController.setAmount(amountController.text).then((value) {
          if (value != null) {
            _refreshAPI();
          }
        });
        paymentIntentData = null;
      });
    } on StripeException catch (e) {
      Get.back();
      var lo1 = jsonEncode(e);
      var lo2 = jsonDecode(lo1);
      StripePayFailedModel lom = StripePayFailedModel.fromJson(lo2);
      showSnackBarAlert(
        message: lom.error.message,
        color: Colors.green,
      );
    } catch (e) {
      Get.back();
      showSnackBarAlert(
        message: e.toString(),
        color: Colors.green,
      );
    }
  }

  ///PayStack Payment Method
  Future<void> payStackPayment(BuildContext context) async {
    var secretKey = walletController
        .paymentSettingModel.value.payStack!.secretKey
        .toString();
    await walletController
        .payStackURLGen(
      amount: amountController.text,
      secretKey: secretKey,
    )
        .then((value) async {
      if (value != null) {
        PayStackUrlModel payStackModel = value;
        bool isDone = await Get.to(() => PayStackScreen(
              walletController: walletController,
              secretKey: secretKey,
              initialURl: payStackModel.data.authorizationUrl,
              amount: amountController.text,
              reference: payStackModel.data.reference,
              callBackUrl: walletController
                  .paymentSettingModel.value.payStack!.callbackUrl
                  .toString(),
            ));
        Get.back();

        if (isDone) {
          walletController.setAmount(amountController.text).then((value) async {
            if (value != null) {
              await _refreshAPI();
              Get.to(const WalletSuccessScreen());
            }
          });
        } else {
          showSnackBarAlert(
              message: "Payment UnSuccessful!!".tr, color: Colors.red);
        }
      } else {
        showSnackBarAlert(
            message: "Error while transaction!".tr, color: Colors.red);
      }
    });
  }

  SnackbarController showSnackBarAlert({required String message, Color color = Colors.green}) {
    return Get.showSnackbar(GetSnackBar(
      isDismissible: true,
      message: message,
      backgroundColor: color,
      duration: const Duration(seconds: 8),
    ));
  }

  String? _ref;

  void setRef() {
    maths.Random numRef = maths.Random();
    int year = DateTime.now().year;
    int refNumber = numRef.nextInt(20000);
    if (Platform.isAndroid) {
      _ref = "AndroidRef$year$refNumber";
    } else if (Platform.isIOS) {
      _ref = "IOSRef$year$refNumber";
    }
  }

  ///FlutterWave Payment Method
  Future<Null> flutterWaveInitiatePayment(
      {required BuildContext context,
      required String amount,
      required UserModel user}) async {
    final url = Uri.parse('https://api.flutterwave.com/v3/payments');
    final headers = {
      'Authorization':
          'Bearer ${walletController.paymentSettingModel.value.flutterWave?.secretKey}',
      'Content-Type': 'application/json',
    };

    final body = jsonEncode({
      "tx_ref": walletController.ref.value,
      "amount": amount,
      "currency": "NGN",
      "redirect_url": "${API.baseUrl}payment/success",
      "payment_options": "ussd, card, barter, payattitude",
      "customer": {
        "email": user.userData?.email.toString(),
        "phonenumber": user.userData?.phone,
        "name": '${user.userData?.prenom} ${user.userData?.nom}',
      },
      "customizations": {
        "title": "Payment for Services",
        "description": "Payment for XYZ services",
      }
    });

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      Get.to(MercadoPagoScreen(initialURl: data['data']['link']))!
          .then((value) async {
        if (value) {
          ShowToastDialog.showToast("Payment Successful!!");
          Get.back();
          await _refreshAPI();
          Get.to(const WalletSuccessScreen());
        } else {
          ShowToastDialog.showToast("Payment UnSuccessful!!");
          Get.back();
        }
      });
    } else {
      print('Payment initialization failed: ${response.body}');
      return null;
    }
  }

  ///payFast
  void payFastPayment(context) {
    PayFast? payfast = walletController.paymentSettingModel.value.payFast;
    PayStackURLGen.getPayHTML(
            payFastSettingData: payfast!,
            amount: double.parse(amountController.text.toString())
                .round()
                .toString())
        .then((String? value) async {
      bool isDone = await Get.to(PayFastScreen(
        htmlData: value!,
        payFastSettingData: payfast,
      ));
      if (isDone) {
        Get.back();
        walletController.setAmount(amountController.text).then((value) async {
          if (value != null) {
            await _refreshAPI();
            Get.to(const WalletSuccessScreen());
          }
        });
      } else {
        Get.back();
        showSnackBarAlert(
          message: "Payment UnSuccessful!!".tr,
          color: Colors.red,
        );
      }
    });
  }

  Future<Null> mercadoPagoMakePayment(
      {required BuildContext context,
      required String amount,
      required UserModel user,
      required WalletController controller}) async {
    final headers = {
      'Authorization':
          'Bearer ${controller.paymentSettingModel.value.mercadopago?.accesstoken ?? ''}',
      'Content-Type': 'application/json',
    };

    final body = jsonEncode({
      "items": [
        {
          "title": "Test",
          "description": "Test Payment",
          "quantity": 1,
          "currency_id": "BRL",
          "unit_price": double.parse(amount),
        }
      ],
      "payer": {"email": user.userData?.email ?? ''},
      "back_urls": {
        "failure": "${API.baseUrl}payment/failure",
        "pending": "${API.baseUrl}payment/pending",
        "success": "${API.baseUrl}payment/success",
      },
      "auto_return": "approved"
    });

    final response = await http.post(
      Uri.parse("https://api.mercadopago.com/checkout/preferences"),
      headers: headers,
      body: body,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      Get.to(MercadoPagoScreen(
        initialURl: controller
                    .paymentSettingModel.value.mercadopago?.isSandboxEnabled ==
                "false"
            ? data['init_point']
            : data['sandbox_init_point'],
      ))!
          .then((value) async {
        if (value) {
          Get.back();
          ShowToastDialog.showToast("Payment Successful!!");
          await _refreshAPI();
          Get.to(const WalletSuccessScreen());
        } else {
          Get.back();
          ShowToastDialog.showToast("Payment UnSuccessful!!");
        }
      });
    } else {
      log('Error creating preference: ${response.body}');
      return null;
    }
  }

  Future<void> showLoadingAlert(BuildContext context) {
    return showDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
          ),
          child: Center(
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppThemeData.primary200,
                          AppThemeData.primary200.withValues(alpha: 0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 3,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Processing Payment'.tr,
                    style: const TextStyle(
                      fontSize: 20,
                      fontFamily: AppThemeData.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please wait while we complete your transaction'.tr,
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: AppThemeData.medium,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  //XenditPayment
  Future<void> xenditPayment(context, amount, WalletController controller) async {
    await createXenditInvoice(amount: amount, controller: controller)
        .then((model) {
      if (model.id != null) {
        Get.to(() => XenditScreen(
                  initialURl: model.invoiceUrl ?? '',
                  transId: model.id ?? '',
                  apiKey: controller.paymentSettingModel.value.xendit!.key!
                      .toString(),
                ))!
            .then((value) {
          if (value == true) {
            Get.back();
            walletController
                .setAmount(amountController.text)
                .then((value) async {
              if (value != null) {
                await _refreshAPI();
                Get.to(const WalletSuccessScreen());
              }
            });
          } else {
            Get.back();
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text("Payment Unsuccessful!!".tr),
              backgroundColor: Colors.red,
            ));
          }
        });
      }
    });
  }

  Future<XenditModel> createXenditInvoice(
      {required var amount, required WalletController controller}) async {
    const url = 'https://api.xendit.co/v2/invoices';
    var headers = {
      'Content-Type': 'application/json',
      'Authorization': generateBasicAuthHeader(
          controller.paymentSettingModel.value.xendit!.key!.toString()),
    };

    final body = jsonEncode({
      'external_id': DateTime.now().millisecondsSinceEpoch.toString(),
      'amount': amount,
      'payer_email': 'customer@domain.com',
      'description': 'Test - VA Successful invoice payment',
      'currency': 'IDR',
    });

    try {
      final response =
          await http.post(Uri.parse(url), headers: headers, body: body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        XenditModel model = XenditModel.fromJson(jsonDecode(response.body));
        Get.back();
        return model;
      } else {
        Get.back();
        return XenditModel();
      }
    } catch (e) {
      Get.back();
      return XenditModel();
    }
  }

  String generateBasicAuthHeader(String apiKey) {
    String credentials = '$apiKey:';
    String base64Encoded = base64Encode(utf8.encode(credentials));
    return 'Basic $base64Encoded';
  }

  //Orangepay payment
  static String accessToken = '';
  static String payToken = '';
  static String orderId = '';
  static String amount = '';

  Future<void> orangeMakePayment(
      {required String amount,
      required BuildContext context,
      required WalletController controller}) async {
    reset();

    var paymentURL = await fetchToken(
        context: context,
        orderId: DateTime.now().millisecondsSinceEpoch.toString(),
        amount: amount,
        currency: 'USD',
        controller: controller);

    if (paymentURL.toString() != '') {
      Get.to(() => OrangeMoneyScreen(
                initialURl: paymentURL,
                accessToken: accessToken,
                amount: amount,
                orangePay: controller.paymentSettingModel.value.orangePay!,
                orderId: orderId,
                payToken: payToken,
              ))!
          .then((value) {
        if (value == true) {
          Get.back();
          walletController.setAmount(amountController.text).then((value) async {
            if (value != null) {
              await _refreshAPI();
              Get.to(const WalletSuccessScreen());
            }
          });
        }
      });
    } else {
      Get.back();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Payment Unsuccessful!!".tr),
        backgroundColor: Colors.red,
      ));
    }
  }

  Future fetchToken(
      {required String orderId,
      required String currency,
      required BuildContext context,
      required String amount,
      required WalletController controller}) async {
    String apiUrl = 'https://api.orange.com/oauth/v3/token';
    Map<String, String> requestBody = {
      'grant_type': 'client_credentials',
    };

    var response = await http.post(Uri.parse(apiUrl),
        headers: <String, String>{
          'Authorization':
              "Basic ${controller.paymentSettingModel.value.orangePay!.key!}",
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: requestBody);

    if (response.statusCode == 200) {
      Map<String, dynamic> responseData = jsonDecode(response.body);
      accessToken = responseData['access_token'];
      return await webpayment(
          context: context,
          amountData: amount,
          currency: currency,
          orderIdData: orderId,
          controller: controller);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: Color(0xff635bff),
          content: Text(
            "Something went wrong, please contact admin.".tr,
            style: TextStyle(fontSize: 17),
          )));
      return '';
    }
  }

  Future webpayment(
      {required String orderIdData,
      required BuildContext context,
      required String currency,
      required String amountData,
      required WalletController controller}) async {
    orderId = orderIdData;
    amount = amountData;
    String apiUrl =
        controller.paymentSettingModel.value.orangePay!.isSandboxEnabled! ==
                "true"
            ? 'https://api.orange.com/orange-money-webpay/dev/v1/webpayment'
            : 'https://api.orange.com/orange-money-webpay/cm/v1/webpayment';
    Map<String, String> requestBody = {
      "merchant_key":
          controller.paymentSettingModel.value.orangePay!.merchantKey ?? '',
      "currency":
          controller.paymentSettingModel.value.orangePay!.isSandboxEnabled ==
                  "true"
              ? "OUV"
              : currency,
      "order_id": orderId,
      "amount": amount,
      "reference": 'Y-Note Test',
      "lang": "en",
      "return_url":
          controller.paymentSettingModel.value.orangePay!.returnUrl!.toString(),
      "cancel_url":
          controller.paymentSettingModel.value.orangePay!.cancelUrl!.toString(),
      "notif_url":
          controller.paymentSettingModel.value.orangePay!.notifUrl!.toString(),
    };

    var response = await http.post(
      Uri.parse(apiUrl),
      headers: <String, String>{
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      },
      body: json.encode(requestBody),
    );

    if (response.statusCode == 201) {
      Get.back();
      Map<String, dynamic> responseData = jsonDecode(response.body);
      if (responseData['message'] == 'OK') {
        payToken = responseData['pay_token'];
        return responseData['payment_url'];
      } else {
        return '';
      }
    } else {
      Get.back();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: Color(0xff635bff),
          content: Text(
            "Something went wrong, please contact admin.".tr,
            style: TextStyle(fontSize: 17),
          )));
      return '';
    }
  }

  static void reset() {
    accessToken = '';
    payToken = '';
    orderId = '';
    amount = '';
  }

  //Midtrans payment
  Future<void> midtransMakePayment(
      {required String amount,
      required BuildContext context,
      required WalletController controller}) async {
    await createPaymentLink(amount: amount, controller: controller).then((url) {
      if (url != '') {
        Get.to(() => MidtransScreen(
                  initialURl: url,
                ))!
            .then((value) {
          if (value == true) {
            walletController
                .setAmount(amountController.text)
                .then((value) async {
              if (value != null) {
                Get.back();
                await _refreshAPI();
                Get.to(const WalletSuccessScreen());
              }
            });
          } else {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text("Payment Unsuccessful".tr),
              backgroundColor: Colors.red,
            ));
          }
        });
      }
    });
  }

  Future<String> createPaymentLink(
      {required var amount, required WalletController controller}) async {
    var ordersId = DateTime.now().millisecondsSinceEpoch.toString();
    final url = Uri.parse(controller
                .paymentSettingModel.value.midtrans!.isSandboxEnabled!
                .toString() ==
            "true"
        ? 'https://api.sandbox.midtrans.com/v1/payment-links'
        : 'https://api.midtrans.com/v1/payment-links');

    final response = await http.post(
      url,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': generateBasicAuthHeader(
            controller.paymentSettingModel.value.midtrans!.key!),
      },
      body: jsonEncode({
        'transaction_details': {
          'order_id': ordersId,
          'gross_amount': double.parse(amount.toString()).toInt(),
        },
        'usage_limit': 2,
        "callbacks": {
          "finish": "https://www.google.com?merchant_order_id=$ordersId"
        },
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseData = jsonDecode(response.body);
      Get.back();
      print('Payment link created: ${responseData['payment_url']}');
      return responseData['payment_url'];
    } else {
      Get.back();
      return '';
    }
  }
}
