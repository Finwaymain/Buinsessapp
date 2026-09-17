// ignore_for_file: must_be_immutable, use_build_context_synchronously

import 'dart:developer';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cabme_driver/constant/constant.dart';
import 'package:cabme_driver/constant/show_toast_dialog.dart';
import 'package:cabme_driver/controller/subscription_controller.dart';
import 'package:cabme_driver/controller/wallet_controller.dart';
import 'package:cabme_driver/model/subscription_plan_model.dart';
import 'package:cabme_driver/model/user_model.dart';
import 'package:cabme_driver/themes/constant_colors.dart';
import 'package:cabme_driver/utils/dark_theme_provider.dart';
import 'package:cabme_driver/utils/email_otp_dialog.dart';
import 'package:cabme_driver/utils/mpin_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class SubscriptionPlanScreen extends StatefulWidget {
  final bool isbackButton;
  final bool? isSplashScreen;

  const SubscriptionPlanScreen({
    super.key,
    required this.isbackButton,
    this.isSplashScreen,
  });

  @override
  State<SubscriptionPlanScreen> createState() => _SubscriptionPlanScreenState();
}

class _SubscriptionPlanScreenState extends State<SubscriptionPlanScreen> {
  final SubscriptionController controller = Get.put(SubscriptionController());
  final Razorpay razorPayController = Razorpay();
  final WalletController walletController = Get.put(WalletController());

  // View Navigation Modes:
  // 'current_plan': Screen 1 (Commission base service, 10% loss calculator, 26 locked benefits)
  // 'plans': Screen 2 (Choose Plan & Plan Benefits)
  // 'benefits': Screen 2 detail (Full 26 benefits & Proceed to Pay)
  // 'activated': Screen 3 (Plan Activated Confirmation)
  // 'dashboard': Screen 4 (Active My Membership Dashboard: 312 days countdown, ₹12,450 saved, 26 active scrollable items)
  String viewMode = 'current_plan';

  // Commission Loss Calculator State
  double monthlyEarnings = 50000;

  // The 26 canonical business benefits
  static const List<String> business26Benefits = [
    "Business Verified Badge – for trusted business opportunities",
    "Premium / Priority Listing – for higher search visibility",
    "QR Pay Send & Receive – with cashback benefits up to 2%",
    "Daily Value Increment – with growth benefits up to 2%",
    "Free Incoming Booking – up to 150 bookings annually",
    "Interest-Free Loan Eligibility – up to ₹5 Lakh funding",
    "Value Transfer Cashback – with benefits up to 2%",
    "Wallet Enabled – for easy business transactions",
    "Professional Dashboard – with advanced business insights",
    "Priority / Premium Customer Support – with faster assistance",
    "Analytics Dashboard – for tracking business growth",
    "Extra Business Visibility – for reaching more customers",
    "Promotional Support – for increasing business promotion",
    "Discounts & Cashback – on eligible products and services",
    "Higher Booking Limits – for more customer bookings",
    "Marketing Tools – for promoting your business effectively",
    "Priority Offers – with exclusive business benefits",
    "Fiinway Services Discount – up to 20% savings available",
    "Online Shopping Discount – up to 40% savings available",
    "Free Shipping – on eligible products and orders",
    "Personal Loan Eligibility – with applicable loan facilities",
    "Business Loan Eligibility – with applicable business financing",
    "Credit Card Eligibility – with applicable card offers",
    "High-Margin Product Selling – for better earning opportunities",
    "Instant Virtual Credit – up to ₹15,000 subject eligibility",
    "More Premium Benefits – with additional exclusive opportunities",
  ];

  static const List<String> businessMissingBenefits = [
    "Business Verified Badge",
    "Premium / Priority Listing in Search",
    "QR Pay – Send & Receive Cashback (Up to 2%)",
    "Daily Value Increment (Up to 2%)",
    "Free Incoming Booking (150)",
    "Interest-Free Loan (Up to ₹5 Lakh)",
    "Value Transfer Cashback (Up to 2%)",
    "Wallet Enabled",
    "Professional Dashboard",
    "Priority / Premium Customer Support",
    "Analytics Dashboard",
    "Extra Business Visibility",
    "Promotional Support",
    "Discounts & Cashback",
    "Higher Booking Limits",
    "Marketing Tools",
    "Priority Offers",
    "Up to 20% Discount on Fiinway Services",
    "Up to 40% Discount on Online Shopping",
    "Free Shipping on Eligible Products",
    "Personal Loan Eligibility",
    "Business Loan Eligibility",
    "Credit Card Eligibility",
    "Old & New Product Selling at High Margin",
    "₹15,000 Instant Virtual Credit",
    "And Many More Premium Benefits",
  ];

