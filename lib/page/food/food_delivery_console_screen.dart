import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:cabme_driver/constant/constant.dart';
import 'package:cabme_driver/service/api.dart';
import 'package:cabme_driver/themes/constant_colors.dart';

class FoodDeliveryConsoleScreen extends StatefulWidget {
  const FoodDeliveryConsoleScreen({super.key});

  @override
  State<FoodDeliveryConsoleScreen> createState() => _FoodDeliveryConsoleScreenState();
}

class _FoodDeliveryConsoleScreenState extends State<FoodDeliveryConsoleScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  List<dynamic> _incomingOrders = [];
  List<dynamic> _activeOrders = [];
  Timer? _pollingTimer;
  Timer? _gpsTimer;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _getCurrentLocation().then((_) {
      _loadData();
    });

    // Auto-poll incoming & active orders every 10s
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _loadData(silent: true);
    });

    // Stream GPS coordinates to backend every 15s
    _gpsTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _streamGpsLocation();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pollingTimer?.cancel();
    _gpsTimer?.cancel();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position? pos = await Geolocator.getLastKnownPosition();
      pos ??= await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 5)),
      );
      if (mounted) {
        setState(() {
          _currentPosition = pos;
        });
      }
    } catch (_) {}
  }

  String _getRiderId() {
    return Constant.getUserData().userData?.id?.toString() ?? '';
  }

  String _getBaseUrl() {
    final base = API.baseUrl;
    return base.endsWith('/') ? '${base}food' : '$base/food';
  }

  Future<void> _loadData({bool silent = false}) async {
    if (!silent && mounted) {
      setState(() => _isLoading = true);
    }

    final riderId = _getRiderId();
    if (riderId.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    await Future.wait([
      _fetchIncomingOrders(riderId),
      _fetchActiveOrders(riderId),
    ]);

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchIncomingOrders(String riderId) async {
    try {
      final lat = _currentPosition?.latitude.toString() ?? '';
      final lng = _currentPosition?.longitude.toString() ?? '';
      final url = Uri.parse('${_getBaseUrl()}/rider/incoming?rider_id=$riderId&latitude=$lat&longitude=$lng&radius_km=15');
      final res = await http.get(url, headers: API.header);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['data'] is List) {
          if (mounted) {
            setState(() {
              _incomingOrders = data['data'];
            });
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _fetchActiveOrders(String riderId) async {
    try {
      final url = Uri.parse('${_getBaseUrl()}/rider/active?rider_id=$riderId');
      final res = await http.get(url, headers: API.header);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['data'] is List) {
          if (mounted) {
            setState(() {
              _activeOrders = data['data'];
            });
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _streamGpsLocation() async {
    final riderId = _getRiderId();
    if (riderId.isEmpty || _activeOrders.isEmpty) return;

    try {
      Position? pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 4)),
      );
      _currentPosition = pos;
      final url = Uri.parse('${_getBaseUrl()}/rider/location');
      await http.post(url, headers: API.header, body: jsonEncode({
        'rider_id': riderId,
        'latitude': pos.latitude,
        'longitude': pos.longitude,
      }));
    } catch (_) {}
  }

  Future<void> _acceptOrder(dynamic order) async {
    final riderId = _getRiderId();
    final user = Constant.getUserData().userData;
    final riderName = '${user?.prenom ?? ''} ${user?.nom ?? ''}'.trim();
    final riderPhone = user?.phone ?? '';

    setState(() => _isLoading = true);
    try {
      final url = Uri.parse('${_getBaseUrl()}/rider/orders/${order['id']}/accept');
      final res = await http.post(url, headers: API.header, body: jsonEncode({
        'rider_id': riderId,
        'rider_name': riderName,
        'rider_phone': riderPhone,
        'latitude': _currentPosition?.latitude,
        'longitude': _currentPosition?.longitude,
      }));

      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        Get.snackbar(
          'Order Accepted!'.tr,
          'Head to ${order['restaurant']?['name'] ?? 'the restaurant'} for pickup.'.tr,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
        await _loadData();
        _tabController.animateTo(1);
      } else {
        Get.snackbar('Error'.tr, data['error'] ?? 'Failed to accept order.'.tr,
            backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar('Error'.tr, e.toString(), backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateOrderStatus(int orderId, String status, {String? pickupOtp, String? deliveryOtp}) async {
    final riderId = _getRiderId();
    setState(() => _isLoading = true);

    try {
      final url = Uri.parse('${_getBaseUrl()}/rider/orders/$orderId/status');
      final body = {
        'rider_id': riderId,
        'status': status,
        'latitude': _currentPosition?.latitude,
        'longitude': _currentPosition?.longitude,
        if (pickupOtp != null) 'pickup_otp': pickupOtp,
        if (deliveryOtp != null) 'delivery_otp': deliveryOtp,
      };

      final res = await http.post(url, headers: API.header, body: jsonEncode(body));

      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        Get.snackbar(
          'Updated!'.tr,
          'Order status updated successfully.'.tr,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
        await _loadData();
      } else {
        Get.snackbar('Error'.tr, data['error'] ?? 'Failed to update order status.'.tr,
            backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar('Error'.tr, e.toString(), backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _promptPickupOtp(dynamic order) {
    // If restaurant already confirmed handover, directly proceed!
    if (order['order_status'] == 'food_picked_up') {
      _updateOrderStatus(order['id'], 'picked_up');
      return;
    }

    final textController = TextEditingController();
    Get.defaultDialog(
      title: 'Pickup Handover Code'.tr,
      content: Column(
        children: [
          Text(
            'Enter the 4-digit Handover Code displayed on the restaurant\'s screen to collect the food parcel.'.tr,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: textController,
            keyboardType: TextInputType.number,
            maxLength: 4,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 8),
            decoration: InputDecoration(
              hintText: '••••',
              counterText: '',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
      textConfirm: 'Confirm Pickup'.tr,
      confirmTextColor: Colors.white,
      buttonColor: ConstantColors.primary,
      onConfirm: () {
        final otp = textController.text.trim();
        if (otp.length != 4) {
          Get.snackbar('Invalid Code'.tr, 'Please enter the 4-digit code shown on the restaurant screen'.tr,
              backgroundColor: Colors.orange, colorText: Colors.white);
          return;
        }
        Get.back();
        _updateOrderStatus(order['id'], 'picked_up', pickupOtp: otp);
      },
      textCancel: 'Cancel'.tr,
    );
  }

  void _promptDeliveryOtp(dynamic order) {
    final textController = TextEditingController();
    final isCod = order['payment_method'] == 'cod';
    final payable = order['customer_payable'] ?? 0;

    Get.defaultDialog(
      title: 'Complete Delivery'.tr,
      content: Column(
        children: [
          if (isCod) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                border: Border.all(color: Colors.amber.shade700),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.payments_outlined, color: Colors.amber, size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'COLLECT CASH: ₹$payable from customer before completing handover!'.tr,
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber.shade900, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          Text(
            'Ask the customer for their 4-digit delivery PIN to complete delivery.'.tr,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: textController,
            keyboardType: TextInputType.number,
            maxLength: 4,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 8),
            decoration: InputDecoration(
              hintText: '••••',
              counterText: '',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
      textConfirm: 'Confirm Delivery'.tr,
      confirmTextColor: Colors.white,
      buttonColor: Colors.green,
      onConfirm: () {
        final otp = textController.text.trim();
        if (otp.length != 4) {
          Get.snackbar('Invalid OTP'.tr, 'Please enter a valid 4-digit OTP'.tr,
              backgroundColor: Colors.orange, colorText: Colors.white);
          return;
        }
        Get.back();
        _updateOrderStatus(order['id'], 'delivered', deliveryOtp: otp);
      },
      textCancel: 'Cancel'.tr,
    );
  }

  void _openMap(double lat, double lng, String label) async {
    final uri = Uri.parse('google.navigation:q=$lat,$lng&mode=d');
    final fallbackUri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
    }
  }

  void _callPhone(String phone) async {
    if (phone.isEmpty) return;
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: Text(
          'Food Delivery Console'.tr,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: ConstantColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.fastfood_outlined, size: 18),
                  const SizedBox(width: 8),
                  Text('Incoming'.tr),
                  if (_incomingOrders.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                      child: Text('${_incomingOrders.length}',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.delivery_dining, size: 20),
                  const SizedBox(width: 8),
                  Text('Active Delivery'.tr),
                  if (_activeOrders.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(10)),
                      child: Text('${_activeOrders.length}',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: _isLoading && _incomingOrders.isEmpty && _activeOrders.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => _loadData(),
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildIncomingTab(isDark),
                  _buildActiveTab(isDark),
                ],
              ),
            ),
    );
  }

  Widget _buildIncomingTab(bool isDark) {
    if (_incomingOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.fastfood_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No Food Orders Nearby'.tr,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Orders ready for pickup at restaurants will appear here.'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: _incomingOrders.length,
      itemBuilder: (context, index) {
        final order = _incomingOrders[index];
        final restaurant = order['restaurant'] ?? {};
        final items = (order['items'] as List?) ?? [];
        final deliveryFee = order['delivery_charge'] ?? 0;
        final dist = order['pickup_distance_km'] ?? '';

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.orange.shade300),
                      ),
                      child: Text(
                        '#${order['order_number']}',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade800, fontSize: 13),
                      ),
                    ),
                    Text(
                      '₹$deliveryFee Delivery Fee',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.storefront, color: ConstantColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        restaurant['name'] ?? 'Restaurant',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                    if (dist.toString().isNotEmpty)
                      Text(
                        '$dist km away',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 28, top: 2),
                  child: Text(
                    restaurant['address'] ?? '',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ),
                const Divider(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Deliver to: ${order['customer_name'] ?? 'Customer'}',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          Text(order['delivery_address'] ?? '',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '${items.length} item(s): ${items.map((i) => '${i['quantity']}x ${i['product_name']}').take(2).join(', ')}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ConstantColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => _acceptOrder(order),
                    icon: const Icon(Icons.check_circle_outline),
                    label: Text(
                      'Accept Food Order (₹$deliveryFee)'.tr,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActiveTab(bool isDark) {
    if (_activeOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delivery_dining_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No Active Delivery'.tr,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Accept an order from the Incoming tab to begin delivery.'.tr,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: _activeOrders.length,
      itemBuilder: (context, index) {
        final order = _activeOrders[index];
        final restaurant = order['restaurant'] ?? {};
        final status = order['order_status'] ?? '';
        final isCod = order['payment_method'] == 'cod';
        final payable = order['customer_payable'] ?? 0;
        final rLat = double.tryParse(restaurant['latitude']?.toString() ?? '') ?? 0.0;
        final rLng = double.tryParse(restaurant['longitude']?.toString() ?? '') ?? 0.0;
        final dLat = double.tryParse(order['delivery_lat']?.toString() ?? '') ?? 0.0;
        final dLng = double.tryParse(order['delivery_lng']?.toString() ?? '') ?? 0.0;

        return Card(
          elevation: 3,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Order #${order['order_number']}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getStatusLabel(status),
                        style: TextStyle(
                          color: _getStatusColor(status),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),

                // PHASE 1: PICKUP FROM RESTAURANT
                if (status == 'rider_assigned' || status == 'rider_at_restaurant') ...[
                  Row(
                    children: [
                      Icon(Icons.storefront, color: ConstantColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Pickup: ${restaurant['name'] ?? 'Restaurant'}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.phone, color: Colors.green),
                        onPressed: () => _callPhone(restaurant['owner_phone'] ?? restaurant['phone'] ?? ''),
                      ),
                      if (rLat != 0.0 && rLng != 0.0)
                        IconButton(
                          icon: const Icon(Icons.directions, color: Colors.blue),
                          onPressed: () => _openMap(rLat, rLng, restaurant['name'] ?? 'Restaurant'),
                        ),
                    ],
                  ),
                  Text(
                    restaurant['address'] ?? '',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 14),
                  if (status == 'rider_assigned')
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => _updateOrderStatus(order['id'], 'arrived_restaurant'),
                        icon: const Icon(Icons.location_on),
                        label: Text('I Have Arrived at Restaurant'.tr, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  if (status == 'rider_at_restaurant')
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ConstantColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          if (order['order_status'] == 'food_picked_up') {
                            _updateOrderStatus(order['id'], 'out_for_delivery');
                          } else {
                            _promptPickupOtp(order);
                          }
                        },
                        icon: const Icon(Icons.check_circle_outline),
                        label: Text(
                          order['order_status'] == 'food_picked_up'
                              ? 'Food Handed Over - Start Delivery'.tr
                              : 'Enter Handover Code & Take Food'.tr,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],

                // PHASE 2: DELIVER TO CUSTOMER
                if (status == 'food_picked_up' || status == 'out_for_delivery' || status == 'rider_at_location') ...[
                  Row(
                    children: [
                      const Icon(Icons.home, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Deliver to: ${order['customer_name'] ?? 'Customer'}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.phone, color: Colors.green),
                        onPressed: () => _callPhone(order['customer_phone'] ?? ''),
                      ),
                      if (dLat != 0.0 && dLng != 0.0)
                        IconButton(
                          icon: const Icon(Icons.directions, color: Colors.blue),
                          onPressed: () => _openMap(dLat, dLng, order['customer_name'] ?? 'Customer'),
                        ),
                    ],
                  ),
                  Text(
                    order['delivery_address'] ?? '',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 10),
                  if (isCod)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(6)),
                      child: Text('COD Amount to Collect: ₹$payable',
                          style: TextStyle(color: Colors.amber.shade900, fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  const SizedBox(height: 14),
                  if (status == 'food_picked_up' || status == 'out_for_delivery')
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => _updateOrderStatus(order['id'], 'arrived_customer'),
                        icon: const Icon(Icons.doorbell),
                        label: Text('I Have Arrived at Doorstep'.tr, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  if (status == 'rider_at_location')
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => _promptDeliveryOtp(order),
                        icon: const Icon(Icons.check_circle),
                        label: Text('Enter Customer Delivery OTP'.tr, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'rider_assigned':
        return Colors.blue;
      case 'rider_at_restaurant':
        return Colors.orange;
      case 'food_picked_up':
      case 'out_for_delivery':
        return Colors.purple;
      case 'rider_at_location':
        return Colors.amber.shade800;
      case 'delivered':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'rider_assigned':
        return 'Heading to Restaurant';
      case 'rider_at_restaurant':
        return 'At Restaurant';
      case 'food_picked_up':
      case 'out_for_delivery':
        return 'Out for Delivery';
      case 'rider_at_location':
        return 'At Customer Doorstep';
      case 'delivered':
        return 'Delivered';
      default:
        return status;
    }
  }
}
