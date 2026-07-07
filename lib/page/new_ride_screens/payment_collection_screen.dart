import 'package:cabme_driver/constant/constant.dart';
import 'package:cabme_driver/model/ride_model.dart';
import 'package:cabme_driver/page/features/SmartValue/MyQR/view/my_qr_view.dart';
import 'package:cabme_driver/themes/button_them.dart';
import 'package:cabme_driver/themes/constant_colors.dart';
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
  String selectedMethod = 'Wallet';
  bool isSwiped = false;
  bool _isConfirming = false;

  void _handleConfirm() {
    if (_isConfirming) return;
    _isConfirming = true;
    setState(() {
      isSwiped = true;
    });
    widget.onConfirm(selectedMethod);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Collect Payment".tr, style: const TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ride amount header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppThemeData.primary200.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    "₹${widget.rideData.montant ?? '0'}",
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Ride Fare",
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Select Payment Method",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildOption('Wallet', hasCashback: true),
            _buildOption('UPI', hasCashback: false),
            _buildOption('Cash', hasCashback: false),
            const Spacer(),
            if (selectedMethod == 'Wallet') ...[
              ButtonThem.buildButton(
                context,
                title: 'Show QR to Collect'.tr,
                btnColor: AppThemeData.primary200,
                txtColor: Colors.white,
                onPress: () {
                  String amountStr = widget.rideData.montant ?? "0";
                  String acNo = Constant.getUserData().userData?.acNo ?? "";
                  String qrPayload = '{"ac_no":"$acNo", "amount":"$amountStr"}';
                  Get.to(() => const MyQRScreen(), arguments: {'qrData': qrPayload});
                },
              ),
              const SizedBox(height: 12),
              ButtonThem.buildButton(
                context,
                title: 'Payment Collected'.tr,
                btnColor: _isConfirming ? Colors.grey : AppThemeData.success300,
                txtColor: Colors.white,
                onPress: () => _handleConfirm(),
              ),
            ] else ...[
              Text(
                "Collected?",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onHorizontalDragEnd: (details) {
                  if (details.primaryVelocity != null && details.primaryVelocity! > 200) {
                    _handleConfirm();
                  }
                },
                child: Container(
                  height: 60,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isSwiped ? Colors.green : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Center(
                    child: Text(
                      isSwiped ? "Confirmed" : "Swipe to Confirm →",
                      style: TextStyle(color: isSwiped ? Colors.white : Colors.black, fontSize: 16),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(String method, {required bool hasCashback}) {
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppThemeData.primary200.withOpacity(0.1) : Colors.white,
          border: Border.all(
            color: isSelected ? AppThemeData.primary200 : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              method == 'Wallet' ? Icons.account_balance_wallet : method == 'UPI' ? Icons.mobile_screen_share : Icons.money,
              color: isSelected ? AppThemeData.primary200 : Colors.grey,
            ),
            const SizedBox(width: 12),
            Text(
              method,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (hasCashback) ...[
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  "Get Cashback!",
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
