import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import '../service/device_readiness_service.dart';
import '../service/location_connectivity_manager.dart';
import '../themes/constant_colors.dart';

class DeviceReadinessBar extends StatelessWidget {
  const DeviceReadinessBar({super.key});

  void _showDiagnosticSheet(BuildContext context, DeviceReadinessService service) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Obx(() {
            final internet = service.isInternetReady.value;
            final notif = service.isNotificationReady.value;
            final locPerm = service.isLocationPermissionReady.value;
            final gps = service.isGpsHardwareReady.value;
            final battery = service.isBatteryOptimizationIgnored.value;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "System Readiness Check".tr,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "Ensure all components are enabled so you receive incoming booking alerts reliably without missing calls or rides.".tr,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                _buildCheckItem(
                  title: "Internet Connection".tr,
                  subtitle: internet ? "Connected".tr : "No network connection detected".tr,
                  isOk: internet,
                  actionText: internet ? null : "Retry".tr,
                  onAction: () => service.checkAllReadiness(),
                  icon: Icons.wifi,
                ),
                _buildCheckItem(
                  title: "Location Permission".tr,
                  subtitle: locPerm ? "Granted".tr : "Required to find nearby bookings".tr,
                  isOk: locPerm,
                  actionText: locPerm ? null : "Enable".tr,
                  onAction: () async {
                    await LocationConnectivityManager.ensurePermission(promptSettingsIfPermanentlyDenied: true);
                    service.checkAllReadiness();
                  },
                  icon: Icons.location_on,
                ),
                _buildCheckItem(
                  title: "GPS / Location Hardware".tr,
                  subtitle: gps ? "GPS is ON".tr : "Device GPS is turned OFF".tr,
                  isOk: gps,
                  actionText: gps ? null : "Turn ON".tr,
                  onAction: () async {
                    await LocationConnectivityManager.checkGpsStatus(requestIfDisabled: true);
                    service.checkAllReadiness();
                  },
                  icon: Icons.gps_fixed,
                ),
                _buildCheckItem(
                  title: "Notification Alerts".tr,
                  subtitle: notif ? "Alerts enabled with loud ring".tr : "Notifications are blocked".tr,
                  isOk: notif,
                  actionText: notif ? null : "Allow".tr,
                  onAction: () async {
                    await service.requestNotificationPermission();
                    service.checkAllReadiness();
                  },
                  icon: Icons.notifications_active,
                ),
                _buildCheckItem(
                  title: "Background Activity / Battery".tr,
                  subtitle: battery ? "Unrestricted background alerts".tr : "Battery saver may delay alarms".tr,
                  isOk: battery,
                  actionText: battery ? null : "Optimize".tr,
                  onAction: () async {
                    await service.requestBatteryOptimizationExemption();
                    service.checkAllReadiness();
                  },
                  icon: Icons.battery_charging_full,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppThemeData.primary200,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      service.checkAllReadiness();
                      Navigator.pop(ctx);
                    },
                    child: Text(
                      "Done".tr,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            );
          }),
        );
      },
    );
  }

  Widget _buildCheckItem({
    required String title,
    required String subtitle,
    required bool isOk,
    String? actionText,
    VoidCallback? onAction,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isOk ? Colors.green.withValues(alpha: 0.06) : Colors.amber.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isOk ? Colors.green.withValues(alpha: 0.3) : Colors.amber.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: isOk ? Colors.green[700] : Colors.amber[800], size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Colors.grey[850],
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          if (isOk)
            const Icon(Icons.check_circle, color: Colors.green, size: 20)
          else if (actionText != null && onAction != null)
            TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                backgroundColor: AppThemeData.primary200,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              onPressed: onAction,
              child: Text(
                actionText,
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = DeviceReadinessService.to;

    return Obx(() {
      final internet = service.isInternetReady.value;
      final notif = service.isNotificationReady.value;
      final locPerm = service.isLocationPermissionReady.value;
      final gps = service.isGpsHardwareReady.value;

      final bool allOk = internet && notif && locPerm && gps;

      return InkWell(
        onTap: () => _showDiagnosticSheet(context, service),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: allOk ? Colors.green.withValues(alpha: 0.08) : Colors.amber.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: allOk ? Colors.green.withValues(alpha: 0.3) : Colors.amber.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            children: [
              Icon(
                allOk ? Icons.check_circle_outline : Icons.info_outline,
                size: 16,
                color: allOk ? Colors.green[700] : Colors.amber[900],
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  allOk
                      ? "System Ready: Alerts & GPS active".tr
                      : "Action Needed: Tap to fix booking alert setup".tr,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: allOk ? Colors.green[800] : Colors.amber[900],
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildMiniDot(Icons.wifi, internet),
                  const SizedBox(width: 4),
                  _buildMiniDot(Icons.location_on, locPerm && gps),
                  const SizedBox(width: 4),
                  _buildMiniDot(Icons.notifications, notif),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right, size: 14, color: Colors.grey[600]),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildMiniDot(IconData icon, bool active) {
    return Icon(
      icon,
      size: 12,
      color: active ? Colors.green[700] : Colors.red[400],
    );
  }
}
