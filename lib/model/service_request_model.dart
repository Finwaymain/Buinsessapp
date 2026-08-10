class ServiceRequestData {
  final int? id;
  final String? serviceName;
  final String? addressType;
  final String? lat;
  final String? lng;
  final String? preferredDate;
  final String? preferredTime;
  final String? description;
  final String? status;
  final String? createdAt;

  ServiceRequestData({
    this.id,
    this.serviceName,
    this.addressType,
    this.lat,
    this.lng,
    this.preferredDate,
    this.preferredTime,
    this.description,
    this.status,
    this.createdAt,
  });

  factory ServiceRequestData.fromJson(Map<String, dynamic> json) {
    return ServiceRequestData(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      serviceName: json['service_name']?.toString(),
      addressType: json['address_type']?.toString(),
      lat: json['lat']?.toString(),
      lng: json['lng']?.toString(),
      preferredDate: json['preferred_date']?.toString(),
      preferredTime: json['preferred_time']?.toString(),
      description: json['description']?.toString(),
      status: json['status']?.toString(),
      createdAt: json['created_at']?.toString(),
    );
  }

  String get statusLabel {
    final s = (status ?? 'Pending').toLowerCase();
    if (s == 'accepted') return 'Accepted';
    if (s == 'in progress' || s == 'in_progress') return 'In Progress';
    if (s == 'completed') return 'Completed';
    if (s == 'rejected') return 'Rejected';
    if (s == 'cancelled' || s == 'canceled') return 'Cancelled';
    return 'Pending';
  }

  bool get isPending {
    final s = (status ?? '').toLowerCase();
    return s.isEmpty || s == 'pending';
  }

  bool get isOngoing {
    final s = (status ?? '').toLowerCase();
    return s == 'accepted' || s == 'in progress' || s == 'in_progress';
  }

  bool get isHistory {
    final s = (status ?? '').toLowerCase();
    return s == 'completed' || s == 'rejected' || s == 'cancelled' || s == 'canceled';
  }

  String get scheduleLabel {
    final date = preferredDate ?? '';
    final time = preferredTime ?? '';
    if (date.isEmpty && time.isEmpty) return 'Schedule not set';
    if (time.isEmpty) return date;
    return '$date · $time';
  }
}
