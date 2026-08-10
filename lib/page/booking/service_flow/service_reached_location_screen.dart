import 'package:cabme_driver/controller/service_booking_flow_controller.dart';
import 'package:cabme_driver/page/booking/service_flow/service_booking_flow.dart';
import 'package:cabme_driver/page/booking/service_flow/service_flow_widgets.dart';
import 'package:cabme_driver/themes/constant_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pinput/pinput.dart';

class ServiceReachedLocationScreen extends StatefulWidget {
  final String tag;

  const ServiceReachedLocationScreen({super.key, required this.tag});

  @override
  State<ServiceReachedLocationScreen> createState() => _ServiceReachedLocationScreenState();
}

class _ServiceReachedLocationScreenState extends State<ServiceReachedLocationScreen> {
  final _otpController = TextEditingController();
  bool _useQr = false;
  bool _verifying = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final flow = serviceFlowFor(widget.tag);

    return Obx(() {
      final beforePhotos = flow.beforePhotos.toList();
      return ServiceFlowScaffold(
      title: 'Reached Location'.tr,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ServiceFlowCard(
              child: Column(
                children: [
                  Icon(Icons.location_on_rounded, size: 56, color: AppThemeData.primary200.withValues(alpha: 0.7)),
                  const SizedBox(height: 12),
                  Text('Verify to Start Service'.tr, style: const TextStyle(fontFamily: AppThemeData.bold, fontSize: 18)),
                  const SizedBox(height: 8),
                  Text(
                    'Please verify using OTP provided by the customer.'.tr,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: AppThemeData.grey500, height: 1.4),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: Text('OTP Verification'.tr),
                    selected: !_useQr,
                    onSelected: (_) => setState(() => _useQr = false),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: Text('Scan QR Code'.tr),
                    selected: _useQr,
                    onSelected: (_) => setState(() => _useQr = true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (!_useQr)
              ServiceFlowCard(
                child: Column(
                  children: [
                    Pinput(
                      controller: _otpController,
                      length: 4,
                      keyboardType: TextInputType.number,
                      defaultPinTheme: PinTheme(
                        width: 56,
                        height: 56,
                        textStyle: const TextStyle(fontFamily: AppThemeData.bold, fontSize: 20),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppThemeData.grey200),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FlowPrimaryButton(
                      label: _verifying ? 'Verifying...'.tr : 'Verify OTP'.tr,
                      onPressed: _verifying
                          ? null
                          : () async {
                              setState(() => _verifying = true);
                              final ok = await flow.verifyOtpAndStart(_otpController.text.trim());
                              setState(() => _verifying = false);
                              if (ok) {
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  resumeServiceFlowAfterStart(widget.tag);
                                });
                              }
                            },
                    ),
                  ],
                ),
              )
            else
              ServiceFlowCard(
                child: Column(
                  children: [
                    Icon(Icons.qr_code_scanner_rounded, size: 64, color: AppThemeData.grey400),
                    const SizedBox(height: 12),
                    Text('QR scan coming soon'.tr, style: TextStyle(color: AppThemeData.grey500)),
                    const SizedBox(height: 12),
                    Text('Use OTP verification for now.'.tr, style: TextStyle(fontSize: 12, color: AppThemeData.grey400)),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            PhotoUploadRow(
              label: 'Upload Before Photos'.tr,
              photos: beforePhotos,
              onAdd: () => flow.pickPhoto(before: true),
              onRemove: (path) => flow.removePhoto(path, before: true),
            ),
          ],
        ),
      ),
      bottomBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FlowPrimaryButton(
            label: 'Start Service'.tr,
            color: AppThemeData.success300,
            icon: Icons.play_arrow_rounded,
            onPressed: _verifying
                ? null
                : () async {
                    if (_otpController.text.trim().length < 4) {
                      Get.snackbar('OTP Required'.tr, 'Please enter the 4-digit OTP from customer.'.tr);
                      return;
                    }
                    setState(() => _verifying = true);
                    final ok = await flow.verifyOtpAndStart(_otpController.text.trim());
                    setState(() => _verifying = false);
                    if (ok) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        resumeServiceFlowAfterStart(widget.tag);
                      });
                    }
                  },
          ),
        ),
      ),
    );
    });
  }
}
