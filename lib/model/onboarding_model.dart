class OnboardingModel {
  final String? success;
  final String? error;
  final String? message;
  final List<OnboardingData>? data;

  OnboardingModel({
    this.success,
    this.error,
    this.message,
    this.data,
  });

  factory OnboardingModel.fromJson(Map<String, dynamic> json) {
    List<OnboardingData> dataList = [];
    if (json['data'] != null && json['data'] is List) {
      var list = json['data'] as List;
      dataList = list
          .where((i) => i != null && i is Map<String, dynamic>)
          .map((i) => OnboardingData.fromJson(i as Map<String, dynamic>))
          .toList();
    }

    return OnboardingModel(
      success: json['success']?.toString(),
      error: json['error']?.toString(),
      message: json['message']?.toString(),
      data: dataList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'error': error,
      'message': message,
      'data': data?.map((screen) => screen.toJson()).toList(),
    };
  }
}

class OnboardingData {
  final String? id;
  final String? type;
  final String? title;
  final String? description;
  final String? image;

  OnboardingData({
    this.id,
    this.type,
    this.title,
    this.description,
    this.image,
  });

  factory OnboardingData.fromJson(Map<String, dynamic> json) {
    return OnboardingData(
      id: json['id']?.toString(),
      type: json['type']?.toString(),
      title: json['title']?.toString(),
      description: json['description']?.toString(),
      image: json['image']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'description': description,
      'image': image,
    };
  }
}
