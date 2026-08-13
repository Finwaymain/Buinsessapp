import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../../../constant/constant.dart';
import '../../../themes/constant_colors.dart';
import '../../../utils/dark_theme_provider.dart';

class TransactionServiceHistoryScreen extends StatefulWidget {
  const TransactionServiceHistoryScreen({super.key});

  @override
  State<TransactionServiceHistoryScreen> createState() => _TransactionServiceHistoryScreenState();
}

class _TransactionServiceHistoryScreenState extends State<TransactionServiceHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<Map<String, dynamic>> _allTimelineItems = [
    {
      'id': 'FS245870',
      'type': 'service',
      'category': 'Services',
      'title': 'Electrician - Fan Repair & Installation',
      'subtitle': 'Booking ID: FS245870 • Customer: Rahul Sharma',
      'date': '30 Jul 2026, 02:30 PM',
      'amount': 850.0,
      'isCredit': true,
      'status': 'Completed',
      'statusColor': Colors.green,
      'icon': Icons.electrical_services_rounded,
      'details': {
        'Customer': 'Rahul Sharma (+91 9876543210)',
        'Address': 'Flat 402, Green Valley Apartments, Sector 62',
        'Payment Mode': 'Fiinway Wallet',
        'Provider Share (90%)': '765.00',
        'Platform Fee (10%)': '85.00',
        'Cashback Earned': '17.00',
      }
    },
    {
      'id': 'WLT99281',
      'type': 'wallet',
      'category': 'Wallet',
      'title': 'Daily Wallet Growth Reward (0.10%)',
      'subtitle': 'Auto-credited from Wallet Growth Engine',
      'date': '30 Jul 2026, 08:00 AM',
      'amount': 24.50,
      'isCredit': true,
      'status': 'Completed',
      'statusColor': Colors.green,
      'icon': Icons.trending_up_rounded,
      'details': {
        'Source': 'Fiinway Wallet Growth Engine',
        'Growth Rate': '0.10% Daily',
        'Base Balance': '24,500.00',
      }
    },
    {
      'id': 'SUB88201',
      'type': 'subscription',
      'category': 'Subscription',
      'title': 'Professional Business Plan Renewal',
      'subtitle': 'Validity: 365 Days • Active until 29 Jul 2027',
      'date': '29 Jul 2026, 11:15 AM',
      'amount': 2500.0,
      'isCredit': false,
      'status': 'Active',
      'statusColor': Colors.blue,
      'icon': Icons.workspace_premium_rounded,
      'details': {
        'Plan': 'Professional Plan (2,500/Year)',
        'Free Ride Quota': '150 Bookings',
        'Loan Eligibility': '50,000 Interest-Free',
        'Cashback Boost': '2% Extra Cashback',
      }
    },
    {
      'id': 'ORD33910',
      'type': 'order',
      'category': 'Orders',
      'title': 'Marketplace Order - Safety Helmet & Kit',
      'subtitle': 'Order ID: ORD33910 • Delivered',
      'date': '28 Jul 2026, 04:10 PM',
      'amount': 1200.0,
      'isCredit': false,
      'status': 'Delivered',
      'statusColor': Colors.green,
      'icon': Icons.shopping_bag_rounded,
      'details': {
        'Item': 'Fiinway Verified Driver Safety Helmet',
        'Shipping': 'FREE (Premium Member Benefit)',
        'Discount Applied': '30% Member Discount (-360)',
      }
    },
    {
      'id': 'REF77102',
      'type': 'referral',
      'category': 'Wallet',
      'title': 'Referral Reward - Customer Signup',
      'subtitle': 'Referred: Amit Kumar (+91 9911223344)',
      'date': '27 Jul 2026, 06:45 PM',
      'amount': 50.0,
      'isCredit': true,
      'status': 'Completed',
      'statusColor': Colors.green,
      'icon': Icons.card_giftcard_rounded,
      'details': {
        'Referred User': 'Amit Kumar',
        'Activity': 'First Service Booking Completed',
        'Bonus Type': 'Refer & Earn Milestone',
      }
    },
    {
      'id': 'HC10294',
      'type': 'healthcare',
      'category': 'Healthcare',
      'title': 'MediCash Health Card Activation',
      'subtitle': 'Card No: MC-9920-1120 • Family Coverage',
      'date': '25 Jul 2026, 01:20 PM',
      'amount': 499.0,
      'isCredit': false,
      'status': 'Active',
      'statusColor': Colors.blue,
      'icon': Icons.medical_services_rounded,
      'details': {
        'Card Type': 'MediCash Shield OPD + Hospitalization',
        'Coverage Limit': '50,000 OPD Discounts',
        'Cashback Received': '25.00',
      }
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _getFilteredItems(String categoryFilter) {
    return _allTimelineItems.where((item) {
      final matchesCategory = categoryFilter == 'All' || item['category'] == categoryFilter;
      final matchesSearch = _searchQuery.isEmpty ||
          item['title'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item['id'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item['subtitle'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.getThem();

    return Scaffold(
      backgroundColor: isDark ? AppThemeData.surface50Dark : AppThemeData.surface50,
      appBar: AppBar(
        title: Text(
          'Transaction & Service History'.tr,
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
      body: Column(
        children: [
          // Search & Filter Box
          Container(
            padding: const EdgeInsets.all(16),
            color: isDark ? const Color(0xFF1E1C15) : Colors.white,
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search by Booking ID, Service, or Customer...'.tr,
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppThemeData.grey500Dark : AppThemeData.grey500,
                ),
                prefixIcon: Icon(Icons.search, color: AppThemeData.primary200),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark ? const Color(0xFF2A2822) : const Color(0xFFF8F6EF),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // 6 Module Tabs
          Container(
            color: isDark ? const Color(0xFF1E1C15) : Colors.white,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: AppThemeData.primary200,
              labelColor: AppThemeData.primary200,
              unselectedLabelColor: isDark ? AppThemeData.grey500Dark : AppThemeData.grey500,
              labelStyle: const TextStyle(fontFamily: AppThemeData.bold, fontSize: 13),
              unselectedLabelStyle: const TextStyle(fontFamily: AppThemeData.regular, fontSize: 13),
              tabs: const [
                Tab(text: 'All History'),
                Tab(text: 'Services'),
                Tab(text: 'Wallet'),
                Tab(text: 'Orders'),
                Tab(text: 'Subscriptions'),
                Tab(text: 'Healthcare Cards'),
              ],
            ),
          ),

          // Tab Content List View
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTimelineList(_getFilteredItems('All'), isDark),
                _buildTimelineList(_getFilteredItems('Services'), isDark),
                _buildTimelineList(_getFilteredItems('Wallet'), isDark),
                _buildTimelineList(_getFilteredItems('Orders'), isDark),
                _buildTimelineList(_getFilteredItems('Subscription'), isDark),
                _buildTimelineList(_getFilteredItems('Healthcare'), isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineList(List<Map<String, dynamic>> items, bool isDark) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_rounded, size: 64, color: AppThemeData.primary200.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text(
              'No records found for this category'.tr,
              style: TextStyle(
                fontSize: 14,
                fontFamily: AppThemeData.medium,
                color: isDark ? AppThemeData.grey500Dark : AppThemeData.grey500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final bool isCredit = item['isCredit'] ?? false;
        final Color statusColor = item['statusColor'] ?? Colors.green;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1C15) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF2C2A26) : const Color(0xFFEFECE4),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppThemeData.primary200.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(item['icon'] as IconData, color: AppThemeData.primary200, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['title'],
                            style: TextStyle(
                              fontSize: 14,
                              fontFamily: AppThemeData.bold,
                              color: isDark ? AppThemeData.grey900Dark : AppThemeData.grey900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item['subtitle'],
                            style: TextStyle(
                              fontSize: 11,
                              fontFamily: AppThemeData.regular,
                              color: isDark ? AppThemeData.grey500Dark : AppThemeData.grey500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item['date'],
                            style: TextStyle(
                              fontSize: 10,
                              fontFamily: AppThemeData.medium,
                              color: isDark ? AppThemeData.grey500Dark : AppThemeData.grey500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${isCredit ? '+' : '-'}${Constant().amountShow(amount: item['amount'].toString())}',
                          style: TextStyle(
                            fontSize: 15,
                            fontFamily: AppThemeData.bold,
                            color: isCredit ? Colors.green : Colors.redAccent,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                          ),
                          child: Text(
                            item['status'],
                            style: TextStyle(
                              fontSize: 10,
                              fontFamily: AppThemeData.bold,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 8),

                // Action Buttons: Details & Invoice
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: () => _showInvoiceDialog(context, item, isDark),
                      icon: const Icon(Icons.picture_as_pdf_rounded, size: 16, color: Colors.blueAccent),
                      label: Text(
                        '📄 Invoice'.tr,
                        style: const TextStyle(fontSize: 12, fontFamily: AppThemeData.bold, color: Colors.blueAccent),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showDetailsDialog(context, item, isDark),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppThemeData.primary200.withValues(alpha: 0.15),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: Icon(Icons.info_outline_rounded, size: 14, color: AppThemeData.primary200),
                      label: Text(
                        'View Details'.tr,
                        style: TextStyle(fontSize: 11, fontFamily: AppThemeData.bold, color: AppThemeData.primary200),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDetailsDialog(BuildContext context, Map<String, dynamic> item, bool isDark) {
    final details = item['details'] as Map<String, dynamic>? ?? {};

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1C15) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(item['icon'] as IconData, color: AppThemeData.primary200),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                item['title'],
                style: TextStyle(
                  fontSize: 15,
                  fontFamily: AppThemeData.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Transaction ID: ${item['id']}', style: const TextStyle(fontSize: 12, fontFamily: AppThemeData.bold)),
            const SizedBox(height: 8),
            const Divider(),
            ...details.entries.map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(e.key, style: TextStyle(fontSize: 12, color: isDark ? AppThemeData.grey500Dark : AppThemeData.grey500)),
                      Flexible(
                        child: Text(
                          e.value.toString(),
                          textAlign: TextAlign.end,
                          style: TextStyle(fontSize: 12, fontFamily: AppThemeData.bold, color: isDark ? Colors.white : Colors.black),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'.tr, style: TextStyle(color: AppThemeData.primary200)),
          ),
        ],
      ),
    );
  }

  void _showInvoiceDialog(BuildContext context, Map<String, dynamic> item, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1C15) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Center(
          child: Column(
            children: [
              Text('FIINWAY OFFICIAL INVOICE', style: TextStyle(fontSize: 14, fontFamily: AppThemeData.bold, color: AppThemeData.primary200)),
              Text('Invoice #: INV-${item['id']}', style: const TextStyle(fontSize: 11, fontFamily: AppThemeData.regular)),
            ],
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2A2822) : const Color(0xFFF9F6EE),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Service: ${item['title']}', style: const TextStyle(fontSize: 12, fontFamily: AppThemeData.bold)),
                  const SizedBox(height: 4),
                  Text('Date: ${item['date']}', style: const TextStyle(fontSize: 11)),
                  Text('Total Paid: ${Constant().amountShow(amount: item['amount'].toString())}', style: const TextStyle(fontSize: 12, fontFamily: AppThemeData.bold, color: Colors.green)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                '✓ Verified Digital Tax Invoice Generated',
                style: TextStyle(fontSize: 10, color: Colors.green, fontFamily: AppThemeData.medium),
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.download_rounded, size: 16),
            label: Text('Download PDF'.tr),
            onPressed: () {
              Navigator.pop(context);
              Get.snackbar('Invoice Downloaded', 'PDF invoice saved to Downloads folder', backgroundColor: Colors.green, colorText: Colors.white);
            },
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'.tr, style: TextStyle(color: isDark ? Colors.white : Colors.black)),
          ),
        ],
      ),
    );
  }
}
