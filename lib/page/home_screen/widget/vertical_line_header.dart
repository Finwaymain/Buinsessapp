import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../themes/constant_colors.dart';
import '../../../utils/dark_theme_provider.dart';

class VerticalLineHeader extends StatelessWidget {
  final String text;
  final double lineHeight;
  final Color? lineColor;
  final TextStyle? textStyle;

   const VerticalLineHeader({
    super.key,
    required this.text,
    this.lineHeight = 25,
    this.lineColor,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.getThem();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 8,
          height: lineHeight,
          decoration: BoxDecoration(
            color: lineColor ?? AppThemeData.primary200,
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(8),
              bottomRight: Radius.circular(8),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            text,
            style: textStyle ??
                TextStyle(
                  color:
                      isDark ? AppThemeData.grey50Dark : Colors.grey.shade800,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
          ),
        ),
      ],
    );
  }
}
