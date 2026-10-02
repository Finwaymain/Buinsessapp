import 'package:cabme_driver/constant/constant.dart';
import 'package:cabme_driver/page/web_view_screen/web_view_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FinanceScreen extends StatelessWidget {
  /// Optional override URL — used when launching directly from the wallet card.
  /// If null, defaults to the finance hub with the user's phone number.
  final String? initialUrl;
  final bool isTab;

  const FinanceScreen({super.key, this.initialUrl, this.isTab = false});

  @override
  Widget build(BuildContext context) {
    final phone = Constant.getUserData().userData?.phone ?? '';
    final encodedPhone = Uri.encodeComponent(phone);
    var url = initialUrl ?? 'https://api.fiinway.com/finance?phone=$encodedPhone';
    if (!url.contains('hide_header=')) {
      final sep = url.contains('?') ? '&' : '?';
      url = '$url${sep}hide_header=1';
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Get.back();
            }
          },
        ),
        title: const Text(
          'Loans',
          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
        ),
        elevation: 0,
      ),
      body: WebViewScreen(
        url: url,
        title: 'Loans',
        showAppBar: false,
      ),
    );
  }
}

