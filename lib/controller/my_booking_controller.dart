import 'dart:async';
import 'dart:convert';

import 'package:cabme_driver/controller/service_booking_flow_controller.dart';
import 'package:cabme_driver/constant/show_toast_dialog.dart';
import 'package:cabme_driver/controller/dash_board_controller.dart';
import 'package:cabme_driver/model/driver_booking_model.dart';
import 'package:cabme_driver/service/api.dart';
import 'package:cabme_driver/utils/Preferences.dart';
import 'package:get/get.dart';
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
      if (!isLoading.value) fetchBookings();
    });
  }

  @override
  void onClose() {
    _pollTimer?.cancel();
    super.onClose();
  }

  Future<void> fetchBookings({bool showLoader = false}) async {
    try {
      if (showLoader) ShowToastDialog.showLoader('Please wait'.tr);
      isLoading.value = true;
      onboardingRequired.value = false;
      locationRequired.value = false;
      locationMessage.value = '';

      final driverId = Preferences.getInt(Preferences.userId);
      final params = <String, String>{
        'id_driver': driverId.toString(),
        'status': _statusParam,
      };

      final uri = Uri.parse(API.driverBookings).replace(queryParameters: params);
      final response = await http.get(uri, headers: API.header);
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
            .toList();
        bookings.assignAll(list);

        final counts = body['counts'] as Map<String, dynamic>? ?? {};
        incomingCount.value = int.tryParse(counts['incoming']?.toString() ?? '0') ?? 0;
        activeCount.value = int.tryParse(counts['active']?.toString() ?? '0') ?? 0;
        historyCount.value = int.tryParse(counts['history']?.toString() ?? '0') ?? 0;
      } else {
        bookings.clear();
      }
    } catch (e) {
      bookings.clear();
    } finally {
      isLoading.value = false;
      if (showLoader) ShowToastDialog.closeLoader();
    }
  }

  void changeTab(int index) {
    if (selectedTab.value == index) return;
    selectedTab.value = index;
    fetchBookings();
  }

  Future<bool> updateServiceStatus(
    String bookingId,
    String status, {
    String? otp,
    Map<String, dynamic>? billPayload,
  }) async {
    try {
      ShowToastDialog.showLoader('Please wait'.tr);
      final driverId = Preferences.getInt(Preferences.userId);
      final body = <String, dynamic>{
        'id_driver': driverId,
        'booking_id': bookingId,
        'status': status,
      };
      if (otp != null && otp.trim().isNotEmpty) {
        body['otp'] = ServiceBookingFlowController.normalizeOtp(otp);
      }
      if (billPayload != null && billPayload.isNotEmpty) {
        body.addAll(billPayload);
      }

      final response = await http.post(
        Uri.parse(API.driverServiceBookingStatus),
        headers: API.header,
        body: json.encode(body),
      );
      ShowToastDialog.closeLoader();
      final responseBody = json.decode(response.body);
      final isSuccess = response.statusCode == 200 &&
          (responseBody['success'] == 'success' || responseBody['success'] == true);
      if (isSuccess) {
        ShowToastDialog.showToast(responseBody['message']?.toString() ?? 'Updated'.tr);
        await fetchBookings();
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
}
