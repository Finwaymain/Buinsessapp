import 'package:cabme_driver/page/web_view_screen/web_view_screen.dart';
import 'package:cabme_driver/utils/onboarding_url.dart';
import 'package:get/get.dart';

void openDriverWebWallet({String title = 'Smart Value Wallet'}) {
  final url = OnboardingUrl.build('/wallet', extra: {'user_type': 'driver'});
  Get.to(() => WebViewScreen(url: url, title: title));
}
