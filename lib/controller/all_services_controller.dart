import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import 'package:cabme_driver/constant/show_toast_dialog.dart';
import 'package:cabme_driver/model/service_category_model.dart';
import 'package:cabme_driver/service/api.dart';
import 'package:cabme_driver/utils/Preferences.dart';

class AllServicesController extends GetxController {
  Future<List<ServiceCategoryData>> fetchCategories({int? parentId}) async {
    try {
      final uri = parentId != null
          ? Uri.parse(API.getServiceCategories).replace(queryParameters: {'parent_id': parentId.toString()})
          : Uri.parse(API.getServiceCategories);
      final response = await http.get(uri, headers: API.header);
      final body = json.decode(response.body);
      if (response.statusCode == 200 && body['success'] == 'success') {
        return (body['data'] as List).map((e) => ServiceCategoryData.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> bookService(Map<String, dynamic> bodyParams) async {
    try {
      ShowToastDialog.showLoader("Submitting request...".tr);
      final response = await http.post(
        Uri.parse(API.bookService),
        headers: API.header,
        body: json.encode(bodyParams),
      );
      ShowToastDialog.closeLoader();
      final body = json.decode(response.body);
      if (response.statusCode == 200 && body['success'] == 'success') {
        ShowToastDialog.showToast("Service request submitted successfully".tr);
        return true;
      }
      ShowToastDialog.showToast(body['message']?.toString() ?? "Failed to submit request".tr);
      return false;
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("An error occurred: $e");
      return false;
    }
  }

  int? get currentUserId => Preferences.getInt(Preferences.userId);
}