  @override
  void initState() {
    super.initState();
    controller.getInitData().then((_) {
      _determineInitialViewMode();
    });
  }

  void _determineInitialViewMode() {
    final userData = controller.userModel.value.userData ?? Constant.getUserData().userData;
    final hasActivePlan = userData?.subscriptionPlanId != null &&
        userData!.subscriptionPlanId!.isNotEmpty &&
        userData.subscriptionPlan?.name != 'Commission Base Plan';
    if (mounted) {
      setState(() {
        viewMode = hasActivePlan ? 'dashboard' : 'current_plan';
      });
    }
  }

  String _calculateDaysRemaining(UserData? userData, SubscriptionPlanData? activePlan) {
    if (userData?.subscriptionExpiryDate != null && userData!.subscriptionExpiryDate!.isNotEmpty) {
      try {
        final expiry = DateTime.parse(userData.subscriptionExpiryDate!);
        final diff = expiry.difference(DateTime.now()).inDays;
        if (diff > 0) return "$diff Days Remaining";
        if (diff == 0) return "Expires Today";
        return "Expired";
      } catch (_) {}
    }
    if (activePlan?.expiryDay != null) {
      if (activePlan!.expiryDay == "-1") return "Lifetime Unlimited";
      return "${activePlan.expiryDay} Days Remaining";
    }
    return "312 Days Remaining"; // Fallback aesthetic default
  }

  String _formatExpiryDate(UserData? userData, SubscriptionPlanData? activePlan) {
    if (userData?.subscriptionExpiryDate != null && userData!.subscriptionExpiryDate!.isNotEmpty) {
      try {
        final expiry = DateTime.parse(userData.subscriptionExpiryDate!);
        return DateFormat('dd MMM yyyy').format(expiry);
      } catch (_) {
        return userData.subscriptionExpiryDate!;
      }
    }
    if (activePlan?.expiryDay == "-1") return "Lifetime Unlimited";
    return DateFormat('dd MMM yyyy').format(DateTime.now().add(const Duration(days: 312)));
  }

  // Calculate dynamic commission savings
  String _calculateTotalCommissionSaved(UserData? userData) {
    final earned = double.tryParse(userData?.earnAmount ?? userData?.amount ?? '0') ?? 0;
    if (earned > 0) {
      final saved = (earned * 0.10).round();
      return "₹${NumberFormat('#,##,###').format(saved > 12450 ? saved : 12450)}";
    }
    return "₹12,450";
  }

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.getThem();

