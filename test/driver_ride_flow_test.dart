import 'package:flutter_test/flutter_test.dart';

class LatLngTest {
  final double latitude;
  final double longitude;
  const LatLngTest(this.latitude, this.longitude);
}

class LatLngBoundsTest {
  final LatLngTest southwest;
  final LatLngTest northeast;
  const LatLngBoundsTest({required this.southwest, required this.northeast});
}

LatLngBoundsTest calculateBounds(List<LatLngTest> coordinates) {
  if (coordinates.isEmpty) {
    throw ArgumentError('Coordinates list cannot be empty');
  }

  double minLat = coordinates.first.latitude;
  double maxLat = coordinates.first.latitude;
  double minLng = coordinates.first.longitude;
  double maxLng = coordinates.first.longitude;

  for (final point in coordinates) {
    if (point.latitude < minLat) minLat = point.latitude;
    if (point.latitude > maxLat) maxLat = point.latitude;
    if (point.longitude < minLng) minLng = point.longitude;
    if (point.longitude > maxLng) maxLng = point.longitude;
  }

  return LatLngBoundsTest(
    southwest: LatLngTest(minLat, minLng),
    northeast: LatLngTest(maxLat, maxLng),
  );
}

String generateNavigationUrl(double lat, double lng) {
  return "https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving";
}

enum DriverRideAction {
  accept,
  startOtpVerify,
  completeRide,
}

class DriverRideStateMachine {
  String status;

  DriverRideStateMachine({this.status = 'new'});

  bool onRideAction(DriverRideAction action, {String? otp, String? expectedOtp}) {
    switch (status) {
      case 'new':
        if (action == DriverRideAction.accept) {
          status = 'confirmed';
          return true;
        }
        return false;

      case 'confirmed':
        if (action == DriverRideAction.startOtpVerify) {
          if (expectedOtp == null || otp == expectedOtp) {
            // Transitions to on ride and stays on RouteViewScreen
            status = 'on ride';
            return true;
          }
          return false;
        }
        return false;

      case 'on ride':
        if (action == DriverRideAction.completeRide) {
          status = 'completed';
          return true;
        }
        return false;

      default:
        return false;
    }
  }
}

void main() {
  group('Driver Ride Flow - Automated Unit Tests', () {
    test('State machine transitions: new -> confirmed -> on ride -> completed (Rapido flow)', () {
      final stateMachine = DriverRideStateMachine(status: 'new');

      // 1. Driver accepts new booking
      final accepted = stateMachine.onRideAction(DriverRideAction.accept);
      expect(accepted, isTrue);
      expect(stateMachine.status, equals('confirmed'));

      // 2. Driver enters invalid OTP
      final wrongOtp = stateMachine.onRideAction(
        DriverRideAction.startOtpVerify,
        otp: '000000',
        expectedOtp: '123456',
      );
      expect(wrongOtp, isFalse);
      expect(stateMachine.status, equals('confirmed'));

      // 3. Driver enters correct OTP -> transitions to on ride
      final correctOtp = stateMachine.onRideAction(
        DriverRideAction.startOtpVerify,
        otp: '123456',
        expectedOtp: '123456',
      );
      expect(correctOtp, isTrue);
      expect(stateMachine.status, equals('on ride'));

      // 4. Driver completes ride at destination
      final completed = stateMachine.onRideAction(DriverRideAction.completeRide);
      expect(completed, isTrue);
      expect(stateMachine.status, equals('completed'));
    });

    test('Bounding box correctly encloses origin and destination for camera view', () {
      final points = [
        const LatLngTest(12.971598, 77.594562), // Origin
        const LatLngTest(12.975000, 77.600000), // Intermediate waypoint
        const LatLngTest(13.035800, 77.597000), // Destination
      ];

      final bounds = calculateBounds(points);
      expect(bounds.southwest.latitude, equals(12.971598));
      expect(bounds.southwest.longitude, equals(77.594562));
      expect(bounds.northeast.latitude, equals(13.035800));
      expect(bounds.northeast.longitude, equals(77.600000));
    });

    test('Turn-by-turn navigation URL generates valid Google Maps intent', () {
      const dropLat = 13.0358;
      const dropLng = 77.5970;
      final url = generateNavigationUrl(dropLat, dropLng);

      expect(url, startsWith('https://www.google.com/maps/dir/?api=1'));
      expect(url, contains('destination=13.0358,77.597'));
      expect(url, contains('travelmode=driving'));
    });

    test('Fare amounts are properly formatted to exactly 2 decimal units', () {
      String formatAmount(String? amount) {
        String raw = (amount == null || amount.isEmpty || amount == 'null') ? '0' : amount;
        double parsed = double.tryParse(raw) ?? 0.0;
        return parsed.toStringAsFixed(2);
      }

      expect(formatAmount('98.10199999999999'), equals('98.10'));
      expect(formatAmount('150'), equals('150.00'));
      expect(formatAmount('45.5'), equals('45.50'));
      expect(formatAmount('0'), equals('0.00'));
      expect(formatAmount(null), equals('0.00'));
    });
  });
}

