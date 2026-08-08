import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../../../controller/login_conroller.dart';
import '../../../utils/dark_theme_provider.dart';
import '../../../utils/driver_dashboard_route.dart';
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
import '../../../utils/onboarding_url.dart';
import '../../auth_screens/phone_entry_screen.dart';
import '../../web_view_screen/web_view_screen.dart';

enum _DashboardMode { loading, native, web }

class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  int currentIndex = 0;
  _DashboardMode _mode = _DashboardMode.loading;

  @override
  void initState() {
    super.initState();
    _resolveDashboard();
  }

  Future<void> _resolveDashboard() async {
    final dashboardController = Get.find<DashBoardController>();
    final refreshed = await dashboardController.getUsrData();
    if (!mounted) return;

    final userData = refreshed ? dashboardController.userModel.value.userData : null;
    setState(() {
      _mode = shouldUseWebDashboard(userData) ? _DashboardMode.web : _DashboardMode.native;
    });
  }

  final List<Widget> _screens = [
    MainHomeScreen(),
    const AddressSearchScreen(isTab: true),
    const InProgressScreen(),
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
    if (controller.getLoginStatus(inProgress: false)) {
      Get.to(
        () => ScannerAndTransferScreen(),
        transition: Transition.rightToLeft,
        duration: const Duration(milliseconds: 500),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_mode == _DashboardMode.loading) {
      final themeChange = Provider.of<DarkThemeProvider>(context);
      final isDarkMode = themeChange.getThem();
      return Scaffold(
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_mode == _DashboardMode.web) {
      final url = OnboardingUrl.build('/onboarding/dashboard');
      return WebViewScreen(url: url, title: 'Dashboard', showAppBar: false);
    }

    final themeChange = Provider.of<DarkThemeProvider>(context);
    final bool isDarkMode = themeChange.getThem();

    return GetBuilder(
      init: LoginController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: isDarkMode ? Colors.black : Colors.white,
          appBar: CustomAppBar(),
          drawer: CustomDrawer(),
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
                  onFingerprintTap: () {
                    _onFingerprintTap(Get.put(MainHomeController()));
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void showDialogPermission(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const LocationPermissionDisclosureDialog(),
    );
  }
}
