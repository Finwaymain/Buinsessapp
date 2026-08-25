import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cabme_driver/constant/constant.dart';
import 'package:cabme_driver/page/web_view_screen/web_view_screen.dart';
import 'package:cabme_driver/utils/Preferences.dart';
import 'package:cabme_driver/utils/onboarding_url.dart';

class ReferralEarnScreen extends StatelessWidget {
  const ReferralEarnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    String driverId = OnboardingUrl.driverId();
    if (driverId.isEmpty || driverId == "0") {
      final intId = Preferences.getInt(Preferences.userId);
      if (intId != 0) driverId = intId.toString();
    }
    if (driverId.isEmpty || driverId == "0") {
      driverId = Preferences.getString(Preferences.userId);
    }
    if (driverId.isEmpty || driverId == "0") {
      driverId = Constant.getUserData().userData?.id ?? '';
    }

    String phone = Constant.getUserData().userData?.phone ?? '';
    if (phone.isEmpty) {
      final userStr = Preferences.getString(Preferences.user);
      if (userStr.isNotEmpty) {
        try {
          final map = jsonDecode(userStr);
          phone = (map['phone'] ?? map['userData']?['phone'] ?? '').toString();
        } catch (_) {}
      }
    }

    final token = OnboardingUrl.accessToken();

    final url = OnboardingUrl.build(
      '/onboarding/referral',
      extra: {
        'driver_id': driverId,
        'id_driver': driverId,
        'user_cat': 'driver',
        'user_type': 'driver',
        if (phone.isNotEmpty) 'phone': phone,
        if (token.isNotEmpty) 'accesstoken': token,
      },
    );

    return WebViewScreen(
      url: url,
      title: 'Partner Dashboard',
      showAppBar: true,
    );
  }
}
