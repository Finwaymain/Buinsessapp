import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../themes/constant_colors.dart';
import '../../../utils/dark_theme_provider.dart'; // import your theme

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTabSelected;
  final VoidCallback onFingerprintTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    required this.onFingerprintTap,
  });

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
                  : AppThemeData.surface50,  // match LoginScreen background color
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
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
                const SizedBox(width: 60,),
                _navItem(Icons.home_repair_service_outlined, 3, themeChange),
                _navItem(Icons.receipt_long, 4,themeChange),
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
                gradient:  LinearGradient(
                  colors: [
                    AppThemeData.primary200,
                    AppThemeData.primary200.withValues(alpha: 0.7),
                  ],                ),
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
                onPressed: onFingerprintTap,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, int index, DarkThemeProvider themeChange) {
    return IconButton(
      onPressed: () => onTabSelected(index),
      icon: Icon(
        icon,
        color: currentIndex == index
            ? AppThemeData.primary200
            :  AppThemeData.primary200.withValues(alpha: 0.2),
      ),
    );
  }
}
