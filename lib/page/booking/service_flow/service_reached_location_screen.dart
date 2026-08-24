import 'package:cabme_driver/controller/my_booking_controller.dart';
import 'package:cabme_driver/controller/service_booking_flow_controller.dart';
import 'package:cabme_driver/page/booking/service_flow/service_booking_flow.dart';
import 'package:cabme_driver/page/booking/service_flow/service_flow_widgets.dart';
import 'package:cabme_driver/themes/constant_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pinput/pinput.dart';

class ServiceReachedLocationScreen extends StatefulWidget {
  final String tag;

  const ServiceReachedLocationScreen({
    super.key,
    required this.tag,
  });

  @override
  State<ServiceReachedLocationScreen> createState() =>
      _ServiceReachedLocationScreenState();
}

class _ServiceReachedLocationScreenState
    extends State<ServiceReachedLocationScreen> {
  final _otpController = TextEditingController();

  bool _verifying = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verifyOtp(
      ServiceBookingFlowController flow,
      ) async {
    if (_verifying) return;
    FocusManager.instance.primaryFocus?.unfocus();

    final otp = _otpController.text.trim();

    if (otp.length != 4) {
      Get.snackbar(
        'OTP Required'.tr,
        'Please enter the 4-digit OTP provided by the customer.'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    setState(() {
      _verifying = true;
    });

    try {
      final ok = await flow.verifyOtpAndStart(otp);

      if (!mounted) return;

      setState(() {
        _verifying = false;
      });

      if (ok) {
        resumeServiceFlowAfterStart(widget.tag);
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _verifying = false;
      });

      Get.snackbar(
        'Verification Failed'.tr,
        'Unable to verify OTP. Please try again.'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final flow = serviceFlowFor(widget.tag);

      return ServiceFlowScaffold(
        title: 'Reached Location'.tr,

        body: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            children: [
              // Header Card
              ServiceFlowCard(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 20,
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppThemeData.primary200.withValues(
                            alpha: 0.10,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.location_on_rounded,
                          size: 38,
                          color: AppThemeData.primary200,
                        ),
                      ),

                      const SizedBox(height: 16),

                      Text(
                        'Verify to Start Service'.tr,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: AppThemeData.bold,
                          fontSize: 20,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'Enter the 4-digit OTP provided by the customer to start the service.'
                            .tr,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: AppThemeData.grey500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // OTP Card
              ServiceFlowCard(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 20,
                  ),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Customer OTP'.tr,
                          style: const TextStyle(
                            fontFamily: AppThemeData.semiBold,
                            fontSize: 15,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      Pinput(
                        controller: _otpController,
                        length: 4,
                        autofocus: true,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        onCompleted: (_) {
                          if (!_verifying) {
                            _verifyOtp(flow);
                          }
                        },
                        defaultPinTheme: PinTheme(
                          width: 58,
                          height: 58,
                          textStyle: const TextStyle(
                            fontFamily: AppThemeData.bold,
                            fontSize: 21,
                          ),
                          decoration: BoxDecoration(
                            color: AppThemeData.grey50,
                            border: Border.all(
                              color: AppThemeData.grey200,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        focusedPinTheme: PinTheme(
                          width: 58,
                          height: 58,
                          textStyle: const TextStyle(
                            fontFamily: AppThemeData.bold,
                            fontSize: 21,
                          ),
                          decoration: BoxDecoration(
                            color: AppThemeData.grey50,
                            border: Border.all(
                              color: AppThemeData.primary200,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        submittedPinTheme: PinTheme(
                          width: 58,
                          height: 58,
                          textStyle: const TextStyle(
                            fontFamily: AppThemeData.bold,
                            fontSize: 21,
                          ),
                          decoration: BoxDecoration(
                            color: AppThemeData.primary200.withValues(
                              alpha: 0.08,
                            ),
                            border: Border.all(
                              color: AppThemeData.primary200,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        child: FlowPrimaryButton(
                          label: _verifying
                              ? 'Verifying...'.tr
                              : 'Verify OTP'.tr,
                          icon: _verifying
                              ? null
                              : Icons.verified_rounded,
                          onPressed: _verifying
                              ? null
                              : () => _verifyOtp(flow),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Information
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppThemeData.primary200.withValues(
                    alpha: 0.06,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppThemeData.primary200.withValues(
                      alpha: 0.15,
                    ),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 20,
                      color: AppThemeData.primary200,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Ask the customer for the OTP displayed in their app. '
                            'The service will start after successful verification.'
                            .tr,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.5,
                          color: AppThemeData.grey500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Cancel Booking
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: AppThemeData.error200,
                ),
                icon: const Icon(
                  Icons.cancel_outlined,
                  size: 18,
                ),
                label: Text(
                  'Cancel Booking'.tr,
                  style: const TextStyle(
                    fontFamily: AppThemeData.semiBold,
                  ),
                ),
                onPressed: () => _confirmCancelBooking(
                  context,
                  flow,
                ),
              ),
            ],
          ),
        ),
      );

  }

  void _confirmCancelBooking(
      BuildContext context,
      ServiceBookingFlowController flow,
      ) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Cancel Booking?'.tr,
          style: const TextStyle(
            fontSize: 16,
            fontFamily: AppThemeData.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to cancel this booking? '
              'It will be released back to other experts.'
              .tr,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('No, Keep'.tr),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppThemeData.error200,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              Get.back();

              final ok = await flow.cancelBooking();

              if (ok) {
                closeServiceFlow(widget.tag);

                if (Get.isRegistered<MyBookingController>()) {
                  final ctrl = Get.find<MyBookingController>();

                  ctrl.markLocallyRejected(
                    flow.booking.id,
                  );

                  ctrl.fetchBookings(
                    showLoader: false,
                  );
                }

                Get.back();
              }
            },
            child: Text('Yes, Cancel'.tr),
          ),
        ],
      ),
    );
  }
}