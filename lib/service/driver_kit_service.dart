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

class DriverKitService extends GetxController {
  static DriverKitService get to => Get.find<DriverKitService>();

  var isLoading = false.obs;
  var kitData = Rxn<DriverKitDataModel>();
  bool _popupShownThisSession = false;

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

  /// Fetch Kit Status and show popup if eligible
  Future<void> fetchKitStatus({bool showPopupIfEligible = true}) async {
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

          // Check if eligible for popup alert
          if (showPopupIfEligible && model.shouldShowPopup && model.kit != null && !_popupShownThisSession) {
            _popupShownThisSession = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showKitPurchasePopup(model);
            });
          }
        }
      }
    } catch (e) {
      debugPrint('DriverKitService error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Category-Aware Alert Dialog
  void _showKitPurchasePopup(DriverKitDataModel data) {
    final kit = data.kit;
    if (kit == null) return;

    final isCompulsory = data.isCompulsory;

    Get.dialog(
      PopScope(
        canPop: !isCompulsory,
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 12,
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Header Badge & Close Button (only if not compulsory)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isCompulsory
                            ? const Color(0xFFEF4444).withValues(alpha: 0.12)
                            : const Color(0xFF10B981).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isCompulsory ? Icons.lock_rounded : Icons.verified_rounded,
                            size: 14,
                            color: isCompulsory ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isCompulsory ? 'Mandatory Step'.tr : 'Official Starter Kit'.tr,
                            style: TextStyle(
                              fontSize: 11,
                              fontFamily: AppThemeData.bold,
                              color: isCompulsory ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isCompulsory)
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.close, size: 20, color: Color(0xFF94A3B8)),
                        onPressed: () => Get.back(),
                      ),
                  ],
                ),

                const SizedBox(height: 14),

                // Icon / Visual Avatar
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppThemeData.primary200, AppThemeData.primary300],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppThemeData.primary200.withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      data.categoryCode == 'bike'
                          ? Icons.two_wheeler_rounded
                          : (data.categoryCode == 'home_service'
                              ? Icons.home_repair_service_rounded
                              : Icons.local_taxi_rounded),
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Kit Title
                Text(
                  kit.title.tr,
                  style: const TextStyle(
                    fontSize: 18,
                    fontFamily: AppThemeData.bold,
                    color: Color(0xFF0F172A),
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 4),

                // Price Tag
                Text(
                  kit.priceFormatted,
                  style: TextStyle(
                    fontSize: 22,
                    fontFamily: AppThemeData.bold,
                    color: AppThemeData.primary200,
                  ),
                ),

                const SizedBox(height: 12),

                // Items Included Box
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
                      Text(
                        'Items Included for ${data.categoryLabel}:'.tr,
                        style: const TextStyle(
                          fontSize: 11,
                          fontFamily: AppThemeData.bold,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...kit.itemsIncluded.map((item) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 5),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle_rounded, size: 14, color: AppThemeData.primary200),
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

                if (isCompulsory) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Admin verification requires purchasing your official kit before taking orders.'.tr,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFFEF4444),
                      fontFamily: AppThemeData.medium,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],

                const SizedBox(height: 20),

                // Order Kit Action Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      if (!isCompulsory) {
                        Get.back();
                      }
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
                          'Buy Partner Kit Now'.tr,
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

                if (!isCompulsory) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Get.back(),
                    child: Text(
                      'Remind Me Later'.tr,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                        fontFamily: AppThemeData.medium,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: !isCompulsory,
    );
  }

  /// Open Kit Purchase WebView
  void openKitWebView(String webviewUrl) {
    if (webviewUrl.isEmpty) return;

    Get.to(() => WebViewScreen(
      url: webviewUrl,
      title: 'Partner Welcome Kit'.tr,
    ))?.then((_) {
      // Re-fetch status when returning from WebView
      fetchKitStatus(showPopupIfEligible: false);
    });
  }
}
