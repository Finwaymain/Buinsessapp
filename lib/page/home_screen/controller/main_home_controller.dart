import 'package:cabme_driver/page/features/Taxi/taxi_dashboard/taxi_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../utils/Preferences.dart';
import '../../auth_screens/phone_entry_screen.dart';
import '../../features/SmartValue/ScanAndTransfer/view/scanner_and_transfer_screen.dart';
import '../../features/SmartValue/Payout/view/payout_screen.dart';
import '../../features/rewards_screen.dart';
import '../../in_progress_screen.dart';
import '../view/home_screen.dart';

class MainHomeController extends GetxController
    with GetTickerProviderStateMixin {
  late List<AnimationController> controllers;
  late List<Animation<Offset>> slideAnimations;

  final featureCards = [
    {
      "routeName": "/addFund",
      "icon": Icons.attach_money,
      "title": "Add Fund",
      "status": 1,
    },
    {
      "routeName": "/rewards",
      "icon": Icons.card_giftcard,
      "title": "Rewards",
      "status": 1,
    },
    {
      "routeName": "/payouts",
      "icon": Icons.payments_outlined,
      "title": "Payouts",
      "status": 1,
    },
  ];

  final serviceCards = [
    {
      "routeName": "/travelTransport",
      "title": "Travel & Transport",
      "subtitle": "Book cabs, recharge passes, pay bills, and more",
      "status": 1,
    },
    {
      "routeName": "/cashbackCard",
      "title": "Cashback Card",
      "subtitle": "Send money to friends or pay shops and earn rewards",
      "status": 1,
    },
    {
      "routeName": "/smartValue",
      "title": "Smart Value",
      "subtitle": "Pay directly within the app and ride instantly",
      "status": 1,
    },
  ];

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
    final status = card['status'] ?? 0;
    final routeName = (card['routeName'] ?? '').toString();
    final bool isLogin = Preferences.getBoolean(Preferences.isLogin) ?? false;

    if (!isLogin) {
      Get.to(() => PhoneEntryScreen(mode: 'signup'),
          transition: Transition.rightToLeftWithFade);
    }
    else if (routeName == '/addFund') {
      Get.to(() => AddFundScreen(), transition: Transition.rightToLeftWithFade);
    }
    else if (routeName == '/rewards') {
      Get.to(() => const RewardsScreen(), transition: Transition.rightToLeftWithFade);
    }
    else if (routeName == '/payouts') {
      Get.to(() => PayoutScreen(), transition: Transition.rightToLeftWithFade);
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
      return false; // user login nahi hai
    } else if (inProgress) {
      Get.to(() => const InProgressScreen(),
          transition: Transition.rightToLeftWithFade);
      return false; // login hai but in progress hai
    } else {
      return true; // login hai aur in progress nahi hai
    }
  }


  void onServiceTap(int index) {
    final card = serviceCards[index];
    final bool isLogin = Preferences.getBoolean(Preferences.isLogin) ?? false;
    final status = card['status'] ?? 0;
    final String routeName = card['routeName']?.toString() ?? '';

    if (!isLogin) {
      Get.to(() => PhoneEntryScreen(mode: 'signup'),
          transition: Transition.rightToLeftWithFade);
    } else if (index == 0) {
      Get.to(() => TaxiDashBoard(), transition: Transition.rightToLeftWithFade);
    } else if (index == 2) {
      Get.to(() => ScannerAndTransferScreen(), transition: Transition.rightToLeftWithFade);
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
