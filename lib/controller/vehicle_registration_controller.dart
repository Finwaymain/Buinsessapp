import 'dart:convert';
import 'dart:io';

import 'package:cabme_driver/constant/show_toast_dialog.dart';
import 'package:cabme_driver/model/get_vehicle_getegory.dart';
import 'package:cabme_driver/model/zone_model.dart';
import 'package:cabme_driver/service/api.dart';
import 'package:cabme_driver/utils/Preferences.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

/// Powers the truck/logistics vehicle registration wizard: category select ->
/// vehicle details -> documents -> complete. Deliberately separate from the
/// existing (unused) VehicleInfoController, which is built around the
/// car-shaped brand/model lookup flow that this simpler truck form doesn't need.
class VehicleRegistrationController extends GetxController {
  RxList<VehicleData> vehicleTypes = <VehicleData>[].obs;
  RxBool isLoadingTypes = false.obs;

  Future<void> fetchVehicleTypes() async {
    isLoadingTypes.value = true;
    try {
      final response = await http.get(Uri.parse(API.vehicleCategory), headers: API.header);
      final body = json.decode(response.body);
      if (response.statusCode == 200 && body['success'].toString().toLowerCase() == 'success') {
        final model = VehicleCategoryModel.fromJson(body);
        // Dedupe by name — the seed data has repeated "Premium XL" rows from
        // earlier testing, which would otherwise show as duplicate tiles.
        final seenNames = <String>{};
        final deduped = (model.vehicleData ?? []).where((v) {
          final name = (v.libelle ?? '').toLowerCase().trim();
          return name.isNotEmpty && seenNames.add(name);
        }).toList();
        vehicleTypes.assignAll(deduped);
      }
    } catch (e) {
      ShowToastDialog.showToast("Failed to load vehicle types: $e");
    } finally {
      isLoadingTypes.value = false;
    }
  }

  /// This deployment currently runs a single operating zone, so registration
  /// auto-picks it rather than showing a zone picker not present in the
  /// reference UI. Returns null if no active zone exists yet.
  Future<int?> fetchDefaultZoneId() async {
    try {
      final response = await http.get(Uri.parse(API.getZone), headers: API.authheader);
      final body = json.decode(response.body);
      if (response.statusCode == 200 && body['success'].toString().toLowerCase() == 'success') {
        final model = ZoneModel.fromJson(body);
        if (model.data != null && model.data!.isNotEmpty) return model.data!.first.id;
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>?> registerVehicle({
    required String vehicleTypeId,
    required String vehicleTypeName,
    required String numberPlate,
    required int zoneId,
  }) async {
    try {
      ShowToastDialog.showLoader("Registering vehicle...");
      final bodyParams = {
        'id_driver': Preferences.getInt(Preferences.userId).toString(),
        'id_categorie_vehicle': vehicleTypeId,
        'brand': vehicleTypeName,
        'model': vehicleTypeName,
        'color': '',
        'numberplate': numberPlate,
        'passenger': '1',
        'zone_id': zoneId.toString(),
        'car_make': '',
        'milage': '',
        'km_driven': '',
      };
      final response = await http.post(Uri.parse(API.vehicleRegister), headers: API.header, body: jsonEncode(bodyParams));
      ShowToastDialog.closeLoader();
      final body = json.decode(response.body);
      if (response.statusCode == 200 && body['success'].toString().toLowerCase() == 'success') {
        return body;
      }
      ShowToastDialog.showToast(body['error']?.toString() ?? "Vehicle registration failed");
      return null;
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("An error occurred: $e");
      return null;
    }
  }

  Future<List<dynamic>> fetchDocumentTypes() async {
    try {
      final response = await http.get(Uri.parse(API.documentList), headers: API.header);
      final body = json.decode(response.body);
      if (response.statusCode == 200 && body['success'].toString().toLowerCase() == 'success') {
        return body['data'] as List;
      }
    } catch (_) {}
    return [];
  }

  Future<List<dynamic>> fetchDriverDocuments() async {
    try {
      final response = await http.get(
        Uri.parse("${API.getDriverUploadedDocument}?driver_id=${Preferences.getInt(Preferences.userId)}"),
        headers: API.header,
      );
      final body = json.decode(response.body);
      if (response.statusCode == 200 && body['success'].toString().toLowerCase() == 'success') {
        return body['data'] as List;
      }
    } catch (_) {}
    return [];
  }

  Future<bool> uploadDocument({required String documentId, required File file}) async {
    try {
      ShowToastDialog.showLoader("Uploading document...");
      var request = http.MultipartRequest('POST', Uri.parse(API.driverDocumentUpdate));
      request.headers.addAll(API.header);
      request.fields['driver_id'] = Preferences.getInt(Preferences.userId).toString();
      request.fields['document_id'] = documentId;
      request.files.add(await http.MultipartFile.fromPath('attachment', file.path));

      final res = await request.send();
      final responseData = await res.stream.toBytes();
      final responseString = String.fromCharCodes(responseData);
      ShowToastDialog.closeLoader();

      Map<String, dynamic> body;
      try {
        body = json.decode(responseString);
      } catch (e) {
        ShowToastDialog.showToast("Server error during upload. Please try again.");
        return false;
      }

      if (res.statusCode == 200 && (body['success'].toString().toLowerCase() == 'success')) {
        ShowToastDialog.showToast(body['message']?.toString() ?? "Uploaded successfully!");
        return true;
      }
      ShowToastDialog.showToast(body['error']?.toString() ?? body['message']?.toString() ?? "Upload failed. Please try again.");
      return false;
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("An error occurred during upload: $e");
      return false;
    }
  }
}
