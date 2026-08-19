class DriverKitResponseModel {
  final String success;
  final DriverKitDataModel? data;

  DriverKitResponseModel({
    required this.success,
    this.data,
  });

  factory DriverKitResponseModel.fromJson(Map<String, dynamic> json) {
    return DriverKitResponseModel(
      success: json['success']?.toString() ?? '',
      data: json['data'] != null ? DriverKitDataModel.fromJson(json['data']) : null,
    );
  }
}

class DriverKitDataModel {
  final int driverId;
  final String driverName;
  final String categoryCode;
  final String categoryLabel;
  final bool isVerified;
  final bool hasPurchased;
  final bool shouldShowPopup;
  final bool isCompulsory;
  final DriverKitItemModel? kit;
  final DriverKitOrderModel? order;

  DriverKitDataModel({
    required this.driverId,
    required this.driverName,
    required this.categoryCode,
    required this.categoryLabel,
    required this.isVerified,
    required this.hasPurchased,
    required this.shouldShowPopup,
    required this.isCompulsory,
    this.kit,
    this.order,
  });

  factory DriverKitDataModel.fromJson(Map<String, dynamic> json) {
    return DriverKitDataModel(
      driverId: json['driver_id'] is int ? json['driver_id'] : int.tryParse(json['driver_id']?.toString() ?? '0') ?? 0,
      driverName: json['driver_name']?.toString() ?? '',
      categoryCode: json['category_code']?.toString() ?? 'bike',
      categoryLabel: json['category_label']?.toString() ?? '',
      isVerified: json['is_verified'] == true,
      hasPurchased: json['has_purchased'] == true,
      shouldShowPopup: json['should_show_popup'] == true,
      isCompulsory: json['is_compulsory'] == true,
      kit: json['kit'] != null ? DriverKitItemModel.fromJson(json['kit']) : null,
      order: json['order'] != null ? DriverKitOrderModel.fromJson(json['order']) : null,
    );
  }
}

class DriverKitItemModel {
  final int id;
  final String categoryCode;
  final String title;
  final String description;
  final double price;
  final String priceFormatted;
  final String image;
  final List<String> itemsIncluded;
  final bool isCompulsory;
  final String webviewUrl;

  DriverKitItemModel({
    required this.id,
    required this.categoryCode,
    required this.title,
    required this.description,
    required this.price,
    required this.priceFormatted,
    required this.image,
    required this.itemsIncluded,
    required this.isCompulsory,
    required this.webviewUrl,
  });

  factory DriverKitItemModel.fromJson(Map<String, dynamic> json) {
    var rawItems = json['items_included'];
    List<String> items = [];
    if (rawItems is List) {
      items = rawItems.map((e) => e.toString()).toList();
    }

    return DriverKitItemModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      categoryCode: json['category_code']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Partner Welcome Kit',
      description: json['description']?.toString() ?? '',
      price: (json['price'] is num) ? (json['price'] as num).toDouble() : double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      priceFormatted: json['price_formatted']?.toString() ?? '₹0.00',
      image: json['image']?.toString() ?? '',
      itemsIncluded: items,
      isCompulsory: json['is_compulsory'] == true,
      webviewUrl: json['webview_url']?.toString() ?? '',
    );
  }
}

class DriverKitOrderModel {
  final int id;
  final String orderNumber;
  final double amount;
  final String tshirtSize;
  final String deliveryStatus;
  final String? trackingNumber;
  final String? courierPartner;
  final String? purchasedAt;

  DriverKitOrderModel({
    required this.id,
    required this.orderNumber,
    required this.amount,
    required this.tshirtSize,
    required this.deliveryStatus,
    this.trackingNumber,
    this.courierPartner,
    this.purchasedAt,
  });

  factory DriverKitOrderModel.fromJson(Map<String, dynamic> json) {
    return DriverKitOrderModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      orderNumber: json['order_number']?.toString() ?? '',
      amount: (json['amount'] is num) ? (json['amount'] as num).toDouble() : double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      tshirtSize: json['tshirt_size']?.toString() ?? '',
      deliveryStatus: json['delivery_status']?.toString() ?? 'processing',
      trackingNumber: json['tracking_number']?.toString(),
      courierPartner: json['courier_partner']?.toString(),
      purchasedAt: json['purchased_at']?.toString(),
    );
  }
}
