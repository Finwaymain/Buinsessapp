import 'package:cabme_driver/controller/dash_board_controller.dart';
import 'package:cabme_driver/controller/my_profile_controller.dart';
import 'package:cabme_driver/page/web_view_screen/web_view_screen.dart';
import 'package:cabme_driver/utils/onboarding_url.dart';
import 'package:get/get.dart';

void openDriverOnboardingEditor({
  String mode = 'edit_profile',
  String title = 'Edit Profile & Services',
}) {
  final url = OnboardingUrl.build('/onboarding', extra: {
    'mode': mode,
    'edit': '1',
  });

  Get.to(() => WebViewScreen(url: url, title: title))?.then((_) {
    if (Get.isRegistered<MyProfileController>()) {
      Get.find<MyProfileController>().getUsrData();
    }
    if (Get.isRegistered<DashBoardController>()) {
      Get.find<DashBoardController>().getUsrData();
    }
  });
}
