import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../../service/api.dart';
import '../../../themes/constant_colors.dart';
import '../../../utils/Preferences.dart';
import '../../../utils/dark_theme_provider.dart';

class ReferralEarnScreen extends StatefulWidget {
  const ReferralEarnScreen({super.key});

  @override
  State<ReferralEarnScreen> createState() => _ReferralEarnScreenState();
}

class _ReferralEarnScreenState extends State<ReferralEarnScreen> {
  int _selectedTab = 0; // 0 = Consumer, 1 = Business

  // Live Backend Data
  String consumerCode = 'FIIN12345';
  String consumerLink = 'https://fiinway.app/r/FIIN12345';
  String consumerTotalRef = '125';
  String consumerEarnings = '₹18,750';
  String consumerWallet = '₹3,250';
  String consumerActiveUsers = '80';

  String bizCode = 'BIZ12345';
  String bizLink = 'https://fiinway.app/r/BIZ12345';
  String bizTotalRef = '98';
  String bizEarnings = '₹12,540';
  String bizActiveUsers = '52';
  String bizUsers = '28';

  @override
  void initState() {
    super.initState();
    _fetchReferralStats();
  }

  Future<void> _fetchReferralStats() async {
    try {
      final driverId = Preferences.getString(Preferences.userId);
      final response = await http.get(
        Uri.parse('${API.referralStats}?driver_id=$driverId'),
        headers: API.header,
      );

      if (response.statusCode == 200) {
        final resData = json.decode(response.body);
        if (resData['success'] == 'success' && resData['data'] != null) {
          final data = resData['data'];
          if (data['consumer'] != null) {
            final cons = data['consumer'];
            consumerCode = cons['referral_code'] ?? consumerCode;
            consumerLink = cons['referral_link'] ?? consumerLink;
            consumerTotalRef = cons['total_referrals']?.toString() ?? consumerTotalRef;
            consumerEarnings = cons['earnings'] ?? consumerEarnings;
            consumerWallet = cons['wallet_balance'] ?? consumerWallet;
            consumerActiveUsers = cons['active_users']?.toString() ?? consumerActiveUsers;
          }
          if (data['business'] != null) {
            final biz = data['business'];
            bizCode = biz['referral_code'] ?? bizCode;
            bizLink = biz['referral_link'] ?? bizLink;
            bizTotalRef = biz['total_referrals']?.toString() ?? bizTotalRef;
            bizEarnings = biz['earnings'] ?? bizEarnings;
            bizActiveUsers = biz['active_users']?.toString() ?? bizActiveUsers;
            bizUsers = biz['business_users']?.toString() ?? bizUsers;
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching referral stats: $e');
    } finally {
      if (mounted) {
        setState(() {});
      }
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    Get.snackbar(
      '$label Copied',
      '$text copied to clipboard!',
      backgroundColor: const Color(0xFF00A859),
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.getThem();

    final isConsumer = _selectedTab == 0;
    final activeCode = isConsumer ? consumerCode : bizCode;
    final activeLink = isConsumer ? consumerLink : bizLink;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF7F9FC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF1E1C15) : Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black87, size: 20),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Refer & Earn'.tr,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontFamily: AppThemeData.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [
              // Top Sub-Tabs Switcher (Consumer vs Business)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedTab = 0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isConsumer ? const Color(0xFF00A859) : Colors.transparent,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Center(
                            child: Text(
                              'Consumer',
                              style: TextStyle(
                                fontSize: 13,
                                fontFamily: AppThemeData.bold,
                                color: isConsumer ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedTab = 1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: !isConsumer ? const Color(0xFF00A859) : Colors.transparent,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Center(
                            child: Text(
                              'Business',
                              style: TextStyle(
                                fontSize: 13,
                                fontFamily: AppThemeData.bold,
                                color: !isConsumer ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Banner Card (Gift Box or Storefront)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00A859), Color(0xFF007A3E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00A859).withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Text(
                      isConsumer ? '🎁' : '🏪',
                      style: const TextStyle(fontSize: 42),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Refer & Earn',
                            style: TextStyle(
                              fontSize: 22,
                              fontFamily: AppThemeData.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isConsumer ? 'Share. Connect. Earn Together' : 'Grow Your Business Network',
                            style: const TextStyle(
                              fontSize: 12,
                              fontFamily: AppThemeData.medium,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Main Referral Details Container
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Your Referral Code Section
                    const Text(
                      'Your Referral Code',
                      style: TextStyle(fontSize: 13, fontFamily: AppThemeData.bold, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F8F0),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: const Color(0xFFA3E6C5)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            activeCode,
                            style: const TextStyle(
                              fontSize: 18,
                              fontFamily: AppThemeData.bold,
                              color: Color(0xFF0F172A),
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _copyToClipboard(activeCode, 'Referral Code'),
                            child: const Icon(Icons.copy_rounded, color: Color(0xFF00A859), size: 18),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Your Referral Link Section
                    const Text(
                      'Your Referral Link',
                      style: TextStyle(fontSize: 13, fontFamily: AppThemeData.bold, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F8F0),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: const Color(0xFFA3E6C5)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              activeLink,
                              style: const TextStyle(
                                fontSize: 13,
                                fontFamily: AppThemeData.medium,
                                color: Color(0xFF00A859),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () => _copyToClipboard(activeLink, 'Referral Link'),
                            child: const Icon(Icons.copy_rounded, color: Color(0xFF00A859), size: 18),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Full-width Green Share Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _copyToClipboard(activeLink, 'Referral Link'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00A859),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                          elevation: 3,
                        ),
                        icon: const Icon(Icons.share_rounded, color: Colors.white, size: 18),
                        label: const Text(
                          'Share Now',
                          style: TextStyle(fontSize: 15, fontFamily: AppThemeData.bold, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 4 Stat Cards Row (Exact Match to Screenshot)
              Row(
                children: isConsumer
                    ? [
                        _buildStatCard('Total Referrals', consumerTotalRef, Icons.groups_rounded, const Color(0xFF00A859), isDark),
                        const SizedBox(width: 8),
                        _buildStatCard('Earnings', consumerEarnings, Icons.stars_rounded, const Color(0xFF00A859), isDark),
                        const SizedBox(width: 8),
                        _buildStatCard('Wallet Balance', consumerWallet, Icons.account_balance_wallet_rounded, const Color(0xFF00A859), isDark),
                        const SizedBox(width: 8),
                        _buildStatCard('Active Users', consumerActiveUsers, Icons.insights_rounded, const Color(0xFF00A859), isDark),
                      ]
                    : [
                        _buildStatCard('Total Referrals', bizTotalRef, Icons.groups_rounded, const Color(0xFF00A859), isDark),
                        const SizedBox(width: 8),
                        _buildStatCard('Earnings', bizEarnings, Icons.add_circle_outline_rounded, const Color(0xFF00A859), isDark),
                        const SizedBox(width: 8),
                        _buildStatCard('Active Users', bizActiveUsers, Icons.verified_user_rounded, const Color(0xFF00A859), isDark),
                        const SizedBox(width: 8),
                        _buildStatCard('Business Users', bizUsers, Icons.check_circle_outline_rounded, const Color(0xFF00A859), isDark),
                      ],
              ),
              const SizedBox(height: 20),

              // Quick Share Bar
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quick Share',
                      style: TextStyle(fontSize: 14, fontFamily: AppThemeData.bold, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildSocialIcon('WhatsApp', const Color(0xFF25D366), Icons.message_rounded, () {
                          _copyToClipboard(activeLink, 'Referral Link');
                        }),
                        _buildSocialIcon('Telegram', const Color(0xFF0088CC), Icons.send_rounded, () {
                          _copyToClipboard(activeLink, 'Referral Link');
                        }),
                        _buildSocialIcon('Facebook', const Color(0xFF1877F2), Icons.facebook_rounded, () {
                          _copyToClipboard(activeLink, 'Referral Link');
                        }),
                        _buildSocialIcon('Instagram', const Color(0xFFE4405F), Icons.camera_alt_rounded, () {
                          _copyToClipboard(activeLink, 'Referral Link');
                        }),
                        _buildSocialIcon('More', const Color(0xFF64748B), Icons.more_horiz_rounded, () {
                          _copyToClipboard(activeLink, 'Referral Link');
                        }),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color accentColor, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: accentColor, size: 16),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9,
                fontFamily: AppThemeData.medium,
                color: isDark ? Colors.white70 : const Color(0xFF64748B),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontFamily: AppThemeData.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialIcon(String label, Color color, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 10, fontFamily: AppThemeData.medium, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}
