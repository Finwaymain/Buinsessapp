import 'package:cabme_driver/controller/terms_of_service_controller.dart';
import 'package:cabme_driver/themes/app_bar_custom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:get/get.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetX<TermsOfServiceController>(
        init: TermsOfServiceController(),
        builder: (controller) {
          return Scaffold(
            appBar: AppbarCustom(
              title: 'Terms & Conditions'.tr,
              elevation: 0,
            ),
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: controller.termsData.value.isNotEmpty
                    ? Html(
                        data: controller.termsData.value,
                      )
                    : const Offstage(),
              ),
            ),
          );
        });
  }
}
