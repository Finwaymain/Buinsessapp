import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';
import '../../../constant/show_toast_dialog.dart';
import '../../../controller/login_conroller.dart';
import '../../../utils/dark_theme_provider.dart';
import '../../../widget/permission_dialog.dart';
import '../../home_screen/controller/main_home_controller.dart';
import '../../in_progress_screen.dart';
import '../../features/SmartValue/ScanAndTransfer/view/scanner_and_transfer_screen.dart';
import '../widget/custom_app_bar.dart';
import '../widget/custom_bottom_navbar.dart';
import '../widget/custom_drawer.dart';
import '../../home_screen/view/home_screen.dart';
import '../../wallet/wallet_screen.dart';
import '../../search_location_screen.dart';
import '../../new_ride_screens/new_ride_screen.dart';

class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  int currentIndex = 0;

  final List<Widget> _screens =  [
    NewRideScreen(isTab: true),
    const AddressSearchScreen(isTab: true),
    const InProgressScreen(), // Center fingerprint button (index 2) does not use this screen directly
    MainHomeScreen(),
    WalletScreen(isTab: true),
  ];

  void _onTabSelected(int index) {
    setState(() => currentIndex = index);
  }

  void _onFingerprintTap(MainHomeController controller) {

    if(controller.getLoginStatus(inProgress: false)) {
      Get.to(
            () =>  ScannerAndTransferScreen(),
        transition: Transition.rightToLeft,
        duration: const Duration(milliseconds: 500),
      );
    }

  }

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    bool isDarkMode = themeChange.getThem();

    return GetBuilder(
        init: LoginController(),
        initState: (state) async {
          try {
            PermissionStatus location = await Location().hasPermission();
            if (PermissionStatus.granted != location) {
              showDialogPermission(context);
            }
          } on PlatformException catch (e) {
            ShowToastDialog.showToast("${e.message}");
          }
        },
        builder: (controller) {
          return Scaffold(
            backgroundColor: isDarkMode ? Colors.black : Colors.white,
            appBar: CustomAppBar(),
            drawer:  CustomDrawer(
            ),
            body: Stack(
              children: [
                Positioned.fill(
                  child: IndexedStack(
                    index: currentIndex,
                    children: _screens,
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: CustomBottomNavBar(
                    currentIndex: currentIndex,
                    onTabSelected: _onTabSelected,
                    onFingerprintTap: (){
                      _onFingerprintTap(Get.put(MainHomeController()));
                    },
                  ),
                ),
              ],
            ),
          );
        });
  }

  void showDialogPermission(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const LocationPermissionDisclosureDialog(),
    );
  }
}
