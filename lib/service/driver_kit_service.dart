import 'dart:convert';
import 'package:cabme_driver/constant/constant.dart';
import 'package:cabme_driver/page/web_view_screen/web_view_screen.dart';
import 'package:cabme_driver/service/api.dart';
import 'package:cabme_driver/themes/constant_colors.dart';
import 'package:cabme_driver/utils/Preferences.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../model/driver_kit_model.dart';
import '../utils/onboarding_url.dart';

class DriverKitService extends GetxController {
  static DriverKitService get to => Get.find<DriverKitService>();

  var isLoading = false.obs;
  var kitData = Rxn<DriverKitDataModel>();

  String _getDriverId() {
    final fromPrefs = Preferences.getString(Preferences.userId);
    if (fromPrefs.isNotEmpty) return fromPrefs;
    final intId = Preferences.getInt(Preferences.userId);
    if (intId != 0) return intId.toString();
    return Constant.getUserData().userData?.id?.toString() ?? '';
  }

  String _getAccessToken() {
    final fromPrefs = Preferences.getString(Preferences.accesstoken);
    if (fromPrefs.isNotEmpty) return fromPrefs;
    return Constant.getUserData().userData?.accesstoken ?? '';
  }

  /// Fetch Kit Status silently (no auto popup)
  Future<void> fetchKitStatus() async {
    final driverId = _getDriverId();
    if (driverId.isEmpty) return;

    final token = _getAccessToken();

    try {
      isLoading.value = true;
      final url = Uri.parse('${API.driverKitStatus}?driver_id=$driverId&accesstoken=$token');
      final res = await http.get(url, headers: API.header);

      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        if (body['success'] == 'success' && body['data'] != null) {
          final model = DriverKitDataModel.fromJson(body['data']);
          kitData.value = model;
        }
      }
    } catch (e) {
      debugPrint('DriverKitService error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Check if driver can open booking console / ride dashboard
  /// If kit is mandatory and not purchased, blocks access and shows prompt
  bool checkBookingAccessWithPrompt() {
    final data = kitData.value;
    if (data == null) return true;

    final bool isCompulsory = data.isCompulsory;
    final bool hasPurchased = data.hasPurchased;

    if (isCompulsory && !hasPurchased && data.kit != null) {
      _showKitRequiredDialog(data);
      return false;
    }

    return true;
  }

  /// Prompt shown when tapping Ride / Booking Console without mandatory kit
  void _showKitRequiredDialog(DriverKitDataModel data) {
    final kit = data.kit;
    if (kit == null) return;

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 12,
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Top Warning Icon
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFFEF4444), const Color(0xFFDC2626)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.lock_person_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // Title
              Text(
                'Partner Kit Required'.tr,
                style: const TextStyle(
                  fontSize: 19,
                  fontFamily: AppThemeData.bold,
                  color: Color(0xFF0F172A),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              // Description
              Text(
                'As a verified partner, purchasing your official starter kit (${kit.title}) is mandatory before you can go online and accept ride bookings.'.tr,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                  height: 1.45,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 14),

              // Included Items preview
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Package Includes:'.tr,
                          style: const TextStyle(
                            fontSize: 11,
                            fontFamily: AppThemeData.bold,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        Text(
                          kit.priceFormatted,
                          style: TextStyle(
                            fontSize: 13,
                            fontFamily: AppThemeData.bold,
                            color: AppThemeData.primary200,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ...kit.itemsIncluded.map((item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle_rounded, size: 13, color: AppThemeData.primary200),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                item,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontFamily: AppThemeData.medium,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Order Kit Now Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Get.back();
                    openKitWebView(kit.webviewUrl);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppThemeData.primary200,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 2,
                    shadowColor: AppThemeData.primary200.withValues(alpha: 0.4),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Order Partner Kit Now'.tr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontFamily: AppThemeData.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),

              TextButton(
                onPressed: () => Get.back(),
                child: Text(
                  'Close'.tr,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                    fontFamily: AppThemeData.medium,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Open Kit Purchase WebView
  void openKitWebView(String webviewUrl) {
    String finalUrl = webviewUrl;
    if (finalUrl.isEmpty || finalUrl.contains('localhost') || !finalUrl.startsWith('http')) {
      final driverId = _getDriverId();
      final token = _getAccessToken();
      finalUrl = OnboardingUrl.build('/onboarding/kit-purchase', extra: {
        'driver_id': driverId,
        'accesstoken': token,
      });
    }

    Get.to(() => WebViewScreen(
      url: finalUrl,
      title: 'Partner Welcome Kit'.tr,
    ))?.then((_) {
      // Re-fetch status when returning from WebView
      fetchKitStatus();
    });
  }
}
