import 'package:cabme_driver/constant/constant.dart';
import 'package:cabme_driver/controller/my_booking_controller.dart';
import 'package:cabme_driver/page/booking/service_flow/service_booking_flow.dart';
import 'package:cabme_driver/page/booking/service_flow/service_flow_widgets.dart';
import 'package:cabme_driver/page/MainDashBoard/screen/main_dashboard.dart';
import 'package:cabme_driver/service/in_app_sound_service.dart';
import 'package:cabme_driver/themes/constant_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ServiceIncomingRequestScreen extends StatefulWidget {
  final String tag;

  const ServiceIncomingRequestScreen({super.key, required this.tag});

  @override
  State<ServiceIncomingRequestScreen> createState() => _ServiceIncomingRequestScreenState();
}

class _ServiceIncomingRequestScreenState extends State<ServiceIncomingRequestScreen> {
  @override
  void initState() {
    super.initState();
    InAppSoundService.playIncomingBookingAlert();
  }

  @override
  void dispose() {
    InAppSoundService.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final flow = serviceFlowFor(widget.tag);
    final booking = flow.currentBooking.value;

    return ServiceFlowScaffold(
      title: 'New Service Request'.tr,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CustomerHeaderCard(booking: booking, onCall: flow.callCustomer),
            ServiceFlowCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildDetailRow(Icons.location_on_outlined, 'Service Address'.tr, booking.address),
                  buildDetailRow(Icons.home_repair_service_outlined, 'Service Category'.tr, booking.categoryLabel),
                  if (booking.serviceItems.isNotEmpty) ...[
                    Text('Sub Services'.tr, style: TextStyle(fontSize: 11, color: AppThemeData.grey500)),
                    const SizedBox(height: 8),
                    ServiceItemsList(items: booking.serviceItems, showPrices: false),
                  ],
                  buildDetailRow(Icons.calendar_today_outlined, 'Preferred Date & Time'.tr, booking.scheduleLabel),
                  if (booking.isUrgent)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppThemeData.error200.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.bolt_rounded, color: AppThemeData.error200, size: 18),
                          const SizedBox(width: 8),
                          Text('Very Urgent'.tr, style: TextStyle(color: AppThemeData.error200, fontFamily: AppThemeData.semiBold)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            ServiceFlowCard(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Estimated Earnings'.tr, style: TextStyle(fontSize: 12, color: AppThemeData.grey500)),
                        const SizedBox(height: 4),
                        Text(
                          Constant().amountShow(amount: booking.amount.toStringAsFixed(0)),
                          style: TextStyle(fontFamily: AppThemeData.bold, fontSize: 22, color: AppThemeData.primary200),
                        ),
                        Text('You will earn for this booking'.tr, style: TextStyle(fontSize: 11, color: AppThemeData.grey500)),
                      ],
                    ),
                  ),
                  Icon(Icons.payments_outlined, color: AppThemeData.primary200.withValues(alpha: 0.5), size: 40),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: FlowPrimaryButton(
                    label: 'Reject'.tr,
                    outlined: true,
                    color: AppThemeData.error200,
                    icon: Icons.close_rounded,
                    onPressed: () async {
                      await InAppSoundService.stop();
                      try {
                        await flow.rejectBooking();
                      } catch (e) {
                        debugPrint('Error rejecting booking: $e');
                      } finally {
                        closeServiceFlow(widget.tag);
                        if (Get.isRegistered<MyBookingController>()) {
                          final ctrl = Get.find<MyBookingController>();
                          // Mark as locally rejected BEFORE any poll can re-add it
                          ctrl.markLocallyRejected(booking.id);
                          ctrl.bookings.removeWhere((e) => e.id == booking.id);
                          ctrl.fetchBookings(showLoader: false);
                        }
                        if (Get.context != null && Navigator.canPop(Get.context!)) {
                          Get.back();
                        } else {
                          Get.offAll(() => const MainDashboard());
                        }
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FlowPrimaryButton(
                    label: 'Accept'.tr,
                    onPressed: () async {
                      await InAppSoundService.stop();
                      final ok = await flow.acceptBooking();
                      if (ok) resumeServiceFlowAfterAccept(widget.tag);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
