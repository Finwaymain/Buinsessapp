import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../constant/constant.dart';
import '../../../constant/show_toast_dialog.dart';
import '../../../controller/dash_board_controller.dart';
import '../../../controller/new_ride_controller.dart';
import '../../../model/user_model.dart';
import '../../../themes/constant_colors.dart';
import '../../../utils/Preferences.dart';
import '../../../utils/dark_theme_provider.dart';
import 'package:get/get.dart';

import '../../features/Taxi/taxi_dashboard/taxi_dashboard.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    bool isDarkMode = themeChange.getThem();
    final controllerDashBoard = Get.put(DashBoardController());

    return AppBar(
      elevation: 0,
      leading: Builder(
        builder: (context) => IconButton(
          icon: Icon(
            Icons.menu,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
          onPressed: () => Scaffold.of(context).openDrawer(), // ✅ Correct
        ),
      ),
      title: Row(
        children: [
          RichText(
            text: TextSpan(
              text: 'Fiin',
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
              children: [
                TextSpan(
                  text: 'way',
                  style: TextStyle(color: AppThemeData.primary200),
                ),
                TextSpan(
                  text: ' Business',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ),
          Spacer(),

          GetX<NewRideController>(
            init: NewRideController(),
            builder: (controller) {
              if (controller.userModel.value.userData == null) {
                return SizedBox(); // Return empty widget if data is not ready
              }
              return Row(
                children: [
                  Text(
                    "Status".tr,
                    style: TextStyle(
                      color: themeChange.getThem()
                          ? AppThemeData.grey500Dark
                          : AppThemeData.grey500,
                      fontFamily: AppThemeData.regular,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(
                    width: 4,
                  ),
                  Transform.scale(
                    scale: 0.8,
                    child: Switch(
                      value: controllerDashBoard.isActive.value,
                      activeThumbColor: AppThemeData.success300,
                      inactiveTrackColor: AppThemeData.warning200,
                      onChanged: (value) async {
                        await controllerDashBoard.getUsrData();
                        if (controllerDashBoard
                                .userModel.value.userData!.statutVehicule ==
                            "no") {
                          showAlertDialog(context, "vehicleInformation");
                        } else {
                          ShowToastDialog.showLoader("Please wait");

                          Map<String, dynamic> bodyParams = {
                            'id_driver': Preferences.getInt(Preferences.userId),
                            'online': controllerDashBoard.isActive.value
                                ? 'no'
                                : 'yes',
                          };

                          await controllerDashBoard
                              .changeOnlineStatus(bodyParams)
                              .then((value) {
                            if (value != null) {
                              if (value['success'] == "success") {
                                UserModel userModel = Constant.getUserData();
                                userModel.userData!.online =
                                    value['data']['online'];
                                controller.userModel.value = userModel;
                                Preferences.setString(Preferences.user,
                                    jsonEncode(userModel.toJson()));
                                controllerDashBoard.isActive.value =
                                    userModel.userData!.online == 'no'
                                        ? false
                                        : true;
                                ShowToastDialog.showToast(value['message']);
                              } else {
                                ShowToastDialog.showToast(value['error']);
                              }
                            }
                          });

                          ShowToastDialog.closeLoader();
                        }
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
