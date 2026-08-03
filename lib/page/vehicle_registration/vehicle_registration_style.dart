import 'package:flutter/material.dart';

const Color kVehicleRegAccent = Color(0xFF2E7D32);

const List<String> kTruckFamilyTypes = ['Mini Truck', 'Pickup', 'Medium Truck', 'Large Truck'];

const Map<String, String> kVehicleCapacityLabel = {
  'Mini Truck': 'Up to 500 kg',
  'Pickup': 'Up to 1 Ton',
  'Medium Truck': 'Up to 3 Ton',
  'Large Truck': '3 Ton & Above',
};

IconData vehicleTypeIcon(String? libelle) {
  final name = (libelle ?? '').toLowerCase();
  if (name.contains('truck') || name.contains('pickup')) return Icons.local_shipping_rounded;
  if (name.contains('bike')) return Icons.two_wheeler_rounded;
  if (name.contains('auto')) return Icons.electric_rickshaw_rounded;
  return Icons.directions_car_rounded;
}
