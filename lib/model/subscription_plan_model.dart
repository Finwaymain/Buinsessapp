import 'dart:convert';

class SubscriptionPlanModel {
  String? success;
  String? error;
  String? message;
  List<SubscriptionPlanData>? data;

  SubscriptionPlanModel({this.success, this.error, this.message, this.data});

  SubscriptionPlanModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    error = json['error'];
    message = json['message'];
    if (json['data'] != null) {
      data = <SubscriptionPlanData>[];
      json['data'].forEach((v) {
        data!.add(SubscriptionPlanData.fromJson(v));
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

class SubscriptionPlanData {
  String? id;
  String? bookingLimit;
  String? description;
  String? expiryDay;
  String? image;
  String? isEnable;
  String? name;
  String? place;
  List<String>? planPoints;
  String? price;
  String? type;
  String? createdAt;
  String? updatedAt;
  String? cashbackOnPurchase;
  int? tierLevel;
  String? commissionRate;
  String? badge;
  List<String>? benefitsList;
  Map<String, dynamic>? lossCalculator;

  SubscriptionPlanData(
      {this.id,
        this.bookingLimit,
        this.description,
        this.expiryDay,
        this.image,
        this.isEnable,
        this.name,
        this.place,
        this.planPoints,
        this.price,
        this.type,
        this.createdAt,
        this.updatedAt,
        this.cashbackOnPurchase,
        this.tierLevel,
        this.commissionRate,
        this.badge,
        this.benefitsList,
        this.lossCalculator});

  SubscriptionPlanData.fromJson(Map<String, dynamic> json) {
    id = json['id']?.toString();
    bookingLimit = json['bookingLimit']?.toString();
    description = json['description']?.toString();
    expiryDay = json['expiryDay']?.toString();
    image = json['image']?.toString();
    isEnable = json['isEnable']?.toString();
    name = json['name']?.toString();
    place = json['place']?.toString();
    if (json['plan_points'] != null) {
      var points = json['plan_points'];
      if (points is String) {
        try {
          var decoded = jsonDecode(points);
          if (decoded is List) {
            planPoints = List<String>.from(decoded.map((e) => e.toString()));
          } else {
            planPoints = [decoded.toString()];
          }
        } catch (e) {
          planPoints = [points.toString()];
        }
      } else if (points is List) {
        planPoints = List<String>.from(points.map((e) => e.toString()));
      } else {
        planPoints = [points.toString()];
      }
    } else {
      planPoints = [];
    }
    price = json['price']?.toString();
    type = json['type']?.toString();
    cashbackOnPurchase = json['cashback_on_purchase']?.toString();
    tierLevel = json['tier_level'] != null ? int.tryParse(json['tier_level'].toString()) : null;
    commissionRate = json['commission_rate']?.toString();
    badge = json['badge']?.toString();
    if (json['benefits_list'] != null) {
      var benefits = json['benefits_list'];
      if (benefits is String) {
        try {
          var decoded = jsonDecode(benefits);
          if (decoded is List) {
            benefitsList = List<String>.from(decoded.map((e) => e.toString()));
          } else {
            benefitsList = [decoded.toString()];
          }
        } catch (_) {
          benefitsList = [benefits.toString()];
        }
      } else if (benefits is List) {
        benefitsList = List<String>.from(benefits.map((e) => e.toString()));
      }
    }
    if (json['loss_calculator'] is Map) {
      lossCalculator = Map<String, dynamic>.from(json['loss_calculator']);
    }
    createdAt = json['created_at']?.toString();
    updatedAt = json['updated_at']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['bookingLimit'] = bookingLimit;
    data['description'] = description;
    data['expiryDay'] = expiryDay;
    data['image'] = image;
    data['isEnable'] = isEnable;
    data['name'] = name;
    data['place'] = place;
    data['plan_points'] = planPoints;
    data['price'] = price;
    data['type'] = type;
    data['cashback_on_purchase'] = cashbackOnPurchase;
    data['tier_level'] = tierLevel;
    data['commission_rate'] = commissionRate;
    data['badge'] = badge;
    data['benefits_list'] = benefitsList;
    data['loss_calculator'] = lossCalculator;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    return data;
  }
}
