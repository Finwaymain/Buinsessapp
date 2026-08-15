import 'package:cabme_driver/page/web_view_screen/web_view_screen.dart';
import 'package:cabme_driver/utils/Preferences.dart';
import 'package:flutter/material.dart';

class ReferralHistoryScreen extends StatelessWidget {
  const ReferralHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final driverId = Preferences.getString(Preferences.userId);
    final token = Preferences.getString(Preferences.accesstoken);
    final url = 'https://api.fiinway.com/onboarding/referral?driver_id=$driverId&accesstoken=$token';

    return WebViewScreen(
      url: url,
      title: 'Referral History',
      showAppBar: true,
    );
  }
}
