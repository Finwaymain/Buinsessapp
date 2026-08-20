import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../../../themes/constant_colors.dart';
import '../../../utils/dark_theme_provider.dart';
import '../../features/SmartValue/ScanAndTransfer/view/scanner_and_transfer_screen.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int)? onTabSelected;
  final VoidCallback? onFingerprintTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    this.onTabSelected,
    this.onFingerprintTap,
  });

  void _handleTabSelected(int index) {
    if (onTabSelected != null) {
      onTabSelected!(index);
    }
  }

  void _handleFingerprintTap() {
    if (onFingerprintTap != null) {
      onFingerprintTap!();
      return;
    }
    Get.to(
      () => ScannerAndTransferScreen(),
      transition: Transition.rightToLeft,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);

    return Container(
      color: Colors.transparent,
      height: 100,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            height: 55,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: themeChange.getThem()
                  ? const Color(0xFF1C1A17)
                  : AppThemeData.surface50,
              borderRadius: BorderRadius.circular(30),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 5,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(Icons.home, 0, themeChange),
                _navItem(Icons.search, 1, themeChange),
                const SizedBox(width: 60),
                _navItem(Icons.home_repair_service_outlined, 3, themeChange),
                _navItem(Icons.account_balance_wallet_rounded, 4, themeChange),
              ],
            ),
          ),
          Positioned(
            top: 0,
            child: Container(
              height: 60,
              width: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppThemeData.primary200,
                    AppThemeData.primary200.withValues(alpha: 0.7),
                  ],
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.fingerprint, color: Colors.white, size: 30),
                onPressed: _handleFingerprintTap,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, int index, DarkThemeProvider themeChange) {
    return IconButton(
      onPressed: () => _handleTabSelected(index),
      icon: Icon(
        icon,
        color: currentIndex == index
            ? AppThemeData.primary200
            : (themeChange.getThem() ? Colors.white38 : AppThemeData.primary200.withValues(alpha: 0.3)),
      ),
    );
  }
}
