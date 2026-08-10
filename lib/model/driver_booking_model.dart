class ServiceLineItem {
  final String name;
  final double price;
  final int quantity;
  final bool completed;

  const ServiceLineItem({
    required this.name,
    this.price = 0,
    this.quantity = 1,
    this.completed = false,
  });

  ServiceLineItem copyWith({bool? completed, double? price, int? quantity}) {
    return ServiceLineItem(
      name: name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      completed: completed ?? this.completed,
    );
  }

  factory ServiceLineItem.fromJson(Map<String, dynamic> json) {
    return ServiceLineItem(
      name: json['name']?.toString() ?? '',
      price: double.tryParse(json['price']?.toString() ?? json['min_price']?.toString() ?? '0') ?? 0,
      quantity: int.tryParse(json['quantity']?.toString() ?? '1') ?? 1,
      completed: json['completed'] == true,
    );
  }
}

class DriverBookingItem {
  final String id;
  final String type;
  final String title;
  final String subtitle;
  final String status;
  final String statusGroup;
  final String customerName;
  final String customerPhone;
  final String customerPhoto;
  final double customerRating;
  final int reviewCount;
  final double amount;
  final String paymentStatus;
  final String date;
  final String pickup;
  final String drop;
  final String address;
  final String addressType;
  final String preferredDate;
  final String preferredTime;
  final String description;
  final String serviceName;
  final String city;
  final String zoneName;
  final double? distanceKm;
  final String? lat;
  final String? lng;
  final bool isUrgent;
  final List<ServiceLineItem> serviceItems;

  DriverBookingItem({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.statusGroup,
    required this.customerName,
    required this.customerPhone,
    this.customerPhoto = '',
    this.customerRating = 4.7,
    this.reviewCount = 0,
    required this.amount,
    this.paymentStatus = 'pending',
    required this.date,
    required this.pickup,
    required this.drop,
    this.address = '',
    this.addressType = '',
    this.preferredDate = '',
    this.preferredTime = '',
    this.description = '',
    this.serviceName = '',
    this.city = '',
    this.zoneName = '',
    this.distanceKm,
    this.lat,
    this.lng,
    this.isUrgent = false,
    this.serviceItems = const [],
  });

  factory DriverBookingItem.fromJson(Map<String, dynamic> json) {
    final desc = json['description']?.toString() ?? '';
    final items = <ServiceLineItem>[];
    final rawItems = json['service_items'];
    if (rawItems is List) {
      for (final entry in rawItems) {
        if (entry is Map) {
          items.add(ServiceLineItem.fromJson(Map<String, dynamic>.from(entry)));
        }
      }
    }
    if (items.isEmpty) {
      items.addAll(_parseServiceItemsFromName(json['service_name']?.toString() ?? json['title']?.toString() ?? ''));
    }

    return DriverBookingItem(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'service',
      title: json['title']?.toString() ?? 'Booking',
      subtitle: json['subtitle']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      statusGroup: json['status_group']?.toString() ?? 'incoming',
      customerName: json['customer_name']?.toString() ?? 'Customer',
      customerPhone: json['customer_phone']?.toString() ?? '',
      customerPhoto: json['customer_photo']?.toString() ?? '',
      customerRating: double.tryParse(json['customer_rating']?.toString() ?? '4.7') ?? 4.7,
      reviewCount: int.tryParse(json['review_count']?.toString() ?? '0') ?? 0,
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0,
      paymentStatus: json['payment_status']?.toString() ?? 'pending',
      date: json['date']?.toString() ?? '',
      pickup: json['pickup']?.toString() ?? '',
      drop: json['drop']?.toString() ?? '',
      address: json['address']?.toString() ?? json['pickup']?.toString() ?? '',
      addressType: json['address_type']?.toString() ?? '',
      preferredDate: json['preferred_date']?.toString() ?? '',
      preferredTime: json['preferred_time']?.toString() ?? '',
      description: desc,
      serviceName: json['service_name']?.toString() ?? json['title']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      zoneName: json['zone_name']?.toString() ?? '',
      distanceKm: json['distance_km'] == null ? null : double.tryParse(json['distance_km'].toString()),
      lat: json['lat']?.toString(),
      lng: json['lng']?.toString(),
      isUrgent: json['is_urgent'] == true || desc.toUpperCase().contains('[VERY URGENT]'),
      serviceItems: items,
    );
  }

  static List<ServiceLineItem> _parseServiceItemsFromName(String raw) {
    final items = <ServiceLineItem>[];
    for (final line in raw.split(RegExp(r'\r?\n'))) {
      var text = line.trim();
      if (text.isEmpty) continue;
      text = text.replaceFirst(RegExp(r'^[-•*]\s*'), '');
      text = text.replaceFirst(RegExp(r'^Selected\s+.+?\(\d+\):\s*', caseSensitive: false), '');
      if (text.isEmpty) continue;
      if (RegExp(r'^Selected\s+.+?\(\d+\):\s*$', caseSensitive: false).hasMatch(text)) continue;
      items.add(ServiceLineItem(name: text));
    }
    if (items.isEmpty && raw.trim().isNotEmpty) {
      items.add(ServiceLineItem(name: raw.trim()));
    }
    return items;
  }

  bool get isRide => type == 'ride';
  bool get isService => type == 'service';
  bool get isParcel => type == 'parcel';

  String get normalizedStatus => status.toLowerCase().trim();

  bool get isIncoming => normalizedStatus == 'pending' || normalizedStatus == 'new' || statusGroup == 'incoming';
  bool get isAccepted => normalizedStatus == 'accepted';
  bool get isInProgress => normalizedStatus == 'in progress' || normalizedStatus == 'in_progress';
  bool get isAwaitingPayment =>
      normalizedStatus == 'awaiting payment' || normalizedStatus == 'awaiting_payment';
  bool get isCompleted => normalizedStatus == 'completed';
  bool get isCancelled => normalizedStatus == 'cancelled' || normalizedStatus == 'canceled';

  bool get isPaid {
    final p = paymentStatus.toLowerCase();
    return p == 'paid' ||
        p == 'paid_wallet' ||
        p == 'paid_cash' ||
        p == 'paid_upi' ||
        p == 'yes' ||
        p == 'success';
  }

  String get locationLabel {
    if (zoneName.isNotEmpty) return zoneName;
    if (city.isNotEmpty) return city;
    return '';
  }

  String get scheduleLabel {
    if (preferredDate.isEmpty && preferredTime.isEmpty) return date;
    if (preferredTime.isEmpty) return preferredDate;
    return '$preferredDate · $preferredTime';
  }

  String get categoryLabel {
    final name = serviceName.isNotEmpty ? serviceName : title;
    final firstLine = name.split('\n').first.trim();
    if (firstLine.toLowerCase().startsWith('selected ')) {
      return firstLine.replaceAll(RegExp(r'\s*\(\d+\)\s*:?\s*$'), '').replaceFirst(RegExp(r'^selected\s+', caseSensitive: false), '').trim();
    }
    return firstLine;
  }

  double get labourCharges {
    if (serviceItems.isEmpty) return amount;
    final sum = serviceItems.fold<double>(0, (t, e) => t + e.price);
    return sum > 0 ? sum : amount;
  }
}
