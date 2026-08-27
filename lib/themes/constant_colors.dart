import 'package:flutter/material.dart';
import 'package:cabme_driver/utils/Preferences.dart';

class ConstantColors {
  static Color? _primary;
  static Color? _blue;

  static bool get isDark {
    try {
      int themeStatus = Preferences.getInt("THEMESTATUS");
      if (themeStatus == 0) return true;
      if (themeStatus == 1) return false;
      return WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
    } catch (e) {
      try {
        return WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
      } catch (_) {
        return false;
      }
    }
  }

  static Color get primary => _primary ?? (isDark ? const Color(0xff60A5FA) : const Color(0xff1E3A8A));
  static set primary(Color value) => _primary = value;

  static Color get blue => _blue ?? (isDark ? const Color(0xff38BDF8) : const Color(0xff0284C7));
  static set blue(Color value) => _blue = value;

  static Color get yellow => const Color(0xffEAA501);
  static Color get yellow1 => const Color(0xffFFC003);
  static Color get background => isDark ? const Color(0xff0F172A) : const Color(0xffF8FAFC);
  static Color get titleTextColor => isDark ? const Color(0xffF8FAFC) : const Color(0xff0F172A);
  static Color get subTitleTextColor => isDark ? const Color(0xff94A3B8) : const Color(0xff475569);
  static Color get hintTextColor => isDark ? const Color(0xff64748B) : const Color(0xff94A3B8);
  static Color get textFieldBoarderColor => isDark ? const Color(0xff334155) : const Color(0xffE2E8F0);
}

class AppThemeData {
  static Color? _primary200;
  static Color? _primary300;
  static Color? _primary400;

  static bool get isDark {
    try {
      int themeStatus = Preferences.getInt("THEMESTATUS");
      if (themeStatus == 0) return true;
      if (themeStatus == 1) return false;
      return WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
    } catch (e) {
      try {
        return WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
      } catch (_) {
        return false;
      }
    }
  }

  // Surface / Cards
  static Color get surface50 => const Color(0XFFFFFFFF);
  static Color get surface50Dark => const Color(0XFF1E293B);

  // Primary brand color
  static Color get primary200 => _primary200 ?? (isDark ? const Color(0XFF60A5FA) : const Color(0XFF1E3A8A));
  static set primary200(Color value) => _primary200 = value;

  static Color get primary300 => _primary300 ?? (isDark ? const Color(0XFF60A5FA) : const Color(0XFF1E3A8A));
  static set primary300(Color value) => _primary300 = value;

  static Color get primary400 => _primary400 ?? (isDark ? const Color(0XFF38BDF8) : const Color(0XFF0284C7)); // secondary / accents
  static set primary400(Color value) => _primary400 = value;

  // Background
  static Color get grey50 => const Color(0XFFF8FAFC);
  static Color get grey50Dark => const Color(0XFF0F172A);

  // Neutrals / Greys / Borders
  static Color get grey100 => const Color(0XFFF1F5F9);
  static Color get grey100Dark => const Color(0XFF334155);
  static Color get grey200 => const Color(0XFFE2E8F0);
  static Color get grey200Dark => const Color(0XFF475569);
  static Color get grey300 => const Color(0XFFCBD5E1);
  static Color get grey300Dark => const Color(0XFF475569);
  static Color get grey400 => const Color(0XFF94A3B8);
  static Color get grey400Dark => const Color(0XFF64748B);
  
  // Text Colors
  static Color get grey900 => const Color(0XFF0F172A);
  static Color get grey900Dark => const Color(0XFFF8FAFC);
  static Color get grey500 => const Color(0XFF64748B);
  static Color get grey500Dark => const Color(0XFF94A3B8);
  static Color get grey800 => const Color(0XFF1E293B);
  static Color get grey800Dark => const Color(0XFFE2E8F0);

  static Color get textFieldBoarderColor => isDark ? const Color(0XFF334155) : const Color(0XFFE2E8F0);

  static Color get yellow => const Color(0XFFFFF7D7);
  static Color get warning200 => const Color(0XFFEF4444); // Red 500
  static Color get success300 => const Color(0XFF10B981); // Emerald 500
  static Color get success50 => isDark ? const Color(0XFF064E3B) : const Color(0XFFE6F4EA);

  static Color get pink => const Color(0XFFFEE2E2);
  static Color get pink2 => const Color(0XFFFFE5E8);

  static Color get error50 => isDark ? const Color(0XFF7F1D1D) : const Color(0XFFFEE2E2);
  static Color get error100 => const Color(0XFFFCA5A5);
  static Color get error200 => const Color(0XFFEF4444);

  static Color get new50 => isDark ? const Color(0XFF1E293B) : const Color(0XFFE0F2FE);
  static Color get new200 => isDark ? const Color(0XFF38BDF8) : const Color(0XFF0284C7);

  static Color get info50 => isDark ? const Color(0XFF1E293B) : const Color(0XFFE0F2FE);
  static Color get info300 => isDark ? const Color(0XFF38BDF8) : const Color(0XFF0284C7);

  static Color get secondary50 => isDark ? const Color(0XFF1E293B) : const Color(0XFFE0F2FE);
  static Color get secondary200 => isDark ? const Color(0XFF38BDF8) : const Color(0XFF0284C7);
  static Color get secondary300 => isDark ? const Color(0XFF60A5FA) : const Color(0XFF1E3A8A);
  static Color get secondar300 => isDark ? const Color(0XFF60A5FA) : const Color(0XFF1E3A8A);

  static Color get success300Light => const Color(0XFFD1FAE5);
  static Color get primary50 => isDark ? const Color(0XFF1E293B) : const Color(0XFFE0F2FE);

  static Color get primary300Dark => const Color(0XFF60A5FA);
  static Color get blue200 => const Color(0XFFE0F2FE);
  static Color get referBgone => const Color(0XFF1E3A8A);
  static Color get referBgtwo => const Color(0XFF0284C7);
  static Color get info200 => const Color(0XFF38BDF8);
  static Color get loadingBgColor => isDark ? const Color(0XFF0F172A) : const Color(0XFFF8FAFC);

  static const String black = 'Switzer-Black';
  static const String bold = 'Switzer-Bold';
  static const String extraBold = 'Switzer-Extrabold';
  static const String extraLight = 'Switzer-Extralight';
  static const String light = 'Switzer-Italic';
  static const String medium = 'Switzer-Medium';
  static const String regular = 'Switzer-Regular';
  static const String semiBold = 'Switzer-Semibold';
  static const String thin = 'Switzer-Thin';
}
