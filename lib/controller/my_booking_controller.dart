import 'dart:convert';

import 'package:cabme_driver/constant/show_toast_dialog.dart';
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
  }

  Future<void> fetchBookings({bool showLoader = false}) async {
    try {
      if (showLoader) ShowToastDialog.showLoader('Please wait'.tr);
      isLoading.value = true;

      final driverId = Preferences.getInt(Preferences.userId);
      final uri = Uri.parse(API.driverBookings).replace(queryParameters: {
        'id_driver': driverId.toString(),
        'status': _statusParam,
      });

      final response = await http.get(uri, headers: API.header);
      final body = json.decode(response.body);

      if (response.statusCode == 200 && body['success'] == 'success') {
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

  Future<bool> updateServiceStatus(String bookingId, String status) async {
    try {
      ShowToastDialog.showLoader('Please wait'.tr);
      final driverId = Preferences.getInt(Preferences.userId);
      final response = await http.post(
        Uri.parse(API.driverServiceBookingStatus),
        headers: API.header,
        body: json.encode({
          'id_driver': driverId,
          'booking_id': bookingId,
          'status': status,
        }),
      );
      ShowToastDialog.closeLoader();
      final body = json.decode(response.body);
      if (response.statusCode == 200 && body['success'] == 'success') {
        ShowToastDialog.showToast(body['message']?.toString() ?? 'Updated'.tr);
        await fetchBookings();
        return true;
      }
      ShowToastDialog.showToast(body['message']?.toString() ?? 'Failed to update'.tr);
      return false;
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.toString());
      return false;
    }
  }
}
