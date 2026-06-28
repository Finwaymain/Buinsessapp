import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:geocoding/geocoding.dart';

import 'package:cabme_driver/constant/constant.dart';
import 'package:cabme_driver/constant/show_toast_dialog.dart';
import 'package:cabme_driver/controller/dash_board_controller.dart';
import 'package:cabme_driver/controller/parcel_order_controller.dart';
import 'package:cabme_driver/controller/parcel_service_controller.dart';
import 'package:cabme_driver/model/parcel_model.dart';
import 'package:cabme_driver/page/parcel_service/all_parcel_screen.dart';
import 'package:cabme_driver/page/parcel_service/parcel_details_screen.dart';
import 'package:cabme_driver/page/parcel_service/parcel_osm_route_view_screen.dart';
import 'package:cabme_driver/page/parcel_service/parcel_route_view_screen.dart';
import 'package:cabme_driver/page/parcel_service/search_parcel_screen.dart';
import 'package:cabme_driver/themes/app_bar_custom.dart';
import 'package:cabme_driver/themes/button_them.dart';
import 'package:cabme_driver/themes/constant_colors.dart';
import 'package:cabme_driver/themes/custom_widget.dart';
import 'package:cabme_driver/utils/Preferences.dart';
import 'package:cabme_driver/utils/dark_theme_provider.dart';

class ParcelConsoleScreen extends StatefulWidget {
  const ParcelConsoleScreen({super.key});

  @override
  State<ParcelConsoleScreen> createState() => _ParcelConsoleScreenState();
}

