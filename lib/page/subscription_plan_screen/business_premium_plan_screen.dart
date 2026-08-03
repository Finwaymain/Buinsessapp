import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../../../constant/constant.dart';
import '../../../themes/constant_colors.dart';
import '../../../utils/dark_theme_provider.dart';

class BusinessPremiumPlanScreen extends StatefulWidget {
  const BusinessPremiumPlanScreen({super.key});

  @override
  State<BusinessPremiumPlanScreen> createState() => _BusinessPremiumPlanScreenState();
}

class _BusinessPremiumPlanScreenState extends State<BusinessPremiumPlanScreen> {
  int selectedPlanIndex = 1; // Default to Professional Plan

  final List<Map<String, dynamic>> _plans = [
    {
      'title': 'Basic Plan',
      'price': '₹1,200',
      'period': '/ Year',
      'tag': 'Standard',
      'isPopular': false,
      'color': Colors.grey,
      'benefits': [
        'Business Profile Listing',
        'Verified QR Code Activation',
        'Wallet Acceptance',
        'Standard Booking Access',
        'Basic Dashboard & Analytics',
      ],
    },
    {
      'title': 'Professional Plan',
      'price': '₹2,500',
      'period': '/ Year',
      'tag': 'Most Popular',
      'isPopular': true,
      'color': AppThemeData.primary200,
      'benefits': [
        'Everything in Basic Plan',
        '150 Free Ride/Booking Quota',
        '₹50,000 Interest-Free Loan Eligibility',
        '2% Extra Wallet Cashback',
        '30% Shopping & Service Discounts',
        'Priority Driver Match & Search',
        'Dedicated Priority Customer Support',
      ],
    },
    {
      'title': 'Premium Plus',
      'price': '₹5,000',
      'period': '/ Year',
      'tag': 'VIP VIP VIP',
      'isPopular': false,
      'color': Colors.amber,
      'benefits': [
        'Everything in Professional Plan',
        'Unlimited Ride/Booking Quota',
        '₹2,000,000 Business Loan Eligibility',
        '5% Extra Wallet Cashback',
        'Featured Top Business Badge & Ranking',
        'Advanced Revenue Analytics Dashboard',
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.getThem();

    return Scaffold(
      backgroundColor: isDark ? AppThemeData.surface50Dark : AppThemeData.surface50,
      appBar: AppBar(
        title: Text(
          'Business Premium Membership'.tr,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontFamily: AppThemeData.bold,
            fontSize: 18,
          ),
        ),
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF1E1C15) : Colors.white,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Active Subscription Membership Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1C15) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppThemeData.primary200, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: AppThemeData.primary200.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppThemeData.primary200.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.workspace_premium_rounded, color: AppThemeData.primary200, size: 32),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Professional Plan Active',
                              style: TextStyle(fontSize: 15, fontFamily: AppThemeData.bold, color: isDark ? Colors.white : Colors.black),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                              child: const Text('ACTIVE', style: TextStyle(fontSize: 9, fontFamily: AppThemeData.bold, color: Colors.green)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '298 Days Remaining • Valid till 29 Jul 2027',
                          style: TextStyle(fontSize: 11, color: isDark ? AppThemeData.grey500Dark : AppThemeData.grey500),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text('Free Rides Left: 112/150', style: TextStyle(fontSize: 11, fontFamily: AppThemeData.bold, color: AppThemeData.primary200)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Text(
              'Select or Upgrade Business Plan'.tr,
              style: TextStyle(fontSize: 16, fontFamily: AppThemeData.bold, color: isDark ? Colors.white : Colors.black),
            ),
            const SizedBox(height: 6),
            Text(
              'Choose a plan to unlock loan eligibility, free ride quotas, and higher cashback rates.'.tr,
              style: TextStyle(fontSize: 12, color: isDark ? AppThemeData.grey500Dark : AppThemeData.grey500),
            ),
            const SizedBox(height: 16),

            // Plan Cards Carousel / List
            ..._plans.asMap().entries.map((entry) {
              final index = entry.key;
              final plan = entry.value;
              final bool isSelected = selectedPlanIndex == index;
              final bool isPopular = plan['isPopular'] ?? false;

              return GestureDetector(
                onTap: () => setState(() => selectedPlanIndex = index),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1C15) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? AppThemeData.primary200 : (isDark ? const Color(0xFF2C2A26) : const Color(0xFFEFECE4)),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected ? AppThemeData.primary200.withValues(alpha: 0.15) : Colors.transparent,
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
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
                              Radio(
                                value: index,
                                groupValue: selectedPlanIndex,
                                activeColor: AppThemeData.primary200,
                                onChanged: (val) => setState(() => selectedPlanIndex = val as int),
                              ),
                              Text(
                                plan['title'],
                                style: TextStyle(fontSize: 16, fontFamily: AppThemeData.bold, color: isDark ? Colors.white : Colors.black),
                              ),
                            ],
                          ),
                          if (isPopular)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppThemeData.primary200,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                plan['tag'],
                                style: const TextStyle(fontSize: 10, fontFamily: AppThemeData.bold, color: Colors.white),
                              ),
                            ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 48.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              plan['price'],
                              style: TextStyle(fontSize: 22, fontFamily: AppThemeData.bold, color: AppThemeData.primary200),
                            ),
                            Text(
                              plan['period'],
                              style: TextStyle(fontSize: 12, color: isDark ? AppThemeData.grey500Dark : AppThemeData.grey500),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 10),

                      // Benefits Checklist
                      ...((plan['benefits'] as List<String>).map((benefit) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_rounded, color: Colors.green, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    benefit,
                                    style: TextStyle(fontSize: 12, fontFamily: AppThemeData.medium, color: isDark ? Colors.white70 : Colors.black87),
                                  ),
                                ),
                              ],
                            ),
                          ))),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),

            // Buy / Upgrade Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  final chosen = _plans[selectedPlanIndex];
                  Get.snackbar(
                    'Plan Selected',
                    'Redirecting to checkout for ${chosen['title']} (${chosen['price']})',
                    backgroundColor: Colors.green,
                    colorText: Colors.white,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppThemeData.primary200,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  'Activate / Upgrade ${_plans[selectedPlanIndex]['title']}'.tr,
                  style: const TextStyle(fontSize: 16, fontFamily: AppThemeData.bold, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
