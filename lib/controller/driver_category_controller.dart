import 'dart:convert';
import 'package:cabme_driver/constant/logdata.dart';
import 'package:cabme_driver/constant/show_toast_dialog.dart';
import 'package:cabme_driver/model/user_category_model.dart';
import 'package:cabme_driver/service/api.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:cabme_driver/controller/auth_otp_controller.dart';
import 'package:cabme_driver/page/auth_screens/vehicle_info_screen.dart';

class DriverCategoryController extends GetxController {
  RxList<UserCategoryData> parentCategories = <UserCategoryData>[].obs;
  RxList<UserCategoryData> subCategories = <UserCategoryData>[].obs;
  
  Rx<UserCategoryData?> selectedParentCategory = Rx<UserCategoryData?>(null);
  Rx<UserCategoryData?> selectedSubCategory = Rx<UserCategoryData?>(null);
  
  RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchUserCategories();
  }

  void selectParentCategory(UserCategoryData? parent) {
    selectedParentCategory.value = parent;
    selectedSubCategory.value = null;
    if (parent != null && parent.subcategories != null) {
      subCategories.assignAll(parent.subcategories!);
    } else {
      subCategories.clear();
    }
  }

  void selectSubCategory(UserCategoryData? sub) {
    selectedSubCategory.value = sub;
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

  Future<void> saveCategory() async {
    if (selectedParentCategory.value == null) {
      ShowToastDialog.showToast("Please select a Category");
      return;
    }
    if (subCategories.isNotEmpty && selectedSubCategory.value == null) {
      ShowToastDialog.showToast("Please select a Subcategory");
      return;
    }

    String categoryId = (selectedSubCategory.value?.id ?? selectedParentCategory.value?.id ?? "").toString();
    
    final authController = Get.isRegistered<AuthOtpController>()
        ? Get.find<AuthOtpController>()
        : Get.put(AuthOtpController());
    final updatedUser = await authController.updateDriverCategory(categoryId);
    
    if (updatedUser != null) {
      ShowToastDialog.showToast("Category updated successfully!");
      // Proceed to Vehicle Info Screen to finish profile
      Get.offAll(() => const VehicleInfoScreen());
    }
  }
}
