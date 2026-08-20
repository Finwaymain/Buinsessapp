import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cabme_driver/page/web_view_screen/web_view_screen.dart';
import 'package:cabme_driver/utils/Preferences.dart';

class ReferralEarnScreen extends StatelessWidget {
  const ReferralEarnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    String driverId = Preferences.getString(Preferences.userId);
    String phone = '';
    final userStr = Preferences.getString(Preferences.user);
    if (userStr.isNotEmpty) {
      try {
        final map = jsonDecode(userStr);
        if (driverId.isEmpty || driverId == "0") {
          driverId = (map['id'] ?? map['id_driver'] ?? map['userData']?['id'] ?? '').toString();
        }
        phone = (map['phone'] ?? map['userData']?['phone'] ?? '').toString();
      } catch (_) {}
    }

    final token = Preferences.getString(Preferences.accesstoken);
    final url = 'https://api.fiinway.com/onboarding/referral?driver_id=$driverId&id_driver=$driverId&user_cat=driver&user_type=driver&phone=${Uri.encodeComponent(phone)}&accesstoken=$token';

    return WebViewScreen(
      url: url,
      title: 'Partner Dashboard',
      showAppBar: true,
    );
  }
}
