import 'dart:async';

import 'package:cabme_driver/constant/constant.dart';
import 'package:cabme_driver/controller/service_booking_flow_controller.dart';
import 'package:cabme_driver/page/booking/my_booking_screen.dart';
import 'package:cabme_driver/page/booking/service_flow/service_booking_flow.dart';
import 'package:cabme_driver/page/booking/service_flow/service_flow_widgets.dart';
import 'package:cabme_driver/page/booking/service_flow/service_payment_received_screen.dart';
import 'package:cabme_driver/themes/constant_colors.dart';
import 'package:cabme_driver/utils/Preferences.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ServiceCompletionScreen extends StatefulWidget {
  final String tag;

  const ServiceCompletionScreen({super.key, required this.tag});

  @override
  State<ServiceCompletionScreen> createState() => _ServiceCompletionScreenState();
}

class _ServiceCompletionScreenState extends State<ServiceCompletionScreen> {
  final _summaryController = TextEditingController();
  bool _submitting = false;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshPaymentStatus());
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _refreshPaymentStatus());
  }

  Future<void> _refreshPaymentStatus() async {
    if (!mounted) return;
    final flow = serviceFlowFor(widget.tag);
    final booking = flow.currentBooking.value;
    if (!booking.isAwaitingPayment) return;

    final updated = await flow.listController.fetchSingleBooking(flow.booking.id);
    if (updated == null || !mounted) return;

    flow.currentBooking.value = updated;
    setState(() {});

    if (updated.isPaid) {
      _pollTimer?.cancel();
      Get.snackbar('Payment Received'.tr, 'You can now complete the job.'.tr);
      Get.off(() => ServicePaymentReceivedScreen(tag: widget.tag));
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _summaryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final flow = serviceFlowFor(widget.tag);

    return Obx(() {
      final booking = flow.currentBooking.value;
      final materialCost = flow.materialCost.value;
      final awaitingPayment = booking.isAwaitingPayment;
      final isPaid = booking.isPaid;

      return ServiceFlowScaffold(
        title: 'Finish Service'.tr,
        showBack: false,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppThemeData.primary200.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppThemeData.primary200.withValues(alpha: 0.25)),
                ),
                child: Column(
                  children: [
                    Icon(Icons.receipt_long_rounded, color: AppThemeData.primary200, size: 40),
                    const SizedBox(height: 8),
                    Text(
                      awaitingPayment
                          ? (isPaid ? 'Payment received from customer'.tr : 'Waiting for customer payment...'.tr)
                          : 'Work finished? Request payment before completing.'.tr,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppThemeData.primary200, fontFamily: AppThemeData.semiBold),
                    ),
                  ],
                ),
              ),
              if (awaitingPayment && !isPaid) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppThemeData.grey200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Scan to Pay (Wallet)'.tr,
                        style: TextStyle(
                          fontFamily: AppThemeData.bold,
                          fontSize: 15,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Show this QR code to the customer to scan and pay directly from their wallet.'.tr,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: AppThemeData.grey500),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: QrImageView(
                          data: '{"type":"service_payment","booking_id":"${booking.id}","driver_id":"${Preferences.getInt(Preferences.userId)}"}',
                          version: QrVersions.auto,
                          size: 180.0,
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              // PhotoUploadRow(
              //   label: 'Upload After Photos'.tr,
              //   photos: afterPhotos,
              //   onAdd: () => flow.pickPhoto(before: false),
              //   onRemove: (path) => flow.removePhoto(path, before: false),
              // ),
              ServiceFlowCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Work Summary'.tr, style: const TextStyle(fontFamily: AppThemeData.semiBold, fontSize: 14)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _summaryController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Describe work completed...'.tr,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onChanged: (v) => flow.workSummary.value = v,
                    ),
                  ],
                ),
              ),
              if (materialCost > 0)
                ServiceFlowCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Material Used'.tr, style: const TextStyle(fontFamily: AppThemeData.semiBold, fontSize: 14)),
                      const SizedBox(height: 8),
                      _chargeRow('Material Cost'.tr, materialCost),
                    ],
                  ),
                ),
              ServiceFlowCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bill Summary'.tr, style: const TextStyle(fontFamily: AppThemeData.semiBold, fontSize: 14)),
                    const SizedBox(height: 10),
                    if (flow.itemizedBillItems.isNotEmpty)
                      ...flow.itemizedBillItems.map((item) => _chargeRow(item.name, item.price))
                    else
                      _chargeRow('Service Charge'.tr, flow.labourTotal),
                    if (flow.visitingCharge.value > 0) _chargeRow('Visiting Charge'.tr, flow.visitingCharge.value),
                    if (flow.materialCost.value > 0) _chargeRow('Material Cost'.tr, flow.materialCost.value),
                    const Divider(height: 20),
                    _chargeRow('Total Bill'.tr, flow.billTotal, bold: true, color: AppThemeData.success300),
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
                if (!awaitingPayment && !isPaid)
                  FlowPrimaryButton(
                    label: _submitting ? 'Sending...'.tr : 'Request Payment from Customer'.tr,
                    icon: Icons.payments_outlined,
                    onPressed: _submitting
                        ? null
                        : () async {
                            setState(() => _submitting = true);
                            final ok = await flow.requestPayment();
                            setState(() => _submitting = false);
                            if (ok) {
                              Get.snackbar('Payment Requested'.tr, 'Customer will pay from their app.'.tr);
                            }
                          },
                  ),
                if (awaitingPayment && !isPaid) ...[
                  FlowPrimaryButton(
                    label: _submitting ? 'Completing...'.tr : 'Received Cash & Complete Job'.tr,
                    color: AppThemeData.success300,
                    icon: Icons.payments_outlined,
                    onPressed: _submitting
                        ? null
                        : () => _confirmCashReceived(context, flow),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Or ask customer to scan QR code / pay online in app.'.tr,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: AppThemeData.grey500),
                  ),
                ],
                if (isPaid)
                  FlowPrimaryButton(
                    label: _submitting ? 'Completing...'.tr : 'Complete Job'.tr,
                    color: AppThemeData.success300,
                    onPressed: _submitting
                        ? null
                        : () async {
                            setState(() => _submitting = true);
                            final ok = await flow.completeJob();
                            setState(() => _submitting = false);
                            if (ok) {
                              Get.delete<ServiceBookingFlowController>(tag: widget.tag);
                              Get.off(() => const MyBookingScreen());
                              Get.snackbar('Completed'.tr, 'Service marked as completed.'.tr);
                            }
                          },
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }

  void _confirmCashReceived(BuildContext context, ServiceBookingFlowController flow) {
    final amountStr = Constant().amountShow(amount: flow.billTotal.toStringAsFixed(0));
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.payments_rounded, color: AppThemeData.success300),
            const SizedBox(width: 8),
            Text('Confirm Cash Payment'.tr, style: const TextStyle(fontSize: 16)),
          ],
        ),
        content: Text(
          'Did you receive $amountStr in cash directly from the customer?'.tr,
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel'.tr),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppThemeData.success300,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Get.back();
              setState(() => _submitting = true);
              final ok = await flow.completeJobWithCash();
              setState(() => _submitting = false);
              if (ok) {
                _pollTimer?.cancel();
                Get.delete<ServiceBookingFlowController>(tag: widget.tag);
                Get.off(() => const MyBookingScreen());
                Get.snackbar('Job Completed'.tr, 'Service completed via Cash payment.'.tr);
              }
            },
            child: Text('Yes, Received Cash'.tr),
          ),
        ],
      ),
    );
  }

  Widget _chargeRow(String label, double amount, {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: TextStyle(fontFamily: bold ? AppThemeData.bold : AppThemeData.regular, fontSize: 14)),
          ),
          Text(
            Constant().amountShow(amount: amount.toStringAsFixed(0)),
            style: TextStyle(fontFamily: bold ? AppThemeData.bold : AppThemeData.semiBold, fontSize: 14, color: color),
          ),
        ],
      ),
    );
  }
}
