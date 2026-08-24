// ignore_for_file: must_be_immutable

import 'package:cabme_driver/constant/constant.dart';
import 'package:cabme_driver/controller/dash_board_controller.dart';
import 'package:cabme_driver/controller/subscription_controller.dart';
import 'package:cabme_driver/model/user_model.dart';


import 'package:cabme_driver/page/MainDashBoard/widget/custom_drawer.dart';
import 'package:cabme_driver/page/new_ride_screens/new_ride_screen.dart';
import 'package:cabme_driver/page/subscription_plan_screen/subscription_plan_screen.dart';
import 'package:cabme_driver/page/web_view_screen/web_view_screen.dart';
import 'package:cabme_driver/themes/constant_colors.dart';
import 'package:cabme_driver/themes/responsive.dart';
import 'package:cabme_driver/utils/Preferences.dart';
import 'package:cabme_driver/utils/onboarding_url.dart';
import 'package:cabme_driver/utils/dark_theme_provider.dart';
import 'package:cabme_driver/utils/network_image_widget.dart';
import 'package:cabme_driver/widget/round_button_fill.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class TaxiDashBoard extends StatelessWidget {
  TaxiDashBoard({super.key});

  DateTime backPress = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return GetBuilder<DashBoardController>(
      init: DashBoardController(),
      builder: (controller) {
        controller.getDrawerItems();
        return Scaffold(body: NewRideScreen());
      },
    );
  }
}

Widget buildAppDrawer(BuildContext context, DashBoardController controller) {
  return const CustomDrawer();
}


class SubscriptionPlanWidget extends StatelessWidget {
  final VoidCallback onClick;
  final UserModel userModel;

  const SubscriptionPlanWidget({
    super.key,
    required this.onClick,
    required this.userModel,
  });

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final userData = userModel.userData;
    if (userData == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: themeChange.getThem() ? AppThemeData.grey800 : AppThemeData.grey200),
        color: themeChange.getThem() ? AppThemeData.grey200Dark : AppThemeData.grey800,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          Positioned(
              bottom: 0,
              top: 10,
              child: Opacity(
                  opacity: 0.8,
                  child: Image.asset(
                    width: Responsive.width(100, context),
                    height: Responsive.height(100, context),
                    "assets/images/ic_gradient.png",
                    color: AppThemeData.secondary300,
                    fit: BoxFit.fill,
                  ))),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    NetworkImageWidget(
                      imageUrl: (userData.subscriptionPlan?.image?.isNotEmpty == true) ? userData.subscriptionPlan!.image! : Constant.placeholderUrl.toString(),
                      fit: BoxFit.cover,
                      width: 50,
                      height: 50,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userData.subscriptionPlan?.name ?? '',
                                  style: TextStyle(
                                    color: themeChange.getThem() ? AppThemeData.grey900 : AppThemeData.grey50,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: AppThemeData.semiBold,
                                  ),
                                ),
                                Text(
                                  userData.subscriptionPlan?.type == 'free'
                                      ? userData.subscriptionPlan?.description ?? ''
                                      : Constant().amountShow(amount: userData.subscriptionPlan?.price),
                                  style: TextStyle(
                                    fontFamily: AppThemeData.medium,
                                    fontSize: 14,
                                    color: AppThemeData.grey400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (userData.subscriptionPlan?.type == 'paid')
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Expiry Date'.tr,
                                  style: TextStyle(
                                    fontFamily: AppThemeData.medium,
                                    fontSize: 12,
                                    color: themeChange.getThem() ? AppThemeData.grey900 : AppThemeData.grey50,
                                  ),
                                ),
                                Text(
                                  userData.subscriptionPlan?.expiryDay == "-1" ? "LifeTime" : userData.subscriptionExpiryDate ?? '',
                                  style: TextStyle(
                                    fontFamily: AppThemeData.regular,
                                    fontSize: 12,
                                    color: AppThemeData.grey400,
                                  ),
                                ),
                              ],
                            )
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                RoundedButtonFill(
                  radius: 14,
                  textColor: AppThemeData.grey200,
                  title: "Change Plan".tr,
                  color: AppThemeData.secondary300,
                  width: 80,
                  height: 4.6,
                  onPress: onClick,
                ),
                if (Constant.adminCommission?.statut == "yes")
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      userData.adminCommission != null
                          ? "${userData.adminCommission?.type == 'Percentage' ? "${userData.adminCommission?.value} %" : "${Constant().amountShow(amount: userData.adminCommission?.value)} Flat"} ${"admin commission will be charged from your account after the ride/parcel booking is completed".tr}"
                          : "${Constant.adminCommission?.type == 'Percentage' ? "${Constant.adminCommission?.value} %" : "${Constant().amountShow(amount: Constant.adminCommission?.value)} Flat"} ${"admin commission will be charged from your account after the ride/parcel booking is completed".tr}", //${"admin commission will be charged from customer billing booking and the admin charge will be earned after the order is accepted by the restaurant.".tr}",
                      style: TextStyle(
                        fontFamily: AppThemeData.medium,
                        fontSize: 9,
                        color: AppThemeData.grey400,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> showAlertDialog(BuildContext context, String type) async {
  return showDialog(
    context: context,
    barrierDismissible: false, // user must tap button!
    builder: (BuildContext context) {
      return AlertDialog(
        // <-- SEE HERE
        title: Text('Information'.tr),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              Text(type == "pendingApproval" 
                  ? 'Your account is pending approval from the admin.'.tr 
                  : 'To start earning with Fiinway you need to fill in your information'.tr),
            ],
          ),
        ),
        actions: <Widget>[
          if (type == "pendingApproval")
            TextButton(
              child: Text(
                'OK'.tr,
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: AppThemeData.regular,
                  color: AppThemeData.primary200,
                ),
              ),
              onPressed: () {
                Get.back();
              },
            )
          else ...[
            TextButton(
              child: Text(
                'No'.tr,
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: AppThemeData.regular,
                  color: AppThemeData.primary200,
                ),
              ),
              onPressed: () {
                Get.back();
              },
            ),
            TextButton(
              child: Text(
                'Yes'.tr,
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: AppThemeData.regular,
                  color: AppThemeData.primary200,
                ),
              ),
              onPressed: () {
                Get.back();
                final finalUrl = OnboardingUrl.build('/onboarding');
                Get.to(() => WebViewScreen(url: finalUrl, title: 'Complete Onboarding'));
              },
            ),
          ]
        ],
      );
    },
  );
}

class DrawerItem {
  String? title;
  String? description;
  String? icon;
  String? section;
  bool? isSwitch;

  DrawerItem({required this.title,required this.description,required this.icon, this.section, this.isSwitch});
}
