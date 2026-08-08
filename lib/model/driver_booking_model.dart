class DriverBookingItem {
  final String id;
  final String type;
  final String title;
  final String subtitle;
  final String status;
  final String statusGroup;
  final String customerName;
  final String customerPhone;
  final double amount;
  final String date;
  final String pickup;
  final String drop;

  DriverBookingItem({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.statusGroup,
    required this.customerName,
    required this.customerPhone,
    required this.amount,
    required this.date,
    required this.pickup,
    required this.drop,
  });

  factory DriverBookingItem.fromJson(Map<String, dynamic> json) {
    return DriverBookingItem(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'service',
      title: json['title']?.toString() ?? 'Booking',
      subtitle: json['subtitle']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      statusGroup: json['status_group']?.toString() ?? 'incoming',
      customerName: json['customer_name']?.toString() ?? 'Customer',
      customerPhone: json['customer_phone']?.toString() ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0,
      date: json['date']?.toString() ?? '',
      pickup: json['pickup']?.toString() ?? '',
      drop: json['drop']?.toString() ?? '',
    );
  }

  bool get isRide => type == 'ride';
  bool get isService => type == 'service';
  bool get isParcel => type == 'parcel';
}
