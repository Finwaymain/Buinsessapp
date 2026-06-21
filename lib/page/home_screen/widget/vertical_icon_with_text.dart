import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../themes/constant_colors.dart';
import '../../../utils/dark_theme_provider.dart';

class VerticalIconWithText extends StatelessWidget {
  final IconData icon;
  final String text;
  final double iconSize;
  final double spacing;
  final Color? iconColor;
  final TextStyle? textStyle;
  final VoidCallback? onTap;

  const VerticalIconWithText({
    super.key,
    required this.icon,
    required this.text,
    this.iconSize = 28,
    this.spacing = 5,
    this.iconColor,
    this.textStyle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.getThem();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: iconSize,
            color: iconColor ??
                (isDark ? AppThemeData.grey900Dark : AppThemeData.grey900),
          ),
          SizedBox(height: spacing),
          Text(
            text,
            style: textStyle ??
                TextStyle(
                  fontSize: 11,
                  color:
                  isDark ? AppThemeData.grey900Dark : AppThemeData.grey900,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
