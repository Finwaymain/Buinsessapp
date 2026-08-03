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
              return Obx(() {
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () async {
                    final refreshed = await controllerDashBoard.getUsrData();
                    if (!refreshed) {
                      ShowToastDialog.showToast("Couldn't refresh your status. Please check your connection and try again.".tr);
                      return;
                    }
                    final userData = controllerDashBoard.userModel.value.userData!;
                    if (userData.statutVehicule == "no") {
                      showAlertDialog(context, "vehicleInformation");
                    } else if (userData.isVerified != "yes") {
                      showAlertDialog(context, "pendingApproval");
                    } else {
                      showActiveServicesDialog(context, controllerDashBoard, isDarkMode);
                    }
                  },
                  child: Row(
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
                      const SizedBox(width: 4),
                      IgnorePointer(
                        child: Transform.scale(
                          scale: 0.8,
                          child: Switch(
                            value: controllerDashBoard.isActive.value,
                            activeThumbColor: AppThemeData.success300,
                            inactiveTrackColor: AppThemeData.warning200,
                            onChanged: (value) {},
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              });
            },
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

void showActiveServicesDialog(BuildContext context, DashBoardController controllerDashBoard, bool isDarkMode) {
  controllerDashBoard.fetchDriverServices();

  showDialog(
    context: context,
    builder: (context) {
      return Obx(() {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: isDarkMode ? const Color(0xFF1E1C15) : const Color(0xFFFFFDF5),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Duty Status & Services".tr,
                      style: TextStyle(
                        fontSize: 18,
                        fontFamily: AppThemeData.bold,
                        color: isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: isDarkMode ? Colors.white : Colors.black),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF2A2822) : const Color(0xFFF9F6EE),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppThemeData.primary200.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Duty Status".tr,
                              style: TextStyle(
                                fontSize: 14,
                                fontFamily: AppThemeData.bold,
                                color: isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              (controllerDashBoard.isActive.value ? "You are Online" : "You are Offline").tr,
                              style: TextStyle(
                                fontSize: 11,
                                fontFamily: AppThemeData.regular,
                                color: controllerDashBoard.isActive.value
                                    ? AppThemeData.success300
                                    : AppThemeData.warning200,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Transform.scale(
                        scale: 0.85,
                        child: Switch(
                          value: controllerDashBoard.isActive.value,
                          activeThumbColor: Colors.white,
                          activeTrackColor: AppThemeData.success300,
                          inactiveThumbColor: Colors.white,
                          inactiveTrackColor: isDarkMode ? const Color(0xFF333333) : const Color(0xFFCCCCCC),
                          onChanged: (value) async {
                            final userData = controllerDashBoard.userModel.value.userData!;
                            if (userData.statutVehicule == "no") {
                              showAlertDialog(context, "vehicleInformation");
                            } else if (userData.isVerified != "yes") {
                              showAlertDialog(context, "pendingApproval");
                            } else {
                              ShowToastDialog.showLoader("Please wait");
                              Map<String, dynamic> bodyParams = {
                                'id_driver': Preferences.getInt(Preferences.userId),
                                'online': controllerDashBoard.isActive.value ? 'no' : 'yes',
                              };
                              await controllerDashBoard.changeOnlineStatus(bodyParams).then((res) {
                                if (res != null) {
                                  if (res['success'] == "success") {
                                    UserModel userModel = Constant.getUserData();
                                    userModel.userData!.online = res['data']['online'];
                                    controllerDashBoard.userModel.value = userModel;
                                    Preferences.setString(Preferences.user, jsonEncode(userModel.toJson()));
                                    controllerDashBoard.isActive.value = userModel.userData!.online == 'no' ? false : true;
                                    ShowToastDialog.showToast(res['message']);
                                  } else {
                                    ShowToastDialog.showToast(res['error']);
                                  }
                                }
                              });
                              ShowToastDialog.closeLoader();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Active Services".tr,
                  style: TextStyle(
                    fontSize: 15,
                    fontFamily: AppThemeData.bold,
                    color: isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Toggle on/off the service types you want to receive requests for.".tr,
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: AppThemeData.regular,
                    color: isDarkMode ? AppThemeData.grey500Dark : AppThemeData.grey500,
                  ),
                ),
                const SizedBox(height: 12),
                if (controllerDashBoard.isLoadingServices.value)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (controllerDashBoard.driverServices.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(
                        "No services found".tr,
                        style: TextStyle(
                          fontSize: 13,
                          fontFamily: AppThemeData.medium,
                          color: isDarkMode ? AppThemeData.grey500Dark : AppThemeData.grey500,
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    constraints: const BoxConstraints(maxHeight: 250),
                    decoration: BoxDecoration(
                      color: isDarkMode ? const Color(0xFF2A2822) : const Color(0xFFF9F6EE),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppThemeData.primary200.withOpacity(0.15),
                        width: 1,
                      ),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: controllerDashBoard.driverServices.length,
                      separatorBuilder: (context, index) => Divider(
                        height: 1,
                        color: isDarkMode ? const Color(0xFF3A3832) : const Color(0xFFEFECE4),
                      ),
                      itemBuilder: (context, index) {
                        final service = controllerDashBoard.driverServices[index];
                        final String title = service['title'] ?? 'Service';
                        final dynamic categoryId = service['subcategory_id'] ?? service['category_id'];
                        final bool isServiceActive = service['statut'] == 'yes';

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title.tr,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontFamily: AppThemeData.medium,
                                        color: isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      (isServiceActive ? "Receiving requests" : "Offline").tr,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontFamily: AppThemeData.regular,
                                        color: isServiceActive
                                            ? AppThemeData.success300
                                            : AppThemeData.warning200,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Transform.scale(
                                scale: 0.85,
                                child: Switch(
                                  value: isServiceActive,
                                  activeThumbColor: Colors.white,
                                  activeTrackColor: AppThemeData.success300,
                                  inactiveThumbColor: Colors.white,
                                  inactiveTrackColor: isDarkMode ? const Color(0xFF333333) : const Color(0xFFCCCCCC),
                                  onChanged: (bool value) async {
                                    final String newStatus = value ? 'yes' : 'no';
                                    await controllerDashBoard.toggleService(categoryId, newStatus);
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      });
    },
  );
}
