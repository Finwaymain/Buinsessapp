// ignore_for_file: must_be_immutable

import 'package:cabme_driver/constant/constant.dart';
import 'package:cabme_driver/controller/dash_board_controller.dart';
import 'package:cabme_driver/controller/subscription_controller.dart';
import 'package:cabme_driver/model/user_model.dart';

import 'package:cabme_driver/page/document_status/document_status_screen.dart';
import 'package:cabme_driver/page/new_ride_screens/new_ride_screen.dart';
import 'package:cabme_driver/page/subscription_plan_screen/subscription_plan_screen.dart';
import 'package:cabme_driver/themes/constant_colors.dart';
import 'package:cabme_driver/themes/responsive.dart';
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

Drawer buildAppDrawer(BuildContext context, DashBoardController controller) {
  final themeChange = Provider.of<DarkThemeProvider>(context);
  var drawerOptions = <Widget>[];
  for (var i = 0; i < controller.drawerItems.length; i++) {
    var d = controller.drawerItems[i];
    drawerOptions.add(
      InkWell(
        onTap: () {
          controller.onSelectItem(i, d.title != 'Log Out');
        },
        // onTap: d.navigate,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Visibility(
              visible: d.section != null,
              child: Padding(
                padding: const EdgeInsets.only(top: 30, bottom: 10, left: 16),
                child: Text(
                  d.section ?? '',
                  style: TextStyle(
                    color: themeChange.getThem() ? AppThemeData.grey500Dark : AppThemeData.grey300Dark,
                    fontSize: 14,
                    fontFamily: AppThemeData.regular,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: (i == (controller.drawerItems.length - 1)) ? 16 : 0),
                    child: Row(mainAxisAlignment: MainAxisAlignment.start, children: [
                      SvgPicture.asset(
                        d.icon,
                        width: 24,
                        height: 24,
                        colorFilter: ColorFilter.mode(
                          i == (controller.drawerItems.length - 1)
                              ? AppThemeData.error50
                              : i == 0
                                  ? AppThemeData.primary200
                                  : themeChange.getThem()
                                      ? AppThemeData.grey900Dark
                                      : AppThemeData.grey900,
                          BlendMode.srcIn,
                        ),
                      ),
                      const SizedBox(
                        width: 16,
                      ),
                      Text(
                        d.title,
                        style: TextStyle(
                          color: i == (controller.drawerItems.length - 1)
                              ? AppThemeData.error50
                              : i == 0
                                  ? AppThemeData.primary200
                                  : themeChange.getThem()
                                      ? AppThemeData.grey900Dark
                                      : AppThemeData.grey900,
                          fontSize: 16,
                          fontFamily: AppThemeData.medium,
                        ),
                      ),
                    ]),
                  ),
                  d.isSwitch == true
                      ? SizedBox(
                          height: 25,
                          child: Switch(
                            trackOutlineColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
                              return Colors.transparent;
                            }),
                            inactiveTrackColor: themeChange.getThem() ? AppThemeData.grey300Dark : AppThemeData.grey300,
                            activeTrackColor: AppThemeData.primary200,
                            thumbColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
                              return themeChange.getThem() ? AppThemeData.grey50 : AppThemeData.grey50Dark;
                              return themeChange.getThem() ? AppThemeData.grey50 : AppThemeData.grey50Dark;
                            }),
                            value: themeChange.getThem(),
                            onChanged: (value) => (themeChange.darkTheme = value == true ? 0 : 1),
                          ),
                        )
                      : SvgPicture.asset(
                          'assets/icons/ic_right_arrow.svg',
                          width: 20,
                          height: 20,
                          colorFilter: ColorFilter.mode(
                            themeChange.getThem() ? AppThemeData.grey400Dark : AppThemeData.grey400,
                            BlendMode.srcIn,
                          ),
                        ),
                ],
              ),
            ),
            if ((controller.drawerItems.length - 2) > i)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                height: 0.5,
                color: themeChange.getThem() ? AppThemeData.grey200Dark : AppThemeData.grey200,
              )
          ],
        ),
      ),
    );
  }

  final userData = controller.userModel.value.userData;
  final bool hasPhoto = userData?.photoPath?.isNotEmpty == true;
  final String photoUrl = hasPhoto ? userData!.photoPath! : (Constant.placeholderUrl ?? '');
  String displayName = userData != null ? "${userData.prenom ?? ''} ${userData.nom ?? ''}".trim() : "Guest User";
  if (displayName.isEmpty) displayName = "Guest User";
  final String displayEmail = userData?.email ?? "guest@fiinway.com";

  return Drawer(
    width: Responsive.width(85, context),
    backgroundColor: themeChange.getThem() ? AppThemeData.surface50Dark : AppThemeData.surface50,
    child: ListView(
      padding: EdgeInsets.zero,
      children: [
        const SizedBox(height: 40),
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: InkWell(
                      onTap: () {},
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(80.0),
                        child: !hasPhoto
                            ? CachedNetworkImage(
                                imageUrl: Constant.placeholderUrl ?? '',
                                height: 80,
                                width: 80,
                                fit: BoxFit.cover,
                                progressIndicatorBuilder: (context, url, downloadProgress) => Center(
                                  child: CircularProgressIndicator(value: downloadProgress.progress),
                                ),
                                errorWidget: (context, url, error) => Image.asset(
                                  "assets/images/appIcon.png",
                                ),
                              )
                            : CachedNetworkImage(
                                imageUrl: photoUrl,
                                height: 80,
                                width: 80,
                                fit: BoxFit.cover,
                                progressIndicatorBuilder: (context, url, downloadProgress) => Center(
                                  child: CircularProgressIndicator(value: downloadProgress.progress),
                                ),
                                errorWidget: (context, url, error) => Image.asset(
                                  "assets/images/appIcon.png",
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: TextStyle(
                            color: themeChange.getThem() ? AppThemeData.grey900Dark : AppThemeData.grey900,
                            fontSize: 22,
                            fontFamily: AppThemeData.regular,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            displayEmail,
                            style: TextStyle(
                              color: themeChange.getThem() ? AppThemeData.grey500Dark : AppThemeData.grey500,
                              fontSize: 14,
                              fontFamily: AppThemeData.regular,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 10),
            if (Constant.subscriptionModel == true || Constant.adminCommission?.statut == "yes")
              Visibility(
                visible: controller.userModel.value.userData?.subscriptionPlanId?.isNotEmpty == true,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SubscriptionPlanWidget(
                    onClick: () {
                      Get.delete<SubscriptionController>();
                      Get.to(SubscriptionPlanScreen(
                        isbackButton: true,
                      ));
                    },
                    userModel: controller.userModel.value,
                  ),
                ),
              ),
            Column(children: drawerOptions),
          ],
        ),
      ],
    ),
  );
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
                      imageUrl: userModel.userData!.subscriptionPlan?.image ?? '',
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
                                  userModel.userData!.subscriptionPlan?.name ?? '',
                                  style: TextStyle(
                                    color: themeChange.getThem() ? AppThemeData.grey900 : AppThemeData.grey50,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: AppThemeData.semiBold,
                                  ),
                                ),
                                Text(
                                  userModel.userData!.subscriptionPlan?.type == 'free'
                                      ? userModel.userData!.subscriptionPlan?.description ?? ''
                                      : Constant().amountShow(amount: userModel.userData!.subscriptionPlan?.price),
                                  style: TextStyle(
                                    fontFamily: AppThemeData.medium,
                                    fontSize: 14,
                                    color: AppThemeData.grey400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (userModel.userData!.subscriptionPlan?.type == 'paid')
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
                                  userModel.userData?.subscriptionPlan?.expiryDay == "-1" ? "LifeTime" : userModel.userData?.subscriptionExpiryDate ?? '',
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
                      userModel.userData?.adminCommission != null
                          ? "${userModel.userData?.adminCommission?.type == 'Percentage' ? "${userModel.userData?.adminCommission?.value} %" : "${Constant().amountShow(amount: userModel.userData?.adminCommission?.value)} Flat"} ${"admin commission will be charged from your account after the ride/parcel booking is completed".tr}"
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
                if (type == "document") {
                  Get.back();
                  Get.to(() => DocumentStatusScreen());
                } else {
                  Get.back();
                  // Driver onboarding has been moved to the web dashboard.
                  Get.snackbar("Information".tr, "Please complete your onboarding on the web panel.".tr);
                }
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
