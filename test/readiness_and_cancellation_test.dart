import 'package:flutter_test/flutter_test.dart';

// Test implementation mirroring DeviceReadinessReport from device_readiness_service.dart
class DeviceReadinessReportTest {
  final bool isInternetReady;
  final bool isNotificationReady;
  final bool isLocationPermissionReady;
  final bool isGpsHardwareReady;
  final bool isBatteryOptimizationIgnored;
  final bool isLocationAcquired;

  const DeviceReadinessReportTest({
    required this.isInternetReady,
    required this.isNotificationReady,
    required this.isLocationPermissionReady,
    required this.isGpsHardwareReady,
    required this.isBatteryOptimizationIgnored,
    required this.isLocationAcquired,
  });

  bool get isFullyReady =>
      isInternetReady &&
      isNotificationReady &&
      isLocationPermissionReady &&
      isGpsHardwareReady;

  List<String> get missingIssues {
    final list = <String>[];
    if (!isInternetReady) list.add("No Internet Connection");
    if (!isNotificationReady) list.add("Notification Permission Missing");
    if (!isLocationPermissionReady) list.add("Location Permission Missing");
    if (!isGpsHardwareReady) list.add("GPS / Location Hardware Disabled");
    if (!isBatteryOptimizationIgnored) list.add("Battery Optimization Active");
    return list;
  }
}

// Logic helper for notification ID computation (from NotificationService)
int computeNotificationId(Map<String, dynamic> data) {
  final bookingId = data['id_ride']?.toString() ??
      data['booking_id']?.toString() ??
      data['id']?.toString() ?? '';
  if (bookingId.isNotEmpty) {
    return bookingId.hashCode & 0x7FFFFFFF;
  }
  return 999999;
}

// Logic helper for cancellation identification (from main.dart)
bool isBookingCancellationMessage(Map<String, dynamic> data) {
  return data['tag'] == 'booking_taken' ||
      data['tag'] == 'booking_cancelled' ||
      data['statut'] == 'taken' ||
      data['statut'] == 'cancelled';
}

// Logic helper for 5-step online check
class OnlineReadinessValidator {
  static bool canGoOnline({
    required bool hasInternet,
    required bool hasNotificationPermission,
    required bool hasLocationPermission,
    required bool hasGpsHardwareEnabled,
    required double latitude,
    required double longitude,
  }) {
    if (!hasInternet) return false;
    if (!hasNotificationPermission) return false;
    if (!hasLocationPermission) return false;
    if (!hasGpsHardwareEnabled) return false;
    if (latitude == 0.0 && longitude == 0.0) return false;
    return true;
  }
}

