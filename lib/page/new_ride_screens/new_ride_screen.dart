import 'dart:convert';
import 'package:cabme_driver/constant/constant.dart';
import 'package:cabme_driver/model/user_model.dart';
import 'package:cabme_driver/page/new_ride_screens/payment_collection_screen.dart';
import 'package:cabme_driver/constant/show_toast_dialog.dart';
import 'package:cabme_driver/controller/dash_board_controller.dart';
import 'package:cabme_driver/controller/new_ride_controller.dart';
import 'package:cabme_driver/model/ride_model.dart';
import 'package:cabme_driver/page/complaint/add_complaint_screen.dart';
import 'package:cabme_driver/page/completed/trip_history_screen.dart';
import 'package:cabme_driver/page/create_ride/create_osm_ride_screen.dart';
import 'package:cabme_driver/page/create_ride/create_ride_screen.dart';
import 'package:cabme_driver/page/features/Taxi/taxi_dashboard/taxi_dashboard.dart';
import 'package:cabme_driver/page/MainDashBoard/widget/custom_drawer.dart';
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
import 'package:cabme_driver/page/auth_screens/phone_entry_screen.dart';
import 'package:cabme_driver/widget/StarRating.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';
import 'package:text_scroll/text_scroll.dart';
import 'package:url_launcher/url_launcher.dart';

class NewRideScreen extends StatefulWidget {
  final bool isTab;
  const NewRideScreen({super.key, this.isTab = false});

  @override
  State<NewRideScreen> createState() => _NewRideScreenState();
}

