import 'dart:ui';
import 'package:cabme_driver/page/booking/service_flow/service_booking_flow.dart';
import 'package:cabme_driver/constant/constant.dart';
import 'package:cabme_driver/controller/my_booking_controller.dart';
import 'package:cabme_driver/model/driver_booking_model.dart';
import 'package:cabme_driver/page/features/Taxi/taxi_dashboard/taxi_dashboard.dart';
import 'package:cabme_driver/page/parcel_service/parcel_console_screen.dart';
import 'package:cabme_driver/page/wallet/wallet_screen.dart';
import 'package:cabme_driver/page/web_view_screen/web_view_screen.dart';
import 'package:cabme_driver/themes/constant_colors.dart';
import 'package:cabme_driver/utils/dark_theme_provider.dart';
import 'package:cabme_driver/utils/onboarding_url.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class MyBookingScreen extends StatefulWidget {
  final int initialTab;
  const MyBookingScreen({super.key, this.initialTab = -1});

  @override
  State<MyBookingScreen> createState() => _MyBookingScreenState();
}

class _MyBookingScreenState extends State<MyBookingScreen> {
  late final MyBookingController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<MyBookingController>()
        ? Get.find<MyBookingController>()
        : Get.put(MyBookingController());

    if (widget.initialTab >= 0) {
      controller.selectedTab.value = widget.initialTab;
      controller.fetchBookings(showLoader: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<DarkThemeProvider>(context).getThem();

    return Obx(() {
      return Scaffold(
          backgroundColor: isDark ? AppThemeData.grey50Dark : AppThemeData.grey50,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: isDark ? AppThemeData.surface50Dark : Colors.white,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: isDark ? Colors.white : AppThemeData.grey900),
              onPressed: () => Get.back(),
            ),
            title: Column(
              children: [
                Text(
                  'My Booking'.tr,
                  style: TextStyle(
                    fontFamily: AppThemeData.bold,
                    fontSize: 18,
                    color: isDark ? Colors.white : AppThemeData.grey900,
                  ),
                ),
                if (controller.profession.value.isNotEmpty)
                  Text(
                    controller.profession.value,
                    style: TextStyle(
                      fontFamily: AppThemeData.regular,
                      fontSize: 11,
                      color: isDark ? AppThemeData.grey500Dark : AppThemeData.grey500,
                    ),
                  ),
              ],
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
                    : controller.onboardingRequired.value
                        ? _OnboardingRequiredView(isDark: isDark, controller: controller)
                        : controller.locationRequired.value
                            ? _LocationRequiredView(isDark: isDark, controller: controller)
                            : RefreshIndicator(
                        color: AppThemeData.primary200,
                        onRefresh: () => controller.fetchBookings(),
                        child: controller.bookings.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: [
                                  SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                                  Icon(Icons.event_note_outlined, size: 56, color: AppThemeData.grey400),
                                  const SizedBox(height: 12),
                                  Center(
                                    child: Text(
                                      'No bookings within 30 km'.tr,
                                      style: TextStyle(
                                        fontFamily: AppThemeData.medium,
                                        color: isDark ? AppThemeData.grey500Dark : AppThemeData.grey500,
                                      ),
                                    ),
                                  ),
                                  if (controller.profession.value.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Center(
                                      child: Text(
                                        '${'Showing'.tr} ${controller.profession.value} ${'bookings only'.tr}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark ? AppThemeData.grey500Dark : AppThemeData.grey400,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              )
                            : ListView.separated(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                                itemCount: controller.bookings.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                  final item = controller.bookings[index];
                                  // Only block incoming bookings when driver has debt
                                  final isBlocked = item.isIncoming && controller.hasDebt.value;
                                  return _BookingCard(
                                    item: item,
                                    isDark: isDark,
                                    isBlocked: isBlocked,
                                    debtAmount: controller.debtAmount.value,
                                    onTap: () => _onTapBooking(item, controller),
                                  );
                                },
                              ),
                        ),
              ),
            ],
          ),
        );
      });
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
    if (controller.selectedTab.value == 2 || item.isCompleted) {
      return; // Do nothing for history tab items — cards are unclickable
    }
    // Block incoming bookings if driver has wallet debt
    if (item.isIncoming && controller.hasDebt.value) {
      _showDebtDialog(controller.debtAmount.value);
      return;
    }
    if (item.isRide) {
      Get.to(() => TaxiDashBoard(), transition: Transition.rightToLeftWithFade);
      return;
    }
    if (item.isParcel) {
      Get.to(() => const ParcelConsoleScreen(), transition: Transition.rightToLeftWithFade);
      return;
    }
    openServiceBookingFlow(item, controller);
  }

