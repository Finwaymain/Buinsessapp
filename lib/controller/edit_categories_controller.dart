import 'dart:convert';
import 'dart:developer';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../constant/constant.dart';
import '../constant/show_toast_dialog.dart';
import '../service/api.dart';
import '../utils/Preferences.dart';

class CategoryItem {
  final int id;
  final String title;
  final String? image;
  final int? parentId;
  final List<CategoryItem> subcategories;

  CategoryItem({
    required this.id,
    required this.title,
    this.image,
    this.parentId,
    this.subcategories = const [],
  });

  factory CategoryItem.fromJson(Map<String, dynamic> json) {
    var subsList = <CategoryItem>[];
    if (json['subcategories'] != null && json['subcategories'] is List) {
      subsList = (json['subcategories'] as List)
          .map((sub) => CategoryItem.fromJson(Map<String, dynamic>.from(sub)))
          .toList();
    }
    return CategoryItem(
      id: int.tryParse(json['id'].toString()) ?? 0,
      title: json['libelle']?.toString() ?? '',
      image: json['image']?.toString(),
      parentId: json['parent_id'] != null ? int.tryParse(json['parent_id'].toString()) : null,
      subcategories: subsList,
    );
  }
}

class EditCategoriesController extends GetxController {
  var isLoading = true.obs;
  var isSaving = false.obs;
  var searchQuery = ''.obs;

  var parentCategories = <CategoryItem>[].obs;
  var selectedParentIndex = 0.obs;

  // Selected subcategory IDs
  var selectedSubcategoryIds = <int>{}.obs;
  var primaryCategoryId = 0.obs;

  @override
  void onInit() {
    super.onInit();
    loadCategories();
  }

  Future<void> loadCategories() async {
    try {
      isLoading.value = true;

      // 1. Fetch user's current selected categories from getDriverServices
      final driverId = Preferences.getInt(Preferences.userId);
      final currentSelected = <int>{};

      try {
        final serviceRes = await http.get(
          Uri.parse('${API.getDriverServices}?driver_id=$driverId'),
          headers: API.header,
        );

        if (serviceRes.statusCode == 200) {
          final serviceData = jsonDecode(serviceRes.body);
          if (serviceData['data'] != null && serviceData['data'] is List) {
            for (var item in serviceData['data']) {
              final subId = int.tryParse(item['subcategory_id']?.toString() ?? '');
              final catId = int.tryParse(item['category_id']?.toString() ?? '');
              if (subId != null && subId > 0) {
                currentSelected.add(subId);
              } else if (catId != null && catId > 0) {
                currentSelected.add(catId);
              }
            }
          }
        }
      } catch (e) {
        log("Error fetching driver services: $e");
      }

      // Also fallback to userModel's selectedCategories or categoryId
      final userModel = Constant.getUserData();
      if (userModel.userData?.categoryId != null) {
        final catId = int.tryParse(userModel.userData!.categoryId!);
        if (catId != null && catId > 0) {
          currentSelected.add(catId);
          if (primaryCategoryId.value == 0) {
            primaryCategoryId.value = catId;
          }
        }
      }

      if (userModel.userData?.selectedCategories != null) {
        for (var cat in userModel.userData!.selectedCategories!) {
          final id = int.tryParse(cat.toString());
          if (id != null && id > 0) currentSelected.add(id);
        }
      }

      selectedSubcategoryIds.assignAll(currentSelected);
      if (currentSelected.isNotEmpty && primaryCategoryId.value == 0) {
        primaryCategoryId.value = currentSelected.first;
      }

      // 2. Fetch full categories list from API.userCategories
      final res = await http.get(
        Uri.parse(API.userCategories),
        headers: API.header,
      );

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        if (json['data'] != null && json['data'] is List) {
          final list = (json['data'] as List)
              .map((c) => CategoryItem.fromJson(Map<String, dynamic>.from(c)))
              .toList();
          parentCategories.assignAll(list);
        }
      }
    } catch (e) {
      log("Error loading categories: $e");
      ShowToastDialog.showToast("Failed to load categories. Please try again.");
    } finally {
      isLoading.value = false;
    }
  }

  void toggleCategory(int subcategoryId) {
    if (selectedSubcategoryIds.contains(subcategoryId)) {
      selectedSubcategoryIds.remove(subcategoryId);
      if (primaryCategoryId.value == subcategoryId) {
        primaryCategoryId.value = selectedSubcategoryIds.isNotEmpty ? selectedSubcategoryIds.first : 0;
      }
    } else {
      selectedSubcategoryIds.add(subcategoryId);
      if (primaryCategoryId.value == 0) {
        primaryCategoryId.value = subcategoryId;
      }
    }
  }

  bool isCategorySelected(int subcategoryId) {
    return selectedSubcategoryIds.contains(subcategoryId);
  }

  List<CategoryItem> get filteredSubcategories {
    if (parentCategories.isEmpty) return [];

    final query = searchQuery.value.trim().toLowerCase();
    if (query.isNotEmpty) {
      final allSubs = <CategoryItem>[];
      for (var parent in parentCategories) {
        for (var sub in parent.subcategories) {
          if (sub.title.toLowerCase().contains(query) || parent.title.toLowerCase().contains(query)) {
            allSubs.add(sub);
          }
        }
        if (parent.subcategories.isEmpty && parent.title.toLowerCase().contains(query)) {
          allSubs.add(parent);
        }
      }
      return allSubs;
    }

    if (selectedParentIndex.value < parentCategories.length) {
      final currentParent = parentCategories[selectedParentIndex.value];
      if (currentParent.subcategories.isNotEmpty) {
        return currentParent.subcategories;
      } else {
        return [currentParent];
      }
    }

    return [];
  }

  Future<bool> saveCategories() async {
    if (selectedSubcategoryIds.isEmpty) {
      ShowToastDialog.showToast("Please select at least one service category.".tr);
      return false;
    }

    try {
      isSaving.value = true;
      ShowToastDialog.showLoader("Saving categories...".tr);

      final driverId = Preferences.getInt(Preferences.userId);
      final primaryId = primaryCategoryId.value != 0 ? primaryCategoryId.value : selectedSubcategoryIds.first;
      final subIdsList = selectedSubcategoryIds.toList();

      final body = {
        'id_conducteur': driverId.toString(),
        'category_id': primaryId.toString(),
        'subcategory_ids': jsonEncode(subIdsList),
      };

      final response = await http.post(
        Uri.parse(API.authUpdateDriverCategory),
        headers: API.header,
        body: jsonEncode(body),
      );

      ShowToastDialog.closeLoader();

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == 'success' || json['success'] == true) {
          if (json['data'] != null) {
            Preferences.setString(Preferences.user, jsonEncode(json['data']));
          }
          ShowToastDialog.showToast("Categories updated successfully!".tr);
          return true;
        } else {
          ShowToastDialog.showToast(json['error']?.toString() ?? "Failed to update categories.".tr);
          return false;
        }
      } else {
        ShowToastDialog.showToast("Server error. Please try again.".tr);
        return false;
      }
    } catch (e) {
      ShowToastDialog.closeLoader();
      log("Error saving categories: $e");
      ShowToastDialog.showToast("An error occurred while saving categories.".tr);
      return false;
    } finally {
      isSaving.value = false;
    }
  }
}
