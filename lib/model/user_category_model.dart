class UserCategoryModel {
  String? success;
  String? error;
  String? message;
  List<UserCategoryData>? data;

  UserCategoryModel({this.success, this.error, this.message, this.data});

  UserCategoryModel.fromJson(Map<String, dynamic> json) {
    success = json['success'].toString();
    error = json['error']?.toString();
    message = json['message']?.toString();
    if (json['data'] != null) {
      data = <UserCategoryData>[];
      json['data'].forEach((v) {
        data!.add(UserCategoryData.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    data['error'] = error;
    data['message'] = message;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class UserCategoryData {
  String? id;
  String? title;
  String? slug;
  String? parentId;
  List<UserCategoryData>? subcategories;

  UserCategoryData({this.id, this.title, this.slug, this.parentId, this.subcategories});

  UserCategoryData.fromJson(Map<String, dynamic> json) {
    id = json['id']?.toString();
    title = (json['title'] ?? json['libelle'])?.toString();
    slug = json['slug']?.toString();
    parentId = json['parent_id']?.toString();
    if (json['subcategories'] != null) {
      subcategories = <UserCategoryData>[];
      json['subcategories'].forEach((v) {
        subcategories!.add(UserCategoryData.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['title'] = title;
    data['slug'] = slug;
    data['parent_id'] = parentId;
    if (subcategories != null) {
      data['subcategories'] = subcategories!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}
