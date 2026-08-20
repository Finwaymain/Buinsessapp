import 'package:cabme_driver/constant/constant.dart';
import 'package:cabme_driver/controller/subscription_controller.dart';
import 'package:cabme_driver/controller/wallet_controller.dart';
import 'package:cabme_driver/page/auth_screens/phone_entry_screen.dart';
import 'package:cabme_driver/page/features/SmartValue/AccountDetails/view/account_details.dart';
import 'package:cabme_driver/page/features/SmartValue/MyQR/view/my_qr_view.dart';
import 'package:cabme_driver/page/features/SmartValue/Payout/view/payout_screen.dart';
import 'package:cabme_driver/page/features/SmartValue/ScanAndTransfer/view/scanner_and_transfer_screen.dart';
import 'package:cabme_driver/page/subscription_plan_screen/subscription_plan_screen.dart' as subs;
import 'package:cabme_driver/themes/constant_colors.dart';
import 'package:cabme_driver/utils/Preferences.dart';
import 'package:cabme_driver/utils/dark_theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class WalletOverviewTab extends StatelessWidget {
  const WalletOverviewTab({
    super.key,
    required this.walletController,
    required this.onTopUp,
    required this.onWithdraw,
    this.bottomPadding = 0,
  });

  final WalletController walletController;
  final VoidCallback onTopUp;
  final VoidCallback onWithdraw;
  final double bottomPadding;

  void _requireLogin(VoidCallback action) {
    if (!Preferences.getBoolean(Preferences.isLogin)) {
      Get.to(() => PhoneEntryScreen(mode: 'signup'));
      return;
    }
    action();
  }

  Color _headingColor(bool isDark) => isDark ? AppThemeData.grey900Dark : AppThemeData.grey900;

  Color _bodyColor(bool isDark) => isDark ? AppThemeData.grey400Dark : AppThemeData.grey500;

  Color _cardBg(bool isDark) => isDark ? AppThemeData.surface50Dark : Colors.white;

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<DarkThemeProvider>(context).getThem();
    final user = Constant.getUserData().userData;
    final plan = user?.subscriptionPlan;
    final planPoints = plan?.planPoints ?? [];

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(bottom: 24 + bottomPadding, top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBalanceHero(isDark),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _moneyBtn('TOP UP', AppThemeData.primary200, onTopUp)),
              const SizedBox(width: 10),
              Expanded(child: _moneyBtn('WITHDRAW', AppThemeData.primary400, onWithdraw)),
            ],
          ),
          const SizedBox(height: 12),
          _buildAccountShortcut(isDark),
          const SizedBox(height: 20),
          Text('Quick Actions', style: _sectionStyle(isDark)),
          const SizedBox(height: 12),
          Row(
            children: [
              _quick(isDark, Icons.send_rounded, 'Transfer', () => _requireLogin(() => Get.to(() => ScannerAndTransferScreen()))),
              _quick(isDark, Icons.account_balance_outlined, 'Payout', () => _requireLogin(() => Get.to(() => PayoutScreen()))),
              _quick(isDark, Icons.qr_code_scanner_rounded, 'Scan', () => _requireLogin(() => Get.to(() => ScannerAndTransferScreen()))),
              _quick(isDark, Icons.qr_code_2_outlined, 'My QR', () => _requireLogin(() => Get.to(() => MyQRScreen()))),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Your Smart Value', style: _sectionStyle(isDark)),
              TextButton(
                onPressed: () => _requireLogin(() {
                  Get.delete<SubscriptionController>();
                  Get.to(() => const subs.SubscriptionPlanScreen(isbackButton: true));
                }),
                child: Text(
                  'Upgrade Plan',
                  style: TextStyle(color: AppThemeData.primary200, fontFamily: AppThemeData.medium, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Obx(() => Column(
                children: [
                  _walletCard(
                    isDark,
                    'Smart Value',
                    'Available balance',
                    walletController.walletAmount.value,
                    Icons.account_balance_wallet_rounded,
                    [AppThemeData.primary200, AppThemeData.primary300],
                  ),
                  const SizedBox(height: 12),
                  _walletCard(
                    isDark,
                    'Cashback',
                    'Rewards & earnings',
                    walletController.earnAmount.value,
                    Icons.card_giftcard_rounded,
                    [AppThemeData.secondary200, AppThemeData.info200],
                  ),
                ],
              )),
          const SizedBox(height: 20),
          Text('My Benefits', style: _sectionStyle(isDark)),
          const SizedBox(height: 10),
          _benefits(isDark, plan?.name, plan?.description, planPoints),
        ],
      ),
    );
  }

  Widget _buildBalanceHero(bool isDark) {
    return Obx(() => Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppThemeData.primary200, AppThemeData.primary400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppThemeData.primary200.withValues(alpha: 0.28),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Smart Value Balance'.tr,
                      style: const TextStyle(color: Colors.white70, fontSize: 14, fontFamily: AppThemeData.medium),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  Constant().amountShowWithoutSymbol(amount: walletController.walletAmount.value.toString()),
                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${'Total Earnings'.tr}: ${Constant().amountShowWithoutSymbol(amount: walletController.totalEarn.toString())}',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: AppThemeData.medium),
                ),
              ),
            ],
          ),
        ));
  }

  Widget _buildAccountShortcut(bool isDark) {
    return Material(
      color: _cardBg(isDark),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => _requireLogin(() => Get.to(() => AccountDetails())),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isDark ? AppThemeData.grey300Dark : AppThemeData.grey200),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppThemeData.primary50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.credit_card_rounded, color: AppThemeData.primary200, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Account & Card Details'.tr,
                      style: TextStyle(color: _headingColor(isDark), fontFamily: AppThemeData.semiBold, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'View Smart Value card and bank account info'.tr,
                      style: TextStyle(color: _bodyColor(isDark), fontSize: 12),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: _bodyColor(isDark)),
            ],
          ),
        ),
      ),
    );
  }

  TextStyle _sectionStyle(bool isDark) {
    return TextStyle(
      color: _headingColor(isDark),
      fontSize: 17,
      fontFamily: AppThemeData.semiBold,
    );
  }

  Widget _moneyBtn(String label, Color color, VoidCallback onTap) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 48,
          child: Center(
            child: Text(
              label.tr,
              style: const TextStyle(color: Colors.white, fontFamily: AppThemeData.semiBold, fontSize: 13),
            ),
          ),
        ),
      ),
    );
  }

  Widget _quick(bool isDark, IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: _cardBg(isDark),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isDark ? AppThemeData.grey300Dark : AppThemeData.grey200),
              ),
              child: Icon(icon, color: AppThemeData.primary200, size: 22),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 10, color: _bodyColor(isDark), fontFamily: AppThemeData.medium),
            ),
          ],
        ),
      ),
    );
  }

  Widget _benefits(bool isDark, String? name, String? description, List<String> points) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg(isDark),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppThemeData.grey300Dark : AppThemeData.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (name != null && name.isNotEmpty)
            Text(name, style: TextStyle(fontFamily: AppThemeData.semiBold, color: _headingColor(isDark), fontSize: 15)),
          if (description != null && description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(description, style: TextStyle(color: _bodyColor(isDark), fontSize: 13)),
          ],
          ...points.map((p) => Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle, size: 16, color: AppThemeData.primary200),
                    const SizedBox(width: 8),
                    Expanded(child: Text(p, style: TextStyle(color: _bodyColor(isDark), fontSize: 13))),
                  ],
                ),
              )),
          if ((name == null || name.isEmpty) && points.isEmpty)
            Text('Subscribe to a plan to unlock wallet benefits.', style: TextStyle(color: _bodyColor(isDark), fontSize: 13)),
        ],
      ),
    );
  }

  Widget _walletCard(bool isDark, String title, String subtitle, double amount, IconData icon, List<Color> colors) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                Text(subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                Constant().amountShowWithoutSymbol(amount: amount.toString()),
                style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
