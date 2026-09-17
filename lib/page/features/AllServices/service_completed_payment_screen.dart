import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:cabme_driver/page/wallet/wallet_screen.dart';
import 'package:cabme_driver/constant/constant.dart';
import 'package:cabme_driver/constant/show_toast_dialog.dart';
import 'package:cabme_driver/controller/service_booking_controller.dart';
import 'package:cabme_driver/model/service_request_model.dart';
import 'package:cabme_driver/themes/button_them.dart';
import 'package:cabme_driver/themes/constant_colors.dart';
import 'package:cabme_driver/utils/dark_theme_provider.dart';
import 'package:cabme_driver/controller/wallet_controller.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'service_payment_success_screen.dart';
import 'service_scan_to_pay_screen.dart';

class ServiceCompletedPaymentScreen extends StatefulWidget {
  final int bookingId;

  const ServiceCompletedPaymentScreen({super.key, required this.bookingId});

  @override
  State<ServiceCompletedPaymentScreen> createState() => _ServiceCompletedPaymentScreenState();
}

class _ServiceCompletedPaymentScreenState extends State<ServiceCompletedPaymentScreen> {
  late final ServiceBookingController _controller;
  late final WalletController _walletController;
  final Razorpay _razorpay = Razorpay();
  ServiceRequestData? _booking;
  String _paymentMethod = 'wallet';
  bool _paying = false;
  bool _loading = true;
  double _walletBalance = 0;
  double _pendingRazorpayAmount = 0;
  bool _applyPromo = true;

  @override
  void initState() {
    super.initState();
    _controller = Get.put(ServiceBookingController(), tag: 'payment_${widget.bookingId}');
    _walletController = Get.isRegistered<WalletController>() ? Get.find<WalletController>() : Get.put(WalletController());
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleRazorpaySuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handleRazorpayError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    _load();
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final item = await _controller.refreshBooking(widget.bookingId);
    final balance = await _controller.fetchWalletBalance();
    if (!mounted) return;
    setState(() {
      _booking = item;
      _walletBalance = balance;
      _loading = false;
    });

    if (item != null && item.isPaid) {
      _goToSuccess(item.payableAmount, item.paymentStatus ?? 'wallet');
    }
  }

  Future<void> _payWithRazorpay(double total) async {
    final razorpay = _walletController.paymentSettingModel.value.razorpay;
    if (razorpay == null || razorpay.isEnabled != 'true' || (razorpay.key ?? '').isEmpty) {
      ShowToastDialog.showToast('UPI/Razorpay is not available. Please choose wallet or cash.'.tr);
      return;
    }

    _pendingRazorpayAmount = total;
    ShowToastDialog.showLoader('Please wait'.tr);
    final order = await _walletController.createOrderRazorPay(amount: total.round(), isTopup: false);
    ShowToastDialog.closeLoader();

    if (order == null || order.id.isEmpty) {
      ShowToastDialog.showToast('Could not start UPI payment.'.tr);
      return;
    }

    _razorpay.open({
      'key': razorpay.key,
      'amount': (total * 100).round(),
      'name': 'Fiinway',
      'order_id': order.id,
      'currency': 'INR',
      'description': 'Home Service Booking',
      'retry': {'enabled': true, 'max_count': 1},
    });
  }

  void _handleRazorpaySuccess(PaymentSuccessResponse response) async {
    setState(() => _paying = true);
    final ok = await _controller.payBooking(bookingId: widget.bookingId, paymentMethod: 'upi', applyPromotional: _applyPromo);
    if (!mounted) return;
    setState(() => _paying = false);
    if (ok) {
      _goToSuccess(_pendingRazorpayAmount, 'upi');
    }
  }

  void _handleRazorpayError(PaymentFailureResponse response) {
    ShowToastDialog.showToast('Payment failed. Please try again.'.tr);
  }

