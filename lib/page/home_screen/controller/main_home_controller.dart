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
        "routeName": "/addValue",
        "icon": Icons.account_balance_wallet_outlined,
        "title": "Add Value",
        "status": 1,
      },
      {
        "routeName": "/referral",
        "icon": Icons.card_giftcard,
        "title": "Partner Dashboard",
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
        "subtitle": "Bike Ride, Cab -  Parcel Delivery & Packers & Mover ",
        "status": 1,
      },
      {
        "routeName": "/medicalCashback",
        "title": "Medical Cashback Card",
        "subtitle": "Earn cashback on medical bills & healthcare",
        "status": 1,
      },
      {
        "routeName": "/smartValue",
        "title": "Smart Value",
        "subtitle": "Earn Upto 2%  By Using App Services",
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
    } else if (routeName == '/addValue' || routeName == '/history') {
      Get.to(() => const WalletScreen(autoOpenTopUp: true), transition: Transition.rightToLeftWithFade);
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
      Get.to(() => const WalletScreen(), transition: Transition.rightToLeftWithFade);
    } else if (routeName == '/medicalCashback') {
      final finalUrl = OnboardingUrl.build('/onboarding/medical-cashback');
      Get.to(() => WebViewScreen(url: finalUrl, title: 'Medical Cashback Card'.tr),
          transition: Transition.rightToLeftWithFade);
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
