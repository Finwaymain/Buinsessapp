import 'package:cabme_driver/page/web_view_screen/web_view_screen.dart';
import 'package:flutter/material.dart';

class OnBoardingScreen extends StatelessWidget {
  const OnBoardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const WebViewScreen(
      url: 'https://api.fiinway.com/onboarding/welcome?type=driver',
      title: 'Welcome to Fiinway Business',
      showAppBar: false,
    );
  }
}