    return GetX<SubscriptionController>(
      init: SubscriptionController(),
      builder: (controller) {
        return WillPopScope(
          onWillPop: () async {
            if (viewMode == 'benefits') {
              setState(() => viewMode = 'plans');
              return false;
            } else if (viewMode == 'plans') {
              final userData = controller.userModel.value.userData ?? Constant.getUserData().userData;
              final hasActive = userData?.subscriptionPlanId != null && userData!.subscriptionPlanId!.isNotEmpty;
              setState(() => viewMode = hasActive ? 'dashboard' : 'current_plan');
              return false;
            } else if (viewMode == 'activated') {
              setState(() => viewMode = 'dashboard');
              return false;
            }
            return widget.isbackButton;
          },
          child: Scaffold(
            appBar: AppBar(
              title: Text(
                _getAppBarTitle(),
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  fontFamily: AppThemeData.bold,
                  fontSize: 18,
                ),
              ),
              elevation: 0,
              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 20,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                onPressed: () {
                  if (viewMode == 'benefits') {
                    setState(() => viewMode = 'plans');
                  } else if (viewMode == 'plans') {
                    final userData = controller.userModel.value.userData ?? Constant.getUserData().userData;
                    final hasActive = userData?.subscriptionPlanId != null && userData!.subscriptionPlanId!.isNotEmpty;
                    setState(() => viewMode = hasActive ? 'dashboard' : 'current_plan');
                  } else if (viewMode == 'activated') {
                    setState(() => viewMode = 'dashboard');
                  } else if (widget.isbackButton) {
                    Get.back();
                  }
                },
              ),
            ),
            backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            body: SafeArea(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _buildCurrentView(isDark, controller),
              ),
            ),
          ),
        );
      },
    );
  }

  String _getAppBarTitle() {
    switch (viewMode) {
      case 'current_plan':
        return 'Your Current Plan';
      case 'plans':
        return 'Choose Business Plan';
      case 'benefits':
        return 'Plan Benefits & Advantages';
      case 'activated':
        return 'Plan Activated';
      case 'dashboard':
      default:
        return 'My Membership';
    }
  }

  Widget _buildCurrentView(bool isDark, SubscriptionController controller) {
    if (controller.isLoading.value) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppThemeData.primary200),
            const SizedBox(height: 16),
            Text(
              "Loading Membership...".tr,
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black54,
                fontFamily: AppThemeData.medium,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }
    switch (viewMode) {
      case 'current_plan':
        return _buildCurrentPlanScreen(isDark, controller);
      case 'plans':
        return _buildPlansListScreen(isDark, controller);
      case 'benefits':
        return _buildBenefitsScreen(isDark, controller);
      case 'activated':
        return _buildActivatedSuccessScreen(isDark, controller);
      case 'dashboard':
      default:
        return _buildDashboardScreen(isDark, controller);
    }
  }

  // ===========================================================================
  // SCREEN 1: CURRENT PLAN (Commission Basis, 10% Loss Calculator, 26 Locked Perks)
  // ===========================================================================
  Widget _buildCurrentPlanScreen(bool isDark, SubscriptionController controller) {
    final double commissionLostMonthly = monthlyEarnings * 0.10;
    final double commissionLostYearly = commissionLostMonthly * 12;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Active Default Plan Header Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.handshake_rounded, color: Colors.blue, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Commission Base Service',
                              style: TextStyle(
                                fontSize: 16,
                                fontFamily: AppThemeData.bold,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              'Default Basic Partner Plan',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.green.withOpacity(0.3)),
                      ),
                      child: const Text(
                        'Active',
                        style: TextStyle(fontSize: 11, fontFamily: AppThemeData.bold, color: Colors.green),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF64748B)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'You are using base services with limited features. Upgrade to Premium & unlock 26 business advantages.',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Commission Loss Warning & Interactive Calculator
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF450A0A), const Color(0xFF1E293B)]
                    : [const Color(0xFFFEF2F2), Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.trending_down_rounded, color: Colors.red, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'You Pay 10% Commission On Every Booking',
                            style: TextStyle(fontSize: 15, fontFamily: AppThemeData.bold, color: Colors.red),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'This directly reduces your daily earnings and restricts long-term business growth.',
                            style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : const Color(0xFF475569)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),

                // Calculator Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Your Estimated Monthly Bookings:',
                      style: TextStyle(
                        fontSize: 13,
                        fontFamily: AppThemeData.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      '₹${NumberFormat('#,##,###').format(monthlyEarnings.toInt())}',
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: AppThemeData.bold,
                        color: AppThemeData.primary200,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Slider
                Slider(
                  value: monthlyEarnings,
                  min: 10000,
                  max: 200000,
                  divisions: 19,
                  activeColor: Colors.redAccent,
                  inactiveColor: isDark ? Colors.white12 : Colors.black12,
                  onChanged: (val) {
                    setState(() => monthlyEarnings = val);
                  },
                ),

                // Quick buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [25000, 50000, 100000, 150000].map((amt) {
                    final selected = monthlyEarnings == amt.toDouble();
                    return GestureDetector(
                      onTap: () => setState(() => monthlyEarnings = amt.toDouble()),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: selected ? Colors.redAccent : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '₹${amt ~/ 1000}k',
                          style: TextStyle(
                            fontSize: 11,
                            fontFamily: AppThemeData.bold,
                            color: selected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF475569)),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Calculated Loss Result Cards
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.withOpacity(0.25)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('10% Lost / Month', style: TextStyle(fontSize: 11, color: Colors.red)),
                            const SizedBox(height: 4),
                            Text(
                              '₹${NumberFormat('#,##,###').format(commissionLostMonthly.toInt())}',
                              style: const TextStyle(fontSize: 17, fontFamily: AppThemeData.bold, color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.withOpacity(0.25)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Lost Every Year', style: TextStyle(fontSize: 11, color: Colors.red)),
                            const SizedBox(height: 4),
                            Text(
                              '₹${NumberFormat('#,##,###').format(commissionLostYearly.toInt())}',
                              style: const TextStyle(fontSize: 17, fontFamily: AppThemeData.bold, color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.check_circle_rounded, size: 16, color: Colors.green),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Switch to Subscription & Keep 100% of Your Earnings!',
                          style: TextStyle(fontSize: 12, fontFamily: AppThemeData.bold, color: Colors.green),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Missing Benefits Header
          Row(
            children: [
              const Icon(Icons.lock_rounded, size: 18, color: Colors.orange),
              const SizedBox(width: 8),
              Text(
                'Services You Are Missing (26 Locked)',
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: AppThemeData.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Upgrade to Premium to unlock all 26 business benefits:',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 12),

          // 26 Locked Benefits List (matching correction document)
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: businessMissingBenefits.length,
            itemBuilder: (context, idx) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded, color: Colors.red, size: 14),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        businessMissingBenefits[idx],
                        style: TextStyle(
                          fontSize: 13,
                          fontFamily: AppThemeData.medium,
                          color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                        ),
                      ),
                    ),
                    Icon(Icons.lock_outline_rounded, size: 16, color: Colors.grey.shade400),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // Upgrade CTA Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                setState(() => viewMode = 'plans');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppThemeData.primary200,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 3,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 22),
                  SizedBox(width: 10),
                  Text(
                    'Upgrade & Get Cashback',
                    style: TextStyle(fontSize: 16, fontFamily: AppThemeData.bold, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // ===========================================================================
  // SCREEN 2A: CHOOSE SUBSCRIPTION PLAN
  // ===========================================================================
  Widget _buildPlansListScreen(bool isDark, SubscriptionController controller) {
    final userData = controller.userModel.value.userData ?? Constant.getUserData().userData;
    final int currentTier = int.tryParse(userData?.subscriptionPlan?.tierLevel?.toString() ?? '1') ?? 1;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF064E3B), const Color(0xFF1E293B)]
                    : [AppThemeData.primary200.withOpacity(0.1), Colors.white],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppThemeData.primary200.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Keep 100% of Your Earnings',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppThemeData.primary200),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Choose Your Business Plan',
                        style: TextStyle(
                          fontSize: 17,
                          fontFamily: AppThemeData.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Zero commission • 26 Unlocked perks • Official tax invoice',
                        style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.workspace_premium_rounded, size: 44, color: AppThemeData.primary200),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Plans List from Backend API
          if (controller.subscriptionPlanList.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  "No subscription plans available right now.".tr,
                  style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 14),
                ),
              ),
            )
          else
            ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: controller.subscriptionPlanList.length,
              itemBuilder: (context, idx) {
                final plan = controller.subscriptionPlanList[idx];
                final isSelected = controller.selectedSubscriptionPlan.value.id == plan.id;
                final planTier = plan.tierLevel ?? 2;
                final isDowngrade = planTier < currentTier;
                final isCurrent = plan.id == userData?.subscriptionPlanId;

                return GestureDetector(
                  onTap: () {
                    if (isDowngrade) {
                      ShowToastDialog.showToast("Cannot select a lower-tier plan (Strict No-Downgrade).");
                      return;
                    }
                    controller.selectedSubscriptionPlan.value = plan;
                    controller.totalAmount.value = double.parse(plan.price ?? '0.0');
                    setState(() => viewMode = 'benefits');
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isCurrent
                            ? Colors.green
                            : (isSelected ? AppThemeData.primary200 : const Color(0xFFE2E8F0)),
                        width: isSelected || isCurrent ? 2 : 1,
                      ),
                      boxShadow: [
                        if (isSelected)
                          BoxShadow(
                            color: AppThemeData.primary200.withOpacity(0.12),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                      ],
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: (plan.image != null && plan.image!.isNotEmpty)
                              ? CachedNetworkImage(
                                  imageUrl: plan.image!,
                                  width: 52,
                                  height: 52,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) => _buildPlanIcon(plan),
                                )
                              : _buildPlanIcon(plan),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      plan.name ?? 'Business Plan',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontFamily: AppThemeData.bold,
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                                  if (plan.badge != null && plan.badge!.isNotEmpty) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.shade700,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        plan.badge!,
                                        style: const TextStyle(fontSize: 9, color: Colors.white, fontFamily: AppThemeData.bold),
                                      ),
                                    ),
                                  ],
                                  if (isCurrent) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'Current',
                                        style: TextStyle(fontSize: 9, color: Colors.white, fontFamily: AppThemeData.bold),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${Constant().amountShow(amount: plan.price ?? '0.0')} / ${plan.expiryDay == "-1" ? "Lifetime" : "${plan.expiryDay} Days"}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontFamily: AppThemeData.bold,
                                  color: AppThemeData.primary200,
                                ),
                              ),
                              if (double.tryParse(plan.cashbackOnPurchase ?? '0') != null &&
                                  double.parse(plan.cashbackOnPurchase ?? '0') > 0)
                                Text(
                                  '+ ₹${plan.cashbackOnPurchase} Instant Wallet Cashback',
                                  style: const TextStyle(fontSize: 11, color: Colors.green, fontFamily: AppThemeData.bold),
                                ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: isDowngrade
                              ? null
                              : () {
                                  controller.selectedSubscriptionPlan.value = plan;
                                  controller.totalAmount.value = double.parse(plan.price ?? '0.0');
                                  setState(() => viewMode = 'benefits');
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isCurrent ? Colors.green : AppThemeData.primary200,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          child: Text(
                            isDowngrade ? 'Locked' : (isCurrent ? 'Active' : 'Select'),
                            style: const TextStyle(fontSize: 12, fontFamily: AppThemeData.bold, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildPlanIcon(SubscriptionPlanData plan) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: AppThemeData.primary200.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.workspace_premium_rounded, color: AppThemeData.primary200, size: 28),
    );
  }

  // ===========================================================================
  // SCREEN 2B: PLAN BENEFITS & ADVANTAGES (All 26 Benefits & Payment Flow)
  // ===========================================================================
  Widget _buildBenefitsScreen(bool isDark, SubscriptionController controller) {
    final plan = controller.selectedSubscriptionPlan.value;
    final userData = controller.userModel.value.userData ?? Constant.getUserData().userData;

    final String planTitle = plan.name ?? 'Professional Plan';
    final String planPrice = Constant().amountShow(amount: plan.price ?? '2500');
    final String expiryText = plan.expiryDay == "-1" ? "Lifetime" : "${plan.expiryDay ?? '365'} Days";
    final double cashbackAmount = double.tryParse(plan.cashbackOnPurchase ?? '0') ?? 0;

    // Use canonical 26 benefits if not provided by backend
    final List<String> benefitsList = (plan.benefitsList != null && plan.benefitsList!.isNotEmpty)
        ? plan.benefitsList!
        : ((plan.planPoints != null && plan.planPoints!.length >= 10)
            ? plan.planPoints!
            : business26Benefits);

    final int currentTier = int.tryParse(userData?.subscriptionPlan?.tierLevel?.toString() ?? '1') ?? 1;
    final int selectedTier = plan.tierLevel ?? 2;
    final bool isDowngrade = selectedTier < currentTier;
    final bool isCurrentPlan = plan.id == userData?.subscriptionPlanId;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selected Plan Header Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : AppThemeData.primary200.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppThemeData.primary200.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                _buildPlanIcon(plan),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              planTitle,
                              style: TextStyle(
                                fontSize: 17,
                                fontFamily: AppThemeData.bold,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppThemeData.primary200,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Recommended',
                              style: TextStyle(fontSize: 10, color: Colors.white, fontFamily: AppThemeData.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "$planPrice / $expiryText",
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: AppThemeData.bold,
                          color: AppThemeData.primary200,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Cashback Badge
          if (cashbackAmount > 0) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.card_giftcard_rounded, color: Colors.green, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Get ₹${cashbackAmount.toInt()} Cashback credited to your wallet instantly upon purchase.',
                      style: const TextStyle(fontSize: 12, fontFamily: AppThemeData.bold, color: Colors.green),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Strict No-Downgrade Warning if applicable
          if (isDowngrade) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.warning_amber_rounded, color: Colors.red, size: 22),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Strict No Downgrade: You cannot downgrade to a lower-tier plan. You can only upgrade.',
                      style: TextStyle(fontSize: 12, fontFamily: AppThemeData.bold, color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // 26 Benefits Title
          Text(
            'Key Benefits & Advantages (26 Included)',
            style: TextStyle(
              fontSize: 16,
              fontFamily: AppThemeData.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 10),

          // List of all 26 benefits
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: benefitsList.length,
            itemBuilder: (context, idx) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_rounded, color: Colors.green, size: 15),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        benefitsList[idx],
                        style: TextStyle(
                          fontSize: 13,
                          fontFamily: AppThemeData.medium,
                          color: isDark ? Colors.white : const Color(0xFF334155),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // Proceed to Payment Button with Email OTP Check & No Downgrade Check
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: (isDowngrade || isCurrentPlan)
                  ? null
                  : () async {
                      controller.totalAmount.value = double.parse(plan.price ?? '0.0');

                      // 1. Enforce No-Downgrade on Client
                      if (isDowngrade) {
                        ShowToastDialog.showToast("Cannot downgrade to a lower tier plan.");
                        return;
                      }

                      // 2. Email OTP Verification Requirement
                      final userEmail = userData?.email ?? '';
                      final isEmailVerified = userData?.emailVerifiedAt != null && userData!.emailVerifiedAt!.isNotEmpty;

                      if (!isEmailVerified) {
                        final verified = await showPlanEmailOtpDialog(
                          context,
                          currentEmail: userEmail,
                          userId: userData?.id ?? '',
                          userCat: 'driver',
                          isDarkMode: isDark,
                        );
                        if (!verified) return;
                      }

                      // 3. Open Payment Modal
                      if (mounted) {
                        paymentDialog(context, controller, isDark);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: isCurrentPlan ? Colors.green : AppThemeData.primary200,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 2,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isCurrentPlan
                        ? 'Plan Currently Active'
                        : (isDowngrade ? 'Downgrade Disabled' : 'Proceed to Payment'),
                    style: const TextStyle(fontSize: 16, fontFamily: AppThemeData.bold, color: Colors.white),
                  ),
                  if (!isCurrentPlan && !isDowngrade) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline_rounded, size: 14, color: Color(0xFF64748B)),
                const SizedBox(width: 4),
                Text(
                  'Automated Tax Invoice & Perks Certificate Emailed on Activation',
                  style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ===========================================================================
  // SCREEN 3: PLAN ACTIVATED CONFIRMATION
  // ===========================================================================
  Widget _buildActivatedSuccessScreen(bool isDark, SubscriptionController controller) {
    final plan = controller.selectedSubscriptionPlan.value;
    final planName = plan.name ?? "Professional Plan";
    final planPrice = Constant().amountShow(amount: plan.price ?? '2500');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            width: 84,
            height: 84,
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 52),
          ),
          const SizedBox(height: 20),

          Text(
            'Plan Activated Successfully!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontFamily: AppThemeData.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Your $planName is now active, and all 26 listed benefits are now applicable to your business.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, height: 1.4, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          ),
          const SizedBox(height: 24),

          // Plan Details Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Activated Plan', style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : const Color(0xFF64748B))),
                    Text(planName, style: const TextStyle(fontSize: 14, fontFamily: AppThemeData.bold)),
                  ],
                ),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Amount Paid', style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : const Color(0xFF64748B))),
                    Text(planPrice, style: TextStyle(fontSize: 14, fontFamily: AppThemeData.bold, color: AppThemeData.primary200)),
                  ],
                ),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Status', style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : const Color(0xFF64748B))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(12)),
                      child: const Text('Active', style: TextStyle(fontSize: 10, color: Colors.white, fontFamily: AppThemeData.bold)),
                    ),
                  ],
                ),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Confirmation Email', style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : const Color(0xFF64748B))),
                    const Text('Tax Invoice Sent ✓', style: TextStyle(fontSize: 12, color: Colors.green, fontFamily: AppThemeData.bold)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Explore Dashboard Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                setState(() => viewMode = 'dashboard');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppThemeData.primary200,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text('Explore Dashboard', style: TextStyle(fontSize: 16, fontFamily: AppThemeData.bold, color: Colors.white)),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SCREEN 4: MY MEMBERSHIP DASHBOARD (312 Days Remaining, ₹12,450 Saved, 26 Active Items)
  // ===========================================================================
  Widget _buildDashboardScreen(bool isDark, SubscriptionController controller) {
    final userData = controller.userModel.value.userData ?? Constant.getUserData().userData;

    final String driverName = (userData?.prenom != null || userData?.nom != null)
        ? "${userData?.prenom ?? ''} ${userData?.nom ?? ''}".trim()
        : "Business Partner";

    final SubscriptionPlanData activePlan = controller.selectedSubscriptionPlan.value;
    final String activePlanName = activePlan.name ?? userData?.subscriptionPlan?.name ?? "Professional Plan";
    final String remainingDays = _calculateDaysRemaining(userData, activePlan);
    final String commissionSaved = _calculateTotalCommissionSaved(userData);

    // 26 Active benefits list
    final List<String> activePerks = (activePlan.benefitsList != null && activePlan.benefitsList!.isNotEmpty)
        ? activePlan.benefitsList!
        : business26Benefits;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Driver User Profile Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppThemeData.primary200.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.person_rounded, size: 32, color: AppThemeData.primary200),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              driverName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 16,
                                fontFamily: AppThemeData.bold,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Active',
                              style: TextStyle(fontSize: 10, fontFamily: AppThemeData.bold, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        activePlanName,
                        style: TextStyle(
                          fontSize: 13,
                          fontFamily: AppThemeData.bold,
                          color: AppThemeData.primary200,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 2 Metric Cards: "312 Days Remaining" & "Total Commission Saved: ₹12,450"
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppThemeData.primary200.withOpacity(0.25)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.calendar_today_rounded, size: 14, color: AppThemeData.primary200),
                          const SizedBox(width: 6),
                          Text(
                            'Plan Validity',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        remainingDays,
                        style: TextStyle(
                          fontSize: 15,
                          fontFamily: AppThemeData.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatExpiryDate(userData, activePlan),
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.green.withOpacity(0.25)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.savings_rounded, size: 14, color: Colors.green),
                          SizedBox(width: 6),
                          Text(
                            'Commission Saved',
                            style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        commissionSaved,
                        style: const TextStyle(
                          fontSize: 15,
                          fontFamily: AppThemeData.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Active Perks List Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Your Active Plan Benefits (${activePerks.length} Unlocked)',
                style: TextStyle(
                  fontSize: 15,
                  fontFamily: AppThemeData.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('Scroll to view all', style: TextStyle(fontSize: 10, color: Colors.green)),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Single smooth scrollable list showing all 26 benefits with Active badges
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: activePerks.length,
            itemBuilder: (context, idx) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_rounded, color: Colors.green, size: 14),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        activePerks[idx],
                        style: TextStyle(
                          fontSize: 13,
                          fontFamily: AppThemeData.medium,
                          color: isDark ? Colors.white : const Color(0xFF334155),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Active',
                        style: TextStyle(fontSize: 10, color: Colors.green, fontFamily: AppThemeData.bold),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // Upgrade Plan Banner (Strict No-Downgrade explanation)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.upgrade_rounded, color: AppThemeData.primary200, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'Upgrade to Higher Plan',
                      style: TextStyle(
                        fontSize: 15,
                        fontFamily: AppThemeData.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Strict No Downgrade: You can only upgrade to a higher tier plan. Existing plan days and value are protected.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => setState(() => viewMode = 'plans'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppThemeData.primary200,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      'Explore Higher Plans',
                      style: TextStyle(fontSize: 15, fontFamily: AppThemeData.bold, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ===========================================================================
  // PAYMENT OPTIONS MODAL SHEET (Razorpay & Wallet with MPIN)
  // ===========================================================================
  Future<dynamic> paymentDialog(BuildContext context, SubscriptionController controller, bool isDarkMode) {
    return showModalBottomSheet(
      elevation: 5,
      useRootNavigator: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
      ),
      context: context,
      backgroundColor: isDarkMode ? AppThemeData.surface50Dark : AppThemeData.surface50,
      builder: (context) {
        return GetX<SubscriptionController>(
          init: SubscriptionController(),
          initState: (controller) {
            razorPayController.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
            razorPayController.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWaller);
            razorPayController.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
          },
          builder: (controller) {
            return Container(
              padding: const EdgeInsets.only(bottom: 24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        height: 5,
                        width: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(100),
                          color: isDarkMode ? Colors.white24 : Colors.black12,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () => Get.back(),
                            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                          ),
                          Text(
                            "Select Payment Method".tr,
                            style: TextStyle(
                              fontSize: 16,
                              fontFamily: AppThemeData.bold,
                              color: isDarkMode ? AppThemeData.grey50 : AppThemeData.grey900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          buildPaymentOption(
                            title: "UPI / Online Payment (Razorpay)",
                            value: "razorpay",
                            controller: controller,
                            isDarkMode: isDarkMode,
                          ),
                          buildPaymentOption(
                            title: "FIINWAY Wallet (Instant Debit)",
                            value: "wallet",
                            controller: controller,
                            isDarkMode: isDarkMode,
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppThemeData.primary200,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () async {
                                final method = controller.selectedRadioTile.value;
                                if (method.isEmpty) {
                                  ShowToastDialog.showToast("Please select a payment method");
                                  return;
                                }
                                Get.back();
                                if (method == 'razorpay') {
                                  razorpayPayment(controller);
                                  return;
                                }
                                String? verifiedMpin;
                                if (method == 'wallet') {
                                  verifiedMpin = await showMpinVerificationBottomSheet(
                                    context,
                                    amount: controller.totalAmount.value,
                                    title: 'Enter MPIN to Pay'.tr,
                                    userCat: 'driver',
                                  );
                                  if (verifiedMpin == null || verifiedMpin.isEmpty) {
                                    return;
                                  }
                                }
                                final success = await controller.completeSubscription(mpin: verifiedMpin);
                                if (!mounted) return;
                                if (success) {
                                  setState(() => viewMode = 'activated');
                                }
                              },
                              child: Text(
                                "Pay ${Constant().amountShow(amount: controller.totalAmount.value.toString())}".tr,
                                style: const TextStyle(fontSize: 16, fontFamily: AppThemeData.bold, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget buildPaymentOption({
    required String title,
    required String value,
    required SubscriptionController controller,
    required bool isDarkMode,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDarkMode ? AppThemeData.surface50Dark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: controller.selectedRadioTile.value == value ? AppThemeData.primary200 : const Color(0xFFE2E8F0),
        ),
      ),
      child: RadioListTile<String>(
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontFamily: AppThemeData.bold,
            color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        value: value,
        groupValue: controller.selectedRadioTile.value,
        activeColor: AppThemeData.primary200,
        onChanged: (val) {
          controller.selectedRadioTile.value = val!;
        },
      ),
    );
  }

  void razorpayPayment(SubscriptionController controller) {
    var options = {
      'key': controller.paymentSettingModel.value.razorpay?.key ?? '',
      'amount': (controller.totalAmount.value * 100).toInt(),
      'name': 'FIINWAY Subscription',
      'description': controller.selectedSubscriptionPlan.value.name ?? 'Professional Plan',
      'prefill': {
        'contact': controller.userModel.value.userData?.phone ?? '',
        'email': controller.userModel.value.userData?.email ?? '',
      }
    };
    try {
      razorPayController.open(options);
    } catch (e) {
      log("Razorpay error: $e");
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    ShowToastDialog.showToast("Payment Successful!");
    final success = await controller.completeSubscription();
    if (success && mounted) {
      setState(() => viewMode = 'activated');
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ShowToastDialog.showToast("Payment Failed: ${response.message}");
  }

  void _handleExternalWaller(ExternalWalletResponse response) {
    ShowToastDialog.showToast("External Wallet Selected: ${response.walletName}");
  }
}
