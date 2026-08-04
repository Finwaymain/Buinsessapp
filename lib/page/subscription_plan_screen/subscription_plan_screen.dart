// ignore_for_file: must_be_immutable, use_build_context_synchronously

import 'dart:developer';
import 'package:cabme_driver/constant/constant.dart';
import 'package:cabme_driver/constant/show_toast_dialog.dart';
import 'package:cabme_driver/controller/subscription_controller.dart';
import 'package:cabme_driver/controller/wallet_controller.dart';
import 'package:cabme_driver/model/subscription_plan_model.dart';
import 'package:cabme_driver/model/user_model.dart';
import 'package:cabme_driver/themes/constant_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../../utils/dark_theme_provider.dart';

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

  // View Navigation Modes (NO top tabs!):
  // 'dashboard': My Membership Dashboard (Default Initial View)
  // 'plans': Choose Subscription Plan Screen
  // 'benefits': Plan Benefits & Advantages Screen
  // 'activated': Plan Activated Confirmation Screen
  String viewMode = 'dashboard';
  int selectedPlanIndex = 1;

  @override
  void initState() {
    super.initState();
    viewMode = 'dashboard';
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
            if (viewMode != 'dashboard') {
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
                  if (viewMode != 'dashboard') {
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
      case 'dashboard':
        return 'My Membership';
      case 'plans':
        return 'Choose Subscription Plan';
      case 'benefits':
        return 'Plan Benefits & Advantages';
      case 'activated':
        return 'Plan Activated';
      default:
        return 'My Membership';
    }
  }

  Widget _buildCurrentView(bool isDark, SubscriptionController controller) {
    switch (viewMode) {
      case 'dashboard':
        return _buildDashboardScreen(isDark, controller);
      case 'plans':
        return _buildPlansListScreen(isDark, controller);
      case 'benefits':
        return _buildBenefitsScreen(isDark, controller);
      case 'activated':
        return _buildActivatedSuccessScreen(isDark, controller);
      default:
        return _buildDashboardScreen(isDark, controller);
    }
  }

  // ===========================================================================
  // 1. DEFAULT SCREEN: MY MEMBERSHIP DASHBOARD (User Info + Active Benefits)
  // ===========================================================================
  Widget _buildDashboardScreen(bool isDark, SubscriptionController controller) {
    final userData = Constant.getUserData().userData;
    final String driverName = (userData?.nom != null && userData!.nom!.isNotEmpty) ? "${userData.nom} ${userData.prenom ?? ''}" : "Amit Sharma";

    final String activePlanName = (controller.selectedSubscriptionPlan.value.name != null && controller.selectedSubscriptionPlan.value.name!.isNotEmpty)
        ? controller.selectedSubscriptionPlan.value.name!
        : "Professional Plan";

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Driver Profile Header Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppThemeData.primary200.withValues(alpha: 0.12),
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
                          Text(
                            driverName,
                            style: TextStyle(
                              fontSize: 16,
                              fontFamily: AppThemeData.bold,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppThemeData.primary200,
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
                          fontFamily: AppThemeData.medium,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Plan Validity Stats
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : AppThemeData.primary200.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppThemeData.primary200.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Plan Validity', style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                      const SizedBox(height: 4),
                      Text('10 Jun 2026', style: TextStyle(fontSize: 14, fontFamily: AppThemeData.bold, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : AppThemeData.primary200.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppThemeData.primary200.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Days Remaining', style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                      const SizedBox(height: 4),
                      Text('312 days', style: TextStyle(fontSize: 14, fontFamily: AppThemeData.bold, color: AppThemeData.primary200)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Subscription Details
          Text('Subscription Details', style: TextStyle(fontSize: 15, fontFamily: AppThemeData.bold, color: isDark ? Colors.white : const Color(0xFF0F172A))),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                _buildSubDetailRow('Plan Name', activePlanName, isDark),
                const Divider(height: 16),
                _buildSubDetailRow('Subscription Price', '₹2,500 / Year', isDark),
                const Divider(height: 16),
                _buildSubDetailRow('Activated On', '10 Jun 2025', isDark),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Active Plan Benefits Progress Grid
          Text('Plan Benefits (Your Active Plan)', style: TextStyle(fontSize: 15, fontFamily: AppThemeData.bold, color: isDark ? Colors.white : const Color(0xFF0F172A))),
          const SizedBox(height: 12),

          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildBenefitProgressCard('Free Rides', '150 / ∞', 0.8, Icons.directions_car_rounded, isDark),
              _buildBenefitProgressCard('Wallet Cashback', '2%', 0.6, Icons.account_balance_wallet_rounded, isDark),
              _buildBenefitProgressCard('Shopping Discount', '30%', 0.7, Icons.shopping_bag_rounded, isDark),
              _buildBenefitProgressCard('Service Discount', '20%', 0.5, Icons.construction_rounded, isDark),
              _buildBenefitProgressCard('Loan Eligibility', '₹5,00,000', 0.9, Icons.account_balance_rounded, isDark),
              _buildBenefitProgressCard('Referral Bonus', '5%', 0.4, Icons.card_giftcard_rounded, isDark),
              _buildBenefitProgressCard('Wallet Increment', '2%', 0.6, Icons.trending_up_rounded, isDark),
              _buildBenefitProgressCard('Priority Booking', 'Enabled', 1.0, Icons.flash_on_rounded, isDark),
            ],
          ),
          const SizedBox(height: 24),

          // Option/Button to Change or Upgrade Plan
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () => setState(() => viewMode = 'plans'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppThemeData.primary200,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Change / Upgrade Subscription Plan',
                    style: TextStyle(fontSize: 15, fontFamily: AppThemeData.bold, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 2. CHOOSE SUBSCRIPTION PLAN SCREEN (List of Available Plans)
  // ===========================================================================
  Widget _buildPlansListScreen(bool isDark, SubscriptionController controller) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Top
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : AppThemeData.primary200.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppThemeData.primary200.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Grow Your Business with',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppThemeData.primary200),
                      ),
                      Text(
                        'FIINWAY Premium Plans',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppThemeData.primary200),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'More Benefits. More Earnings. More Growth.',
                        style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.show_chart_rounded, size: 40, color: AppThemeData.primary200),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Center(
            child: Text(
              'Choose Your Business Plan',
              style: TextStyle(
                fontSize: 18,
                fontFamily: AppThemeData.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Render Dynamic Plans from Controller or fallback default plans
          controller.isLoading.value
              ? Center(child: Constant.loader(context, isDarkMode: isDark))
              : controller.subscriptionPlanList.isNotEmpty
                  ? ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: controller.subscriptionPlanList.length,
                      itemBuilder: (context, idx) {
                        final plan = controller.subscriptionPlanList[idx];
                        final isSelected = selectedPlanIndex == idx;

                        return GestureDetector(
                          onTap: () {
                            controller.selectedSubscriptionPlan.value = plan;
                            controller.totalAmount.value = double.parse(plan.price ?? '0.0');
                            setState(() => selectedPlanIndex = idx);
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? AppThemeData.primary200 : const Color(0xFFE2E8F0),
                                width: isSelected ? 2 : 1,
                              ),
                              boxShadow: [
                                if (isSelected) BoxShadow(color: AppThemeData.primary200.withValues(alpha: 0.12), blurRadius: 10, offset: const Offset(0, 4)),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: AppThemeData.primary200.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(Icons.workspace_premium_rounded, color: AppThemeData.primary200, size: 28),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        plan.name ?? 'Business Plan',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontFamily: AppThemeData.bold,
                                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${Constant().amountShow(amount: plan.price ?? '0.0')} / ${plan.expiryDay == "-1" ? "Lifetime" : "${plan.expiryDay} Days"}',
                                        style: TextStyle(fontSize: 14, fontFamily: AppThemeData.bold, color: AppThemeData.primary200),
                                      ),
                                    ],
                                  ),
                                ),
                                OutlinedButton(
                                  onPressed: () {
                                    controller.selectedSubscriptionPlan.value = plan;
                                    controller.totalAmount.value = double.parse(plan.price ?? '0.0');
                                    setState(() {
                                      selectedPlanIndex = idx;
                                      viewMode = 'benefits';
                                    });
                                  },
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: AppThemeData.primary200),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: Text('View Benefits', style: TextStyle(fontSize: 11, fontFamily: AppThemeData.bold, color: AppThemeData.primary200)),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    )
                  : _buildDefaultPlansList(isDark, controller),

          const SizedBox(height: 20),

          // Select Plan CTA Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () => setState(() => viewMode = 'benefits'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppThemeData.primary200,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text('Select Plan & View Benefits', style: TextStyle(fontSize: 15, fontFamily: AppThemeData.bold, color: Colors.white)),
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

  Widget _buildDefaultPlansList(bool isDark, SubscriptionController controller) {
    final List<Map<String, dynamic>> defaultPlans = [
      {'title': 'Basic Plan', 'price': '₹1,200 / Year', 'tag': 'Popular'},
      {'title': 'Professional Plan', 'price': '₹2,500 / Year', 'tag': 'Recommended'},
      {'title': 'Premium Plus', 'price': '₹5,000 / Year', 'tag': 'VIP'},
    ];

    return Column(
      children: defaultPlans.asMap().entries.map((entry) {
        final idx = entry.key;
        final plan = entry.value;
        final isSelected = selectedPlanIndex == idx;

        return GestureDetector(
          onTap: () => setState(() => selectedPlanIndex = idx),
          child: Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? AppThemeData.primary200 : const Color(0xFFE2E8F0),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppThemeData.primary200.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.workspace_premium_rounded, color: AppThemeData.primary200, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan['title'],
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: AppThemeData.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        plan['price'],
                        style: TextStyle(fontSize: 15, fontFamily: AppThemeData.bold, color: AppThemeData.primary200),
                      ),
                    ],
                  ),
                ),
                OutlinedButton(
                  onPressed: () {
                    setState(() {
                      selectedPlanIndex = idx;
                      viewMode = 'benefits';
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppThemeData.primary200),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text('View Benefits', style: TextStyle(fontSize: 11, fontFamily: AppThemeData.bold, color: AppThemeData.primary200)),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ===========================================================================
  // 3. PLAN BENEFITS & ADVANTAGES PAGE
  // ===========================================================================
  Widget _buildBenefitsScreen(bool isDark, SubscriptionController controller) {
    final String planTitle = (controller.subscriptionPlanList.isNotEmpty && selectedPlanIndex < controller.subscriptionPlanList.length)
        ? (controller.subscriptionPlanList[selectedPlanIndex].name ?? 'Professional Plan')
        : 'Professional Plan';

    final String planPrice = (controller.subscriptionPlanList.isNotEmpty && selectedPlanIndex < controller.subscriptionPlanList.length)
        ? Constant().amountShow(amount: controller.subscriptionPlanList[selectedPlanIndex].price ?? '2500')
        : '₹2,500 / Year';

    final List<String> benefitsList = [
      'Business Verified Batch',
      'Premium Listing',
      'QR Pay Send & Receive (Up to 2%)',
      'Daily Value Increment (Up to 2%)',
      'Free Incoming Booking (150)',
      'Interest-Free Loan Eligibility (Up to ₹5 Lakh)',
      'Value Transfer Cashback (Up to 2%)',
      'Wallet Enabled',
      'Professional Dashboard',
      'Priority Support',
      'Analytics Dashboard',
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selected Plan Header Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : AppThemeData.primary200.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppThemeData.primary200.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppThemeData.primary200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        planTitle,
                        style: TextStyle(fontSize: 16, fontFamily: AppThemeData.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        planPrice,
                        style: TextStyle(fontSize: 15, fontFamily: AppThemeData.bold, color: AppThemeData.primary200),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Text('Key Benefits & Advantages', style: TextStyle(fontSize: 16, fontFamily: AppThemeData.bold, color: isDark ? Colors.white : const Color(0xFF0F172A))),
          const SizedBox(height: 12),

          ...benefitsList.map((b) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppThemeData.primary200.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.check_rounded, color: AppThemeData.primary200, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      b,
                      style: TextStyle(fontSize: 13, fontFamily: AppThemeData.medium, color: isDark ? Colors.white : const Color(0xFF334155)),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 24),

          // Proceed to Payment Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                if (controller.subscriptionPlanList.isNotEmpty && selectedPlanIndex < controller.subscriptionPlanList.length) {
                  controller.selectedSubscriptionPlan.value = controller.subscriptionPlanList[selectedPlanIndex];
                  controller.totalAmount.value = double.parse(controller.selectedSubscriptionPlan.value.price ?? '0.0');
                }
                paymentDialog(context, controller, isDark);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppThemeData.primary200,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text('Proceed to Payment', style: TextStyle(fontSize: 16, fontFamily: AppThemeData.bold, color: Colors.white)),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
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
                Text('Secure Payment Gateway', style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 4. PLAN ACTIVATED SUCCESS CONFIRMATION SCREEN
  // ===========================================================================
  Widget _buildActivatedSuccessScreen(bool isDark, SubscriptionController controller) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: AppThemeData.primary200,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 48),
          ),
          const SizedBox(height: 16),

          Text(
            'Plan Activated Successfully!',
            style: TextStyle(fontSize: 20, fontFamily: AppThemeData.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
          ),
          const SizedBox(height: 4),
          Text(
            'Your Business Subscription Plan is now active',
            style: TextStyle(fontSize: 13, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          ),
          const SizedBox(height: 20),

          // Activated Plan Summary Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : AppThemeData.primary200.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppThemeData.primary200.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppThemeData.primary200,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Professional Plan', style: TextStyle(fontSize: 16, fontFamily: AppThemeData.bold, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: AppThemeData.primary200, borderRadius: BorderRadius.circular(6)),
                            child: const Text('Active', style: TextStyle(fontSize: 10, fontFamily: AppThemeData.bold, color: Colors.white)),
                          ),
                        ],
                      ),
                      Text('₹2,500 / Year', style: TextStyle(fontSize: 14, fontFamily: AppThemeData.bold, color: AppThemeData.primary200)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Go to Dashboard Button (Updates Dashboard with Activated Plan)
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () => setState(() => viewMode = 'dashboard'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppThemeData.primary200,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text('Go to Dashboard', style: TextStyle(fontSize: 16, fontFamily: AppThemeData.bold, color: Colors.white)),
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

  Widget _buildSubDetailRow(String label, String value, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
        Text(value, style: TextStyle(fontSize: 13, fontFamily: AppThemeData.bold, color: isDark ? Colors.white : const Color(0xFF0F172A))),
      ],
    );
  }

  Widget _buildBenefitProgressCard(String title, String val, double progress, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppThemeData.primary200.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: AppThemeData.primary200),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, fontFamily: AppThemeData.semiBold, color: isDark ? Colors.white70 : const Color(0xFF475569)),
                ),
              ),
            ],
          ),
          Text(val, style: TextStyle(fontSize: 14, fontFamily: AppThemeData.bold, color: isDark ? Colors.white : const Color(0xFF0F172A))),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(AppThemeData.primary200!),
            ),
          ),
        ],
      ),
    );
  }

  // Payment Options Bottom Sheet
  Future<dynamic> paymentDialog(BuildContext context, SubscriptionController controller, bool isDarkMode) {
    return showModalBottomSheet(
      elevation: 5,
      useRootNavigator: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(topLeft: Radius.circular(15), topRight: Radius.circular(15))),
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
            return SizedBox(
              height: Get.height / 1.15,
              child: SingleChildScrollView(
                child: InkWell(
                  onTap: () => FocusScope.of(context).unfocus(),
                  child: Column(
                    children: [
                      Center(
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 10),
                          height: 8,
                          width: 75,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(100),
                            color: isDarkMode ? AppThemeData.grey300Dark : AppThemeData.grey300,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Get.back(),
                            icon: Transform(
                              alignment: Alignment.center,
                              transform: Directionality.of(context) == TextDirection.rtl ? Matrix4.rotationY(3.14159) : Matrix4.identity(),
                              child: SvgPicture.asset(
                                'assets/icons/ic_left.svg',
                                width: 18,
                                height: 18,
                                colorFilter: ColorFilter.mode(
                                  isDarkMode ? AppThemeData.grey50 : AppThemeData.grey900,
                                  BlendMode.srcIn,
                                ),
                              ),
                            ),
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
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            buildPaymentOption(
                              title: "Razorpay",
                              value: "razorpay",
                              controller: controller,
                              isDarkMode: isDarkMode,
                            ),
                            buildPaymentOption(
                              title: "Wallet",
                              value: "wallet",
                              controller: controller,
                              isDarkMode: isDarkMode,
                            ),
                            buildPaymentOption(
                              title: "Stripe",
                              value: "stripe",
                              controller: controller,
                              isDarkMode: isDarkMode,
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppThemeData.primary200,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () async {
                                  if (controller.selectedRadioTile.value == 'razorpay') {
                                    Get.back();
                                    razorpayPayment(controller);
                                  } else {
                                    Get.back();
                                    await controller.completeSubscription();
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
          color: controller.selectedRadioTile.value == value ? AppThemeData.primary200! : const Color(0xFFE2E8F0),
        ),
      ),
      child: RadioListTile<String>(
        title: Text(
          title,
          style: TextStyle(
            fontSize: 15,
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
      'description': controller.selectedSubscriptionPlan.value.name ?? 'Business Premium Plan',
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
    await controller.completeSubscription();
    setState(() => viewMode = 'activated');
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ShowToastDialog.showToast("Payment Failed: ${response.message}");
  }

  void _handleExternalWaller(ExternalWalletResponse response) {
    ShowToastDialog.showToast("External Wallet Selected: ${response.walletName}");
  }
}
