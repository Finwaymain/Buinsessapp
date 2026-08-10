import 'package:cabme_driver/constant/constant.dart';
import 'package:cabme_driver/controller/service_booking_flow_controller.dart';
import 'package:cabme_driver/page/booking/my_booking_screen.dart';
import 'package:cabme_driver/page/booking/service_flow/service_booking_flow.dart';
import 'package:cabme_driver/page/booking/service_flow/service_flow_widgets.dart';
import 'package:cabme_driver/themes/constant_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class ServicePaymentReceivedScreen extends StatelessWidget {
  final String tag;

  const ServicePaymentReceivedScreen({super.key, required this.tag});

  @override
  Widget build(BuildContext context) {
    final flow = serviceFlowFor(tag);
    final booking = flow.currentBooking.value;
    final now = DateTime.now();

    return ServiceFlowScaffold(
      title: 'Payment Received'.tr,
      showBack: false,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppThemeData.success300.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Icon(Icons.check_circle_rounded, color: AppThemeData.success300, size: 44),
                  const SizedBox(height: 8),
                  Text('Payment Received'.tr, style: TextStyle(fontFamily: AppThemeData.bold, fontSize: 18, color: AppThemeData.success300)),
                  Text('Customer has paid successfully'.tr, style: TextStyle(fontSize: 12, color: AppThemeData.grey500)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ServiceFlowCard(
              child: Column(
                children: [
                  _row('Service Charge'.tr, flow.labourTotal),
                  if (flow.visitingCharge.value > 0) _row('Visiting Charge'.tr, flow.visitingCharge.value),
                  if (flow.materialCost.value > 0) _row('Material Cost'.tr, flow.materialCost.value),
                  _row('Sub Total'.tr, flow.billSubtotal),
                  if (flow.platformFee > 0) _row('Platform Fee'.tr, -flow.platformFee),
                  const Divider(height: 20),
                  _row('Total Amount'.tr, flow.billTotal, bold: true, color: AppThemeData.success300),
                ],
              ),
            ),
            ServiceFlowCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Payment Details'.tr, style: const TextStyle(fontFamily: AppThemeData.semiBold, fontSize: 14)),
                  const SizedBox(height: 10),
                  _detail('Payment Method'.tr, 'Wallet'),
                  _detail('Paid By'.tr, booking.customerName),
                  _detail('Date & Time'.tr, DateFormat('dd MMM yyyy, hh:mm a').format(now)),
                  _detail('Booking ID'.tr, '#${booking.id}'),
                ],
              ),
            ),
            ServiceFlowCard(
              child: Column(
                children: [
                  Text('You Earn'.tr, style: TextStyle(fontSize: 13, color: AppThemeData.grey500)),
                  const SizedBox(height: 6),
                  Text(
                    Constant().amountShow(amount: flow.billSubtotal.toStringAsFixed(0)),
                    style: TextStyle(fontFamily: AppThemeData.bold, fontSize: 32, color: AppThemeData.success300),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FlowPrimaryButton(
                label: 'Download Invoice'.tr,
                outlined: true,
                icon: Icons.download_rounded,
                onPressed: () => Get.snackbar('Invoice'.tr, 'Invoice download coming soon'.tr),
              ),
              const SizedBox(height: 10),
              FlowPrimaryButton(
                label: 'Back to Bookings'.tr,
                onPressed: () {
                  Get.delete<ServiceBookingFlowController>(tag: tag);
                  Get.off(() => const MyBookingScreen());
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, double amount, {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(fontFamily: bold ? AppThemeData.bold : AppThemeData.regular, fontSize: 14))),
          Text(
            '${amount < 0 ? '-' : ''}${Constant().amountShow(amount: amount.abs().toStringAsFixed(0))}',
            style: TextStyle(fontFamily: bold ? AppThemeData.bold : AppThemeData.semiBold, fontSize: 14, color: color),
          ),
        ],
      ),
    );
  }

  Widget _detail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(fontSize: 12, color: AppThemeData.grey500))),
          Text(value, style: const TextStyle(fontSize: 13, fontFamily: AppThemeData.semiBold)),
        ],
      ),
    );
  }
}
