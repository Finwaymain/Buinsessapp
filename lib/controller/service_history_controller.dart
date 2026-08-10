import 'dart:convert';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import 'package:cabme_driver/model/service_request_model.dart';
import 'package:cabme_driver/service/api.dart';
import 'package:cabme_driver/utils/Preferences.dart';

class ServiceHistoryController extends GetxController {
  final RxBool isLoading = true.obs;
  final RxList<ServiceRequestData> items = <ServiceRequestData>[].obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchHistory();
  }

  Future<void> fetchHistory() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final userId = Preferences.getInt(Preferences.userId);
      if (userId == 0) {
        items.clear();
        errorMessage.value = 'Please login to view service bookings';
        return;
      }

      final uri = Uri.parse(API.serviceHistory).replace(queryParameters: {'user_id': userId.toString()});
      final headers = Map<String, String>.from(API.header);
      headers['id_user'] = userId.toString();

      final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 20));
      final raw = response.body.trim();
      if (raw.isEmpty || raw.startsWith('<!DOCTYPE') || raw.startsWith('<html')) {
        errorMessage.value = 'Unable to load service bookings';
        items.clear();
        return;
      }

      final body = json.decode(raw);
      if (response.statusCode == 200 && body['success'] == 'success' && body['data'] is List) {
        items.value = (body['data'] as List)
            .map((e) => ServiceRequestData.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      } else {
        errorMessage.value = body['message']?.toString() ?? 'Failed to load service bookings';
        items.clear();
      }
    } catch (e) {
      errorMessage.value = 'Failed to load service bookings';
      items.clear();
    } finally {
      isLoading.value = false;
    }
  }

  List<ServiceRequestData> get pending => items.where((e) => e.isPending).toList();
  List<ServiceRequestData> get ongoing => items.where((e) => e.isOngoing).toList();
  List<ServiceRequestData> get history => items.where((e) => e.isHistory).toList();
}
