import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../../themes/constant_colors.dart';
import '../../utils/dark_theme_provider.dart';
import '../features/Taxi/taxi_dashboard/taxi_dashboard.dart';
import '../new_ride_screens/new_ride_screen.dart';
import '../features/AllServices/all_services_screen.dart';
import '../parcel_service/parcel_console_screen.dart';
import '../marketplace/view/marketplace_home_screen.dart';
import '../referral/referral_earn_screen.dart';
import '../wallet/wallet_screen.dart';
import '../features/SmartValue/ScanAndTransfer/view/scanner_and_transfer_screen.dart';
import '../features/SmartValue/MyQR/view/my_qr_view.dart';
import '../features/SmartValue/Payout/view/payout_screen.dart';
import '../features/SmartValue/AccountDetails/view/account_details.dart';
import '../subscription_plan_screen/business_premium_plan_screen.dart';
import '../add_bank_details/add_bank_account.dart';
import '../contact_us/customer_support_screen.dart';

class DriverServiceSearchItem {
  final String id;
  final String title;
  final String category;
  final String description;
  final String iconEmoji;
  final IconData? iconData;
  final Color accentColor;
  final String? badge;
  final VoidCallback onTap;

  DriverServiceSearchItem({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.iconEmoji,
    this.iconData,
    required this.accentColor,
    this.badge,
    required this.onTap,
  });
}

class SearchAllServicesScreen extends StatefulWidget {
  final bool isTab;
  const SearchAllServicesScreen({super.key, this.isTab = false});

  @override
  State<SearchAllServicesScreen> createState() => _SearchAllServicesScreenState();
}