class _NewRideScreenState extends State<NewRideScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final controllerDashBoard = Get.put(DashBoardController());
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController resonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    resonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final bool isDark = themeChange.getThem();

    return GetX<NewRideController>(
      init: NewRideController(),
      builder: (controller) {
        final incomingRides = controller.rideList.where((r) {
          final s = (r.statut ?? '').toLowerCase().trim();
          return s == 'new' || s == 'requested';
        }).toList();

        final pendingRides = controller.rideList.where((r) {
          final s = (r.statut ?? '').toLowerCase().trim();
          final pay = (r.statutPaiement ?? '').toLowerCase().trim();
          return s == 'confirmed' || s == 'on ride' || s == 'on_ride' || s == 'started' || s == 'in_progress' || (s == 'completed' && pay != 'yes');
        }).toList();

        final completedRides = controller.rideList.where((r) {
          final s = (r.statut ?? '').toLowerCase().trim();
          final pay = (r.statutPaiement ?? '').toLowerCase().trim();
          return (s == 'completed' && pay == 'yes') || s == 'rejected' || s == 'canceled' || s == 'driver_rejected';
        }).toList();

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: isDark ? AppThemeData.surface50Dark : AppThemeData.surface50,
          appBar: widget.isTab
              ? null
              : AppBar(
                  backgroundColor: isDark ? AppThemeData.surface50Dark : AppThemeData.surface50,
                  elevation: 0,
                  titleSpacing: 16,
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Ride Bookings'.tr,
                        style: TextStyle(
                          color: isDark ? AppThemeData.grey900Dark : AppThemeData.grey900,
                          fontSize: 18,
                          fontFamily: AppThemeData.semiBold,
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: controllerDashBoard.isActive.value ? AppThemeData.success300 : AppThemeData.warning200,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            controllerDashBoard.isActive.value ? "Online".tr : "Offline".tr,
                            style: TextStyle(
                              color: controllerDashBoard.isActive.value ? AppThemeData.success300 : (isDark ? AppThemeData.grey500Dark : AppThemeData.grey500),
                              fontFamily: AppThemeData.medium,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Transform.scale(
                            scale: 0.8,
                            child: Switch(
                              value: controllerDashBoard.isActive.value,
                              activeColor: AppThemeData.success300,
                              inactiveTrackColor: AppThemeData.warning200,
                              onChanged: (value) async {
                                await controllerDashBoard.getUsrData();
                                if (controllerDashBoard.userModel.value.userData!.statutVehicule == "no") {
                                  showAlertDialog(context, "vehicleInformation");
                                } else if (controllerDashBoard.userModel.value.userData!.isVerified == "no" || controllerDashBoard.userModel.value.userData!.isVerified!.isEmpty) {
                                  showAlertDialog(context, "document");
                                } else {
                                  ShowToastDialog.showLoader("Please wait");
                                  Map<String, dynamic> bodyParams = {
                                    'id_driver': Preferences.getInt(Preferences.userId),
                                    'online': controllerDashBoard.isActive.value ? 'no' : 'yes',
                                  };
                                  await controllerDashBoard.changeOnlineStatus(bodyParams).then((val) {
                                    if (val != null && val['success'] == "success") {
                                      UserModel userModel = Constant.getUserData();
                                      userModel.userData!.online = val['data']['online'];
                                      controller.userModel.value = userModel;
                                      Preferences.setString(Preferences.user, jsonEncode(userModel.toJson()));
                                      controllerDashBoard.isActive.value = userModel.userData!.online == 'no' ? false : true;
                                      ShowToastDialog.showToast(val['message']);
                                    } else if (val != null) {
                                      ShowToastDialog.showToast(val['error']);
                                    }
                                  });
                                  ShowToastDialog.closeLoader();
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
          floatingActionButton: Visibility(
            visible: !widget.isTab,
            child: FloatingActionButton.extended(
              backgroundColor: AppThemeData.primary200,
              foregroundColor: Colors.white,
              onPressed: () async {
                if (!(Preferences.getBoolean(Preferences.isLogin) ?? false)) {
                  Get.to(() => PhoneEntryScreen(mode: 'signup'));
                  return;
                }
                if (Constant.selectedMapType == 'osm') {
                  Get.to(() => const CreateOsmRideScreen())?.then((v) {
                    controller.getNewRide();
                  });
                } else {
                  Get.to(() => const CreateRideScreen())?.then((v) {
                    controller.getNewRide();
                  });
                }
              },
              icon: const Icon(Icons.add_road_rounded, size: 20),
              label: Text(
                'Manual Trip'.tr,
                style: const TextStyle(fontSize: 13, fontFamily: AppThemeData.medium),
              ),
            ),
          ),
          drawer: widget.isTab ? null : const CustomDrawer(),
          body: Column(
            children: [
              // ── Top Segmented Tab Bar ──
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? AppThemeData.grey800 : AppThemeData.grey100,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                  indicator: BoxDecoration(
                    color: AppThemeData.primary200,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppThemeData.primary200.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: isDark ? AppThemeData.grey400Dark : AppThemeData.grey500,
                  labelStyle: const TextStyle(fontFamily: AppThemeData.semiBold, fontSize: 12),
                  unselectedLabelStyle: const TextStyle(fontFamily: AppThemeData.medium, fontSize: 12),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  tabs: [
                    Tab(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Incoming".tr),
                            if (incomingRides.isNotEmpty) ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  incomingRides.length.toString(),
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    Tab(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Pending".tr),
                            if (pendingRides.isNotEmpty) ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppThemeData.warning200,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  pendingRides.length.toString(),
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    Tab(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Completed".tr),
                            if (completedRides.isNotEmpty) ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: isDark ? AppThemeData.grey400Dark : AppThemeData.grey400,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  completedRides.length.toString(),
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Tab Views ──
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildRidesList(
                      context: context,
                      rides: incomingRides,
                      controller: controller,
                      isDark: isDark,
                      emptyMessage: "No incoming ride requests at the moment.\nStay online to receive instant trip alerts.".tr,
                      emptyIcon: Icons.notifications_none_rounded,
                      cardBuilder: (ride) => _buildIncomingCard(context, ride, controller, isDark),
                    ),
                    _buildRidesList(
                      context: context,
                      rides: pendingRides,
                      controller: controller,
                      isDark: isDark,
                      emptyMessage: "No pending or active rides in progress.".tr,
                      emptyIcon: Icons.directions_car_outlined,
                      cardBuilder: (ride) => _buildPendingCard(context, ride, controller, isDark),
                    ),
                    _buildRidesList(
                      context: context,
                      rides: completedRides,
                      controller: controller,
                      isDark: isDark,
                      emptyMessage: "No completed ride history yet.".tr,
                      emptyIcon: Icons.history_rounded,
                      cardBuilder: (ride) => _buildCompletedCard(context, ride, controller, isDark),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRidesList({
    required BuildContext context,
    required List<RideData> rides,
    required NewRideController controller,
    required bool isDark,
    required String emptyMessage,
    required IconData emptyIcon,
    required Widget Function(RideData) cardBuilder,
  }) {
    return RefreshIndicator(
      color: AppThemeData.primary200,
      onRefresh: () => controller.getNewRide(),
      child: controller.isLoading.value
          ? const Center(child: CircularProgressIndicator())
          : rides.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(height: Responsive.height(15, context)),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(emptyIcon, size: 54, color: isDark ? AppThemeData.grey400Dark : AppThemeData.grey400),
                          const SizedBox(height: 14),
                          Text(
                            emptyMessage,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isDark ? AppThemeData.grey500Dark : AppThemeData.grey500,
                              fontFamily: AppThemeData.regular,
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : ListView.builder(
                  padding: EdgeInsets.only(left: 16, right: 16, top: 8, bottom: widget.isTab ? 120 : 70),
                  itemCount: rides.length,
                  itemBuilder: (context, index) => cardBuilder(rides[index]),
                ),
    );
  }

  Widget _buildIncomingCard(BuildContext context, RideData data, NewRideController controller, bool isDark) {
    final fareStr = Constant().amountShow(amount: data.montant.toString());
    final distanceStr = '${double.tryParse(data.distance.toString())?.toStringAsFixed(1) ?? data.distance ?? "0"} ${Constant.distanceUnit}';
    final durationStr = data.duree?.toString() ?? "";

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? AppThemeData.surface50Dark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppThemeData.grey800 : AppThemeData.grey200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: CachedNetworkImage(
                    imageUrl: data.photoPath.toString(),
                    height: 44,
                    width: 44,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(color: Colors.grey.shade200),
                    errorWidget: (context, url, error) => Image.asset("assets/images/appIcon.png", width: 44, height: 44),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${data.prenom ?? ''} ${data.nom ?? ''}'.trim().isEmpty ? 'Passenger'.tr : '${data.prenom ?? ''} ${data.nom ?? ''}'.trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppThemeData.semiBold,
                          fontSize: 15,
                          color: isDark ? AppThemeData.grey900Dark : AppThemeData.grey900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          StarRating(
                            size: 13,
                            rating: double.tryParse(data.moyenneDriver.toString()) ?? 5.0,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            (double.tryParse(data.moyenneDriver.toString()) ?? 5.0).toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppThemeData.grey400Dark : AppThemeData.grey500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppThemeData.primary200.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    fareStr,
                    style: TextStyle(
                      fontFamily: AppThemeData.bold,
                      fontSize: 15,
                      color: AppThemeData.primary200,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _buildRouteSnippet(data.departName ?? '', data.destinationName ?? '', isDark),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _buildMetricChip(Icons.straighten_rounded, distanceStr, isDark),
                if (durationStr.isNotEmpty)
                  _buildMetricChip(Icons.access_time_rounded, durationStr, isDark),
                _buildMetricChip(Icons.people_outline_rounded, "${data.numberPoeple ?? '1'} Rider".tr, isDark),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: OutlinedButton(
                    onPressed: () => buildShowBottomSheet(context, data, controller, isDark),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppThemeData.error200,
                      side: BorderSide(color: AppThemeData.error200.withValues(alpha: 0.5)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(
                      "Reject".tr,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () async {
                      ShowToastDialog.showLoader("Accepting ride...");
                      Map<String, String> bodyParams = {
                        'id_ride': data.id.toString(),
                        'id_user': data.idUserApp.toString(),
                        'driver_name': '${data.prenomConducteur ?? ''} ${data.nomConducteur ?? ''}'.trim(),
                        'driver_phone': data.driverPhone.toString(),
                        'from_id': Preferences.getInt(Preferences.userId).toString(),
                      };
                      final res = await controller.confirmedRide(bodyParams);
                      ShowToastDialog.closeLoader();
                      controller.getNewRide();
                      if (res != null) {
                        data.statut = "confirmed";
                        var argumentData = {'type': 'confirmed', 'data': data};
                        if (Constant.liveTrackingMapType == "inappmap") {
                          if (Constant.selectedMapType == 'osm') {
                            Get.to(() => const RouteOsmViewScreen(), arguments: argumentData);
                          } else {
                            Get.to(() => const RouteViewScreen(), arguments: argumentData);
                          }
                        } else {
                          Constant.redirectMap(
                            latitude: double.tryParse(data.latitudeDepart ?? '0') ?? 0,
                            longLatitude: double.tryParse(data.longitudeDepart ?? '0') ?? 0,
                            name: data.departName ?? 'Pickup Location',
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppThemeData.primary200,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 1,
                    ),
                    child: Text(
                      "Accept Ride".tr,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingCard(BuildContext context, RideData data, NewRideController controller, bool isDark) {
    final bool isOnRide = data.statut == "on ride" || data.statut == "on_ride";
    final fareStr = Constant().amountShow(amount: data.montant.toString());

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? AppThemeData.surface50Dark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOnRide
              ? AppThemeData.warning200.withValues(alpha: 0.4)
              : AppThemeData.primary200.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isOnRide
                          ? AppThemeData.warning200.withValues(alpha: 0.15)
                          : AppThemeData.primary200.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isOnRide ? "On Ride — In Progress".tr : "Confirmed — Ready for Pickup".tr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppThemeData.bold,
                        fontSize: 12,
                        color: isOnRide ? AppThemeData.warning200 : AppThemeData.primary200,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    if (data.phone != null && data.phone!.isNotEmpty) {
                      Constant.makePhoneCall(data.phone!);
                    }
                  },
                  icon: const Icon(Icons.phone_rounded, color: Colors.green, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${data.prenom ?? ''} ${data.nom ?? ''}'.trim().isEmpty ? 'Passenger'.tr : '${data.prenom ?? ''} ${data.nom ?? ''}'.trim(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppThemeData.semiBold,
                      fontSize: 16,
                      color: isDark ? AppThemeData.grey900Dark : AppThemeData.grey900,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  fareStr,
                  style: TextStyle(
                    fontFamily: AppThemeData.bold,
                    fontSize: 16,
                    color: isDark ? AppThemeData.grey900Dark : AppThemeData.grey900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildRouteSnippet(data.departName ?? '', data.destinationName ?? '', isDark),
            const SizedBox(height: 16),
            if (!isOnRide) ...[
              ElevatedButton.icon(
                onPressed: () async {
                  var argumentData = {'type': 'confirmed', 'data': data};
                  if (Constant.liveTrackingMapType == "inappmap") {
                    if (Constant.selectedMapType == 'osm') {
                      await Get.to(() => const RouteOsmViewScreen(), arguments: argumentData);
                    } else {
                      await Get.to(() => const RouteViewScreen(), arguments: argumentData);
                    }
                    controller.getNewRide();
                  } else {
                    Constant.redirectMap(
                      latitude: double.tryParse(data.latitudeDepart ?? '0') ?? 0,
                      longLatitude: double.tryParse(data.longitudeDepart ?? '0') ?? 0,
                      name: data.departName ?? 'Pickup Location',
                    );
                  }
                },
                icon: const Icon(Icons.navigation_rounded, color: Colors.white, size: 18),
                label: Text(
                  "Navigate to Pickup".tr,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppThemeData.primary200,
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => _showStartRideOtpModal(context, data, controller, isDark),
                icon: Icon(Icons.key_rounded, color: isDark ? AppThemeData.grey900Dark : AppThemeData.grey900, size: 18),
                label: Text(
                  "START RIDE (Enter OTP)".tr,
                  style: TextStyle(
                    color: isDark ? AppThemeData.grey900Dark : AppThemeData.grey900,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(46),
                  side: BorderSide(color: isDark ? AppThemeData.grey200Dark : AppThemeData.grey300),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () => buildShowBottomSheet(context, data, controller, isDark),
                  child: Text(
                    "Cancel Trip".tr,
                    style: TextStyle(color: AppThemeData.error200, fontSize: 12),
                  ),
                ),
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        if (Constant.liveTrackingMapType == "inappmap") {
                          var argumentData = {'type': data.statut, 'data': data};
                          if (Constant.selectedMapType == 'osm') {
                            await Get.to(const RouteOsmViewScreen(), arguments: argumentData);
                          } else {
                            await Get.to(const RouteViewScreen(), arguments: argumentData);
                          }
                          controller.getNewRide();
                        } else {
                          Constant.redirectMap(
                            latitude: double.tryParse(data.latitudeArrivee ?? '0') ?? 0,
                            longLatitude: double.tryParse(data.longitudeArrivee ?? '0') ?? 0,
                            name: data.destinationName ?? '',
                          );
                        }
                      },
                      icon: const Icon(Icons.navigation_rounded, size: 16),
                      label: Text("Navigate".tr),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        void openPaymentCollection() {
                          Get.to(() => PaymentCollectionScreen(
                            rideData: data,
                            onConfirm: (String paymethod) {
                              if (paymethod.toLowerCase() == "cash") {
                                controller.cashPaymentRequest(data, paymethod: "Cash").then((cashVal) {
                                  if (cashVal != null) {
                                    Get.back();
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return CustomDialogBox(
                                          title: "Completed Successfully".tr,
                                          descriptions: "Cash payment collected successfully.".tr,
                                          text: "Ok".tr,
                                          onPress: () {
                                            Get.back();
                                            controller.getNewRide();
                                            _tabController.animateTo(2);
                                          },
                                          img: Image.asset('assets/images/green_checked.png'),
                                        );
                                      },
                                    );
                                  }
                                });
                              } else {
                                Get.back();
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return CustomDialogBox(
                                      title: "Completed Successfully".tr,
                                      descriptions: "Ride successfully completed.".tr,
                                      text: "Ok".tr,
                                      onPress: () {
                                        Get.back();
                                        controller.getNewRide();
                                        _tabController.animateTo(2);
                                      },
                                      img: Image.asset('assets/images/green_checked.png'),
                                    );
                                  },
                                );
                              }
                            },
                          ));
                        }

                        if ((data.statut ?? '').toLowerCase().trim() == 'completed') {
                          openPaymentCollection();
                        } else {
                          Map<String, String> bodyParams = {
                            'id_ride': data.id.toString(),
                            'id_user': data.idUserApp.toString(),
                            'driver_name': '${data.prenomConducteur ?? ''} ${data.nomConducteur ?? ''}'.trim(),
                            'from_id': Preferences.getInt(Preferences.userId).toString(),
                          };
                          controller.setCompletedRequest(bodyParams, data, paymethod: "Pending").then((value) {
                            if (value != null) {
                              openPaymentCollection();
                            }
                          });
                        }
                      },
                      icon: Icon(
                        (data.statut ?? '').toLowerCase().trim() == 'completed' ? Icons.payments_rounded : Icons.check_circle_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                      label: Text(
                        (data.statut ?? '').toLowerCase().trim() == 'completed' ? "COLLECT CASH".tr : "COMPLETE".tr,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: (data.statut ?? '').toLowerCase().trim() == 'completed' ? AppThemeData.primary200 : AppThemeData.success300,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompletedCard(BuildContext context, RideData data, NewRideController controller, bool isDark) {
    final fareStr = Constant().amountShow(amount: data.montant.toString());
    final isCompleted = data.statut == "completed";

    return InkWell(
      onTap: () async {
        if (isCompleted) {
          var isDone = await Get.to(const TripHistoryScreen(), arguments: {
            "rideData": data,
          });
          if (isDone != null) {
            controller.getNewRide();
          }
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: isDark ? AppThemeData.surface50Dark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppThemeData.grey800 : AppThemeData.grey200,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? AppThemeData.success300.withValues(alpha: 0.12)
                          : AppThemeData.error200.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      Constant().capitalizeWords(data.statut ?? 'Completed'),
                      style: TextStyle(
                        fontFamily: AppThemeData.bold,
                        fontSize: 12,
                        color: isCompleted ? AppThemeData.success300 : AppThemeData.error200,
                      ),
                    ),
                  ),
                  Text(
                    data.dateRetour ?? data.creer ?? '',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppThemeData.grey400Dark : AppThemeData.grey500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${data.prenom ?? ''} ${data.nom ?? ''}'.trim().isEmpty ? 'Passenger'.tr : '${data.prenom ?? ''} ${data.nom ?? ''}'.trim(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppThemeData.semiBold,
                        fontSize: 15,
                        color: isDark ? AppThemeData.grey900Dark : AppThemeData.grey900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    fareStr,
                    style: TextStyle(
                      fontFamily: AppThemeData.bold,
                      fontSize: 16,
                      color: isCompleted ? AppThemeData.success300 : (isDark ? AppThemeData.grey400Dark : AppThemeData.grey500),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildRouteSnippet(data.departName ?? '', data.destinationName ?? '', isDark),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Payment: ${data.statutPaiement == 'yes' ? 'Settled' : 'Pending'}".tr,
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: AppThemeData.medium,
                      color: isDark ? AppThemeData.grey400Dark : AppThemeData.grey500,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        "Trip Details".tr,
                        style: TextStyle(
                          fontSize: 13,
                          fontFamily: AppThemeData.semiBold,
                          color: AppThemeData.primary200,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.chevron_right_rounded, size: 18, color: AppThemeData.primary200),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRouteSnippet(String pickup, String dropoff, bool isDark) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 3),
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                pickup.isEmpty ? "Pickup location".tr : pickup,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppThemeData.grey900Dark : AppThemeData.grey900,
                  fontFamily: AppThemeData.medium,
                ),
              ),
            ),
          ],
        ),
        Container(
          margin: const EdgeInsets.only(left: 4),
          height: 14,
          width: 2,
          color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 3),
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.redAccent,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                dropoff.isEmpty ? "Destination location".tr : dropoff,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppThemeData.grey900Dark : AppThemeData.grey900,
                  fontFamily: AppThemeData.medium,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricChip(IconData icon, String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppThemeData.grey800 : AppThemeData.grey100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: isDark ? AppThemeData.grey400Dark : AppThemeData.grey500),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontFamily: AppThemeData.medium,
              color: isDark ? AppThemeData.grey400Dark : AppThemeData.grey500,
            ),
          ),
        ],
      ),
    );
  }

  void _showStartRideOtpModal(BuildContext context, RideData data, NewRideController controller, bool isDark) {
    controller.otpController.clear();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: isDark ? AppThemeData.surface50Dark : Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.shield_outlined, size: 40, color: AppThemeData.primary200),
                const SizedBox(height: 12),
                Text(
                  "Enter Ride OTP".tr,
                  style: const TextStyle(fontFamily: AppThemeData.bold, fontSize: 18),
                ),
                const SizedBox(height: 6),
                Text(
                  "Ask passenger for the 6-digit OTP to start trip".tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: isDark ? AppThemeData.grey400Dark : AppThemeData.grey500),
                ),
                const SizedBox(height: 20),
                Pinput(
                  controller: controller.otpController,
                  length: 6,
                  keyboardType: TextInputType.number,
                  defaultPinTheme: PinTheme(
                    width: 42,
                    height: 48,
                    textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: isDark ? AppThemeData.grey800 : AppThemeData.grey100,
                      border: Border.all(color: AppThemeData.textFieldBoarderColor),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Get.back(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text("Cancel".tr),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final otp = controller.otpController.text.trim();
                          if (otp.length == 6) {
                            ShowToastDialog.showLoader("Verifying OTP...");
                            final res = await controller.verifyOTP(
                              userId: data.idUserApp!.toString(),
                              rideId: data.id!.toString(),
                            );
                            ShowToastDialog.closeLoader();
                            if (res != null && res['success'] == "success") {
                              Map<String, String> bodyParams = {
                                'id_ride': data.id.toString(),
                                'id_user': data.idUserApp.toString(),
                                'use_name': '${data.prenomConducteur ?? ''} ${data.nomConducteur ?? ''}'.trim(),
                                'from_id': Preferences.getInt(Preferences.userId).toString(),
                              };
                              final onRideRes = await controller.setOnRideRequest(bodyParams);
                              if (onRideRes != null) {
                                Get.back();
                                ShowToastDialog.showToast("Trip started successfully");
                                controller.getNewRide();
                              }
                            } else {
                              ShowToastDialog.showToast(res?['error'] ?? "Invalid OTP, please try again".tr);
                            }
                          } else {
                            ShowToastDialog.showToast("Please enter complete 6-digit OTP".tr);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppThemeData.primary200,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(
                          "Verify & Start".tr,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<dynamic> buildShowBottomSheet(BuildContext context, RideData data, NewRideController controller, bool isDark) {
    resonController.clear();
    return showModalBottomSheet(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppThemeData.surface50Dark : Colors.white,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Cancel Trip".tr,
                style: const TextStyle(fontSize: 18, fontFamily: AppThemeData.bold),
              ),
              const SizedBox(height: 6),
              Text(
                "Please provide a reason for cancelling this trip request:".tr,
                style: TextStyle(fontSize: 13, color: isDark ? AppThemeData.grey400Dark : AppThemeData.grey500),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: resonController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "Reason for cancellation...".tr,
                  filled: true,
                  fillColor: isDark ? AppThemeData.grey800 : AppThemeData.grey100,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text("Keep Trip".tr),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (resonController.text.trim().isEmpty) {
                          ShowToastDialog.showToast("Please enter a cancellation reason".tr);
                          return;
                        }
                        ShowToastDialog.showLoader("Cancelling trip...");
                        Map<String, String> bodyParams = {
                          'id_ride': data.id.toString(),
                          'id_user': data.idUserApp.toString(),
                          'name': '${data.prenomConducteur ?? ''} ${data.nomConducteur ?? ''}'.trim(),
                          'from_id': Preferences.getInt(Preferences.userId).toString(),
                          'other_info': resonController.text.trim(),
                        };
                        await controller.canceledRide(bodyParams);
                        ShowToastDialog.closeLoader();
                        Get.back();
                        controller.getNewRide();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppThemeData.error200,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        "Confirm Cancel".tr,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
