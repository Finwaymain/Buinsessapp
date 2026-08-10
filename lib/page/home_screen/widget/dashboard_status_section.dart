import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../constant/constant.dart';
import '../../../constant/show_toast_dialog.dart';
import '../../../controller/dash_board_controller.dart';
import '../../../themes/constant_colors.dart';
import '../../../utils/Preferences.dart';
import '../../../utils/driver_dashboard_route.dart';
import '../../../utils/onboarding_url.dart';
import '../../booking/my_booking_screen.dart';
import '../../features/Taxi/taxi_dashboard/taxi_dashboard.dart';
import '../../web_view_screen/web_view_screen.dart';

/// Online toggle + today's stats, shown on the driver home screen right
/// below the greeting/onboarding-status header. Kept as a standalone
/// section (rather than folded into the existing header) so it can pull
/// its own data independently without touching the header's already-fixed
/// onboarding-status logic.
class DashboardStatusSection extends StatefulWidget {
  const DashboardStatusSection({super.key});

  @override
  State<DashboardStatusSection> createState() => _DashboardStatusSectionState();
}

class _DashboardStatusSectionState extends State<DashboardStatusSection> {
  @override
  void initState() {
    super.initState();
    Get.find<DashBoardController>().fetchDashboardStats();
  }

  Future<void> _toggleOnline(DashBoardController controller, bool goOnline) async {
    final refreshed = await controller.getUsrData();
    if (!refreshed) {
      ShowToastDialog.showToast("Couldn't refresh your status. Please check your connection and try again.".tr);
      return;
    }
    final userData = controller.userModel.value.userData!;
    if (userData.onboardingCompleted != "yes") {
      final finalUrl = OnboardingUrl.build('/onboarding');
      Get.to(() => WebViewScreen(url: finalUrl, title: 'Complete Onboarding'))?.then((_) => controller.getUsrData());
      return;
    }
    if (userData.isVerified != "yes") {
      ShowToastDialog.showToast("Your account is pending verification approval.".tr);
      return;
    }

    final bodyParams = {
      'id_driver': Preferences.getInt(Preferences.userId),
      'online': goOnline ? 'yes' : 'no',
    };
    final res = await controller.changeOnlineStatus(bodyParams);
    if (res != null && res['success'] == 'success') {
      controller.isActive.value = goOnline;
      ShowToastDialog.showToast(res['message']?.toString() ?? '');
      controller.fetchDashboardStats();
    } else {
      ShowToastDialog.showToast(res?['error']?.toString() ?? 'Could not update status'.tr);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DashBoardController>();

    return Obx(() {
      final userData = controller.userModel.value.userData;
      final showOnlineStatus = shouldShowOnlineStatus(userData);
      final isOnline = controller.isActive.value;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showOnlineStatus) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isOnline ? AppThemeData.success300.withValues(alpha: 0.12) : AppThemeData.warning200.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isOnline ? AppThemeData.success300 : AppThemeData.warning200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isOnline ? AppThemeData.success300 : AppThemeData.warning200,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          (isOnline ? "You are Online" : "You are Offline").tr,
                          style: TextStyle(
                            fontFamily: AppThemeData.semiBold,
                            fontSize: 14,
                            color: isOnline ? AppThemeData.success300 : AppThemeData.warning200,
                          ),
                        ),
                      ],
                    ),
                    Switch(
                      value: isOnline,
                      activeThumbColor: AppThemeData.success300,
                      inactiveTrackColor: AppThemeData.warning200.withValues(alpha: 0.4),
                      onChanged: (value) => _toggleOnline(controller, value),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 2x2 stat grid
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                  icon: Icons.payments_outlined,
                    label: "Today's Earnings",
                    value: Obx(() => Text(
                          Constant().amountShow(amount: controller.todayEarnings.value),
                          style: _statValueStyle(),
                        )),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.event_available_outlined,
                    label: "Today's Bookings",
                    value: Obx(() => Text(controller.todayBookings.value, style: _statValueStyle())),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (!Preferences.getBoolean(Preferences.isLogin)) return;
                    },
                    child: _StatCard(
                    icon: Icons.account_balance_wallet_outlined,
                      label: "Wallet Balance",
                      value: Obx(() => Text(
                            Constant().amountShow(amount: controller.userModel.value.userData?.amount?.toString() ?? "0"),
                            style: _statValueStyle(),
                          )),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.star_outline_rounded,
                    label: "Your Rating",
                    value: Obx(() => Text(
                          "${controller.driverRating.value} (${controller.driverRatingCount.value})",
                          style: _statValueStyle(),
                        )),
                  ),
                ),
              ],
            ),

            // Pending requests
            Obx(() {
              final count = int.tryParse(controller.pendingRequestsCount.value) ?? 0;
              if (count <= 0) return const SizedBox();
              return Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppThemeData.primary200.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: InkWell(
                  onTap: () {
                    if (!Preferences.getBoolean(Preferences.isLogin)) return;
                    Get.to(() => const MyBookingScreen(), transition: Transition.rightToLeftWithFade);
                  },
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: AppThemeData.primary200, borderRadius: BorderRadius.circular(20)),
                        child: Text(count.toString(), style: const TextStyle(color: Colors.white, fontFamily: AppThemeData.bold, fontSize: 12)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Pending Requests — new service requests waiting for your response".tr,
                          style: TextStyle(fontFamily: AppThemeData.medium, fontSize: 12, color: AppThemeData.primary200),
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, color: AppThemeData.primary200),
                    ],
                  ),
                ),
              );
            }),

            // Active service
            Obx(() {
              final active = controller.activeService.value;
              if (active == null) return const SizedBox();
              return Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppThemeData.success300.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppThemeData.success300.withValues(alpha: 0.3)),
                ),
                child: InkWell(
                  onTap: () => Get.to(() => TaxiDashBoard(), transition: Transition.rightToLeftWithFade),
                  child: Row(
                    children: [
                      Icon(Icons.directions_car_filled_rounded, color: AppThemeData.success300),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Active Service".tr, style: TextStyle(fontFamily: AppThemeData.bold, fontSize: 12, color: AppThemeData.success300)),
                            const SizedBox(height: 2),
                            Text(
                              "${active['depart_name'] ?? ''} → ${active['destination_name'] ?? ''}",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        (active['statut'] == 'on ride' ? 'In Progress' : 'Confirmed').tr,
                        style: TextStyle(fontFamily: AppThemeData.medium, fontSize: 10, color: AppThemeData.success300),
                      ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 8),
          ],
        ),
      );
    });
  }

  TextStyle _statValueStyle() => const TextStyle(fontFamily: AppThemeData.bold, fontSize: 16);
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget value;

  const _StatCard({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppThemeData.primary200.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppThemeData.primary200.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppThemeData.primary200, size: 20),
          const SizedBox(height: 8),
          value,
          const SizedBox(height: 2),
          Text(
            label.tr,
            style: TextStyle(fontFamily: AppThemeData.regular, fontSize: 11, color: AppThemeData.grey500),
          ),
        ],
      ),
    );
  }
}
