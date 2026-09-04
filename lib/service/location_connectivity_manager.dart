import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'package:location/location.dart' as loc_pkg;
import 'package:cabme_driver/constant/show_toast_dialog.dart';
import 'package:cabme_driver/utils/Preferences.dart';
import 'package:get/get.dart';

class LocationConnectivityManager {
  static final loc_pkg.Location _nativeLoc = loc_pkg.Location();
  static StreamSubscription<Position>? _positionStream;

  /// 1. Check if Internet Connection is active
  static Future<bool> checkInternet() async {
    try {
      final result = await InternetAddress.lookup('google.com').timeout(
        const Duration(seconds: 4),
        onTimeout: () => [],
      );
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// 2. Check if Location Permission is already granted (non-prompting)
  static Future<bool> isPermissionGranted() async {
    try {
      final permission = await Geolocator.checkPermission();
      return permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    } catch (e) {
      log("isPermissionGranted error: $e");
      return false;
    }
  }

  /// Check & Request Location Permission only when needed
  /// Never asks again if already granted.
  static Future<bool> ensurePermission({bool promptSettingsIfPermanentlyDenied = false}) async {
    try {
      // If already granted, return true immediately. Never prompt!
      if (await isPermissionGranted()) {
        await Preferences.setBoolean('location_permission_granted', true);
        return true;
      }

      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.always ||
            permission == LocationPermission.whileInUse) {
          await Preferences.setBoolean('location_permission_granted', true);
          return true;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (promptSettingsIfPermanentlyDenied) {
          ShowToastDialog.showToast(
            "Location permission is permanently denied. Please enable it in Settings to receive ride bookings.".tr,
          );
          await Geolocator.openAppSettings();
        }
        return false;
      }

      return permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    } catch (e) {
      log("ensurePermission error: $e");
      return false;
    }
  }

  /// 3. Check GPS hardware status (Service Enabled)
  /// If GPS is already ON, immediately returns true.
  /// If OFF, optionally triggers native Google Play location prompt.
  static Future<bool> checkGpsStatus({bool requestIfDisabled = false}) async {
    try {
      bool isGpsOn = await Geolocator.isLocationServiceEnabled();
      if (isGpsOn) {
        return true;
      }

      if (requestIfDisabled) {
        // Native Google Location Services prompt (no custom dialog needed)
        try {
          isGpsOn = await _nativeLoc.requestService();
        } catch (_) {
          isGpsOn = await Geolocator.isLocationServiceEnabled();
        }
      }

      return isGpsOn;
    } catch (e) {
      log("checkGpsStatus error: $e");
      return false;
    }
  }

  /// 4. Complete Unified Pipeline: Internet -> Permission -> GPS
  /// Used before going Online or fetching location.
  static Future<bool> ensureReadyForTracking({
    bool showToastOnFailure = true,
    bool requestGpsIfDisabled = true,
  }) async {
    try {
      // Step 1: Internet Check
      final hasInternet = await checkInternet();
      if (!hasInternet) {
        if (showToastOnFailure) {
          ShowToastDialog.showToast("No internet connection. Please check your data or Wi-Fi.".tr);
        }
        return false;
      }

      // Step 2: Location Permission Check (only prompts if NOT already granted)
      final hasPermission = await ensurePermission(promptSettingsIfPermanentlyDenied: true);
      if (!hasPermission) {
        if (showToastOnFailure) {
          ShowToastDialog.showToast("Location permission is required to receive incoming bookings.".tr);
        }
        return false;
      }

      // Step 3: GPS Status Check (if already ON, passes instantly)
      final isGpsOn = await checkGpsStatus(requestIfDisabled: requestGpsIfDisabled);
      if (!isGpsOn) {
        if (showToastOnFailure) {
          ShowToastDialog.showToast("Please enable GPS/Location on your device to continue.".tr);
        }
        return false;
      }

      return true;
    } catch (e) {
      log("ensureReadyForTracking error: $e");
      return false;
    }
  }

  /// 5. Safely get current location coordinates
  static Future<Position?> getCurrentPosition() async {
    try {
      final isReady = await ensureReadyForTracking(showToastOnFailure: false, requestGpsIfDisabled: true);
      if (!isReady) return null;

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 8),
      );
    } catch (e) {
      log("getCurrentPosition error: $e, trying last known position");
      try {
        return await Geolocator.getLastKnownPosition();
      } catch (_) {
        return null;
      }
    }
  }

  /// 6. Start continuous background/foreground location updates
  static void startLocationTracking({
    required Function(Position position) onLocationUpdate,
    double distanceFilter = 10,
  }) {
    stopLocationTracking();

    _positionStream = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilter.toInt(),
      ),
    ).listen(
      (Position position) {
        onLocationUpdate(position);
      },
      onError: (e) {
        log("Position stream error: $e");
      },
    );
  }

  /// Stop continuous location updates
  static void stopLocationTracking() {
    _positionStream?.cancel();
    _positionStream = null;
  }
}
