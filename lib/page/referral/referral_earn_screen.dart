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
          if (mounted) {
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
      backgroundColor: AppThemeData.primary200,
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
      backgroundColor: isDark ? AppThemeData.surface50Dark : AppThemeData.surface50,
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
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // 1. App-Themed Banner Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [
                      AppThemeData.primary200,
                      AppThemeData.primary200.withValues(alpha: 0.85),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppThemeData.primary200.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Text('🎁', style: TextStyle(fontSize: 40)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Refer & Earn'.tr,
                            style: const TextStyle(
                              fontSize: 22,
                              fontFamily: AppThemeData.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Share. Connect. Earn Together'.tr,
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: AppThemeData.medium,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 2. Main Referral Code & Link Container (Using App Theme Cards)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1C15) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? const Color(0xFF2C2A26) : const Color(0xFFEFECE4)),
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
                    Text(
                      'Your Referral Code'.tr,
                      style: TextStyle(
                        fontSize: 13,
                        fontFamily: AppThemeData.bold,
                        color: isDark ? AppThemeData.grey900Dark : AppThemeData.grey900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppThemeData.success50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppThemeData.success300.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            referralCode,
                            style: TextStyle(
                              fontSize: 18,
                              fontFamily: AppThemeData.bold,
                              color: AppThemeData.primary200,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: () => _copyToClipboard(referralCode, 'Referral Code'),
                            child: Icon(Icons.copy_rounded, color: AppThemeData.primary200, size: 18),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Your Referral Link Section
                    Text(
                      'Your Referral Link'.tr,
                      style: TextStyle(
                        fontSize: 13,
                        fontFamily: AppThemeData.bold,
                        color: isDark ? AppThemeData.grey900Dark : AppThemeData.grey900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppThemeData.success50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppThemeData.success300.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              referralLink,
                              style: TextStyle(
                                fontSize: 12,
                                fontFamily: AppThemeData.medium,
                                color: AppThemeData.primary200,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _copyToClipboard(referralLink, 'Referral Link'),
                            child: Icon(Icons.copy_rounded, color: AppThemeData.primary200, size: 18),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Primary App-Themed Share Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _copyToClipboard(referralLink, 'Referral Link'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppThemeData.primary200,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
                        icon: const Icon(Icons.share_rounded, color: Colors.white, size: 18),
                        label: Text(
                          'Share Now'.tr,
                          style: const TextStyle(fontSize: 15, fontFamily: AppThemeData.bold, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 3. 4 Stat Cards Row (App Theme Colors)
              Row(
                children: [
                  _buildStatCard('Total Referrals', totalReferrals, Icons.groups_rounded, isDark),
                  const SizedBox(width: 8),
                  _buildStatCard('Earnings', totalEarnings, Icons.stars_rounded, isDark),
                  const SizedBox(width: 8),
                  _buildStatCard('Wallet Balance', walletBalance, Icons.account_balance_wallet_rounded, isDark),
                  const SizedBox(width: 8),
                  _buildStatCard('Active Users', activeUsers, Icons.insights_rounded, isDark),
                ],
              ),
              const SizedBox(height: 16),

              // 4. Quick Share Bar (App Theme Styling)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1C15) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? const Color(0xFF2C2A26) : const Color(0xFFEFECE4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Share'.tr,
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: AppThemeData.bold,
                        color: isDark ? AppThemeData.grey900Dark : AppThemeData.grey900,
                      ),
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
                        _buildSocialIcon('More', isDark ? AppThemeData.grey400Dark : AppThemeData.grey500, Icons.more_horiz_rounded, () {
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

  Widget _buildStatCard(String title, String value, IconData icon, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1C15) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? const Color(0xFF2C2A26) : const Color(0xFFEFECE4)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppThemeData.primary200.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppThemeData.primary200, size: 16),
            ),
            const SizedBox(height: 6),
            Text(
              title.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9,
                fontFamily: AppThemeData.medium,
                color: isDark ? AppThemeData.grey500Dark : AppThemeData.grey500,
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
                color: isDark ? AppThemeData.grey900Dark : AppThemeData.grey900,
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
            label.tr,
            style: TextStyle(
              fontSize: 10,
              fontFamily: AppThemeData.medium,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
