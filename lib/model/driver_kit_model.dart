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
  final bool bookingRequired;
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
    required this.bookingRequired,
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
      bookingRequired: json['booking_required'] == true,
      kit: json['kit'] != null ? DriverKitItemModel.fromJson(json['kit']) : null,
      order: json['order'] != null ? DriverKitOrderModel.fromJson(json['order']) : null,
    );
  }
}

class DriverKitItemModel {
  final int id;
  final String sku;
  final String categoryCode;
  final String title;
  final String description;
  final double price;
  final String priceFormatted;
  final double mrp;
  final String mrpFormatted;
  final double cashbackAmount;
  final String cashbackFormatted;
  final int stockQuantity;
  final String image;
  final List<String> itemsIncluded;
  final List<String> sizes;
  final bool isCompulsory;
  final bool bookingRequired;
  final String webviewUrl;
  final double costPrice;
  final String status;
  final List<DriverKitProductModel> products;

  DriverKitItemModel({
    required this.id,
    required this.sku,
    required this.categoryCode,
    required this.title,
    required this.description,
    required this.price,
    required this.priceFormatted,
    required this.mrp,
    required this.mrpFormatted,
    required this.cashbackAmount,
    required this.cashbackFormatted,
    required this.stockQuantity,
    required this.image,
    required this.itemsIncluded,
    required this.sizes,
    required this.isCompulsory,
    required this.bookingRequired,
    required this.webviewUrl,
    required this.costPrice,
    required this.status,
    required this.products,
  });

  factory DriverKitItemModel.fromJson(Map<String, dynamic> json) {
    var rawItems = json['items_included'];
    List<String> items = [];
    if (rawItems is List) {
      items = rawItems.map((e) => e.toString()).toList();
    }

    var rawSizes = json['sizes'];
    List<String> sizeList = [];
    if (rawSizes is List) {
      sizeList = rawSizes.map((e) => e.toString()).toList();
    }
    if (sizeList.isEmpty) {
      sizeList = ['S', 'M', 'L', 'XL', 'XXL'];
    }

    var rawProducts = json['products'];
    List<DriverKitProductModel> prodList = [];
    if (rawProducts is List) {
      prodList = rawProducts
          .whereType<Map<String, dynamic>>()
          .map((p) => DriverKitProductModel.fromJson(p))
          .toList();
    }

    double p = (json['price'] is num) ? (json['price'] as num).toDouble() : double.tryParse(json['price']?.toString() ?? '0') ?? 0.0;
    double m = (json['mrp'] is num) ? (json['mrp'] as num).toDouble() : double.tryParse(json['mrp']?.toString() ?? '0') ?? (p * 1.5);
    double cb = (json['cashback_amount'] is num) ? (json['cashback_amount'] as num).toDouble() : double.tryParse(json['cashback_amount']?.toString() ?? '0') ?? 0.0;
    double cp = (json['cost_price'] is num) ? (json['cost_price'] as num).toDouble() : double.tryParse(json['cost_price']?.toString() ?? '0') ?? 0.0;

    return DriverKitItemModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      sku: json['sku']?.toString() ?? '',
      categoryCode: json['category_code']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Partner Welcome Kit',
      description: json['description']?.toString() ?? '',
      price: p,
      priceFormatted: json['price_formatted']?.toString() ?? '₹${p.toStringAsFixed(0)}',
      mrp: m,
      mrpFormatted: json['mrp_formatted']?.toString() ?? '₹${m.toStringAsFixed(0)}',
      cashbackAmount: cb,
      cashbackFormatted: json['cashback_formatted']?.toString() ?? '₹${cb.toStringAsFixed(0)}',
      stockQuantity: json['stock_quantity'] is int ? json['stock_quantity'] : int.tryParse(json['stock_quantity']?.toString() ?? '500') ?? 500,
      image: json['image']?.toString() ?? '',
      itemsIncluded: items,
      sizes: sizeList,
      isCompulsory: json['is_compulsory'] == true,
      bookingRequired: json['booking_required'] != false,
      webviewUrl: json['webview_url']?.toString() ?? '',
      costPrice: cp,
      status: json['status']?.toString() ?? 'published',
      products: prodList,
    );
  }
}

class DriverKitProductModel {
  final int? id;
  final String name;
  final String image;
  final String variant;
  final int quantity;
  final bool isFree;
  final double price;
  final bool isMandatory;