  void _handleExternalWallet(ExternalWalletResponse response) async {
    ShowToastDialog.showToast('Payment processing via ${response.walletName ?? 'UPI'}'.tr);
    setState(() => _paying = true);
    final ok = await _controller.payBooking(bookingId: widget.bookingId, paymentMethod: 'upi', applyPromotional: _applyPromo);
    if (!mounted) return;
    setState(() => _paying = false);
    if (ok) {
      _goToSuccess(_pendingRazorpayAmount, 'upi');
    }
  }

  Future<void> _pay() async {
    final booking = _booking;
    if (booking == null || booking.isPaid) return;

    final baseTotal = booking.payableAmount;
    if (baseTotal <= 0) {
      ShowToastDialog.showToast('Payment amount is not available. Please contact support.'.tr);
      return;
    }

    final hasPromo = booking.hasPromotionalBonus;
    final promoDiscount = booking.promotionalDiscountValue;
    final effectiveBase = (hasPromo && !_applyPromo) ? (baseTotal + promoDiscount) : baseTotal;

    final totalTax = Constant.calculateTotalTaxes(effectiveBase, _paymentMethod);
    final totalWithTax = effectiveBase + totalTax;

    if (_paymentMethod == 'wallet') {
      final paymentSuccess = await Get.to(() => ServiceScanToPayScreen(
            bookingId: widget.bookingId,
            expectedDriverId: booking.driverId?.toString() ?? '',
            amount: totalWithTax,
            controller: _controller,
            applyPromotional: _applyPromo,
          ));

      if (paymentSuccess == true) {
        _goToSuccess(totalWithTax, 'wallet');
      }
      return;
    }

    if (_paymentMethod == 'upi') {
      await _payWithRazorpay(totalWithTax);
      return;
    }

    setState(() => _paying = true);
    final ok = await _controller.payBooking(
      bookingId: widget.bookingId,
      paymentMethod: _paymentMethod,
      applyPromotional: _applyPromo,
    );
    if (!mounted) return;
    setState(() => _paying = false);

    if (ok) {
      _goToSuccess(totalWithTax, _paymentMethod);
    }
  }

  void _goToSuccess(double amount, String method) {
    Get.off(
      () => ServicePaymentSuccessScreen(
        bookingId: widget.bookingId,
        amountPaid: amount,
        paymentMethod: method,
        initialBooking: _booking,
      ),
    );
  }

