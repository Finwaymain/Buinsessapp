import 'package:cabme_driver/constant/constant.dart';
import 'package:cabme_driver/controller/wallet_controller.dart';
import 'package:cabme_driver/model/trancation_model.dart';
import 'package:cabme_driver/themes/constant_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../../../utils/dark_theme_provider.dart';

class WalletTransactionsTab extends StatelessWidget {
  const WalletTransactionsTab({
    super.key,
    required this.controller,
    required this.itemBuilder,
    this.bottomPadding = 0,
  });

  final WalletController controller;
  final Widget Function(TansactionData data, bool isDark) itemBuilder;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);

    return Obx(() {
      if (controller.isLoading.value && controller.transactionList.isEmpty) {
        return Center(child: CircularProgressIndicator(color: AppThemeData.primary200));
      }

      if (controller.transactionList.isEmpty) {
        return Center(child: Constant.emptyView('No transaction found'));
      }

      return ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(bottom: 24 + bottomPadding),
        itemCount: controller.transactionList.length,
        itemBuilder: (context, index) {
          return itemBuilder(controller.transactionList[index], themeChange.getThem());
        },
      );
    });
  }
}
