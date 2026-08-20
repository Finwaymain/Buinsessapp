import 'package:cabme_driver/constant/constant.dart';
import 'package:cabme_driver/page/features/SmartValue/AccountDetails/controller/account_details_controller.dart';
import 'package:cabme_driver/themes/constant_colors.dart';
import 'package:cabme_driver/utils/dark_theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class WalletAccountDetailsPanel extends StatelessWidget {
  const WalletAccountDetailsPanel({super.key, required this.controller});

  final AccountDetailsController controller;

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<DarkThemeProvider>(context).getThem();
    final headingColor = isDark ? AppThemeData.grey900Dark : AppThemeData.grey900;
    final labelColor = isDark ? AppThemeData.grey400Dark : AppThemeData.grey500;
    final valueColor = isDark ? AppThemeData.grey900Dark : AppThemeData.grey900;

    return Obx(() {
      final hasProfile = controller.accountDetailsModel.value?.data != null ||
          Constant.getUserData().userData != null;

      if (controller.isLoading.value && !hasProfile) {
        return const SizedBox.shrink();
      }

      final status = controller.accountDetailsModel.value?.data?.statut == 'yes' ? 'Active' : 'Inactive';

      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? AppThemeData.surface50Dark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? AppThemeData.grey300Dark : AppThemeData.grey200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Account Details',
              style: TextStyle(color: headingColor, fontSize: 17, fontFamily: AppThemeData.semiBold),
            ),
            const SizedBox(height: 16),
            _row('Mobile Number', controller.mobile, Icons.phone_outlined, isDark, labelColor, valueColor),
            _row('Digital Credit Account', controller.accountNumber, Icons.vpn_key_outlined, isDark, labelColor, valueColor),
            _row('Balance', Constant().amountShow(amount: controller.amount), Icons.account_balance_wallet_outlined, isDark, labelColor, valueColor),
            _row('Earned Amount', Constant().amountShow(amount: controller.earnAmount), Icons.trending_up, isDark, labelColor, valueColor),
            
            _row('Card Status', status, Icons.verified_outlined, isDark, labelColor, valueColor, isStatus: true),
          ],
        ),
      );
    });
  }

  Widget _row(
    String label,
    String value,
    IconData icon,
    bool isDark,
    Color labelColor,
    Color valueColor, {
    bool isStatus = false,
  }) {
    final statusColor = value == 'Active' ? AppThemeData.success300 : AppThemeData.error200;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? AppThemeData.primary300Dark.withValues(alpha: 0.15) : AppThemeData.primary50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: AppThemeData.primary200),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: labelColor, fontSize: 12, fontFamily: AppThemeData.regular)),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isStatus ? statusColor : valueColor,
                    fontSize: 15,
                    fontFamily: AppThemeData.medium,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
