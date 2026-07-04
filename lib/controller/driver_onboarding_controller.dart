import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:cabme_driver/constant/constant.dart';
import 'package:cabme_driver/constant/logdata.dart';
import 'package:cabme_driver/constant/show_toast_dialog.dart';
import 'package:cabme_driver/model/brand_model.dart';
import 'package:cabme_driver/model/get_vehicle_data_model.dart' as prefix;
import 'package:cabme_driver/model/get_vehicle_getegory.dart';
import 'package:cabme_driver/model/model.dart';
import 'package:cabme_driver/model/user_model.dart';
import 'package:cabme_driver/model/user_category_model.dart';
import 'package:cabme_driver/model/uploaded_document_model.dart';
import 'package:cabme_driver/model/vehicle_register_model.dart';
import 'package:cabme_driver/model/zone_model.dart';
import 'package:cabme_driver/service/api.dart';
import 'package:cabme_driver/utils/Preferences.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:cabme_driver/controller/auth_otp_controller.dart';
import 'package:cabme_driver/controller/dash_board_controller.dart';
import 'package:cabme_driver/controller/new_ride_controller.dart';

class DriverOnboardingController extends GetxController {
  // ── LOADING AND SESSION ───────────────────────────────────────────────────
  RxBool isLoading = true.obs;
  UserModel? userModel;
  String userCat = "driver";

  // ── CATEGORY SELECTION STATE ──────────────────────────────────────────────
  RxList<UserCategoryData> parentCategories = <UserCategoryData>[].obs;
  Rxn<UserCategoryData> selectedPrimaryRole = Rxn<UserCategoryData>();
  RxList<UserCategoryData> selectedDeliveryServices = <UserCategoryData>[].obs;

  // ── VEHICLE INFO STATE ────────────────────────────────────────────────────
  Rx<TextEditingController> brandController = TextEditingController().obs;
  Rx<TextEditingController> modelController = TextEditingController().obs;
  Rx<TextEditingController> colorController = TextEditingController().obs;
  Rx<TextEditingController> carMakeController = TextEditingController().obs;
  Rx<TextEditingController> millageController = TextEditingController().obs;
  Rx<TextEditingController> kmDrivenController = TextEditingController().obs;
  Rx<TextEditingController> numberPlateController = TextEditingController().obs;
  Rx<TextEditingController> numberOfPassengersController = TextEditingController().obs;
  Rx<TextEditingController> zoneNameController = TextEditingController().obs;

  RxList selectedZone = <int>[].obs;
  RxList<ZoneData> zoneList = <ZoneData>[].obs;

  RxString selectedCategoryID = "".obs;
  RxString selectedBrandID = "".obs;
  RxString selectedModelID = "".obs;
  RxString validCategoryIds = "".obs;

  List<VehicleData> vehicleCategoryList = [];

  // ── DOCUMENT STATUS STATE ─────────────────────────────────────────────────
  var documentList = <UploadedDocumentData>[].obs;

  @override
  void onInit() {
    super.onInit();
    getUserdata();
    initializeFlow();
  }

  Future<void> getUserdata() async {
    userModel = Constant.getUserData();
    userCat = userModel?.userData?.userCat ?? "driver";
  }

