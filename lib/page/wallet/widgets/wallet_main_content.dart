import 'package:cabme_driver/controller/wallet_controller.dart';
import 'package:cabme_driver/model/trancation_model.dart';
import 'package:cabme_driver/page/wallet/widgets/wallet_overview_tab.dart';
import 'package:cabme_driver/page/wallet/widgets/wallet_transactions_tab.dart';
import 'package:cabme_driver/page/wallet/widgets/wallet_withdrawals_tab.dart';
import 'package:cabme_driver/themes/constant_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../utils/dark_theme_provider.dart';

class WalletMainContent extends StatefulWidget {
  const WalletMainContent({
    super.key,
    required this.walletController,
    required this.onTopUp,
    required this.onWithdraw,
    required this.onRefresh,
    required this.transactionBuilder,
    this.isTab = false,
  });

  final WalletController walletController;
  final VoidCallback onTopUp;
  final VoidCallback onWithdraw;
  final Future<void> Function() onRefresh;
  final Widget Function(TansactionData data, bool isDark) transactionBuilder;
  final bool isTab;

  @override
  State<WalletMainContent> createState() => _WalletMainContentState();
}

class _WalletMainContentState extends State<WalletMainContent> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.onRefresh());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<DarkThemeProvider>(context).getThem();
    final bottomPad = widget.isTab ? 112.0 : 16.0;
    final headingColor = isDark ? AppThemeData.grey900Dark : AppThemeData.grey900;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!widget.isTab)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              'Wallet',
              style: TextStyle(
                color: headingColor,
                fontSize: 20,
                fontFamily: AppThemeData.semiBold,
              ),
            ),
          ),
        Container(
          margin: EdgeInsets.fromLTRB(16, widget.isTab ? 8 : 10, 16, 0),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDark ? AppThemeData.grey100Dark : AppThemeData.grey100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? AppThemeData.grey300Dark : AppThemeData.grey200),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              color: AppThemeData.primary200,
              borderRadius: BorderRadius.circular(8),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelColor: Colors.white,
            unselectedLabelColor: isDark ? AppThemeData.grey400Dark : AppThemeData.grey500,
            labelStyle: const TextStyle(fontFamily: AppThemeData.semiBold, fontSize: 12),
            unselectedLabelStyle: const TextStyle(fontFamily: AppThemeData.medium, fontSize: 12),
            labelPadding: const EdgeInsets.symmetric(horizontal: 2),
            tabs: const [
              Tab(text: 'Overview'),
              Tab(text: 'History'),
              Tab(text: 'Withdraw'),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TabBarView(
              controller: _tabController,
              children: [
                RefreshIndicator(
                  color: AppThemeData.primary200,
                  onRefresh: widget.onRefresh,
                  child: WalletOverviewTab(
                    walletController: widget.walletController,
                    onTopUp: widget.onTopUp,
                    onWithdraw: widget.onWithdraw,
                    bottomPadding: bottomPad,
                  ),
                ),
                RefreshIndicator(
                  color: AppThemeData.primary200,
                  onRefresh: widget.onRefresh,
                  child: WalletTransactionsTab(
                    controller: widget.walletController,
                    itemBuilder: widget.transactionBuilder,
                    bottomPadding: bottomPad,
                  ),
                ),
                RefreshIndicator(
                  color: AppThemeData.primary200,
                  onRefresh: widget.onRefresh,
                  child: WalletWithdrawalsTab(bottomPadding: bottomPad),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
