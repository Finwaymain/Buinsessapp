import 'dart:async';

import 'package:cabme_driver/constant/constant.dart';
import 'package:cabme_driver/controller/service_booking_flow_controller.dart';
import 'package:cabme_driver/page/booking/my_booking_screen.dart';
import 'package:cabme_driver/page/booking/service_flow/service_booking_flow.dart';
import 'package:cabme_driver/page/booking/service_flow/service_flow_widgets.dart';
import 'package:cabme_driver/themes/constant_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

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

    await flow.listController.fetchBookings();
    final updated = flow.listController.bookings.firstWhereOrNull((e) => e.id == flow.booking.id);
    if (updated == null || !mounted) return;

    flow.currentBooking.value = updated;
    setState(() {});

    if (updated.isPaid) {
      _pollTimer?.cancel();
      Get.snackbar('Payment Received'.tr, 'You can now complete the job.'.tr);
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
      final afterPhotos = flow.afterPhotos.toList();
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
              const SizedBox(height: 12),
              PhotoUploadRow(
                label: 'Upload After Photos'.tr,
                photos: afterPhotos,
                onAdd: () => flow.pickPhoto(before: false),
                onRemove: (path) => flow.removePhoto(path, before: false),
              ),
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
                  children: [
                    _chargeRow('Labour Charges'.tr, flow.labourTotal),
                    if (flow.visitingCharge.value > 0) _chargeRow('Visiting Charge'.tr, flow.visitingCharge.value),
                    if (flow.materialCost.value > 0) _chargeRow('Material Cost'.tr, flow.materialCost.value),
                    if (flow.platformFeeStored.value > 0) _chargeRow('Platform Fee'.tr, flow.platformFeeStored.value),
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
                  const SizedBox(height: 8),
                  Text(
                    'Complete Job will unlock after customer pays.'.tr,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: AppThemeData.grey500),
                  ),
                ],
                const SizedBox(height: 10),
                FlowPrimaryButton(
                  label: _submitting ? 'Completing...'.tr : 'Complete Job'.tr,
                  color: AppThemeData.success300,
                  onPressed: (_submitting || !isPaid)
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