class _ParcelConsoleScreenState extends State<ParcelConsoleScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final serviceController = Get.put(ParcelServiceController());
  final orderController = Get.put(ParcelOrderController());
  final dashboardController = Get.find<DashBoardController>();

  Timer? _pollingTimer;
  String _currentCity = "";
  final Set<String> _ignoredParcelIds = {};
  bool _isPolling = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _resolveCurrentCity().then((_) {
      _startPolling();
    });
    orderController.getParcel();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _resolveCurrentCity() async {
    if (Constant.currentLocation != null) {
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          Constant.currentLocation!.latitude!,
          Constant.currentLocation!.longitude!,
        );
        if (placemarks.isNotEmpty) {
          setState(() {
            _currentCity = placemarks.first.locality ?? 
                           placemarks.first.subAdministrativeArea ?? 
                           "";
          });
        }
      } catch (e) {
        debugPrint("Geocoding failed: $e");
      }
    }
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 6), (timer) {
      if (!mounted) return;
      // Only poll if the driver is online in the app
      if (dashboardController.isActive.value && _tabController.index == 0) {
        _fetchRequests();
      }
    });
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    if (_isPolling) return;
    setState(() {
      _isPolling = true;
    });

    final lat = Constant.currentLocation?.latitude ?? "";
    final lng = Constant.currentLocation?.longitude ?? "";
    final driverId = Preferences.getInt(Preferences.userId).toString();

    // Query parameters
    final urlParams = "?source_lat=$lat"
                      "&source_lng=$lng"
                      "&driver_id=$driverId"
                      "&source_city=$_currentCity";

    try {
      await serviceController.searchParcel(urlParams);
      // Trigger a vibration if there's any new active parcel request
      final activeRequests = serviceController.searchParcelList.where((p) {
        return p.status == "new" && !_ignoredParcelIds.contains(p.id.toString());
      }).toList();

      if (activeRequests.isNotEmpty) {
        HapticFeedback.lightImpact();
      }
    } catch (e) {
      debugPrint("Error fetching parcel requests: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isPolling = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.getThem();

    return Scaffold(
      backgroundColor: isDark ? AppThemeData.surface50Dark : AppThemeData.surface50,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(110.0),
        child: Column(
          children: [
            AppbarCustom(title: 'Parcel Console'.tr),
            Container(
              color: isDark ? AppThemeData.surface50Dark : AppThemeData.surface50,
              child: TabBar(
                controller: _tabController,
                indicatorColor: AppThemeData.primary200,
                labelColor: AppThemeData.primary200,
                unselectedLabelColor: isDark ? Colors.grey[400] : Colors.grey[600],
                indicatorWeight: 3.0,
                onTap: (index) {
                  if (index == 0) {
                    _startPolling();
                  } else {
                    _pollingTimer?.cancel();
                    orderController.getParcel();
                  }
                  setState(() {});
                },
                tabs: [
                  Tab(text: 'Incoming Requests'.tr),
                  Tab(text: 'My Active Orders'.tr),
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildIncomingRequestsTab(isDark, themeChange),
          _buildMyOrdersTab(isDark, themeChange),
        ],
      ),
    );
  }

  Widget _buildIncomingRequestsTab(bool isDark, DarkThemeProvider themeChange) {
    return Obx(() {
      final activeRequests = serviceController.searchParcelList.where((p) {
        return p.status == "new" && !_ignoredParcelIds.contains(p.id.toString());
      }).toList();

      if (!dashboardController.isActive.value) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.portable_wifi_off,
                size: 64,
                color: isDark ? Colors.grey[600] : Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                "You are currently Offline".tr,
                style: TextStyle(
                  fontSize: 18,
                  fontFamily: AppThemeData.semiBold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Go online on the dashboard to receive requests.".tr,
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: AppThemeData.regular,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ),
        );
      }

      if (activeRequests.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                height: 300,
                child: ScanningRadar(),
              ),
              const SizedBox(height: 24),
              Text(
                "Scanning for Parcel Deliveries...".tr,
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: AppThemeData.medium,
                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                ),
              ),
              if (_currentCity.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  "City: $_currentCity",
                  style: TextStyle(
                    fontSize: 13,
                    fontFamily: AppThemeData.regular,
                    color: isDark ? Colors.grey[500] : Colors.grey[500],
                  ),
                ),
              ],
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: activeRequests.length,
        itemBuilder: (context, index) {
          final parcel = activeRequests[index];
          return _buildRequestCard(parcel, isDark, themeChange);
        },
      );
    });
  }

  Widget _buildRequestCard(ParcelData parcel, bool isDark, DarkThemeProvider themeChange) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppThemeData.surface50Dark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(
          color: isDark ? AppThemeData.grey200Dark.withOpacity(0.5) : AppThemeData.grey200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with price / distance
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppThemeData.primary200.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "New Parcel Delivery".tr,
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: AppThemeData.semiBold,
                        color: AppThemeData.primary200,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Type: ${parcel.parcelType ?? 'General'}".tr,
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: AppThemeData.regular,
                        color: isDark ? Colors.grey[300] : Colors.grey[700],
                      ),
                    ),
                  ],
                ),
                Text(
                  Constant().amountShow(amount: parcel.amount.toString()),
                  style: TextStyle(
                    fontSize: 20,
                    fontFamily: AppThemeData.bold,
                    color: AppThemeData.new200,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sender / Receiver Locations
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Icon(Icons.circle, size: 12, color: AppThemeData.primary200),
                        Container(
                          width: 2,
                          height: 40,
                          color: Colors.grey[400],
                        ),
                        const Icon(Icons.location_on, size: 16, color: Colors.red),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Pickup".tr,
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: AppThemeData.bold,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                          Text(
                            parcel.source ?? "",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontFamily: AppThemeData.medium,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            "Dropoff".tr,
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: AppThemeData.bold,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                          Text(
                            parcel.destination ?? "",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontFamily: AppThemeData.medium,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                // Weight and size details
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSpecItem(Icons.scale_outlined, "Weight".tr, "${parcel.parcelWeight ?? '0'} kg", isDark),
                    _buildSpecItem(Icons.straighten_outlined, "Size".tr, "${parcel.parcelDimension ?? '-'} ft", isDark),
                    _buildSpecItem(Icons.navigation_outlined, "Dist".tr, "${double.parse(parcel.distance.toString()).toStringAsFixed(1)} ${parcel.distanceUnit}", isDark),
                  ],
                ),
                const SizedBox(height: 20),
                // Accept / Decline Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () {
                          setState(() {
                            _ignoredParcelIds.add(parcel.id.toString());
                          });
                        },
                        child: Text(
                          "Decline".tr,
                          style: TextStyle(
                            fontFamily: AppThemeData.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppThemeData.primary200,
                          foregroundColor: isDark ? AppThemeData.grey900Dark : AppThemeData.grey900,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () async {
                          Map<String, String> bodyParams = {
                            "id_parcel": parcel.id.toString(),
                            "id_user": parcel.idUserApp.toString(),
                            "driver_name": "${serviceController.userModel!.userData!.prenom} ${serviceController.userModel!.userData!.nom}",
                            "driver_id": Preferences.getInt(Preferences.userId).toString(),
                          };
                          final res = await serviceController.confirmedParcel(bodyParams);
                          if (res != null) {
                            ShowToastDialog.showToast(res['message'] ?? 'Parcel Accepted Successfully'.tr);
                            _tabController.animateTo(1);
                            orderController.getParcel();
                          }
                        },
                        child: Text(
                          "Accept".tr,
                          style: TextStyle(
                            fontFamily: AppThemeData.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSpecItem(IconData icon, String label, String val, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppThemeData.primary200),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontFamily: AppThemeData.regular,
              ),
            ),
            Text(
              val,
              style: TextStyle(
                fontSize: 12,
                fontFamily: AppThemeData.semiBold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildMyOrdersTab(bool isDark, DarkThemeProvider themeChange) {
    return Obx(() {
      if (orderController.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      final orders = orderController.parcelList;
      if (orders.isEmpty) {
        return Center(
          child: Text(
            "You don't have any parcel orders confirmed.".tr,
            style: TextStyle(
              fontSize: 14,
              fontFamily: AppThemeData.regular,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        );
      }
      return RefreshIndicator(
        onRefresh: () => orderController.getParcel(),
        child: ListView.builder(
          padding: const EdgeInsets.only(bottom: 24),
          physics: const BouncingScrollPhysics(),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            return _buildMyOrderHistoryItem(context, order, isDark);
          },
        ),
      );
    });
  }

  Widget _buildMyOrderHistoryItem(BuildContext context, ParcelData data, bool isDarkMode) {
    return GestureDetector(
      onTap: () async {
        if (data.status == "completed") {
          var isDone = await Get.to(const ParcelDetailsScreen(), arguments: {
            "parcelData": data,
          });
          if (isDone != null) {
            orderController.getParcel();
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
          color: isDarkMode ? AppThemeData.surface50Dark : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            )
          ],
          border: Border.all(
            color: isDarkMode ? AppThemeData.grey200Dark.withOpacity(0.3) : AppThemeData.grey200,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: Container(
                    margin: const EdgeInsets.only(right: 16, left: 16),
                    width: 110,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Constant.statusParcelColor(data),
                      borderRadius: BorderRadius.circular(6),
                    ),
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
                            const SizedBox(height: 10),
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
                          Text(
                            "${double.parse(data.distance.toString()).toStringAsFixed(1)} ${data.distanceUnit}",
                            style: TextStyle(
                              fontFamily: AppThemeData.semiBold,
                              color: AppThemeData.new200,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 2),
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
                            Text(
                              data.duration.toString(),
                              style: TextStyle(
                                fontFamily: AppThemeData.semiBold,
                                color: AppThemeData.new200,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 2),
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
                            Text(
                              Constant().amountShow(amount: data.amount.toString()),
                              maxLines: 1,
                              style: TextStyle(
                                fontFamily: AppThemeData.semiBold,
                                color: AppThemeData.new200,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text('Price'.tr,
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
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ScanningRadar extends StatefulWidget {
  const ScanningRadar({super.key});

  @override
  State<ScanningRadar> createState() => _ScanningRadarState();
}

class _ScanningRadarState extends State<ScanningRadar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.getThem();
    final baseColor = AppThemeData.primary200.withOpacity(0.12);

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          ...List.generate(3, (index) {
            return AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                double progress = (_controller.value + (index / 3)) % 1.0;
                double opacity = (1.0 - progress) * 0.5;
                double size = 80.0 + (progress * 180.0);
                return Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: baseColor.withOpacity(opacity),
                    border: Border.all(
                      color: AppThemeData.primary200.withOpacity(opacity * 0.4),
                      width: 1.5,
                    ),
                  ),
                );
              },
            );
          }),
          Container(
            width: 85,
            height: 85,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppThemeData.primary200,
              boxShadow: [
                BoxShadow(
                  color: AppThemeData.primary200.withOpacity(0.3),
                  blurRadius: 12,
                  spreadRadius: 2,
                )
              ],
            ),
            child: Icon(
              Icons.local_shipping_outlined,
              color: isDark ? AppThemeData.grey900 : AppThemeData.grey900Dark,
              size: 34,
            ),
          )
        ],
      ),
    );
  }
}