  DriverKitProductModel({
    this.id,
    required this.name,
    required this.image,
    required this.variant,
    required this.quantity,
    required this.isFree,
    required this.price,
    required this.isMandatory,
  });

  factory DriverKitProductModel.fromJson(Map<String, dynamic> json) {
    return DriverKitProductModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      name: json['name']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
      variant: json['variant']?.toString() ?? '',
      quantity: json['quantity'] is int ? json['quantity'] : int.tryParse(json['quantity']?.toString() ?? '1') ?? 1,
      isFree: json['is_free'] == true || json['is_free'] == 1 || json['is_free']?.toString() == '1',
      price: (json['price'] is num) ? (json['price'] as num).toDouble() : double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      isMandatory: json['is_mandatory'] != false && json['is_mandatory']?.toString() != '0',
    );
  }
}

class DriverKitOrderModel {
  final int id;
  final String orderNumber;
  final double amount;
  final String selectedSize;
  final String deliveryStatus;
  final String trackingCode;
  final String? trackingUrl;
  final String courierPartner;
  final String? expectedDeliveryDate;
  final String? deliveryPartnerName;
  final String? deliveryPartnerPhone;
  final String? deliveryPartnerVehicle;
  final String? deliveryPartnerId;
  final List<KitTimelineStepModel> timeline;
  final String? purchasedAt;

  DriverKitOrderModel({
    required this.id,
    required this.orderNumber,
    required this.amount,
    required this.selectedSize,
    required this.deliveryStatus,
    required this.trackingCode,
    this.trackingUrl,
    required this.courierPartner,
    this.expectedDeliveryDate,
    this.deliveryPartnerName,
    this.deliveryPartnerPhone,
    this.deliveryPartnerVehicle,
    this.deliveryPartnerId,
    required this.timeline,
    this.purchasedAt,
  });

  factory DriverKitOrderModel.fromJson(Map<String, dynamic> json) {
    var rawTimeline = json['timeline'] ?? json['status_timeline'];
    List<KitTimelineStepModel> steps = [];
    if (rawTimeline is List) {
      steps = rawTimeline.map((e) => KitTimelineStepModel.fromJson(Map<String, dynamic>.from(e))).toList();
    }

    return DriverKitOrderModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      orderNumber: json['order_number']?.toString() ?? '',
      amount: (json['amount'] is num) ? (json['amount'] as num).toDouble() : double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      selectedSize: json['selected_size']?.toString() ?? json['tshirt_size']?.toString() ?? 'L',
      deliveryStatus: json['delivery_status']?.toString() ?? 'booked',
      trackingCode: json['tracking_code']?.toString() ?? json['tracking_number']?.toString() ?? 'FWP7823456789',
      trackingUrl: json['tracking_url']?.toString(),
      courierPartner: json['courier_partner']?.toString() ?? 'Blue Dart Express',
      expectedDeliveryDate: json['expected_delivery']?.toString() ?? json['expected_delivery_date']?.toString() ?? 'Today by 6:00 PM',
      deliveryPartnerName: json['delivery_partner_name']?.toString() ?? json['delivery_executive']?['name']?.toString() ?? 'Ravi Kumar',
      deliveryPartnerPhone: json['delivery_partner_phone']?.toString() ?? json['delivery_executive']?['phone']?.toString() ?? '+91 98765 43210',
      deliveryPartnerVehicle: json['delivery_partner_vehicle']?.toString() ?? json['delivery_executive']?['vehicle_no']?.toString() ?? 'DL 1L AB 1234',
      deliveryPartnerId: json['delivery_partner_id']?.toString() ?? json['delivery_executive']?['partner_id']?.toString() ?? 'BD567890',
      timeline: steps,
      purchasedAt: json['purchased_at']?.toString(),
    );
  }
}

class KitTimelineStepModel {
  final String status;
  final String title;
  final String date;
  final String description;
  final bool isCompleted;
  final bool isCurrent;

  KitTimelineStepModel({
    required this.status,
    required this.title,
    required this.date,
    required this.description,
    required this.isCompleted,
    required this.isCurrent,
  });

  factory KitTimelineStepModel.fromJson(Map<String, dynamic> json) {
    return KitTimelineStepModel(
      status: json['status']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      isCompleted: json['is_completed'] == true,
      isCurrent: json['is_current'] == true,
    );
  }
}
