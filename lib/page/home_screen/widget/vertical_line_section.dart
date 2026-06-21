import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../themes/constant_colors.dart';
import '../../../utils/dark_theme_provider.dart';
import 'vertical_line_header.dart';

class VerticalLineSection extends StatelessWidget {
  final String text;
  final double lineHeight;
  final Color? lineColor;
  final TextStyle? textStyle;
  final List<Widget> cardChildren;
  final EdgeInsetsGeometry? margin ;

  const VerticalLineSection({
    super.key,
    required this.text,
    required this.cardChildren,
    this.lineHeight = 25,
    this.lineColor,
    this.textStyle,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.getThem();
    return Container(
      margin: margin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          VerticalLineHeader(
            text: text,
            lineHeight: lineHeight,
            lineColor: lineColor,
            textStyle: textStyle,
          ),
          const SizedBox(height: 12),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1917) : AppThemeData.surface50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                width: 1,
                color: isDark
                    ? AppThemeData.primary200.withValues(alpha: 0.12)
                    : AppThemeData.primary200.withValues(alpha: 0.15),
              ),
            ),
            child: LayoutBuilder(
                builder: (context, constraints) {
                  const int maxItemsPerRow = 4;
                  const double spacing = 20;

                  final double totalSpacing = spacing * (maxItemsPerRow - 1);
                  final double itemWidth =
                      (constraints.maxWidth - totalSpacing) / maxItemsPerRow;

                  // List with placeholders if less than maxItemsPerRow
                  final List<Widget> allChildren = [...cardChildren];

                  // If last row has less than 4, fill with empty boxes to align layout
                  int remainder = cardChildren.length % maxItemsPerRow;
                  if (remainder != 0) {
                    int fillers = maxItemsPerRow - remainder;
                    for (int i = 0; i < fillers; i++) {
                      allChildren.add(const SizedBox()); // Empty cell
                    }
                  }

                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: allChildren.map((child) {
                      return SizedBox(
                        width: itemWidth,
                        child: child,
                      );
                    }).toList(),
                  );
                },
              ),
          ),
        ],
      ),
    );
  }
}
