import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cabme_driver/constant/constant.dart';
import 'package:cabme_driver/model/ride_model.dart';
import 'package:cabme_driver/service/api.dart';
import 'package:cabme_driver/themes/button_them.dart';
import 'package:cabme_driver/themes/constant_colors.dart';
import 'package:cabme_driver/themes/custom_dialog_box.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PaymentCollectionScreen extends StatefulWidget {
  final RideData rideData;
  final Function(String paymethod) onConfirm;

  const PaymentCollectionScreen({
    Key? key,
    required this.rideData,
    required this.onConfirm,
  }) : super(key: key);

  @override
  _PaymentCollectionScreenState createState() => _PaymentCollectionScreenState();
}

class _PaymentCollectionScreenState extends State<PaymentCollectionScreen> {
  String selectedMethod = 'Cash';
  bool isSwiped = false;
  bool _isConfirming = false;
  Timer? _paymentPollTimer;

  @override
  void initState() {
    super.initState();
    _startPaymentPolling();
  }

  @override
  void dispose() {
    _paymentPollTimer?.cancel();
    super.dispose();
  }

  void _startPaymentPolling() {
    _paymentPollTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (widget.rideData.id == null || !mounted || _isConfirming) return;
      try {
        final response = await http.get(
          Uri.parse("${API.rideDetails}?ride_id=${widget.rideData.id}"),
          headers: API.header,
        ).timeout(const Duration(seconds: 4));

        if (response.statusCode == 200) {
          Map<String, dynamic> rawJson = jsonDecode(response.body);
          dynamic rawItem = rawJson['data'] ?? rawJson['rideDetailsdata'];
          if (rawItem != null && rawItem is Map) {
            String paymentStatus = (rawItem['statut_paiement'] ?? '').toString().toLowerCase();
            if (paymentStatus == "yes" || paymentStatus == "paid") {
              _paymentPollTimer?.cancel();
              _isConfirming = true;
              if (mounted) {
                Get.back(); // close PaymentCollectionScreen
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return CustomDialogBox(
                      title: "Payment Received".tr,
                      descriptions: "Customer has successfully completed payment.".tr,
                      text: "Ok".tr,
                      onPress: () {
                        Get.back();
                        Get.back();
                      },
                      img: Image.asset('assets/images/green_checked.png'),
                    );
                  },
                );
              }
            }
          }
        }
      } catch (_) {}
    });
  }

  void _handleConfirm() {
    if (_isConfirming) return;
    _isConfirming = true;
    _paymentPollTimer?.cancel();
    setState(() {
      isSwiped = true;
    });
    widget.onConfirm(selectedMethod);
  }

  @override
  Widget build(BuildContext context) {
    final baseFare = double.tryParse(widget.rideData.montant?.toString() ?? '0') ?? 0.0;
    final activeMethod = selectedMethod.toLowerCase();
    final taxBreakdown = Constant.getTaxBreakdown(baseFare, activeMethod);
    final totalTax = Constant.calculateTotalTaxes(baseFare, activeMethod);
    final totalPayable = baseFare + totalTax;

    return Scaffold(
      appBar: AppBar(
        title: Text("Collect Payment".tr, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount Summary Card with dynamic GST and Platform Fees
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppThemeData.primary200,
                    AppThemeData.primary200.withValues(alpha: 0.85),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    Constant().amountShow(amount: totalPayable.toString()),
                    style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    selectedMethod == 'Cash' ? "Total Cash to Collect".tr : "Total Fare".tr,
                    style: const TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Detailed Fare Breakdown Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Fare Breakdown".tr, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _breakdownRow("Base Ride Fare".tr, Constant().amountShow(amount: baseFare.toString())),
                  if (taxBreakdown.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    ...taxBreakdown.map((t) => _breakdownRow(
                          t['label'] as String,
                          "+${Constant().amountShow(amount: (t['amount'] as double).toString())}",
                          color: AppThemeData.primary200,
                        )),
                  ],
                  const Divider(height: 20, thickness: 0.8),
                  _breakdownRow(
                    "Total Amount".tr,
                    Constant().amountShow(amount: totalPayable.toString()),
                    isBold: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Text(
              "Select Collection Method".tr,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // 1. Collect Cash Option
            _buildOption(
              'Cash',
              title: 'Collect Cash'.tr,
              subtitle: 'Collect ${Constant().amountShow(amount: totalPayable.toString())} directly in cash'.tr,
              icon: Icons.money_rounded,
            ),

            // 2. Wallet Payment Option
            _buildOption(
              'Wallet',
              title: 'Wallet Payment'.tr,
              subtitle: 'Customer pays via Fiinway Wallet directly in user app'.tr,
              icon: Icons.account_balance_wallet_rounded,
            ),

            const SizedBox(height: 28),

            // Confirmation Actions
            if (selectedMethod == 'Cash') ...[
              Text(
                "Cash Collected?".tr,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onHorizontalDragEnd: (details) {
                  if (details.primaryVelocity != null && details.primaryVelocity! > 200) {
                    _handleConfirm();
                  }
                },
                child: Container(
                  height: 56,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isSwiped ? AppThemeData.success300 : AppThemeData.primary200,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      isSwiped ? "Payment Confirmed ✓".tr : "Swipe / Tap to Confirm Cash →".tr,
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                onTap: _handleConfirm,
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF8F0),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppThemeData.primary200.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppThemeData.primary200, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "The customer will pay ${Constant().amountShow(amount: totalPayable.toString())} from their wallet. Confirm once completed.".tr,
                        style: TextStyle(fontSize: 12.5, color: Colors.grey.shade800),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ButtonThem.buildButton(
                context,
                title: 'Confirm Payment Received'.tr,
                btnColor: _isConfirming ? Colors.grey : AppThemeData.success300,
                txtColor: Colors.white,
                onPress: () => _handleConfirm(),
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _breakdownRow(String label, String amount, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isBold ? 14 : 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBold ? Colors.black87 : Colors.grey.shade700,
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: isBold ? 15 : 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: color ?? (isBold ? AppThemeData.primary200 : Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOption(String method, {required String title, required String subtitle, required IconData icon}) {
    bool isSelected = selectedMethod == method;
    return GestureDetector(
      onTap: () {
        if (_isConfirming) return;
        setState(() {
          selectedMethod = method;
          isSwiped = false;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? AppThemeData.primary200.withValues(alpha: 0.08) : Colors.white,
          border: Border.all(
            color: isSelected ? AppThemeData.primary200 : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1.0,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? AppThemeData.primary200.withValues(alpha: 0.15) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: isSelected ? AppThemeData.primary200 : Colors.grey.shade700, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected ? AppThemeData.primary200 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: AppThemeData.primary200, size: 22)
            else
              Icon(Icons.radio_button_unchecked, color: Colors.grey.shade400, size: 22),
          ],
        ),
      ),
    );
  }
}
