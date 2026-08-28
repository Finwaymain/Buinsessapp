import 'package:flutter_test/flutter_test.dart';
import 'package:cabme_driver/model/ride_model.dart';
import 'package:cabme_driver/model/driver_booking_model.dart';

void main() {
  group('Notification Payload Parsing & Routing Tests', () {
    test('Home Service notification payload identification', () {
      final Map<String, dynamic> homeServiceData = {
        'type': 'homeservice',
        'tag': 'homeservicerequest',
        'booking_id': '105',
        'service_name': 'AC Installation',
        'statut': 'new',
      };

      final bool isHomeService = homeServiceData['type'] == 'homeservice' ||
          homeServiceData['tag'] == 'homeservicerequest' ||
          homeServiceData['tag'] == 'homeservicenotif' ||
          (homeServiceData['booking_id'] != null && homeServiceData['booking_id'].toString().isNotEmpty);

      expect(isHomeService, isTrue);
      expect(homeServiceData['booking_id'], equals('105'));
    });

    test('Taxi Ride notification payload identification', () {
      final Map<String, dynamic> taxiRideData = {
        'statut': 'new',
        'tag': 'ridenewrider',
        'id': '201',
        'id_user_app': '55',
        'depart_name': 'Sector 18, Noida',
        'destination_name': 'Connaught Place, Delhi',
        'latitude_depart': '28.5700',
        'longitude_depart': '77.3200',
        'latitude_arrivee': '28.6300',
        'longitude_arrivee': '77.2100',
      };

      final bool isHomeService = taxiRideData['type'] == 'homeservice' ||
          taxiRideData['tag'] == 'homeservicerequest' ||
          taxiRideData['booking_id'] != null;

      expect(isHomeService, isFalse);

      final rideData = RideData.fromJson(taxiRideData);
      expect(rideData.id, equals('201'));
      expect(rideData.latitudeDepart, equals('28.5700'));
      expect(rideData.longitudeDepart, equals('77.3200'));
    });

    test('DriverBookingItem status transitions and properties', () {
      final item = DriverBookingItem(
        id: '105',
        type: 'homeservice',
        title: 'AC Installation',
        subtitle: 'AC Repair & Service',
        status: 'Pending',
        statusGroup: 'incoming',
        customerName: 'Rahul Verma',
        customerPhone: '+919876543210',
        amount: 599.0,
        date: '2026-08-28',
        pickup: 'Tower A, Flat 402, Green Valley',
        drop: '',
        address: 'Tower A, Flat 402, Green Valley',
        paymentStatus: 'pending',
      );

      expect(item.isIncoming, isTrue);
      expect(item.isAccepted, isFalse);
      expect(item.isCompleted, isFalse);
      expect(item.isRide, isFalse);
    });
  });
}
