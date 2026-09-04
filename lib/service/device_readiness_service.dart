import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'location_connectivity_manager.dart';

class DeviceReadinessReport {
  final bool isInternetReady;
  final bool isNotificationReady;
  final bool isLocationPermissionReady;
  final bool isGpsHardwareReady;
  final bool isBatteryOptimizationIgnored;
  final bool isLocationAcquired;

  const DeviceReadinessReport({
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
    if (!isBatteryOptimizationIgnored) list.add("Battery Optimization Active (May delay alerts)");
    return list;
  }
}

class DeviceReadinessService extends GetxController with WidgetsBindingObserver {
  static DeviceReadinessService get to {
    if (!Get.isRegistered<DeviceReadinessService>()) {
      return Get.put(DeviceReadinessService());
    }
    return Get.find<DeviceReadinessService>();
  }

  final RxBool isInternetReady = false.obs;
  final RxBool isNotificationReady = false.obs;
  final RxBool isLocationPermissionReady = false.obs;
  final RxBool isGpsHardwareReady = false.obs;
  final RxBool isBatteryOptimizationIgnored = false.obs;
  final RxBool isLocationAcquired = false.obs;
  final RxBool isChecking = false.obs;

  StreamSubscription<ServiceStatus>? _gpsStatusSub;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    checkAllReadiness();
    _listenGpsHardware();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _gpsStatusSub?.cancel();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      checkAllReadiness();
    }
  }

  void _listenGpsHardware() {
    try {
      _gpsStatusSub?.cancel();
      _gpsStatusSub = Geolocator.getServiceStatusStream().listen((status) {
        final enabled = status == ServiceStatus.enabled;
        isGpsHardwareReady.value = enabled;
      });
    } catch (e) {
      log("Error listening to GPS service status: $e");
    }
  }

  Future<DeviceReadinessReport> checkAllReadiness({bool testLocationFix = false}) async {
    isChecking.value = true;
    try {
      // 1. Check Internet
      bool internet = false;
      try {
        final result = await InternetAddress.lookup('google.com').timeout(const Duration(seconds: 4));
        internet = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      } catch (_) {
        internet = false;
      }
      isInternetReady.value = internet;

      // 2. Check Notification Permission
      bool notif = false;
      try {
        final notifStatus = await Permission.notification.status;
        notif = notifStatus.isGranted || notifStatus.isLimited;
      } catch (_) {
        notif = true; // Fallback for older Android
      }
      isNotificationReady.value = notif;

      // 3. Check Location Permission
      final locPerm = await LocationConnectivityManager.isPermissionGranted();
      isLocationPermissionReady.value = locPerm;

      // 4. Check GPS Hardware
      bool gps = false;
      try {
        gps = await Geolocator.isLocationServiceEnabled();
      } catch (_) {
        gps = false;
      }
      isGpsHardwareReady.value = gps;

      // 5. Check Battery Optimization (Android only)
      bool batteryIgnored = true;
      if (Platform.isAndroid) {
        try {
          batteryIgnored = await Permission.ignoreBatteryOptimizations.isGranted;
        } catch (_) {
          batteryIgnored = true;
        }
      }
      isBatteryOptimizationIgnored.value = batteryIgnored;

      // 6. Test location fix if requested
      if (testLocationFix && locPerm && gps) {
        final pos = await LocationConnectivityManager.getCurrentPosition();
        isLocationAcquired.value = (pos != null && pos.latitude != 0.0 && pos.longitude != 0.0);
      }

      return DeviceReadinessReport(
        isInternetReady: isInternetReady.value,
        isNotificationReady: isNotificationReady.value,
        isLocationPermissionReady: isLocationPermissionReady.value,
        isGpsHardwareReady: isGpsHardwareReady.value,
        isBatteryOptimizationIgnored: isBatteryOptimizationIgnored.value,
        isLocationAcquired: isLocationAcquired.value,
      );
    } finally {
      isChecking.value = false;
    }
  }

  Future<bool> requestNotificationPermission() async {
    try {
      final status = await Permission.notification.request();
      final granted = status.isGranted || status.isLimited;
      isNotificationReady.value = granted;
      if (status.isPermanentlyDenied) {
        await openAppSettings();
      }
      return granted;
    } catch (e) {
      log("requestNotificationPermission error: $e");
      return false;
    }
  }

  Future<bool> requestBatteryOptimizationExemption() async {
    if (!Platform.isAndroid) return true;
    try {
      final status = await Permission.ignoreBatteryOptimizations.request();
      final granted = status.isGranted;
      isBatteryOptimizationIgnored.value = granted;
      return granted;
    } catch (e) {
      log("requestBatteryOptimizationExemption error: $e");
      return false;
    }
  }
}