  void _showDebtDialog(double amount) {
    final amountStr = Constant().amountShow(amount: amount.toStringAsFixed(2));
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.account_balance_wallet_rounded, color: AppThemeData.error200),
            const SizedBox(width: 8),
            Text('Outstanding Balance'.tr, style: TextStyle(fontSize: 16)),
          ],
        ),
        content: Text(
          'You have an outstanding commission balance of $amountStr. Please top up your wallet to accept new bookings.'.tr,
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Later'.tr),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppThemeData.primary200,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Get.back();
              Get.to(() => WalletScreen());
            },
            child: Text('Go to Wallet'.tr),
          ),
        ],
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({
    required this.item,
    required this.isDark,
    required this.onTap,
    this.isBlocked = false,
    this.debtAmount = 0,
  });

  final DriverBookingItem item;
  final bool isDark;
  final VoidCallback onTap;
  final bool isBlocked;
  final double debtAmount;

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
    final isClickable = !item.isCompleted;
    final card = Material(
      color: isDark ? AppThemeData.surface50Dark : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: isClickable ? onTap : null,
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
              if (item.subtitle.isNotEmpty && item.subtitle != item.description) ...[
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
              if (item.address.isNotEmpty) ...[
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.location_on_outlined, size: 15, color: AppThemeData.primary200),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item.address,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppThemeData.grey400Dark : AppThemeData.grey500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (item.scheduleLabel.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.schedule_rounded, size: 14, color: AppThemeData.grey400),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        item.scheduleLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, color: isDark ? AppThemeData.grey500Dark : AppThemeData.grey500),
                      ),
                    ),
                  ],
                ),
              ],
              if (item.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  item.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: isDark ? AppThemeData.grey500Dark : AppThemeData.grey500),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  if (item.customerPhone.isNotEmpty) ...[
                    Icon(Icons.phone_outlined, size: 14, color: AppThemeData.grey400),
                    const SizedBox(width: 4),
                    Text(
                      item.customerPhone,
                      style: TextStyle(fontSize: 11, color: isDark ? AppThemeData.grey500Dark : AppThemeData.grey500),
                    ),
                    const SizedBox(width: 12),
                  ],
                  if (item.distanceKm != null) ...[
                    Icon(Icons.near_me_outlined, size: 14, color: AppThemeData.grey400),
                    const SizedBox(width: 4),
                    Text(
                      '${item.distanceKm!.toStringAsFixed(1)} km',
                      style: TextStyle(fontSize: 11, color: isDark ? AppThemeData.grey500Dark : AppThemeData.grey500),
                    ),
                    const Spacer(),
                  ] else
                    const Spacer(),
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

    if (!isBlocked) return card;

    // Debt overlay: blur the card and show lock icon + message
    return Stack(
      children: [
        card,
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
              child: GestureDetector(
                onTap: onTap, // triggers _showDebtDialog via _onTapBooking
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppThemeData.error200.withValues(alpha: 0.6),
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lock_rounded, color: Colors.white, size: 28),
                        const SizedBox(height: 6),
                        Text(
                          'Pay commission to accept'.tr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _OnboardingRequiredView extends StatelessWidget {
  const _OnboardingRequiredView({required this.isDark, required this.controller});

  final bool isDark;
  final MyBookingController controller;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_ind_outlined, size: 64, color: AppThemeData.primary200.withValues(alpha: 0.7)),
            const SizedBox(height: 16),
            Text(
              'Complete onboarding first'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppThemeData.bold,
                fontSize: 18,
                color: isDark ? AppThemeData.grey900Dark : AppThemeData.grey900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select your service category to receive matching bookings near you.'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppThemeData.grey500Dark : AppThemeData.grey500,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final finalUrl = OnboardingUrl.build('/onboarding');
                  Get.to(() => WebViewScreen(url: finalUrl, title: 'Complete Onboarding'))?.then((_) {
                    controller.fetchBookings();
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppThemeData.primary200,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Complete Onboarding'.tr),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationRequiredView extends StatelessWidget {
  const _LocationRequiredView({required this.isDark, required this.controller});

  final bool isDark;
  final MyBookingController controller;

  @override
  Widget build(BuildContext context) {
    final message = controller.locationMessage.value.isNotEmpty
        ? controller.locationMessage.value
        : 'Please turn on your status and enable GPS to capture your location'.tr;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off_outlined, size: 64, color: AppThemeData.warning200.withValues(alpha: 0.9)),
            const SizedBox(height: 16),
            Text(
              'Location not available'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppThemeData.bold,
                fontSize: 18,
                color: isDark ? AppThemeData.grey900Dark : AppThemeData.grey900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppThemeData.grey500Dark : AppThemeData.grey500,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: controller.enableLocationAndRefresh,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppThemeData.primary200,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Turn On Status & Capture Location'.tr),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Get.back(),
              child: Text('Go Back'.tr),
            ),
          ],
        ),
      ),
    );
  }
}