class _SearchAllServicesScreenState extends State<SearchAllServicesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  String _searchQuery = '';

  final List<String> _categories = [
    'All',
    'Rides & Taxi',
    'Home Services',
    'Logistics',
    'Smart Value',
    'Marketplace',
  ];

  List<DriverServiceSearchItem> _buildServicesList() {
    return [
      // 1. RIDES & TAXI
      DriverServiceSearchItem(
        id: 'ride_requests',
        title: 'Ride Bookings & Requests',
        category: 'Rides & Taxi',
        description: 'View incoming, pending & completed passenger rides',
        iconEmoji: '🚖',
        iconData: Icons.local_taxi_rounded,
        accentColor: const Color(0xFF2C5CE6),
        badge: 'Live',
        onTap: () => Get.to(() => const NewRideScreen()),
      ),
      DriverServiceSearchItem(
        id: 'taxi_console',
        title: 'Driver Taxi Console',
        category: 'Rides & Taxi',
        description: 'Manage online status, GPS navigation & trip telemetry',
        iconEmoji: '🗺️',
        iconData: Icons.navigation_rounded,
        accentColor: const Color(0xFF00875A),
        onTap: () => Get.to(() => TaxiDashBoard()),
      ),
      DriverServiceSearchItem(
        id: 'bike_rides',
        title: 'Bike Taxi Trips',
        category: 'Rides & Taxi',
        description: 'Accept quick two-wheeler city passenger rides',
        iconEmoji: '🛵',
        iconData: Icons.two_wheeler_rounded,
        accentColor: const Color(0xFF00B8D9),
        onTap: () => Get.to(() => const NewRideScreen()),
      ),
      DriverServiceSearchItem(
        id: 'auto_rides',
        title: 'Auto Rickshaw Trips',
        category: 'Rides & Taxi',
        description: 'Auto bookings with direct meter/upfront fares',
        iconEmoji: '🛺',
        iconData: Icons.electric_rickshaw_rounded,
        accentColor: const Color(0xFFFF8B00),
        onTap: () => Get.to(() => const NewRideScreen()),
      ),

      // 2. LOGISTICS & DELIVERY
      DriverServiceSearchItem(
        id: 'parcel_console',
        title: 'Parcel Delivery Console',
        category: 'Logistics',
        description: 'Manage package pickups, drop-offs & proof of delivery',
        iconEmoji: '📦',
        iconData: Icons.local_shipping_rounded,
        accentColor: const Color(0xFFE65100),
        badge: 'Orders',
        onTap: () => Get.to(() => const ParcelConsoleScreen()),
      ),
      DriverServiceSearchItem(
        id: 'parcel_urgent',
        title: 'Urgent & Document Delivery',
        category: 'Logistics',
        description: 'Priority courier, medicine & confidential paper runs',
        iconEmoji: '📄',
        iconData: Icons.description_rounded,
        accentColor: const Color(0xFF0097A7),
        onTap: () => Get.to(() => const ParcelConsoleScreen()),
      ),

      // 3. HOME SERVICES
      DriverServiceSearchItem(
        id: 'svc_hub',
        title: 'Home Services Partner Hub',
        category: 'Home Services',
        description: 'Browse available service categories, leads & jobs',
        iconEmoji: '🛠️',
        iconData: Icons.home_repair_service_rounded,
        accentColor: const Color(0xFF6AA720),
        badge: 'Leads',
        onTap: () => Get.to(() => const AllServicesScreen()),
      ),
      DriverServiceSearchItem(
        id: 'svc_electrician',
        title: 'Electrician Services',
        category: 'Home Services',
        description: 'Fan, wiring, MCB & inverter installation jobs',
        iconEmoji: '⚡',
        iconData: Icons.electrical_services_rounded,
        accentColor: const Color(0xFFFFB300),
        onTap: () => Get.to(() => const AllServicesScreen()),
      ),
      DriverServiceSearchItem(
        id: 'svc_plumbing',
        title: 'Plumbing Services',
        category: 'Home Services',
        description: 'Pipe leaks, sanitaryware & motor repair requests',
        iconEmoji: '🔧',
        iconData: Icons.plumbing_rounded,
        accentColor: const Color(0xFF0288D1),
        onTap: () => Get.to(() => const AllServicesScreen()),
      ),
      DriverServiceSearchItem(
        id: 'svc_appliances',
        title: 'AC & Appliance Servicing',
        category: 'Home Services',
        description: 'AC gas refill, washing machine & fridge maintenance',
        iconEmoji: '❄️',
        iconData: Icons.ac_unit_rounded,
        accentColor: const Color(0xFF00ACC1),
        onTap: () => Get.to(() => const AllServicesScreen()),
      ),
      DriverServiceSearchItem(
        id: 'svc_cleaning',
        title: 'Cleaning & Deep Clean',
        category: 'Home Services',
        description: 'Full house cleaning, commercial & sofa shampooing',
        iconEmoji: '🧹',
        iconData: Icons.cleaning_services_rounded,
        accentColor: const Color(0xFF43A047),
        onTap: () => Get.to(() => const AllServicesScreen()),
      ),

      // 4. SMART VALUE & FINANCE
      DriverServiceSearchItem(
        id: 'sv_wallet',
        title: 'Driver Wallet & Earnings',
        category: 'Smart Value',
        description: 'Check earnings, trip income, commission deductions & balance',
        iconEmoji: '💳',
        iconData: Icons.account_balance_wallet_rounded,
        accentColor: const Color(0xFF6AA720),
        badge: 'Earnings',
        onTap: () => Get.to(() => WalletScreen()),
      ),
      DriverServiceSearchItem(
        id: 'sv_payout',
        title: 'Direct Bank Payout',
        category: 'Smart Value',
        description: 'Transfer your wallet earnings directly into your bank account',
        iconEmoji: '🏦',
        iconData: Icons.payments_rounded,
        accentColor: const Color(0xFF2C5CE6),
        badge: 'Fast Payout',
        onTap: () => Get.to(() => PayoutScreen()),
      ),
      DriverServiceSearchItem(
        id: 'sv_bank_details',
        title: 'Bank Account & UPI Details',
        category: 'Smart Value',
        description: 'Update bank name, account number & IFSC code',
        iconEmoji: '🏧',
        iconData: Icons.account_balance_rounded,
        accentColor: const Color(0xFF455A64),
        onTap: () => Get.to(() => const AddBankAccount()),
      ),
      DriverServiceSearchItem(
        id: 'sv_account_card',
        title: 'Smart Value Card & Profile',
        category: 'Smart Value',
        description: 'View Smart Value virtual card and driver profile',
        iconEmoji: '💳',
        iconData: Icons.credit_card_rounded,
        accentColor: const Color(0xFF6554C0),
        onTap: () => Get.to(() => AccountDetails()),
      ),
      DriverServiceSearchItem(
        id: 'sv_scan',
        title: 'Scan & Pay / Transfer',
        category: 'Smart Value',
        description: 'Instant QR scanner & P2P wallet money transfers',
        iconEmoji: '📲',
        iconData: Icons.qr_code_scanner_rounded,
        accentColor: const Color(0xFF5E35B1),
        onTap: () => Get.to(() => ScannerAndTransferScreen()),
      ),
      DriverServiceSearchItem(
        id: 'sv_myqr',
        title: 'My Driver QR Code',
        category: 'Smart Value',
        description: 'Show personal QR code to collect payments from passengers',
        iconEmoji: '🔳',
        iconData: Icons.qr_code_rounded,
        accentColor: const Color(0xFF424242),
        onTap: () => Get.to(() => MyQRScreen()),
      ),
      DriverServiceSearchItem(
        id: 'sv_referral',
        title: 'Refer Partners & Earn',
        category: 'Smart Value',
        description: 'Invite other drivers and earn direct cash bonuses',
        iconEmoji: '🎁',
        iconData: Icons.card_giftcard_rounded,
        accentColor: const Color(0xFFFF6F00),
        badge: 'Bonus',
        onTap: () => Get.to(() => const ReferralEarnScreen()),
      ),
      DriverServiceSearchItem(
        id: 'sv_subscription',
        title: 'Premium Membership Plans',
        category: 'Smart Value',
        description: 'Unlock 0% commission and verified VIP partner benefits',
        iconEmoji: '⭐',
        iconData: Icons.star_rounded,
        accentColor: const Color(0xFFFFB300),
        badge: 'VIP',
        onTap: () => Get.to(() => const BusinessPremiumPlanScreen()),
      ),

      // 5. MARKETPLACE & SUPPORT
      DriverServiceSearchItem(
        id: 'mkt_home',
        title: 'Fiinway Marketplace',
        category: 'Marketplace',
        description: 'Exclusive driver accessory discounts & local deals',
        iconEmoji: '🛍️',
        iconData: Icons.storefront_rounded,
        accentColor: const Color(0xFF673AB7),
        badge: 'Offers',
        onTap: () => Get.to(() => const MarketplaceHomeScreen()),
      ),
      DriverServiceSearchItem(
        id: 'support_help',
        title: 'Driver Partner Support',
        category: 'Smart Value',
        description: '24x7 priority support helpline, chat & SOS assistance',
        iconEmoji: '🎧',
        iconData: Icons.support_agent_rounded,
        accentColor: const Color(0xFF009688),
        onTap: () => Get.to(() => const CustomerSupportScreen()),
      ),
    ];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.getThem();
    final allServices = _buildServicesList();

    final filteredServices = allServices.where((item) {
      final matchesCategory = _selectedCategory == 'All' || item.category == _selectedCategory;
      final query = _searchQuery.trim().toLowerCase();
      final matchesQuery = query.isEmpty ||
          item.title.toLowerCase().contains(query) ||
          item.description.toLowerCase().contains(query) ||
          item.category.toLowerCase().contains(query);
      return matchesCategory && matchesQuery;
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? AppThemeData.surface50Dark : AppThemeData.surface50,
      appBar: widget.isTab
          ? null
          : AppBar(
              backgroundColor: isDark ? AppThemeData.surface50Dark : Colors.white,
              elevation: 0.5,
              title: Text(
                'Explore Services',
                style: TextStyle(
                  fontFamily: AppThemeData.semiBold,
                  fontSize: 18,
                  color: isDark ? Colors.white : AppThemeData.grey900,
                ),
              ),
              centerTitle: true,
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 20,
                  color: isDark ? Colors.white : AppThemeData.grey900,
                ),
                onPressed: () => Get.back(),
              ),
            ),
      body: SafeArea(
        top: !widget.isTab,
        child: Column(
          children: [
            // Top Search Bar Section
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              color: isDark ? AppThemeData.surface50Dark : Colors.white,
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E2436) : const Color(0xFFF4F6F9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                      style: TextStyle(
                        fontFamily: AppThemeData.medium,
                        fontSize: 14,
                        color: isDark ? Colors.white : AppThemeData.grey900,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search rides, home services, parcel, wallet...',
                        hintStyle: TextStyle(
                          fontFamily: AppThemeData.regular,
                          fontSize: 13,
                          color: isDark ? AppThemeData.grey500Dark : AppThemeData.grey400,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: AppThemeData.primary200,
                          size: 22,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.clear_rounded,
                                  size: 18,
                                  color: isDark ? Colors.white54 : AppThemeData.grey500,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Horizontal Category Filter Chips
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final cat = _categories[index];
                        final isSelected = _selectedCategory == cat;
                        return InkWell(
                          onTap: () {
                            setState(() {
                              _selectedCategory = cat;
                            });
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppThemeData.primary200
                                  : isDark
                                      ? const Color(0xFF1E2436)
                                      : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? AppThemeData.primary200
                                    : isDark
                                        ? Colors.white10
                                        : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                cat,
                                style: TextStyle(
                                  fontFamily: isSelected ? AppThemeData.semiBold : AppThemeData.medium,
                                  fontSize: 12,
                                  color: isSelected
                                      ? Colors.white
                                      : isDark
                                          ? AppThemeData.grey400Dark
                                          : AppThemeData.grey800,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Services List
            Expanded(
              child: filteredServices.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E2436) : const Color(0xFFF1F5F9),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.search_off_rounded,
                                size: 48,
                                color: isDark ? Colors.white38 : AppThemeData.grey400,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No matching services found',
                              style: TextStyle(
                                fontFamily: AppThemeData.semiBold,
                                fontSize: 16,
                                color: isDark ? Colors.white : AppThemeData.grey900,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Try searching for "Rides", "Parcel", "Payout", or "Electrician"',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: AppThemeData.regular,
                                fontSize: 13,
                                color: isDark ? AppThemeData.grey500Dark : AppThemeData.grey500,
                              ),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                  _selectedCategory = 'All';
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppThemeData.primary200,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              ),
                              child: const Text(
                                'Clear Search',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: AppThemeData.semiBold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                      itemCount: filteredServices.length,
                      itemBuilder: (context, index) {
                        final item = filteredServices[index];
                        return _buildServiceCard(item, isDark);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard(DriverServiceSearchItem item, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2436) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFEBF0F7),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.2) : const Color(0xFF2C5CE6).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: item.onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                // Icon Avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: item.accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: item.iconData != null
                        ? Icon(item.iconData, color: item.accentColor, size: 24)
                        : Text(
                            item.iconEmoji,
                            style: const TextStyle(fontSize: 22),
                          ),
                  ),
                ),

                const SizedBox(width: 14),

                // Title, Category & Description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              item.title,
                              style: TextStyle(
                                fontFamily: AppThemeData.semiBold,
                                fontSize: 14.5,
                                color: isDark ? Colors.white : AppThemeData.grey900,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (item.badge != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: item.accentColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                item.badge!,
                                style: TextStyle(
                                  fontFamily: AppThemeData.semiBold,
                                  fontSize: 10,
                                  color: item.accentColor,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.description,
                        style: TextStyle(
                          fontFamily: AppThemeData.regular,
                          fontSize: 12,
                          color: isDark ? AppThemeData.grey500Dark : AppThemeData.grey500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Arrow Action
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF283049) : const Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 13,
                    color: isDark ? Colors.white70 : AppThemeData.grey500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
