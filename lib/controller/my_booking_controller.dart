import 'dart:async';
import 'dart:convert';

import 'package:cabme_driver/controller/service_booking_flow_controller.dart';
import 'package:cabme_driver/constant/show_toast_dialog.dart';
import 'package:cabme_driver/controller/dash_board_controller.dart';
import 'package:cabme_driver/model/driver_booking_model.dart';
import 'package:cabme_driver/service/api.dart';
import 'package:cabme_driver/utils/Preferences.dart';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class MyBookingController extends GetxController {
  final isLoading = true.obs;
  final selectedTab = 0.obs;
  final bookings = <DriverBookingItem>[].obs;
  final incomingCount = 0.obs;
  final activeCount = 0.obs;
  final historyCount = 0.obs;
  final onboardingRequired = false.obs;
  final locationRequired = false.obs;
  final driverOnline = false.obs;
  final hasDriverLocation = false.obs;
  final locationMessage = ''.obs;
  final profession = ''.obs;

  // Wallet debt tracking
  final walletBalance = 0.0.obs;
  final hasDebt = false.obs;
  final debtAmount = 0.0.obs;

  // Static so it survives controller recreation (GetX dispose/re-put cycles).
  // Rejected booking IDs are NEVER shown again for the entire app session.
  static final _locallyRejectedIds = <String>{};

  Timer? _pollTimer;

  String get _statusParam {
    switch (selectedTab.value) {
      case 1:
        return 'active';
      case 2:
        return 'history';
      default:
        return 'incoming';
    }
  }

  @override
  void onInit() {
    super.onInit();
    fetchBookings();
    _pollTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (!isLoading.value) fetchBookings(isSilentPoll: true);
    });
  }

  @override
  void onClose() {
    _pollTimer?.cancel();
    super.onClose();
  }

  Future<void> fetchBookings({bool showLoader = false, bool isSilentPoll = false}) async {
    // Also refresh wallet status on every fetch so debt badge stays accurate
    _fetchWalletStatus();
    try {
      if (showLoader) ShowToastDialog.showLoader('Please wait'.tr);

      // Only set isLoading to true on initial load when list is empty
      if (bookings.isEmpty && !isSilentPoll && !showLoader) {
        isLoading.value = true;
      }

      onboardingRequired.value = false;
      locationRequired.value = false;
      locationMessage.value = '';

      final driverId = _getResolvedDriverId();
      final params = <String, String>{
        'id_driver': driverId.toString(),
        'status': _statusParam,
      };

      final headers = Map<String, String>.from(API.header);
      if (driverId != 0) {
        headers['id_conducteur'] = driverId.toString();
        headers['id_user'] = driverId.toString();
      }

      final uri = Uri.parse(API.driverBookings).replace(queryParameters: params);
      final response = await http.get(uri, headers: headers);
      final body = json.decode(response.body);

      if (body['onboarding_required'] == true) {
        onboardingRequired.value = true;
        bookings.clear();
        incomingCount.value = 0;
        activeCount.value = 0;
        historyCount.value = 0;
        return;
      }

      if (body['location_required'] == true) {
        locationRequired.value = true;
        driverOnline.value = body['driver_online'] == true;
        hasDriverLocation.value = body['has_location'] == true;
        locationMessage.value = body['message']?.toString() ?? 'Please turn on your status and enable GPS to capture your location'.tr;
        bookings.clear();
        incomingCount.value = 0;
        activeCount.value = 0;
        historyCount.value = 0;
        return;
      }

      if (response.statusCode == 200 && body['success'] == 'success') {
        profession.value = body['profession']?.toString() ?? '';
        final list = (body['data'] as List? ?? [])
            .map((e) => DriverBookingItem.fromJson(Map<String, dynamic>.from(e)))
            .toList()
            // Always filter out locally rejected IDs so polls can't bring them back
            .where((e) => !_locallyRejectedIds.contains(e.id))
            .toList();
        bookings.assignAll(list);

        // Update badge counts from server counts map so all tab counts stay accurate
        if (body['counts'] is Map) {
          final c = Map<String, dynamic>.from(body['counts'] as Map);
          incomingCount.value = int.tryParse(c['incoming']?.toString() ?? '0') ?? 0;
          activeCount.value = int.tryParse(c['active']?.toString() ?? '0') ?? 0;
          historyCount.value = int.tryParse(c['history']?.toString() ?? '0') ?? 0;
        } else {
          if (selectedTab.value == 0) incomingCount.value = list.length;
          if (selectedTab.value == 1) activeCount.value = list.length;
          if (selectedTab.value == 2) historyCount.value = list.length;
        }

        // Auto switch to Active tab if user is on Incoming tab (0) and there are no incoming bookings but active bookings exist
        if (selectedTab.value == 0 && incomingCount.value == 0 && activeCount.value > 0) {
          selectedTab.value = 1;
          fetchBookings(isSilentPoll: true);
        }
      } else {
        if (bookings.isEmpty) bookings.clear();
      }
    } catch (e) {
      if (bookings.isEmpty) bookings.clear();
    } finally {
      isLoading.value = false;
      if (showLoader) ShowToastDialog.closeLoader();
    }
  }

  /// Call this immediately when a driver rejects/cancels a booking so it
  /// is never shown again in this session, even if a background poll races
  /// against the rejection API write.
  void markLocallyRejected(String bookingId) {
    _locallyRejectedIds.add(bookingId);
    bookings.removeWhere((e) => e.id == bookingId);
    // Immediately recompute counts so badges update without waiting for next fetch
    incomingCount.value = bookings.where((e) => e.isIncoming).length;
    activeCount.value = bookings.where((e) => e.isAccepted || e.isInProgress || e.isAwaitingPayment).length;
    historyCount.value = bookings.where((e) => e.isCompleted || e.isCancelled).length;
  }

  void changeTab(int index) {
    if (selectedTab.value == index) return;
    selectedTab.value = index;
    fetchBookings();
  }

  int _getResolvedDriverId() {
    int driverId = Preferences.getInt(Preferences.userId);
    if (driverId != 0) return driverId;
    final strId = Preferences.getString(Preferences.userId);
    if (strId.isNotEmpty) {
      final parsed = int.tryParse(strId);
      if (parsed != null && parsed != 0) return parsed;
    }
    final userDataId = Constant.getUserData().userData?.id;
    if (userDataId != null) {
      final parsed = int.tryParse(userDataId.toString());
      if (parsed != null && parsed != 0) return parsed;
    }
    return 0;
  }

  Future<bool> updateServiceStatus(
    String bookingId,
    String status, {
    String? otp,
    String? paymentMethod,
    Map<String, dynamic>? billPayload,
  }) async {
    try {
      ShowToastDialog.showLoader('Please wait'.tr);
      final driverId = _getResolvedDriverId();
      final body = <String, dynamic>{
        'id_driver': driverId,
        'driver_id': driverId,
        'booking_id': bookingId,
        'status': status,
      };
      if (otp != null && otp.trim().isNotEmpty) {
        body['otp'] = ServiceBookingFlowController.normalizeOtp(otp);
      }
      if (paymentMethod != null && paymentMethod.isNotEmpty) {
        body['payment_method'] = paymentMethod;
      }
      if (billPayload != null && billPayload.isNotEmpty) {
        body.addAll(billPayload);
      }

      final headers = Map<String, String>.from(API.header);
      if (driverId != 0) {
        headers['id_conducteur'] = driverId.toString();
        headers['id_user'] = driverId.toString();
      }

      final response = await http.post(
        Uri.parse(API.driverServiceBookingStatus),
        headers: headers,
        body: json.encode(body),
      );
      ShowToastDialog.closeLoader();
      final responseBody = json.decode(response.body);
      final isSuccess = response.statusCode == 200 &&
          (responseBody['success'] == 'success' || responseBody['success'] == true);
      if (isSuccess) {
        if (status == 'rejected' || status == 'cancelled' || status == 'canceled') {
          // Add to local rejected set FIRST so subsequent polls can't bring it back
          _locallyRejectedIds.add(bookingId);
          bookings.removeWhere((e) => e.id == bookingId);
        }
        ShowToastDialog.showToast(responseBody['message']?.toString() ?? 'Updated'.tr);
        await fetchBookings(showLoader: false);
        return true;
      }
      ShowToastDialog.showToast(responseBody['message']?.toString() ?? 'Failed to update'.tr);
      return false;
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.toString());
      return false;
    }
  }

  Future<void> enableLocationAndRefresh() async {
    try {
      ShowToastDialog.showLoader('Capturing your location...'.tr);
      final dashController = Get.isRegistered<DashBoardController>()
          ? Get.find<DashBoardController>()
          : Get.put(DashBoardController());

      if (!dashController.isActive.value) {
        final res = await dashController.changeOnlineStatus({
          'id_driver': Preferences.getInt(Preferences.userId),
          'online': 'yes',
        });
        if (res == null || res['success'] != 'success') {
          ShowToastDialog.closeLoader();
          ShowToastDialog.showToast(res?['error']?.toString() ?? 'Could not turn on status'.tr);
          return;
        }
        dashController.isActive.value = true;
      }

      await dashController.updateCurrentLocation();
      await Future.delayed(const Duration(seconds: 2));
      ShowToastDialog.closeLoader();
      await fetchBookings();
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.toString());
    }
  }

  /// Silently fetches the driver wallet status and updates [hasDebt] / [debtAmount].
  Future<void> _fetchWalletStatus() async {
    try {
      final driverId = Preferences.getInt(Preferences.userId);
      final uri = Uri.parse(API.driverWalletStatus)
          .replace(queryParameters: {'id_driver': driverId.toString()});
      final response = await http.get(uri, headers: API.header);
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body['success'] == 'success') {
          walletBalance.value = double.tryParse(body['wallet_balance']?.toString() ?? '0') ?? 0;
          hasDebt.value = body['has_debt'] == true;
          debtAmount.value = double.tryParse(body['debt_amount']?.toString() ?? '0') ?? 0;
        }
      }
    } catch (_) {
      // Wallet status check is non-critical — silently ignore errors
    }
  }

  /// Fetches a single booking detail by ID. Useful for polling status of an active flow
  /// independent of the currently selected tab in the booking screen list.
  Future<DriverBookingItem?> fetchSingleBooking(String bookingId) async {
    try {
      final driverId = _getResolvedDriverId();
      final headers = Map<String, String>.from(API.header);
      if (driverId != 0) {
        headers['id_conducteur'] = driverId.toString();
        headers['id_user'] = driverId.toString();
      }

      final uri = Uri.parse('${API.baseUrl}service-booking/$bookingId');
      final response = await http.get(uri, headers: headers);
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body['success'] == 'success' && body['data'] != null) {
          final updated = DriverBookingItem.fromJson(Map<String, dynamic>.from(body['data']));
          // Update it in our local bookings list if present
          final index = bookings.indexWhere((e) => e.id == bookingId);
          if (index != -1) {
            bookings[index] = updated;
            bookings.refresh();
          }
          return updated;
        }
      }
    } catch (e) {
      debugPrint('Error fetching single booking: $e');
    }
    return null;
  }
}
