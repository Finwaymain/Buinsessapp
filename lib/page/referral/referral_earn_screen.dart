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
  // Live Dynamic Data from API
  String referralCode = 'FIIN8829';
  String referralLink = 'https://fiinway.online/r/FIIN8829';
  String totalReferrals = '0';
  String totalEarnings = '₹0.00';
  String walletBalance = '₹0.00';
  String activeUsers = '0';

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
          setState(() {
            referralCode = data['referral_code'] ?? referralCode;
            referralLink = data['referral_link'] ?? referralLink;
            totalReferrals = data['total_referrals']?.toString() ?? totalReferrals;
            totalEarnings = data['earnings'] ?? totalEarnings;
            walletBalance = data['wallet_balance'] ?? walletBalance;
            activeUsers = data['active_users']?.toString() ?? activeUsers;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching referral stats: $e');
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
              // 1. Banner Card
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
                child: const Row(
                  children: [
                    Text('🎁', style: TextStyle(fontSize: 42)),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Refer & Earn',
                            style: TextStyle(
                              fontSize: 22,
                              fontFamily: AppThemeData.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Share. Connect. Earn Together',
                            style: TextStyle(
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

              // 2. Main Referral Code & Link Card
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
                            referralCode,
                            style: const TextStyle(
                              fontSize: 18,
                              fontFamily: AppThemeData.bold,
                              color: Color(0xFF0F172A),
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _copyToClipboard(referralCode, 'Referral Code'),
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
                              referralLink,
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
                            onTap: () => _copyToClipboard(referralLink, 'Referral Link'),
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
                        onPressed: () => _copyToClipboard(referralLink, 'Referral Link'),
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

              // 3. 4 Stat Cards Row (Live API Data)
              Row(
                children: [
                  _buildStatCard('Total Referrals', totalReferrals, Icons.groups_rounded, const Color(0xFF00A859), isDark),
                  const SizedBox(width: 8),
                  _buildStatCard('Earnings', totalEarnings, Icons.stars_rounded, const Color(0xFF00A859), isDark),
                  const SizedBox(width: 8),
                  _buildStatCard('Wallet Balance', walletBalance, Icons.account_balance_wallet_rounded, const Color(0xFF00A859), isDark),
                  const SizedBox(width: 8),
                  _buildStatCard('Active Users', activeUsers, Icons.insights_rounded, const Color(0xFF00A859), isDark),
                ],
              ),
              const SizedBox(height: 20),

              // 4. Quick Share Bar
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
                          _copyToClipboard(referralLink, 'Referral Link');
                        }),
                        _buildSocialIcon('Telegram', const Color(0xFF0088CC), Icons.send_rounded, () {
                          _copyToClipboard(referralLink, 'Referral Link');
                        }),
                        _buildSocialIcon('Facebook', const Color(0xFF1877F2), Icons.facebook_rounded, () {
                          _copyToClipboard(referralLink, 'Referral Link');
                        }),
                        _buildSocialIcon('Instagram', const Color(0xFFE4405F), Icons.camera_alt_rounded, () {
                          _copyToClipboard(referralLink, 'Referral Link');
                        }),
                        _buildSocialIcon('More', const Color(0xFF64748B), Icons.more_horiz_rounded, () {
                          _copyToClipboard(referralLink, 'Referral Link');
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
