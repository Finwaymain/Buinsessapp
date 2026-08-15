import 'package:cabme_driver/page/features/Taxi/taxi_dashboard/taxi_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../utils/Preferences.dart';
import '../../../utils/onboarding_url.dart';
import '../../auth_screens/phone_entry_screen.dart';
import '../../features/SmartValue/ScanAndTransfer/view/scanner_and_transfer_screen.dart';
import '../../features/SmartValue/Payout/view/payout_screen.dart';
import '../../features/rewards_screen.dart';
import '../../history/transaction_service_history_screen.dart';
import '../../features/SmartValue/MyQR/view/my_qr_view.dart';
import '../../wallet/wallet_screen.dart';
import '../../referral/referral_earn_screen.dart';
import '../../referral/submit_aadhar_screen.dart';
import '../../subscription_plan_screen/business_premium_plan_screen.dart';
import '../../in_progress_screen.dart';
import '../view/home_screen.dart';
import '../../web_view_screen/web_view_screen.dart';

class MainHomeController extends GetxController
    with GetTickerProviderStateMixin {
  late List<AnimationController> controllers;
  late List<Animation<Offset>> slideAnimations;

  bool get hasAadhar =>
      (Preferences.getString('user_aadhar_number') ??
              Preferences.getString('driver_aadhar_number') ??
              '')
          .isNotEmpty;

  List<Map<String, dynamic>> get featureCards {
    return [
      {
        "routeName": "/history",
        "icon": Icons.history_rounded,
        "title": "History & Invoices",
        "status": 1,
      },
      {
        "routeName": "/referral",
        "icon": Icons.card_giftcard,
        "title": hasAadhar ? "Partner Dashboard" : "Join as a Partner",
        "status": 1,
      },
      {
        "routeName": "/premium",
        "icon": Icons.workspace_premium,
        "title": "Business Plan",
        "status": 1,
      },
    ];
  }

  List<Map<String, dynamic>> get serviceCards {
    return [
      {
        "routeName": "/travelTransport",
        "title": "Travel & Transport",
        "subtitle": "Book cabs, view requests, and track active rides",
        "status": 1,
      },
      {
        "routeName": "/referralProgram",
        "title": hasAadhar ? "Partner Dashboard" : "Join as a Partner",
        "subtitle": hasAadhar
            ? "Manage team, track stats & earn lifetime cashback"
            : "Submit Aadhaar to become a partner & earn rewards",
        "status": 1,
      },
      {
        "routeName": "/smartValue",
        "title": "Smart Value & QR",
        "subtitle": "Scan QR & transfer Smart Value money instantly",
        "status": 1,
      },
    ];
  }

  bool _isDisposed = false;

  @override
  void onInit() {
    super.onInit();

    controllers = List.generate(serviceCards.length, (index) {
      return AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      );
    });

    slideAnimations = controllers.map((controller) {
      return Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOut));
    }).toList();

    _startAnimations();
  }

  Future<void> _startAnimations() async {
    try {
      for (int i = 0; i < controllers.length; i++) {
        await Future.delayed(Duration(milliseconds: i * 200));
        if (!_isDisposed) {
          controllers[i].forward();
        }
      }
      if (!_isDisposed) {
        update();
      }
    } catch (e) {
      // Prevent crash if animation controller is disposed
    }
  }

  void onFeatureTap(int index) {
    final card = featureCards[index];
    final routeName = (card['routeName'] ?? '').toString();
    final bool isLogin = Preferences.getBoolean(Preferences.isLogin) ?? false;

    if (!isLogin) {
      Get.to(() => PhoneEntryScreen(mode: 'signup'),
          transition: Transition.rightToLeftWithFade);
    } else if (routeName == '/history') {
      Get.to(() => WalletScreen(initialIndex: 1), transition: Transition.rightToLeftWithFade);
    } else if (routeName == '/referral') {
      Get.to(() => const ReferralEarnScreen(), transition: Transition.rightToLeftWithFade);
    } else if (routeName == '/premium') {
      Get.to(() => const BusinessPremiumPlanScreen(), transition: Transition.rightToLeftWithFade);
    } else {
      Get.to(() => const InProgressScreen(),
          transition: Transition.rightToLeftWithFade);
    }
  }

  bool getLoginStatus({required bool inProgress}) {
    final bool isLogin = Preferences.getBoolean(Preferences.isLogin) ?? false;

    if (!isLogin) {
      Get.to(() => PhoneEntryScreen(mode: 'signup'),
          transition: Transition.rightToLeftWithFade);
      return false;
    } else if (inProgress) {
      Get.to(() => const InProgressScreen(),
          transition: Transition.rightToLeftWithFade);
      return false;
    } else {
      return true;
    }
  }

  void onServiceTap(int index) {
    final card = serviceCards[index];
    final bool isLogin = Preferences.getBoolean(Preferences.isLogin) ?? false;
    final String routeName = card['routeName']?.toString() ?? '';

    if (!isLogin) {
      Get.to(() => PhoneEntryScreen(mode: 'signup'),
          transition: Transition.rightToLeftWithFade);
    } else if (routeName == '/smartValue') {
      Get.to(() => MyQRScreen(), transition: Transition.rightToLeftWithFade);
    } else if (routeName == '/referralProgram') {
      Get.to(() => const ReferralEarnScreen(), transition: Transition.rightToLeftWithFade);
    } else if (index == 0) {
      Get.to(() => TaxiDashBoard(), transition: Transition.rightToLeftWithFade);
    } else {
      Get.to(() => const InProgressScreen(),
          transition: Transition.rightToLeftWithFade);
    }
  }

  @override
  void onClose() {
    _isDisposed = true;
    for (var controller in controllers) {
      controller.dispose();
    }
    super.onClose();
  }
}