  String _money(double value) => '${Constant.currency ?? ''}${value.toStringAsFixed(0)}';

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<DarkThemeProvider>(context).getThem();
    final booking = _booking;
    final baseTotal = booking?.payableAmount ?? 0.0;
    final hasPromo = booking?.hasPromotionalBonus ?? false;
    final promoAmount = booking?.promotionalAmountValue ?? 0.0;
    final promoDiscount = booking?.promotionalDiscountValue ?? 0.0;
    final displayedSubtotal = hasPromo ? (baseTotal + promoAmount) : baseTotal;
    final effectiveBase = (hasPromo && !_applyPromo) ? (baseTotal + promoDiscount) : baseTotal;
    final taxBreakdown = Constant.getTaxBreakdown(effectiveBase, _paymentMethod);
    final totalTaxAmount = Constant.calculateTotalTaxes(effectiveBase, _paymentMethod);
    final finalPayableTotal = effectiveBase + totalTaxAmount;
    final visitLabel = booking?.visitingChargeLabel ?? '';
    final visitAmount = booking?.visitingChargeAmount ?? 0.0;
    final materialAmount = booking?.materialCostAmount ?? 0.0;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: isDarkMode ? AppThemeData.surface50Dark : const Color(0xFFF7F8FA),
        appBar: AppBar(
          backgroundColor: isDarkMode ? AppThemeData.surface50Dark : Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Text(
            'Complete Payment'.tr,
            style: TextStyle(fontFamily: AppThemeData.bold, fontSize: 18, color: isDarkMode ? AppThemeData.grey900Dark : Colors.black),
          ),
        ),
        body: _loading || booking == null
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [AppThemeData.primary200, AppThemeData.primary300]),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                const Icon(Icons.celebration, color: Colors.white, size: 36),
                                const SizedBox(height: 8),
                                Text('Payment Required'.tr, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text('Pay now so the expert can complete your booking.'.tr, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _card(
                            isDarkMode,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Payment Summary'.tr, style: const TextStyle(fontFamily: AppThemeData.semiBold, fontSize: 14)),
                                const SizedBox(height: 10),
                                if (booking.bookedServiceItems.isNotEmpty)
                                  ...booking.bookedServiceItems.map((e) {
                                    final isFirst = booking.bookedServiceItems.indexOf(e) == 0;
                                    double itemPrice = e.priceAvailable ? e.minPrice : (double.tryParse(e.price.toString()) ?? 0.0);
                                    if (hasPromo && isFirst && itemPrice + visitAmount < displayedSubtotal && promoAmount > 0) {
                                      itemPrice += promoAmount;
                                    }
                                    return _priceRow(
                                      e.name,
                                      itemPrice > 0 ? _money(itemPrice) : (e.displayPrice.isNotEmpty ? e.displayPrice : 'Rate on visit'.tr),
                                      isDarkMode,
                                    );
                                  }),
                                if (visitAmount > 0)
                                  _priceRow('Visiting Charge'.tr, _money(visitAmount), isDarkMode)
                                else if (visitLabel.isNotEmpty)
                                  _priceRow('Visiting Charge'.tr, visitLabel, isDarkMode),
                                if (materialAmount > 0)
                                  _priceRow('Material Cost'.tr, _money(materialAmount), isDarkMode),
                                if (hasPromo) ...[
                                  const Divider(height: 16),
                                  _priceRow('Booking Total'.tr, _money(displayedSubtotal), isDarkMode, bold: true),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: _applyPromo ? Colors.green.withValues(alpha: 0.08) : Colors.grey.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: _applyPromo ? Colors.green.withValues(alpha: 0.35) : Colors.grey.shade300,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.card_giftcard_rounded, color: Colors.green, size: 22),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '🎁 Promotion Bonus'.tr,
                                                style: TextStyle(
                                                  fontFamily: AppThemeData.semiBold,
                                                  fontSize: 13,
                                                  color: _applyPromo ? Colors.green.shade800 : (isDarkMode ? AppThemeData.grey300Dark : Colors.grey.shade700),
                                                ),
                                              ),
                                              Text(
                                                'Exclusive service discount'.tr,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: isDarkMode ? AppThemeData.grey400Dark : Colors.grey.shade600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          '-${_money(promoDiscount)}',
                                          style: TextStyle(
                                            fontFamily: AppThemeData.bold,
                                            fontSize: 14,
                                            color: _applyPromo ? Colors.green : Colors.grey,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Transform.scale(
                                          scale: 0.8,
                                          child: Switch(
                                            value: _applyPromo,
                                            activeColor: Colors.green,
                                            onChanged: (val) {
                                              setState(() => _applyPromo = val);
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                if (taxBreakdown.isNotEmpty) ...[
                                  const Divider(height: 16),
                                  ...taxBreakdown.map((t) => _priceRow(
                                        t['label'] as String,
                                        '+${_money(t['amount'] as double)}',
                                        isDarkMode,
                                        color: AppThemeData.primary200,
                                      )),
                                ],
                                const Divider(height: 20),
                                _priceRow(
                                  'Total Amount'.tr,
                                  finalPayableTotal > 0 ? _money(finalPayableTotal) : booking.displayPayableLabel,
                                  isDarkMode,
                                  bold: true,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          _card(
                            isDarkMode,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Select Payment Method'.tr, style: const TextStyle(fontFamily: AppThemeData.semiBold, fontSize: 14)),
                                const SizedBox(height: 4),
                                Text(
                                  '${'Wallet balance'.tr}: ${_money(_walletBalance)}',
                                  style: TextStyle(fontSize: 12, color: isDarkMode ? AppThemeData.grey500Dark : AppThemeData.grey500),
                                ),
                                const SizedBox(height: 8),
                                RadioListTile<String>(
                                  value: 'wallet',
                                  groupValue: _paymentMethod,
                                  activeColor: AppThemeData.primary200,
                                  title: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Wallet Balance'.tr,
                                        ),
                                      ),
                                      if (_walletBalance < finalPayableTotal && finalPayableTotal > 0)
                                        InkWell(
                                          borderRadius: BorderRadius.circular(20),
                                          onTap: () {
                                            Get.to(() => WalletScreen());
                                          },
                                          child: Container(
                                            width: 34,
                                            height: 34,
                                            decoration: BoxDecoration(
                                              color: AppThemeData.primary200.withValues(
                                                alpha: 0.10,
                                              ),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.add_rounded,
                                              size: 22,
                                              color: AppThemeData.primary200,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  subtitle: _walletBalance < finalPayableTotal && finalPayableTotal > 0
                                      ? Text(
                                          'Insufficient balance'.tr,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.orange.shade700,
                                          ),
                                        )
                                      : Text(
                                          Constant.calculateTotalTaxes(effectiveBase, 'wallet') > 0
                                              ? 'Pay ${_money(finalPayableTotal)} directly from wallet'
                                              : 'Pay ${_money(finalPayableTotal)} directly from wallet (tax-exempt)'.tr,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isDarkMode
                                                ? AppThemeData.grey500Dark
                                                : AppThemeData.grey500,
                                          ),
                                        ),
                                  onChanged: booking.isPaid
                                      ? null
                                      : (v) => setState(
                                            () => _paymentMethod = v ?? 'wallet',
                                          ),
                                ),
                                RadioListTile<String>(
                                  value: 'upi',
                                  groupValue: _paymentMethod,
                                  activeColor: AppThemeData.primary200,
                                  title: Text('UPI'.tr),
                                  subtitle: Text('Pay via Razorpay UPI'.tr, style: TextStyle(fontSize: 11, color: isDarkMode ? AppThemeData.grey500Dark : AppThemeData.grey500)),
                                  onChanged: booking.isPaid ? null : (v) => setState(() => _paymentMethod = v ?? 'upi'),
                                ),
                                RadioListTile<String>(
                                  value: 'cash',
                                  groupValue: _paymentMethod,
                                  activeColor: AppThemeData.primary200,
                                  title: Text('Cash / Other'.tr),
                                  onChanged: booking.isPaid ? null : (v) => setState(() => _paymentMethod = v ?? 'cash'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    color: isDarkMode ? AppThemeData.grey100Dark : Colors.white,
                    child: SafeArea(
                      top: false,
                      child: ButtonThem.buildButton(
                        context,
                        title: booking.isPaid
                            ? 'Already Paid'.tr
                            : (_paying ? 'Processing...'.tr : '${'Pay'.tr} ${finalPayableTotal > 0 ? _money(finalPayableTotal) : booking.displayPayableLabel}'),
                        btnColor: AppThemeData.primary200,
                        txtColor: Colors.white,
                        radius: 12,
                        onPress: (_paying || booking.isPaid || finalPayableTotal <= 0) ? () {} : _pay,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _card(bool isDarkMode, {required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDarkMode ? AppThemeData.grey100Dark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
      ),
      child: child,
    );
  }

  Widget _priceRow(String label, String value, bool isDarkMode, {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(fontSize: 13, fontFamily: bold ? AppThemeData.semiBold : AppThemeData.regular))),
          Text(value, style: TextStyle(fontSize: 13, fontFamily: bold ? AppThemeData.bold : AppThemeData.semiBold, color: color ?? (bold ? AppThemeData.primary200 : null))),
        ],
      ),
    );
  }
}
