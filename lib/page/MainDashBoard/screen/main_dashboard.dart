import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
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
import '../../../controller/dash_board_controller.dart';
import '../../../utils/Preferences.dart';
import '../../auth_screens/phone_entry_screen.dart';
import '../../web_view_screen/web_view_screen.dart';

class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _bootstrapAndMaybeRedirect();
  }

  // Drivers whose onboarding categories are entirely non-Transport & Mobility
  // (home services, repairs, etc.) get the web-based dashboard instead of this
  // native taxi-style shell — they're auto-approved on submit and never use
  // the ride-matching flow this screen's tabs are built around.
  Future<void> _bootstrapAndMaybeRedirect() async {
    final dashboardController = Get.find<DashBoardController>();
    final refreshed = await dashboardController.getUsrData();
    if (!refreshed || !mounted) return;

    final userData = dashboardController.userModel.value.userData;
    if (userData?.onboardingCompleted == 'yes' && userData?.isTransportCategory == false) {
      final token = userData?.accesstoken ?? '';
      final driverId = userData?.id ?? '';
      final url = 'https://fiinway.online/onboarding/dashboard?accesstoken=$token&driver_id=$driverId';
      Get.offAll(() => WebViewScreen(url: url, title: 'Dashboard', showAppBar: false));
    }
  }

  final List<Widget> _screens =  [
    MainHomeScreen(),
    const AddressSearchScreen(isTab: true),
    const InProgressScreen(), // Center fingerprint button (index 2) does not use this screen directly
    NewRideScreen(isTab: true),
    WalletScreen(isTab: true),
  ];

  void _onTabSelected(int index) {
    if (index != 0) {
      if (!(Preferences.getBoolean(Preferences.isLogin) ?? false)) {
        Get.to(() => PhoneEntryScreen(mode: 'signup'), transition: Transition.rightToLeftWithFade);
        return;
      }
    }
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
