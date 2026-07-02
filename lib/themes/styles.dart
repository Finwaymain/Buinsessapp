import 'dart:developer';

import 'package:cabme_driver/themes/constant_colors.dart';
import 'package:flutter/material.dart';

class Styles {
  static ThemeData themeData(bool isDarkTheme, BuildContext context) {
    log("THEME :: $isDarkTheme");
    
    final primaryColor = isDarkTheme ? const Color(0XFF60A5FA) : const Color(0XFF1E3A8A);
    final secondaryColor = isDarkTheme ? const Color(0XFF38BDF8) : const Color(0XFF0284C7);
    final backgroundColor = isDarkTheme ? const Color(0XFF0F172A) : const Color(0XFFF8FAFC);
    final cardColor = isDarkTheme ? const Color(0XFF1E293B) : const Color(0XFFFFFFFF);
    final textColor = isDarkTheme ? const Color(0XFFF8FAFC) : const Color(0XFF0F172A);

    return ThemeData(
      scaffoldBackgroundColor: backgroundColor,
      primaryColor: primaryColor,
      cardColor: cardColor,
      brightness: isDarkTheme ? Brightness.dark : Brightness.light,
      
      appBarTheme: AppBarTheme(
        backgroundColor: cardColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        titleTextStyle: TextStyle(
          color: textColor,
          fontSize: 18,
          fontFamily: AppThemeData.semiBold,
        ),
      ),
      
      colorScheme: isDarkTheme
          ? ColorScheme.dark(
              primary: primaryColor,
              secondary: secondaryColor,
              surface: cardColor,
              error: const Color(0XFFEF4444),
            )
          : ColorScheme.light(
              primary: primaryColor,
              secondary: secondaryColor,
              surface: cardColor,
              error: const Color(0XFFEF4444),
            ),

      timePickerTheme: TimePickerThemeData(
        backgroundColor: cardColor,
        dialTextStyle: TextStyle(
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
        dialTextColor: textColor,
        hourMinuteTextColor: textColor,
        dayPeriodTextColor: textColor,
      ),
    );
  }
}
