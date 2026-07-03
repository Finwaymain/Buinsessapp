import 'dart:convert';
import 'package:cabme_driver/constant/logdata.dart';
import 'package:cabme_driver/constant/show_toast_dialog.dart';
import 'package:cabme_driver/model/user_category_model.dart';
import 'package:cabme_driver/service/api.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:cabme_driver/controller/auth_otp_controller.dart';

class DriverCategoryController extends GetxController {
  RxList<UserCategoryData> parentCategories = <UserCategoryData>[].obs;
  
  // Selected multiple parent categories
  RxList<UserCategoryData> selectedParentCategories = <UserCategoryData>[].obs;
  
  // Map of parent_id -> selected subcategory
  RxMap<String, UserCategoryData> selectedSubCategories = <String, UserCategoryData>{}.obs;
  
  RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchUserCategories();
  }

  bool isActiveCategory(String? title) {
    if (title == null) return false;
    return title.contains('Transport & Mobility') || title.contains('Delivery & Logistics');
  }

  void toggleParentCategory(UserCategoryData parent) {
    if (!isActiveCategory(parent.title)) {
      ShowToastDialog.showToast("This category is coming soon!");
      return;
    }

    if (selectedParentCategories.contains(parent)) {
      selectedParentCategories.remove(parent);
      selectedSubCategories.remove(parent.id.toString());
    } else {
      selectedParentCategories.add(parent);
    }
  }

  void selectSubCategory(String parentId, UserCategoryData sub) {
    selectedSubCategories[parentId] = sub;
  }

  Future<void> fetchUserCategories() async {
    try {
      isLoading.value = true;
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
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> saveCategory() async {
    if (selectedParentCategories.isEmpty) {
      ShowToastDialog.showToast("Please select at least one Category");
      return false;
    }

    // Verify each selected parent has a subcategory selected
    for (var parent in selectedParentCategories) {
      if (parent.subcategories != null && parent.subcategories!.isNotEmpty) {
        if (!selectedSubCategories.containsKey(parent.id.toString())) {
          ShowToastDialog.showToast("Please select a subcategory for ${parent.title}");
          return false;
        }
      }
    }

    // Prepare JSON array of categories
    List<Map<String, dynamic>> finalSelection = [];
    for (var parent in selectedParentCategories) {
      final sub = selectedSubCategories[parent.id.toString()];
      finalSelection.add({
        "category_id": parent.id,
        "subcategory_id": sub?.id,
      });
    }

    // Currently API takes single categoryId. 
    // We will serialize as JSON for now, assuming backend will be updated to accept a list or we send the primary one.
    // For now we will send the first selected subcategory/category as fallback, but also a custom field if we modify API
    String primaryCategoryId = finalSelection.first["subcategory_id"]?.toString() ?? finalSelection.first["category_id"].toString();
    
    final authController = Get.isRegistered<AuthOtpController>()
        ? Get.find<AuthOtpController>()
        : Get.put(AuthOtpController());
    
    final updatedUser = await authController.updateDriverCategory(primaryCategoryId, categories: finalSelection);
    return updatedUser != null;
  }
}
