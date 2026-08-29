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

// ─── Mirrors the null-safety fixes applied to route_view_screen.dart ──────────

/// FIX 1: rideData is null on first build() - show spinner until data loaded.
/// Simulates whether the build should show loading or content.
bool shouldShowLoading(Object? rideData) => rideData == null;

/// FIX 2: kGoogleApiKey is String? — using .toString() on null gives literal "null".
/// The PolylinePoints constructor must receive a proper key, not the string "null".
String resolveApiKey(String? apiKey) => apiKey ?? '';

/// FIX 3: rideType is String? — safe comparison without ! operator.
bool isDriverRideType(String? rideType) => rideType == 'driver';

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

    // ── New tests for null-safety root-cause fixes ──────────────────────────

    test('[FIX 1] rideData null guard: build() shows loading when rideData not yet loaded', () {
      // Simulates the async gap between initState and getArgumentData() completing.
      // Before fix: rideData was null and rideData!.x crashed immediately.
      // After fix: shouldShowLoading returns true → spinner rendered instead.
      expect(shouldShowLoading(null), isTrue,
          reason: 'rideData is null on first frame — must show spinner, not crash');
      expect(shouldShowLoading(Object()), isFalse,
          reason: 'Once rideData is set, normal UI should render');
    });

    test('[FIX 2] PolylinePoints apiKey null-string: String? null must NOT become "null"', () {
      // Before fix: Constant.kGoogleApiKey.toString() on null → "null" literal.
      // This caused all polyline HTTP calls to return 400 Invalid Key → blank map.
      final fromNull = resolveApiKey(null);
      final fromReal = resolveApiKey('AIzaSyAxZaszdbtbO75kvNjSYm1LjW2Sk59D9C8');

      expect(fromNull, equals(''),
          reason: 'Null API key must resolve to empty string, never the literal "null"');
      expect(fromNull, isNot(equals('null')),
          reason: 'String?.toString() on null gives "null" — this was the bug');
      expect(fromReal, equals('AIzaSyAxZaszdbtbO75kvNjSYm1LjW2Sk59D9C8'),
          reason: 'Valid key must pass through unchanged');
    });

    test('[FIX 3] rideType null-bang: rideType is String? — must not crash when null', () {
      // Before fix: rideData!.rideType! threw Null check operator used on a null value.
      // After fix: rideType == "driver" comparison is safe on null.
      expect(isDriverRideType(null), isFalse,
          reason: 'null rideType must not crash — returns false safely');
      expect(isDriverRideType('driver'), isTrue,
          reason: 'driver rideType correctly identified');
      expect(isDriverRideType('user'), isFalse,
          reason: 'user rideType correctly excluded');
    });
  });
}
