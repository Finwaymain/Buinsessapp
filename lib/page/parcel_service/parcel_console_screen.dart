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
import 'package:cabme_driver/model/food_order_model.dart';
import 'package:cabme_driver/model/parcel_model.dart';
import 'package:cabme_driver/page/parcel_service/parcel_details_screen.dart';
import 'package:cabme_driver/page/parcel_service/parcel_osm_route_view_screen.dart';
import 'package:cabme_driver/page/parcel_service/parcel_route_view_screen.dart';
import 'package:cabme_driver/page/parcel_service/search_parcel_screen.dart';
import 'package:cabme_driver/service/food_rider_service.dart';
import 'package:cabme_driver/themes/app_bar_custom.dart';
import 'package:cabme_driver/themes/constant_colors.dart';
import 'package:cabme_driver/themes/custom_widget.dart';
import 'package:cabme_driver/utils/Preferences.dart';
import 'package:cabme_driver/utils/dark_theme_provider.dart';
import 'package:cabme_driver/utils/driver_dashboard_route.dart';

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
  final Set<String> _ignoredFoodOrderIds = {};
  List<FoodOrderData> _foodIncomingOrders = [];
  List<FoodOrderData> _foodActiveOrders = [];
  bool _isPolling = false;
  bool _isFoodRider = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final userData = dashboardController.userModel.value.userData;
    _isFoodRider = isDeliveryConsoleDriver(userData);

    _resolveCurrentCity().then((_) {
      _startPolling();
    });
    _fetchActiveOrders();
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

    final lat = Constant.currentLocation?.latitude;
    final lng = Constant.currentLocation?.longitude;
    final driverId = Preferences.getInt(Preferences.userId).toString();

    final urlParams = "?source_lat=${lat ?? ''}"
                      "&source_lng=${lng ?? ''}"
                      "&driver_id=$driverId"
                      "&source_city=$_currentCity";

    try {
      await serviceController.searchParcel(urlParams, quiet: true);

      if (_isFoodRider) {
        final incomingFood = await FoodRiderService.getIncomingOrders(
          lat: lat,
          lng: lng,
          radiusKm: 15.0,
        );
        if (mounted) {
          setState(() {
            _foodIncomingOrders = incomingFood;
          });
        }
      }

      final activeParcels = serviceController.searchParcelList.where((p) {
        return p.status == "new" && !_ignoredParcelIds.contains(p.id.toString());
      }).toList();

      final activeFood = _foodIncomingOrders.where((f) {
        return !_ignoredFoodOrderIds.contains(f.id.toString());
      }).toList();

      if (activeParcels.isNotEmpty || activeFood.isNotEmpty) {
        HapticFeedback.lightImpact();
      }
    } catch (e) {
      debugPrint("Error fetching requests: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isPolling = false;
        });
      }
    }
  }

  Future<void> _fetchActiveOrders() async {
    await orderController.getParcel();
    if (_isFoodRider) {
      final active = await FoodRiderService.getActiveOrders(Preferences.getInt(Preferences.userId));
      if (mounted) {
        setState(() {
          _foodActiveOrders = active;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.getThem();
    final consoleTitle = _isFoodRider ? 'Delivery Console'.tr : 'Parcel Console'.tr;

    return Scaffold(
      backgroundColor: isDark ? AppThemeData.surface50Dark : AppThemeData.surface50,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(110.0),
        child: Column(
          children: [
            AppbarCustom(title: consoleTitle),
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
                    _fetchActiveOrders();
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
      final activeParcels = serviceController.searchParcelList.where((p) {
        return p.status == "new" && !_ignoredParcelIds.contains(p.id.toString());
      }).toList();

      final activeFood = _foodIncomingOrders.where((f) {
        return !_ignoredFoodOrderIds.contains(f.id.toString());
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

      if (activeParcels.isEmpty && activeFood.isEmpty) {
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
                _isFoodRider 
                    ? "Scanning for Parcel & Food Deliveries...".tr
                    : "Scanning for Parcel Deliveries...".tr,
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

      final totalItems = activeFood.length + activeParcels.length;

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: totalItems,
        itemBuilder: (context, index) {
          if (index < activeFood.length) {
            final food = activeFood[index];
            return _buildFoodRequestCard(food, isDark, themeChange);
          } else {
            final parcel = activeParcels[index - activeFood.length];
            return _buildRequestCard(parcel, isDark, themeChange);
          }
        },
      );
    });
  }

  Widget _buildFoodRequestCard(FoodOrderData food, bool isDark, DarkThemeProvider themeChange) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppThemeData.surface50Dark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(
          color: isDark ? AppThemeData.grey200Dark.withValues(alpha: 0.5) : AppThemeData.grey200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.12),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange[800],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.delivery_dining, size: 16, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            "FOOD ORDER".tr,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "#${food.orderNumber ?? ''}",
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: AppThemeData.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
                Text(
                  Constant().amountShow(amount: (food.deliveryCharge ?? 0).toString()),
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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        const Icon(Icons.restaurant, size: 16, color: Colors.orange),
                        Container(
                          width: 2,
                          height: 44,
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
                            "Pick up from".tr,
                            style: TextStyle(
                              fontSize: 11,
                              fontFamily: AppThemeData.bold,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                          Text(
                            food.restaurant?.name ?? "Restaurant",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontFamily: AppThemeData.bold,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          Text(
                            food.restaurant?.address ?? "",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: AppThemeData.regular,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            "Deliver to customer".tr,
                            style: TextStyle(
                              fontSize: 11,
                              fontFamily: AppThemeData.bold,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                          Text(
                            food.deliveryAddress ?? "",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontFamily: AppThemeData.medium,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          if (food.deliveryLandmark != null && food.deliveryLandmark!.isNotEmpty)
                            Text(
                              "Near ${food.deliveryLandmark!}",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontFamily: AppThemeData.regular,
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.fastfood_outlined, size: 16, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        food.itemsSummary,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontFamily: AppThemeData.medium,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSpecItem(
                      Icons.navigation_outlined, 
                      "Pickup Distance".tr, 
                      "${food.pickupDistanceKm != null ? food.pickupDistanceKm!.toStringAsFixed(1) : '0.0'} km", 
                      isDark
                    ),
                    _buildSpecItem(
                      Icons.payments_outlined, 
                      "Payment".tr, 
                      food.paymentMethod?.toUpperCase() ?? "COD", 
                      isDark
                    ),
                    _buildSpecItem(
                      Icons.receipt_long_outlined, 
                      "Order Value".tr, 
                      Constant().amountShow(amount: (food.customerPayable ?? 0).toString()), 
                      isDark
                    ),
                  ],
                ),
                const SizedBox(height: 20),
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
                            _ignoredFoodOrderIds.add(food.id.toString());
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
                          backgroundColor: Colors.orange[700],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () async {
                          ShowToastDialog.showLoader("Accepting order...".tr);
                          final user = dashboardController.userModel.value.userData;
                          final riderId = Preferences.getInt(Preferences.userId);
                          final riderName = "${user?.prenom ?? ''} ${user?.nom ?? ''}".trim();
                          final riderPhone = user?.phone ?? '';

                          final res = await FoodRiderService.acceptOrder(
                            food.id!,
                            riderId: riderId,
                            riderName: riderName.isNotEmpty ? riderName : "Rider",
                            riderPhone: riderPhone,
                          );
                          ShowToastDialog.closeLoader();

                          if (res != null && res['success'] == true) {
                            ShowToastDialog.showToast("Order accepted! Head to the restaurant.".tr);
                            _tabController.animateTo(1);
                            _fetchActiveOrders();
                          } else {
                            ShowToastDialog.showToast(res?['error'] ?? "Failed to accept order".tr);
                          }
                        },
                        child: Text(
                          "Accept Food Order".tr,
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

  Widget _buildRequestCard(ParcelData parcel, bool isDark, DarkThemeProvider themeChange) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppThemeData.surface50Dark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(
          color: isDark ? AppThemeData.grey200Dark.withValues(alpha: 0.5) : AppThemeData.grey200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppThemeData.primary200.withValues(alpha: 0.1),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSpecItem(Icons.scale_outlined, "Weight".tr, "${parcel.parcelWeight ?? '0'} kg", isDark),
                    _buildSpecItem(Icons.straighten_outlined, "Size".tr, "${parcel.parcelDimension ?? '-'} ft", isDark),
                    _buildSpecItem(Icons.navigation_outlined, "Dist".tr, "${double.parse(parcel.distance.toString()).toStringAsFixed(1)} ${parcel.distanceUnit}", isDark),
                  ],
                ),
                const SizedBox(height: 20),
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
                            _fetchActiveOrders();
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
      final parcels = orderController.parcelList;
      final foodOrders = _foodActiveOrders;

      if (parcels.isEmpty && foodOrders.isEmpty) {
        return Center(
          child: Text(
            "You don't have any active delivery orders.".tr,
            style: TextStyle(
              fontSize: 14,
              fontFamily: AppThemeData.regular,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        );
      }

      final totalItems = foodOrders.length + parcels.length;

      return RefreshIndicator(
        onRefresh: () => _fetchActiveOrders(),
        child: ListView.builder(
          padding: const EdgeInsets.only(bottom: 24),
          physics: const BouncingScrollPhysics(),
          itemCount: totalItems,
          itemBuilder: (context, index) {
            if (index < foodOrders.length) {
              final food = foodOrders[index];
              return _buildFoodActiveOrderCard(context, food, isDark);
            } else {
              final order = parcels[index - foodOrders.length];
              return _buildMyOrderHistoryItem(context, order, isDark);
            }
          },
        ),
      );
    });
  }

  Widget _buildFoodActiveOrderCard(BuildContext context, FoodOrderData food, bool isDark) {
    String statusLabel = "Rider Assigned";
    Color statusColor = Colors.amber[800]!;
    Color statusBg = Colors.amber.withValues(alpha: 0.15);

    if (food.orderStatus == 'rider_at_restaurant') {
      statusLabel = "At Restaurant";
      statusColor = Colors.blue[700]!;
      statusBg = Colors.blue.withValues(alpha: 0.15);
    } else if (food.orderStatus == 'food_picked_up') {
      statusLabel = "Food Picked Up";
      statusColor = Colors.teal[700]!;
      statusBg = Colors.teal.withValues(alpha: 0.15);
    } else if (food.orderStatus == 'out_for_delivery') {
      statusLabel = "Out for Delivery";
      statusColor = Colors.purple[700]!;
      statusBg = Colors.purple.withValues(alpha: 0.15);
    } else if (food.orderStatus == 'rider_at_location') {
      statusLabel = "Arrived at Customer";
      statusColor = Colors.orange[800]!;
      statusBg = Colors.orange.withValues(alpha: 0.15);
    } else if (food.orderStatus == 'delivered') {
      statusLabel = "Delivered";
      statusColor = Colors.green[700]!;
      statusBg = Colors.green.withValues(alpha: 0.15);
    }

    final riderId = Preferences.getInt(Preferences.userId);

    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppThemeData.surface50Dark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
        border: Border.all(
          color: isDark ? AppThemeData.grey200Dark.withValues(alpha: 0.3) : AppThemeData.grey200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange[800],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.delivery_dining, size: 14, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          "FOOD",
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "#${food.orderNumber ?? ''}",
                    style: TextStyle(
                      fontSize: 15,
                      fontFamily: AppThemeData.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(
                radius: 18,
                backgroundColor: Colors.orange,
                child: Icon(Icons.restaurant, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      food.restaurant?.name ?? "Restaurant",
                      style: TextStyle(
                        fontSize: 15,
                        fontFamily: AppThemeData.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    Text(
                      food.restaurant?.address ?? "",
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: AppThemeData.regular,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  if (food.restaurant?.phone != null && food.restaurant!.phone!.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.phone, color: Colors.green, size: 22),
                      onPressed: () => Constant.makePhoneCall(food.restaurant!.phone!),
                    ),
                  if (food.restaurant?.latitude != null && food.restaurant?.longitude != null)
                    IconButton(
                      icon: const Icon(Icons.directions, color: Colors.blue, size: 22),
                      onPressed: () => Constant.redirectMap(
                        latitude: food.restaurant!.latitude!,
                        longLatitude: food.restaurant!.longitude!,
                        name: food.restaurant!.name ?? "Restaurant",
                      ),
                    ),
                ],
              )
            ],
          ),
          const SizedBox(height: 12),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(
                radius: 18,
                backgroundColor: Colors.redAccent,
                child: Icon(Icons.person_pin_circle, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      food.customerName ?? "Customer",
                      style: TextStyle(
                        fontSize: 15,
                        fontFamily: AppThemeData.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    Text(
                      food.deliveryAddress ?? "",
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: AppThemeData.regular,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    if (food.deliveryLandmark != null && food.deliveryLandmark!.isNotEmpty)
                      Text(
                        "Near ${food.deliveryLandmark}",
                        style: TextStyle(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ),
              Row(
                children: [
                  if (food.customerPhone != null && food.customerPhone!.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.phone, color: Colors.green, size: 22),
                      onPressed: () => Constant.makePhoneCall(food.customerPhone!),
                    ),
                  if (food.deliveryLat != null && food.deliveryLng != null)
                    IconButton(
                      icon: const Icon(Icons.navigation, color: Colors.purple, size: 22),
                      onPressed: () => Constant.redirectMap(
                        latitude: food.deliveryLat!,
                        longLatitude: food.deliveryLng!,
                        name: food.customerName ?? "Customer Delivery",
                      ),
                    ),
                ],
              )
            ],
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[900] : Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Order Items: ${food.itemsSummary}",
                  style: TextStyle(
                    fontSize: 13,
                    fontFamily: AppThemeData.medium,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      food.paymentMethod?.toLowerCase() == 'cod' 
                          ? "Collect Cash on Delivery:".tr 
                          : "Paid Online:".tr,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: food.paymentMethod?.toLowerCase() == 'cod' ? Colors.red : Colors.green,
                      ),
                    ),
                    Text(
                      Constant().amountShow(amount: (food.customerPayable ?? 0).toString()),
                      style: TextStyle(
                        fontSize: 15,
                        fontFamily: AppThemeData.bold,
                        color: AppThemeData.new200,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (food.orderStatus == 'rider_assigned') ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.store),
                label: Text("Arrived at Restaurant".tr, style: const TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () async {
                  ShowToastDialog.showLoader("Updating...".tr);
                  final res = await FoodRiderService.updateOrderStatus(
                    food.id!,
                    riderId: riderId,
                    status: 'arrived_restaurant',
                  );
                  ShowToastDialog.closeLoader();
                  if (res != null && res['success'] == true) {
                    ShowToastDialog.showToast("Status updated to At Restaurant".tr);
                    _fetchActiveOrders();
                  }
                },
              ),
            ),
          ] else if (food.orderStatus == 'rider_at_restaurant') ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.takeout_dining),
                label: Text("Confirm Food Pickup (Enter OTP)".tr, style: const TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () async {
                  final otp = await _showOtpInputDialog(
                    context: context,
                    title: "Pickup Handover OTP".tr,
                    subtitle: "Ask the restaurant staff for the 4-digit pickup OTP to verify handover.".tr,
                    confirmButtonText: "Verify & Pick Up".tr,
                    isDark: isDark,
                  );
                  if (otp != null) {
                    ShowToastDialog.showLoader("Verifying OTP...".tr);
                    final res = await FoodRiderService.updateOrderStatus(
                      food.id!,
                      riderId: riderId,
                      status: 'picked_up',
                      pickupOtp: otp,
                    );
                    ShowToastDialog.closeLoader();
                    if (res != null && res['success'] == true) {
                      ShowToastDialog.showToast("Food picked up! Now start delivery.".tr);
                      _fetchActiveOrders();
                    } else {
                      ShowToastDialog.showToast(res?['error'] ?? "Invalid pickup OTP".tr);
                    }
                  }
                },
              ),
            ),
          ] else if (food.orderStatus == 'food_picked_up') ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.motorcycle),
                label: Text("Start Delivery to Customer".tr, style: const TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () async {
                  ShowToastDialog.showLoader("Updating...".tr);
                  final res = await FoodRiderService.updateOrderStatus(
                    food.id!,
                    riderId: riderId,
                    status: 'out_for_delivery',
                  );
                  ShowToastDialog.closeLoader();
                  if (res != null && res['success'] == true) {
                    ShowToastDialog.showToast("Out for delivery! Navigate to customer.".tr);
                    _fetchActiveOrders();
                  }
                },
              ),
            ),
          ] else if (food.orderStatus == 'out_for_delivery') ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[800],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      ShowToastDialog.showLoader("Updating...".tr);
                      final res = await FoodRiderService.updateOrderStatus(
                        food.id!,
                        riderId: riderId,
                        status: 'arrived_customer',
                      );
                      ShowToastDialog.closeLoader();
                      if (res != null && res['success'] == true) {
                        ShowToastDialog.showToast("Arrived at customer location.".tr);
                        _fetchActiveOrders();
                      }
                    },
                    child: Text("Arrived at Customer".tr, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _completeFoodDelivery(context, food, riderId, isDark),
                    child: Text("Complete (OTP)".tr, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            )
          ] else if (food.orderStatus == 'rider_at_location') ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.check_circle),
                label: Text("Complete Delivery (Enter OTP)".tr, style: const TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () => _completeFoodDelivery(context, food, riderId, isDark),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _completeFoodDelivery(BuildContext context, FoodOrderData food, int riderId, bool isDark) async {
    final isCod = food.paymentMethod?.toLowerCase() == 'cod';
    final subtitle = isCod 
        ? "⚠️ Collect ₹${food.customerPayable} CASH from customer.\nAsk customer for the 4-digit Delivery OTP:".tr
        : "Ask the customer for their 4-digit Delivery OTP to complete handover:".tr;

    final otp = await _showOtpInputDialog(
      context: context,
      title: "Deliver Food Order".tr,
      subtitle: subtitle,
      confirmButtonText: isCod ? "Collected Cash & Complete".tr : "Complete Delivery".tr,
      isDark: isDark,
    );

    if (otp != null) {
      ShowToastDialog.showLoader("Completing delivery...".tr);
      final res = await FoodRiderService.updateOrderStatus(
        food.id!,
        riderId: riderId,
        status: 'delivered',
        deliveryOtp: otp,
      );
      ShowToastDialog.closeLoader();

      if (res != null && res['success'] == true) {
        ShowToastDialog.showToast("Order delivered successfully! 🎉".tr);
        _fetchActiveOrders();
      } else {
        ShowToastDialog.showToast(res?['error'] ?? "Failed to complete delivery. Check OTP.".tr);
      }
    }
  }

  Future<String?> _showOtpInputDialog({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String confirmButtonText,
    bool isDark = false,
  }) async {
    final otpController = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: isDark ? AppThemeData.surface50Dark : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(title, style: TextStyle(fontFamily: AppThemeData.bold, fontSize: 18)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(subtitle, style: TextStyle(fontSize: 14, color: isDark ? Colors.grey[300] : Colors.grey[700])),
              const SizedBox(height: 16),
              TextField(
                controller: otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                autofocus: true,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 4),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  counterText: "",
                  hintText: "• • • •",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: Text("Cancel".tr, style: const TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppThemeData.primary200,
                foregroundColor: isDark ? AppThemeData.grey900Dark : AppThemeData.grey900,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                if (otpController.text.trim().isNotEmpty) {
                  Navigator.pop(ctx, otpController.text.trim());
                } else {
                  ShowToastDialog.showToast("Please enter the OTP".tr);
                }
              },
              child: Text(confirmButtonText, style: TextStyle(fontFamily: AppThemeData.bold)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMyOrderHistoryItem(BuildContext context, ParcelData data, bool isDarkMode) {
    return GestureDetector(
      onTap: () async {
        if (data.status == "completed") {
          var isDone = await Get.to(const ParcelDetailsScreen(), arguments: {
            "parcelData": data,
          });
          if (isDone != null) {
            _fetchActiveOrders();
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
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            )
          ],
          border: Border.all(
            color: isDarkMode ? AppThemeData.grey200Dark.withValues(alpha: 0.3) : AppThemeData.grey200,
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
    final baseColor = AppThemeData.primary200.withValues(alpha: 0.12);

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
                    color: baseColor.withValues(alpha: opacity),
                    border: Border.all(
                      color: AppThemeData.primary200.withValues(alpha: opacity * 0.4),
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
                  color: AppThemeData.primary200.withValues(alpha: 0.3),
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