class FoodOrderModel {
  bool? success;
  String? error;
  List<FoodOrderData>? data;

  FoodOrderModel({this.success, this.error, this.data});

  FoodOrderModel.fromJson(Map<String, dynamic> json) {
    success = json['success'] == true;
    error = json['error']?.toString();
    if (json['data'] != null && json['data'] is List) {
      data = <FoodOrderData>[];
      for (var v in (json['data'] as List)) {
        data!.add(FoodOrderData.fromJson(v));
      }
    }
  }
}

class FoodOrderData {
  int? id;
  String? orderNumber;
  int? restaurantId;
  String? customerName;
  String? customerPhone;
  String? deliveryAddress;
  String? deliveryLandmark;
  double? deliveryLat;
  double? deliveryLng;
  double? distanceKm;
  double? pickupDistanceKm;
  String? specialInstructions;
  double? foodAmount;
  double? deliveryCharge;
  double? customerPayable;
  String? paymentMethod;
  String? paymentStatus;
  String? orderStatus;
  int? riderId;
  String? riderName;
  String? riderPhone;
  String? riderStatus;
  String? pickupOtp;
  String? deliveryOtp;
  FoodRestaurantData? restaurant;
  List<FoodOrderItemData>? items;

  FoodOrderData({
    this.id,
    this.orderNumber,
    this.restaurantId,
    this.customerName,
    this.customerPhone,
    this.deliveryAddress,
    this.deliveryLandmark,
    this.deliveryLat,
    this.deliveryLng,
    this.distanceKm,
    this.pickupDistanceKm,
    this.specialInstructions,
    this.foodAmount,
    this.deliveryCharge,
    this.customerPayable,
    this.paymentMethod,
    this.paymentStatus,
    this.orderStatus,
    this.riderId,
    this.riderName,
    this.riderPhone,
    this.riderStatus,
    this.pickupOtp,
    this.deliveryOtp,
    this.restaurant,
    this.items,
  });

  FoodOrderData.fromJson(Map<String, dynamic> json) {
    id = json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '');
    orderNumber = json['order_number']?.toString();
    restaurantId = json['restaurant_id'] is int ? json['restaurant_id'] : int.tryParse(json['restaurant_id']?.toString() ?? '');
    customerName = json['customer_name']?.toString();
    customerPhone = json['customer_phone']?.toString();
    deliveryAddress = json['delivery_address']?.toString();
    deliveryLandmark = json['delivery_landmark']?.toString();
    deliveryLat = double.tryParse(json['delivery_lat']?.toString() ?? '');
    deliveryLng = double.tryParse(json['delivery_lng']?.toString() ?? '');
    distanceKm = double.tryParse(json['distance_km']?.toString() ?? '');
    pickupDistanceKm = double.tryParse(json['pickup_distance_km']?.toString() ?? '');
    specialInstructions = json['special_instructions']?.toString();
    foodAmount = double.tryParse(json['food_amount']?.toString() ?? '');
    deliveryCharge = double.tryParse(json['delivery_charge']?.toString() ?? '');
    customerPayable = double.tryParse(json['customer_payable']?.toString() ?? '');
    paymentMethod = json['payment_method']?.toString();
    paymentStatus = json['payment_status']?.toString();
    orderStatus = json['order_status']?.toString();
    riderId = json['rider_id'] is int ? json['rider_id'] : int.tryParse(json['rider_id']?.toString() ?? '');
    riderName = json['rider_name']?.toString();
    riderPhone = json['rider_phone']?.toString();
    riderStatus = json['rider_status']?.toString();
    pickupOtp = json['pickup_otp']?.toString();
    deliveryOtp = json['delivery_otp']?.toString();

    if (json['restaurant'] != null && json['restaurant'] is Map<String, dynamic>) {
      restaurant = FoodRestaurantData.fromJson(json['restaurant']);
    }
    if (json['items'] != null && json['items'] is List) {
      items = <FoodOrderItemData>[];
      for (var v in (json['items'] as List)) {
        items!.add(FoodOrderItemData.fromJson(v));
      }
    }
  }

  String get itemsSummary {
    if (items == null || items!.isEmpty) return "Food Order";
    return items!.map((e) => "${e.quantity ?? 1}x ${e.name ?? ''}").join(", ");
  }
}

class FoodRestaurantData {
  int? id;
  String? name;
  String? address;
  String? phone;
  double? latitude;
  double? longitude;
  String? image;

  FoodRestaurantData({
    this.id,
    this.name,
    this.address,
    this.phone,
    this.latitude,
    this.longitude,
    this.image,
  });

  FoodRestaurantData.fromJson(Map<String, dynamic> json) {
    id = json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '');
    name = json['name']?.toString();
    address = json['address']?.toString();
    phone = json['phone']?.toString();
    latitude = double.tryParse(json['latitude']?.toString() ?? '');
    longitude = double.tryParse(json['longitude']?.toString() ?? '');
    image = json['image']?.toString();
  }
}

class FoodOrderItemData {
  int? id;
  String? name;
  int? quantity;
  double? price;
  String? variantName;

  FoodOrderItemData({
    this.id,
    this.name,
    this.quantity,
    this.price,
    this.variantName,
  });

  FoodOrderItemData.fromJson(Map<String, dynamic> json) {
    id = json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '');
    name = json['name']?.toString();
    quantity = json['quantity'] is int ? json['quantity'] : int.tryParse(json['quantity']?.toString() ?? '1');
    price = double.tryParse(json['price']?.toString() ?? '');
    variantName = json['variant_name']?.toString();
  }
}
