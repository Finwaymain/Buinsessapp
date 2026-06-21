import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../themes/constant_colors.dart';
import '../../../utils/dark_theme_provider.dart';

class ServiceCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const ServiceCard({super.key, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.getThem();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppThemeData.primary200,
            AppThemeData.primary200.withValues(alpha: 0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppThemeData.surface50,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: AppThemeData.semiBold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: AppThemeData.surface50.withValues(alpha: 0.7),
              fontSize: 12,
              fontFamily: AppThemeData.regular,
            ),
          ),
        ],
      ),
    );
  }
}