  Future<void> initializeFlow() async {
    isLoading.value = true;
    try {
      await fetchUserCategories();
      loadExistingSelections();
      await getVehicleDataAPI();
      await getCarServiceBooks();
    } catch (e) {
      log("Error during onboarding flow initialization: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // ── CATEGORY METHODS ──────────────────────────────────────────────────────
  void loadExistingSelections() {
    if (userModel?.userData == null) return;
    final uData = userModel!.userData!;
    
    // Find and set primary transport role
    if (uData.categoryId != null && uData.categoryId!.isNotEmpty) {
      final transportParent = parentCategories.firstWhereOrNull(
        (p) => p.title?.contains('Transport & Mobility') ?? false
      );
      if (transportParent != null && transportParent.subcategories != null) {
        final found = transportParent.subcategories!.firstWhereOrNull(
          (sub) => sub.id.toString() == uData.categoryId
        );
        if (found != null) {
          selectedPrimaryRole.value = found;
          Preferences.setString("selected_role", found.title ?? "");
        }
      }
    }
    
    // Find and set delivery services
    if (uData.selectedCategories != null && uData.selectedCategories!.isNotEmpty) {
      selectedDeliveryServices.clear();
      final deliveryParent = parentCategories.firstWhereOrNull(
        (p) => p.title?.contains('Delivery & Logistics') ?? false
      );
      if (deliveryParent != null && deliveryParent.subcategories != null) {
        for (var subId in uData.selectedCategories!) {
          if (subId == uData.categoryId) continue; // Skip primary
          final found = deliveryParent.subcategories!.firstWhereOrNull(
            (sub) => sub.id.toString() == subId
          );
          if (found != null) {
            selectedDeliveryServices.add(found);
          }
        }
      }
    }
  }

  List<UserCategoryData> getAvailableDeliveryServices() {
    if (selectedPrimaryRole.value == null) return [];
    
    final deliveryParent = parentCategories.firstWhereOrNull(
      (p) => p.title?.contains('Delivery & Logistics') ?? false
    );
    if (deliveryParent == null || deliveryParent.subcategories == null) return [];
    
    final primaryName = selectedPrimaryRole.value!.title?.toLowerCase() ?? '';
    
    return deliveryParent.subcategories!.where((sub) {
      final subName = sub.title?.toLowerCase() ?? '';
      
      if (primaryName.contains('cab driver')) {
        return subName.contains('pickup & drop') || subName.contains('parcel delivery');
      } else if (primaryName.contains('bike rider')) {
        return subName.contains('pickup & drop') || subName.contains('parcel delivery') || subName.contains('food delivery');
      } else if (primaryName.contains('auto driver')) {
        return subName.contains('pickup & drop') || subName.contains('parcel delivery');
      } else if (primaryName.contains('e-rickshaw')) {
        return subName.contains('pickup & drop') || subName.contains('parcel delivery');
      } else if (primaryName.contains('truck owner')) {
        return subName.contains('packers & movers');
      } else if (primaryName.contains('pickup')) {
        return subName.contains('pickup & drop') || subName.contains('logistics partner') || subName.contains('packers & movers');
      }
      return false;
    }).toList();
  }

  void selectPrimaryRole(UserCategoryData role) {
    selectedPrimaryRole.value = role;
    final allowed = getAvailableDeliveryServices();
    selectedDeliveryServices.removeWhere((sub) => !allowed.any((a) => a.id == sub.id));
  }

  void toggleDeliveryService(UserCategoryData sub) {
    if (selectedDeliveryServices.contains(sub)) {
      selectedDeliveryServices.remove(sub);
    } else {
      selectedDeliveryServices.add(sub);
    }
  }

  Future<void> fetchUserCategories() async {
    try {
      final response = await http.get(Uri.parse(API.userCategories), headers: API.authheader);
      if (response.statusCode == 200) {
        Map<String, dynamic> responseBody = json.decode(response.body);
        if (responseBody['success'] == "success") {
          UserCategoryModel model = UserCategoryModel.fromJson(responseBody);
          if (model.data != null) {
            parentCategories.assignAll(model.data!);
          }
        }
      }
    } catch (e) {
      showLog("Error fetching categories: $e");
    }
  }

  Future<bool> saveCategory() async {
    if (selectedPrimaryRole.value == null) {
      ShowToastDialog.showToast("Please select your primary transport role");
      return false;
    }

    ShowToastDialog.showLoader("Please wait".tr);

    try {
      final primaryCategoryId = selectedPrimaryRole.value!.id.toString();
      final subcategoryIds = selectedDeliveryServices.map((sub) => sub.id.toString()).toList();

      // Automatically append Marketplace & Sellers subcategory IDs
      final marketplaceParent = parentCategories.firstWhereOrNull(
        (p) => p.title?.contains('Marketplace & Sellers') ?? false
      );
      if (marketplaceParent != null && marketplaceParent.subcategories != null) {
        for (var sub in marketplaceParent.subcategories!) {
          final idStr = sub.id.toString();
          if (!subcategoryIds.contains(idStr)) {
            subcategoryIds.add(idStr);
          }
        }
      }

      final authController = Get.isRegistered<AuthOtpController>()
          ? Get.find<AuthOtpController>()
          : Get.put(AuthOtpController());

      final updatedUser = await authController.updateDriverCategory(primaryCategoryId, subcategoryIds);
      ShowToastDialog.closeLoader();
      if (updatedUser != null) {
        log("Driver category updated successfully to category ID: $primaryCategoryId");
        userModel = updatedUser;
        
        // Synchronize state across other active controllers to reflect new categories immediately
        if (Get.isRegistered<DashBoardController>()) {
          Get.find<DashBoardController>().userModel.value = updatedUser;
          Get.find<DashBoardController>().update();
        }
        if (Get.isRegistered<NewRideController>()) {
          Get.find<NewRideController>().userModel.value = updatedUser;
          Get.find<NewRideController>().update();
        }
        
        return true;
      }
      ShowToastDialog.showToast("Failed to save categories. Please try again.".tr);
      return false;
    } catch (e) {
      ShowToastDialog.closeLoader();
      showLog("Error saving categories: $e");
      ShowToastDialog.showToast("Error updating categories".tr);
      return false;
    }
  }

  // ── VEHICLE METHODS ───────────────────────────────────────────────────────
  Future<dynamic> getVehicleDataAPI() async {
    try {
      final driverId = Preferences.getInt(Preferences.userId);
      if (driverId <= 0) return null;
      final response = await http.get(Uri.parse("${API.getVehicleData}$driverId"), headers: API.header);

      showLog("API :: URL :: ${API.getVehicleData}$driverId ");
      showLog("API :: responseStatus :: ${response.statusCode} ");
      Map<String, dynamic> responseBody = json.decode(response.body);
      if (response.statusCode == 200 && responseBody['success'] == "success") {
        await getVehicleData(prefix.GetVehicleDataModel.fromJson(responseBody));
        await getVehicleCategory();
        await getZone();
        await getBrand();
        Map<String, String> bodyParams = {
          'brand': brandController.value.text,
          'vehicle_type': validCategoryIds.value,
        };
        getModel(bodyParams);
      } else if (response.statusCode == 200 && responseBody['success'] == "Failed") {
        await getVehicleCategory();
        await getZone();
      }
    } catch (e) {
      showLog("Error fetching vehicle data: $e");
    }
    return null;
  }

  Future<void> getVehicleData(prefix.GetVehicleDataModel getVehicleDataModel) async {
    final prefix.VehicleData vehicleData = getVehicleDataModel.vehicleData!;
    selectedBrandID.value = vehicleData.brand ?? '';
    selectedModelID.value = vehicleData.model ?? '';
    colorController.value.text = vehicleData.color ?? '';
    carMakeController.value.text = vehicleData.carMake ?? '';
    numberPlateController.value.text = vehicleData.numberplate ?? '';
    numberOfPassengersController.value.text = vehicleData.passenger ?? '';
    kmDrivenController.value.text = vehicleData.km ?? '';
    millageController.value.text = vehicleData.milage ?? '';
    selectedCategoryID.value = vehicleData.idTypeVehicule?.toString() ?? '';

    selectedZone.clear();
    if (vehicleData.zone_id != null) {
      for (var element in vehicleData.zone_id!) {
        selectedZone.add(int.parse(element.toString()));
      }
    }
  }

  Future<VehicleRegisterModel?> vehicleRegister(Map<String, String> bodyParams) async {
    try {
      ShowToastDialog.showLoader("Please wait");
      final response = await http.post(Uri.parse(API.vehicleRegister), headers: API.header, body: jsonEncode(bodyParams));
      showLog("API :: URL :: ${API.vehicleRegister} ");
      showLog("API :: Request Body :: ${jsonEncode(bodyParams)} ");
      showLog("API :: responseStatus :: ${response.statusCode} ");

      Map<String, dynamic> responseBody = json.decode(response.body);
      ShowToastDialog.closeLoader();
      if (response.statusCode == 200) {
        return VehicleRegisterModel.fromJson(responseBody);
      } else {
        ShowToastDialog.showToast(responseBody['error'] ?? 'Something went wrong. Please try again later');
      }
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.toString());
    }
    return null;
  }

  Future<VehicleData?> getVehicleCategory() async {
    try {
      final response = await http.get(Uri.parse(API.vehicleCategory), headers: API.header);
      Map<String, dynamic> responseBody = json.decode(response.body);
      if (response.statusCode == 200) {
        final VehicleCategoryModel getVehicleCategory = VehicleCategoryModel.fromJson(responseBody);
        vehicleCategoryList = getVehicleCategory.vehicleData!;

        String role = Preferences.getString("selected_role");
        if (role.isEmpty && selectedPrimaryRole.value != null) {
          role = selectedPrimaryRole.value!.title ?? "";
        }
        if (role.isNotEmpty) {
          final roleLower = role.toLowerCase();
          if (roleLower.contains("bike")) {
            vehicleCategoryList = vehicleCategoryList.where((element) => element.libelle?.toLowerCase() == "bike").toList();
          } else if (roleLower.contains("auto") || roleLower.contains("rickshaw")) {
            vehicleCategoryList = vehicleCategoryList.where((element) => element.libelle?.toLowerCase() == "auto").toList();
          } else if (roleLower.contains("pickup") || roleLower.contains("truck")) {
            vehicleCategoryList = vehicleCategoryList.where((element) => element.libelle?.toLowerCase() == "pickup").toList();
          } else {
            List<String> cabCategories = ["mini", "sedan", "suv", "xl (6–7 seater)", "luxury", "premium xl (luxury mpv/suv)"];
            vehicleCategoryList = vehicleCategoryList.where((element) => cabCategories.contains(element.libelle?.toLowerCase())).toList();
          }
        }
        validCategoryIds.value = vehicleCategoryList.map((e) => e.id).join(",");
        update();
        return VehicleData.fromJson(responseBody);
      }
    } catch (e) {
      showLog("Error fetching vehicle categories: $e");
    }
    return null;
  }

  Future<List<BrandData>?> getBrand() async {
    try {
      String url = API.brand;
      if (validCategoryIds.value.isNotEmpty) {
        url = "$url?vehicle_type_id=${validCategoryIds.value}";
      }
      final response = await http.get(Uri.parse(url), headers: API.header);
      Map<String, dynamic> responseBody = json.decode(response.body);
      if (response.statusCode == 200 && responseBody['success'] == "success") {
        BrandModel model = BrandModel.fromJson(responseBody);
        for (int i = 0; i < model.data!.length; i++) {
          if (selectedBrandID.value.toString() == model.data![i].id.toString()) {
            brandController.value.text = model.data![i].name.toString();
          }
        }
        return model.data!;
      }
    } catch (e) {
      showLog("Error fetching brands: $e");
    }
    return null;
  }

  Future<List<ZoneData>?> getZone() async {
    try {
      final response = await http.get(Uri.parse(API.getZone), headers: API.authheader);
      Map<String, dynamic> responseBody = json.decode(response.body);
      if (response.statusCode == 200 && responseBody['success'] == "success") {
        ZoneModel model = ZoneModel.fromJson(responseBody);
        zoneNameController.value.text = "";
        for (var element in selectedZone) {
          zoneNameController.value.text =
              "${zoneNameController.value.text}${zoneNameController.value.text.isEmpty ? "" : ","} ${model.data!.where((p0) => p0.id == element).first.name}";
        }
        zoneList.value = model.data!;
        return model.data;
      }
    } catch (e) {
      showLog("Error fetching zones: $e");
    }
    return null;
  }

  Future<List<ModelData>?> getModel(bodyParams) async {
    try {
      final response = await http.post(Uri.parse(API.model), headers: API.header, body: jsonEncode(bodyParams));
      Map<String, dynamic> responseBody = json.decode(response.body);
      if (response.statusCode == 200 && responseBody['success'] == "success") {
        Model model = Model.fromJson(responseBody);
        for (int i = 0; i < model.data!.length; i++) {
          if (selectedModelID.value.toString() == model.data![i].id.toString()) {
            modelController.value.text = model.data![i].name.toString();
          }
        }
        return model.data!;
      }
    } catch (e) {
      showLog("Error fetching models: $e");
    }
    return null;
  }

  // ── DOCUMENT METHODS ──────────────────────────────────────────────────────
  Future<dynamic> getCarServiceBooks() async {
    try {
      final driverId = Preferences.getInt(Preferences.userId);
      if (driverId <= 0) return null;
      final response = await http.get(Uri.parse("${API.getDriverUploadedDocument}?driver_id=$driverId"), headers: API.header);
      Map<String, dynamic> responseBody = json.decode(response.body);
      if (response.statusCode == 200 && responseBody['success'] == "success") {
        UploadedDocumentModel model = UploadedDocumentModel.fromJson(responseBody);
        documentList.value = model.data!;
      }
    } catch (e) {
      showLog("Error fetching documents: $e");
    }
    return null;
  }

  Future<dynamic> updateDocument(String driverDocumentId, String path) async {
    try {
      ShowToastDialog.showLoader("Please wait");
      var request = http.MultipartRequest('POST', Uri.parse(API.driverDocumentUpdate));
      request.headers.addAll(API.header);
      request.files.add(http.MultipartFile.fromBytes(
        'attachment',
        File(path).readAsBytesSync(),
        filename: File(path).path.split('/').last,
      ));
      request.fields['document_id'] = driverDocumentId;
      request.fields['driver_id'] = Preferences.getInt(Preferences.userId).toString();

      var res = await request.send();
      var responseData = await res.stream.toBytes();
      Map<String, dynamic> response = jsonDecode(String.fromCharCodes(responseData));
      ShowToastDialog.closeLoader();

      if (res.statusCode == 200 && response['success'].toString().toLowerCase() == 'success') {
        ShowToastDialog.showToast("Document uploaded! Pending verification by admin.");
        await getCarServiceBooks();
        return true;
      } else {
        ShowToastDialog.showToast(response['error'] ?? 'Upload failed. Please try again.');
      }
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.toString());
    }
    return null;
  }

  @override
  void dispose() {
    brandController.value.clear();
    modelController.value.clear();
    colorController.value.clear();
    carMakeController.value.clear();
    millageController.value.clear();
    kmDrivenController.value.clear();
    numberPlateController.value.clear();
    numberOfPassengersController.value.clear();
    zoneNameController.value.clear();
    selectedCategoryID.value = "";
    selectedBrandID.value = "";
    selectedModelID.value = "";
    super.dispose();
  }
}
