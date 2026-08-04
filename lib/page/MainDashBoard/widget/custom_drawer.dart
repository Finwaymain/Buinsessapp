import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../../../constant/constant.dart';
import '../../../constant/image_constant.dart';
import '../../../controller/dash_board_controller.dart';
import '../../../controller/subscription_controller.dart';
import '../../../themes/constant_colors.dart';
import '../../../utils/Preferences.dart';
import '../../../utils/dark_theme_provider.dart';
import '../../auth_screens/phone_entry_screen.dart';
import '../../subscription_plan_screen/subscription_plan_screen.dart' as subs;

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isLogin = Preferences.getBoolean(Preferences.isLogin) ?? false;
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final bool isDark = themeChange.getThem();
    final dashBoardController = Get.put(DashBoardController());

    var drawerOptions = <Widget>[];
    for (var i = 0; i < dashBoardController.drawerItems.length; i++) {
      var d = dashBoardController.drawerItems[i];
      if (d.title == 'Log Out' && !isLogin) {
        continue;
      }
      drawerOptions.add(InkWell(
        onTap: () {
          dashBoardController.onSelectItem(i, isLogin);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  SvgPicture.asset(
                    d.icon,
                    width: 20,
                    height: 20,
                    colorFilter: ColorFilter.mode(
                      dashBoardController.selectedDrawerIndex.value == i
                          ? AppThemeData.primary200
                          : themeChange.getThem()
                              ? AppThemeData.grey400Dark
                              : AppThemeData.grey400,
                      BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    d.title,
                    style: TextStyle(
                      color: dashBoardController.selectedDrawerIndex.value == i
                          ? AppThemeData.primary200
                          : themeChange.getThem()
                              ? AppThemeData.grey900Dark
                              : AppThemeData.grey900,
                      fontSize: 15,
                      fontFamily: AppThemeData.medium,
                    ),
                  ),
                ],
              ),
              SvgPicture.asset(
                'assets/icons/ic_right_arrow.svg',
                width: 18,
                height: 18,
                colorFilter: ColorFilter.mode(
                  themeChange.getThem() ? AppThemeData.grey400Dark : AppThemeData.grey400,
                  BlendMode.srcIn,
                ),
              ),
            ],
          ),
        ),
      ));
    }

    return Drawer(
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Drawer Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(left: 16, right: 16, top: 50, bottom: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppThemeData.primary200,
                    AppThemeData.primary200.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        height: 60,
                        width: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(60.0),
                          child: isLogin
                              ? CachedNetworkImage(
                                  imageUrl: (dashBoardController.userModel.value.userData?.photoPath?.isNotEmpty == true)
                                      ? dashBoardController.userModel.value.userData!.photoPath!
                                      : (Constant.placeholderUrl ?? ''),
                                  height: double.infinity,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorWidget: (context, url, error) => Image.asset(
                                    ImageConstant.logo,
                                    height: double.infinity,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Container(
                                  color: Colors.grey[400],
                                  child: const Icon(Icons.person, size: 40, color: Colors.white),
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isLogin
                                  ? "${dashBoardController.userModel.value.userData?.prenom ?? ''} ${dashBoardController.userModel.value.userData?.nom ?? ''}"
                                  : "Guest User",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppThemeData.surface50,
                                fontSize: 16,
                                fontFamily: AppThemeData.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isLogin
                                  ? "${(dashBoardController.userModel.value.userData?.phone ?? 'guest')}@fiinway.com".toLowerCase()
                                  : "guest@fiinway.com",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppThemeData.surface50.withValues(alpha: 0.8),
                                fontSize: 11,
                                fontFamily: AppThemeData.regular,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ALWAYS VISIBLE: Change / Upgrade Plan Card in Side Drawer Header
            GestureDetector(
              onTap: () {
                Get.back(); // close drawer
                Get.delete<SubscriptionController>();
                Get.to(() => const subs.SubscriptionPlanScreen(isbackButton: true));
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppThemeData.primary200, width: 1.5),
                  boxShadow: [
                    BoxShadow(color: AppThemeData.primary200.withValues(alpha: 0.12), blurRadius: 6, offset: const Offset(0, 2)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppThemeData.primary200.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.workspace_premium_rounded, color: AppThemeData.primary200, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'My Membership & Upgrade Plan',
                            style: TextStyle(
                              color: isDark ? Colors.white : AppThemeData.grey900,
                              fontSize: 13,
                              fontFamily: AppThemeData.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Change plan & view active benefits',
                            style: TextStyle(
                              color: themeChange.getThem() ? AppThemeData.grey400Dark : AppThemeData.grey500,
                              fontSize: 11,
                              fontFamily: AppThemeData.regular,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded, color: AppThemeData.primary200, size: 14),
                  ],
                ),
              ),
            ),

            const Divider(height: 1),

            Column(children: drawerOptions),
          ],
        ),
      ),
    );
  }
}