void main() {
  group('Device Readiness & Health Report Tests', () {
    test('isFullyReady is true when all core services are active', () {
      const report = DeviceReadinessReportTest(
        isInternetReady: true,
        isNotificationReady: true,
        isLocationPermissionReady: true,
        isGpsHardwareReady: true,
        isBatteryOptimizationIgnored: true,
        isLocationAcquired: true,
      );
      expect(report.isFullyReady, isTrue);
      expect(report.missingIssues, isEmpty);
    });

    test('isFullyReady is false when GPS is disabled', () {
      const report = DeviceReadinessReportTest(
        isInternetReady: true,
        isNotificationReady: true,
        isLocationPermissionReady: true,
        isGpsHardwareReady: false, // GPS off
        isBatteryOptimizationIgnored: true,
        isLocationAcquired: false,
      );
      expect(report.isFullyReady, isFalse);
      expect(report.missingIssues, contains("GPS / Location Hardware Disabled"));
    });

    test('isFullyReady is false when notifications are blocked', () {
      const report = DeviceReadinessReportTest(
        isInternetReady: true,
        isNotificationReady: false, // Notif blocked
        isLocationPermissionReady: true,
        isGpsHardwareReady: true,
        isBatteryOptimizationIgnored: true,
        isLocationAcquired: true,
      );
      expect(report.isFullyReady, isFalse);
      expect(report.missingIssues, contains("Notification Permission Missing"));
    });

    test('isFullyReady reports multiple missing issues accurately', () {
      const report = DeviceReadinessReportTest(
        isInternetReady: false,
        isNotificationReady: false,
        isLocationPermissionReady: false,
        isGpsHardwareReady: false,
        isBatteryOptimizationIgnored: false,
        isLocationAcquired: false,
      );
      expect(report.isFullyReady, isFalse);
      expect(report.missingIssues.length, equals(5));
      expect(report.missingIssues, contains("No Internet Connection"));
      expect(report.missingIssues, contains("Notification Permission Missing"));
      expect(report.missingIssues, contains("Location Permission Missing"));
      expect(report.missingIssues, contains("GPS / Location Hardware Disabled"));
      expect(report.missingIssues, contains("Battery Optimization Active"));
    });
  });

  group('Notification De-duplication & Hash Tests', () {
    test('Same booking ID produces identical positive notification ID', () {
      final payload1 = {'id_ride': '402', 'title': 'New Ride'};
      final payload2 = {'id_ride': '402', 'title': 'New Ride (Retry)'};

      final id1 = computeNotificationId(payload1);
      final id2 = computeNotificationId(payload2);

      expect(id1, equals(id2));
      expect(id1, isPositive);
    });

    test('Different booking IDs produce distinct notification IDs', () {
      final ridePayload = {'id_ride': '402'};
      final servicePayload = {'booking_id': '805'};

      final rideId = computeNotificationId(ridePayload);
      final serviceId = computeNotificationId(servicePayload);

      expect(rideId, isNot(equals(serviceId)));
    });

    test('Works for home service booking_id parameter', () {
      final payload = {'booking_id': 'HS_9999'};
      final notifId = computeNotificationId(payload);
      expect(notifId, isPositive);
      expect(notifId, equals('HS_9999'.hashCode & 0x7FFFFFFF));
    });
  });

  group('Booking Cancellation & Alarm Dismissal Tests', () {
    test('Identifies booking_taken tag as cancellation event', () {
      final payload = {
        'tag': 'booking_taken',
        'statut': 'taken',
        'id_ride': '402',
      };
      expect(isBookingCancellationMessage(payload), isTrue);
    });

    test('Identifies booking_cancelled tag as cancellation event', () {
      final payload = {
        'tag': 'booking_cancelled',
        'statut': 'cancelled',
        'booking_id': 'HS_101',
      };
      expect(isBookingCancellationMessage(payload), isTrue);
    });

    test('Normal incoming ride is NOT treated as cancellation', () {
      final payload = {
        'tag': 'ridenewrider',
        'statut': 'new',
        'id_ride': '505',
      };
      expect(isBookingCancellationMessage(payload), isFalse);
    });

    test('Normal home service request is NOT treated as cancellation', () {
      final payload = {
        'type': 'homeservice',
        'tag': 'homeservicerequest',
        'statut': 'new',
        'booking_id': 'HS_202',
      };
      expect(isBookingCancellationMessage(payload), isFalse);
    });
  });

  group('5-Step Online Availability ("Most Important Rule") Tests', () {
    test('Driver can go online when all 5 checks pass with valid GPS coordinates', () {
      final canGo = OnlineReadinessValidator.canGoOnline(
        hasInternet: true,
        hasNotificationPermission: true,
        hasLocationPermission: true,
        hasGpsHardwareEnabled: true,
        latitude: 28.5355,
        longitude: 77.3910,
      );
      expect(canGo, isTrue);
    });

    test('Driver BLOCKED from going online if Internet is missing', () {
      final canGo = OnlineReadinessValidator.canGoOnline(
        hasInternet: false,
        hasNotificationPermission: true,
        hasLocationPermission: true,
        hasGpsHardwareEnabled: true,
        latitude: 28.5355,
        longitude: 77.3910,
      );
      expect(canGo, isFalse);
    });

    test('Driver BLOCKED from going online if GPS Hardware is OFF', () {
      final canGo = OnlineReadinessValidator.canGoOnline(
        hasInternet: true,
        hasNotificationPermission: true,
        hasLocationPermission: true,
        hasGpsHardwareEnabled: false,
        latitude: 28.5355,
        longitude: 77.3910,
      );
      expect(canGo, isFalse);
    });

    test('Driver BLOCKED from going online if Notification Permission is missing', () {
      final canGo = OnlineReadinessValidator.canGoOnline(
        hasInternet: true,
        hasNotificationPermission: false,
        hasLocationPermission: true,
        hasGpsHardwareEnabled: true,
        latitude: 28.5355,
        longitude: 77.3910,
      );
      expect(canGo, isFalse);
    });

    test('Driver BLOCKED from going online if GPS coordinates are invalid (0,0)', () {
      final canGo = OnlineReadinessValidator.canGoOnline(
        hasInternet: true,
        hasNotificationPermission: true,
        hasLocationPermission: true,
        hasGpsHardwareEnabled: true,
        latitude: 0.0,
        longitude: 0.0,
      );
      expect(canGo, isFalse);
    });
  });
}
