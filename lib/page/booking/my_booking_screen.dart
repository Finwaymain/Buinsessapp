import 'package:cabme_driver/constant/constant.dart';
import 'package:cabme_driver/controller/my_booking_controller.dart';
import 'package:cabme_driver/model/driver_booking_model.dart';
import 'package:cabme_driver/page/features/Taxi/taxi_dashboard/taxi_dashboard.dart';
import 'package:cabme_driver/page/parcel_service/parcel_console_screen.dart';
import 'package:cabme_driver/themes/constant_colors.dart';
import 'package:cabme_driver/utils/dark_theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class MyBookingScreen extends StatelessWidget {
  const MyBookingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<DarkThemeProvider>(context).getThem();

    return GetX<MyBookingController>(
      init: MyBookingController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: isDark ? AppThemeData.grey50Dark : AppThemeData.grey50,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: isDark ? AppThemeData.surface50Dark : Colors.white,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: isDark ? Colors.white : AppThemeData.grey900),
              onPressed: () => Get.back(),
            ),
            title: Text(
              'My Booking'.tr,
              style: TextStyle(
                fontFamily: AppThemeData.bold,
                fontSize: 18,
                color: isDark ? Colors.white : AppThemeData.grey900,
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: Icon(Icons.refresh_rounded, color: isDark ? Colors.white : AppThemeData.grey900),
                onPressed: () => controller.fetchBookings(showLoader: true),
              ),
            ],
          ),
          body: Column(
            children: [
              _buildTabs(controller, isDark),
              Expanded(
                child: controller.isLoading.value
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        color: AppThemeData.primary200,
                        onRefresh: () => controller.fetchBookings(),
                        child: controller.bookings.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: [
                                  SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                                  Icon(Icons.event_note_outlined, size: 56, color: AppThemeData.grey400),
                                  const SizedBox(height: 12),
                                  Center(
                                    child: Text(
                                      'No bookings found'.tr,
                                      style: TextStyle(
                                        fontFamily: AppThemeData.medium,
                                        color: isDark ? AppThemeData.grey500Dark : AppThemeData.grey500,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : ListView.separated(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                                itemCount: controller.bookings.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                  final item = controller.bookings[index];
                                  return _BookingCard(
                                    item: item,
                                    isDark: isDark,
                                    onTap: () => _onTapBooking(item, controller),
                                  );
                                },
                              ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabs(MyBookingController controller, bool isDark) {
    final tabs = [
      ('Incoming'.tr, controller.incomingCount.value),
      ('Active'.tr, controller.activeCount.value),
      ('History'.tr, controller.historyCount.value),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppThemeData.grey100Dark : AppThemeData.grey100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final selected = controller.selectedTab.value == index;
          final label = tabs[index].$1;
          final count = tabs[index].$2;
          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => controller.changeTab(index),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? AppThemeData.primary200 : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontFamily: AppThemeData.semiBold,
                        fontSize: 13,
                        color: selected ? Colors.white : (isDark ? AppThemeData.grey400Dark : AppThemeData.grey500),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      count.toString(),
                      style: TextStyle(
                        fontFamily: AppThemeData.medium,
                        fontSize: 11,
                        color: selected ? Colors.white70 : (isDark ? AppThemeData.grey500Dark : AppThemeData.grey400),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  void _onTapBooking(DriverBookingItem item, MyBookingController controller) {
    if (item.isRide) {
      Get.to(() => TaxiDashBoard(), transition: Transition.rightToLeftWithFade);
      return;
    }
    if (item.isParcel) {
      Get.to(() => const ParcelConsoleScreen(), transition: Transition.rightToLeftWithFade);
      return;
    }
    _showServiceActions(item, controller);
  }

  void _showServiceActions(DriverBookingItem item, MyBookingController controller) {
    final status = item.status.toLowerCase();
    final canAccept = status == 'pending' || status == 'new';
    final canStart = status == 'accepted';
    final canComplete = status == 'in progress' || status == 'accepted';

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.title, style: const TextStyle(fontFamily: AppThemeData.bold, fontSize: 18)),
              const SizedBox(height: 6),
              Text(item.subtitle, style: TextStyle(color: AppThemeData.grey500, fontSize: 13)),
              const SizedBox(height: 8),
              Text('${'Customer'.tr}: ${item.customerName}', style: const TextStyle(fontFamily: AppThemeData.medium)),
              const SizedBox(height: 16),
              if (canAccept) ...[
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Get.back();
                          await controller.updateServiceStatus(item.id, 'accepted');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppThemeData.primary200,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('Accept'.tr),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          Get.back();
                          await controller.updateServiceStatus(item.id, 'rejected');
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppThemeData.error200,
                          side: BorderSide(color: AppThemeData.error200),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('Reject'.tr),
                      ),
                    ),
                  ],
                ),
              ] else if (canStart) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      Get.back();
                      await controller.updateServiceStatus(item.id, 'in_progress');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppThemeData.primary200,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Start Job'.tr),
                  ),
                ),
              ] else if (canComplete) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      Get.back();
                      await controller.updateServiceStatus(item.id, 'completed');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppThemeData.primary200,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Mark Completed'.tr),
                  ),
                ),
              ] else ...[
                Text('${'Status'.tr}: ${item.status}', style: TextStyle(color: AppThemeData.grey500)),
              ],
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({
    required this.item,
    required this.isDark,
    required this.onTap,
  });

  final DriverBookingItem item;
  final bool isDark;
  final VoidCallback onTap;

  Color get _typeColor {
    switch (item.type) {
      case 'ride':
        return AppThemeData.primary200;
      case 'parcel':
        return const Color(0xFFFB8C00);
      default:
        return AppThemeData.info200;
    }
  }

  IconData get _typeIcon {
    switch (item.type) {
      case 'ride':
        return Icons.directions_car_rounded;
      case 'parcel':
        return Icons.local_shipping_rounded;
      default:
        return Icons.handyman_rounded;
    }
  }

  Color get _statusColor {
    final s = item.status.toLowerCase();
    if (s.contains('complete')) return AppThemeData.success300;
    if (s.contains('reject') || s.contains('cancel')) return AppThemeData.error200;
    if (s.contains('pending') || s == 'new') return const Color(0xFFF59E0B);
    return AppThemeData.primary200;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark ? AppThemeData.surface50Dark : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? AppThemeData.grey100Dark : AppThemeData.grey200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _typeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_typeIcon, color: _typeColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: AppThemeData.semiBold,
                            fontSize: 15,
                            color: isDark ? AppThemeData.grey900Dark : AppThemeData.grey900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.customerName,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppThemeData.grey500Dark : AppThemeData.grey500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      item.status,
                      style: TextStyle(
                        fontSize: 11,
                        fontFamily: AppThemeData.semiBold,
                        color: _statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              if (item.subtitle.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  item.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppThemeData.grey400Dark : AppThemeData.grey500,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.schedule_rounded, size: 14, color: AppThemeData.grey400),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      item.date,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: isDark ? AppThemeData.grey500Dark : AppThemeData.grey500),
                    ),
                  ),
                  if (item.amount > 0)
                    Text(
                      Constant().amountShow(amount: item.amount.toString()),
                      style: TextStyle(
                        fontFamily: AppThemeData.bold,
                        fontSize: 14,
                        color: isDark ? AppThemeData.grey900Dark : AppThemeData.primary200,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
