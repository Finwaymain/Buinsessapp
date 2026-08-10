import 'package:cabme_driver/constant/constant.dart';
import 'package:cabme_driver/controller/service_booking_flow_controller.dart';
import 'package:cabme_driver/page/booking/service_flow/service_booking_flow.dart';
import 'package:cabme_driver/page/booking/service_flow/service_flow_widgets.dart';
import 'package:cabme_driver/themes/constant_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'service_reached_location_screen.dart';

class ServiceBookingDetailsScreen extends StatelessWidget {
  final String tag;

  const ServiceBookingDetailsScreen({super.key, required this.tag});

  @override
  Widget build(BuildContext context) {
    final flow = serviceFlowFor(tag);

    return Obx(() {
      final booking = flow.currentBooking.value;
      final items = flow.serviceItems.toList();
      return ServiceFlowScaffold(
        title: 'Booking Details'.tr,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              ServiceFlowCard(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppThemeData.primary200.withValues(alpha: 0.12),
                      child: Text(booking.customerName.isNotEmpty ? booking.customerName[0] : 'C',
                          style: TextStyle(fontFamily: AppThemeData.bold, color: AppThemeData.primary200)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(booking.customerName, style: const TextStyle(fontFamily: AppThemeData.bold, fontSize: 16)),
                          if (booking.customerPhone.isNotEmpty)
                            Text(booking.customerPhone, style: TextStyle(fontSize: 13, color: AppThemeData.grey500)),
                        ],
                      ),
                    ),
                    IconButton(onPressed: flow.callCustomer, icon: Icon(Icons.call_rounded, color: AppThemeData.primary200)),
                    IconButton(onPressed: () {}, icon: Icon(Icons.chat_bubble_outline_rounded, color: AppThemeData.primary200)),
                  ],
                ),
              ),
              ServiceFlowCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: buildDetailRow(Icons.location_on_outlined, 'Service Address'.tr, booking.address)),
                        TextButton.icon(
                          onPressed: flow.openNavigation,
                          icon: const Icon(Icons.navigation_rounded, size: 16),
                          label: Text('Navigate'.tr),
                        ),
                      ],
                    ),
                    Container(
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          colors: [AppThemeData.primary200.withValues(alpha: 0.15), AppThemeData.primary400.withValues(alpha: 0.08)],
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(Icons.map_outlined, size: 48, color: AppThemeData.primary200.withValues(alpha: 0.4)),
                          Positioned(
                            bottom: 10,
                            child: Text('Tap Navigate to open maps'.tr, style: TextStyle(fontSize: 11, color: AppThemeData.grey500)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              ServiceFlowCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Selected Services'.tr, style: const TextStyle(fontFamily: AppThemeData.semiBold, fontSize: 14)),
                    const SizedBox(height: 8),
                    ServiceItemsList(items: items, showPrices: true),
                  ],
                ),
              ),
              if (booking.description.replaceAll('[VERY URGENT]', '').trim().isNotEmpty)
                ServiceFlowCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Customer Note'.tr, style: const TextStyle(fontFamily: AppThemeData.semiBold, fontSize: 14)),
                      const SizedBox(height: 8),
                      Text(
                        booking.description.replaceAll('[VERY URGENT]', '').replaceAll('[Order Note]', '').trim(),
                        style: TextStyle(fontSize: 13, color: AppThemeData.grey500, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ServiceFlowCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Amount'.tr, style: const TextStyle(fontFamily: AppThemeData.semiBold, fontSize: 15)),
                    Text(
                      Constant().amountShow(amount: booking.amount.toStringAsFixed(0)),
                      style: TextStyle(fontFamily: AppThemeData.bold, fontSize: 18, color: AppThemeData.success300),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: FlowPrimaryButton(
              label: 'Start Navigation'.tr,
              icon: Icons.navigation_rounded,
              onPressed: () async {
                await flow.openNavigation();
                Get.to(() => ServiceReachedLocationScreen(tag: tag));
              },
            ),
          ),
        ),
      );
    });
  }
}
