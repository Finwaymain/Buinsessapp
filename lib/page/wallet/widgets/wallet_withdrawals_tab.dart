import 'package:cabme_driver/constant/constant.dart';
import 'package:cabme_driver/controller/withdrawals_controller.dart';
import 'package:cabme_driver/themes/constant_colors.dart';
import 'package:cabme_driver/themes/custom_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../../../utils/dark_theme_provider.dart';

class WalletWithdrawalsTab extends StatelessWidget {
  const WalletWithdrawalsTab({super.key, this.bottomPadding = 0});

  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);

    return GetX<WithdrawalsController>(
      init: WithdrawalsController(),
      builder: (controller) {
        if (controller.isLoading.value) {
          return Center(child: CircularProgressIndicator(color: AppThemeData.primary200));
        }

        if (controller.rideList.isEmpty) {
          return Center(child: Constant.emptyView("Your don't have any Withdrawals request".tr));
        }

        return ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.only(bottom: 24 + bottomPadding, top: 8),
          itemCount: controller.rideList.length,
          itemBuilder: (context, index) {
            final item = controller.rideList[index];
            final isDark = themeChange.getThem();
            final isSuccess = item.statut.toString() == 'success';
            final statusColor = isSuccess ? AppThemeData.success300 : AppThemeData.error50;

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppThemeData.surface50Dark : AppThemeData.surface50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? AppThemeData.grey300Dark : AppThemeData.grey300),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                      offset: const Offset(0, 2),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SvgPicture.asset(
                        'assets/icons/ic_wallet.svg',
                        width: 25,
                        height: 25,
                        colorFilter: ColorFilter.mode(
                          isDark ? AppThemeData.grey900Dark : AppThemeData.grey900,
                          BlendMode.srcIn,
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.creer.toString(),
                                      style: TextStyle(
                                        color: isDark ? AppThemeData.grey900Dark : AppThemeData.grey900,
                                        fontFamily: AppThemeData.medium,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    Constant().amountShowWithoutSymbol(amount: item.amount.toString()),
                                    style: TextStyle(
                                      color: statusColor,
                                      fontSize: 16,
                                      fontFamily: AppThemeData.medium,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                item.statut.toString(),
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 14,
                                  fontFamily: AppThemeData.medium,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: dividerCust(isDarkMode: isDark),
                              ),
                              Text(
                                item.bankName.toString(),
                                style: TextStyle(
                                  color: isDark ? AppThemeData.grey900Dark : AppThemeData.grey900,
                                  fontFamily: AppThemeData.regular,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item.accountNo.toString(),
                                style: TextStyle(
                                  color: isDark ? AppThemeData.grey900Dark : AppThemeData.grey900,
                                  fontFamily: AppThemeData.regular,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: dividerCust(isDarkMode: isDark),
                              ),
                              Text(
                                'Note'.tr,
                                style: TextStyle(
                                  color: isDark ? AppThemeData.grey900Dark : AppThemeData.grey900,
                                  fontFamily: AppThemeData.regular,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item.note.toString(),
                                style: TextStyle(
                                  color: isDark ? AppThemeData.grey900Dark : AppThemeData.grey900,
                                  fontFamily: AppThemeData.medium,
                                ),
                              ),
                            ],
                          ),
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
}
