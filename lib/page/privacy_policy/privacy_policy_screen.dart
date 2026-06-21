import 'package:cabme_driver/controller/privacy_policy_controller.dart';
import 'package:cabme_driver/themes/app_bar_custom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:get/get.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetX<PrivacyPolicyController>(
        init: PrivacyPolicyController(),
        builder: (controller) {
          return Scaffold(
            appBar: AppbarCustom(
              title: 'Privacy & Policy'.tr,
              elevation: 0,
            ),
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: controller.privacyData.value.isNotEmpty
                    ? Html(
                        data: controller.privacyData.value,
                      )
                    : const Offstage(),
              ),
            ),
          );
        });
  }
}
