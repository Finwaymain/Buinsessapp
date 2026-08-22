import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';

class ShowToastDialog {
  static void showToast(
      String? message, {
        bool isError = false,
        bool isWarning = false,
      }) {
    if (message == null) return;
    String msg = message.trim();
    if (msg.isEmpty || msg.toLowerCase() == "null") return;

    // Ignore internal dev/placeholder exceptions from propagating to UI
    if (msg.contains("Failed to load album") ||
        msg.contains("Null check operator") ||
        msg.contains("null check operator") ||
        msg.contains("type cast") ||
        msg.contains("is not a subtype") ||
        msg.contains("Exception")) {
      debugPrint("Silent Toast Blocked: $msg");
      return;
    }

    String lowerMsg = msg.toLowerCase();
    bool actualError = isError ||
        lowerMsg.contains("error") ||
        lowerMsg.contains("fail") ||
        lowerMsg.contains("invalid") ||
        lowerMsg.contains("incorrect") ||
        lowerMsg.contains("not found") ||
        lowerMsg.contains("not match") ||
        lowerMsg.contains("denied") ||
        lowerMsg.contains("unauthorized") ||
        lowerMsg.contains("rejected") ||
        lowerMsg.contains("insufficient") ||
        lowerMsg.contains("declined") ||
        lowerMsg.contains("expire") ||
        lowerMsg.contains("cancel") ||
        lowerMsg.contains("already exist") ||
        lowerMsg.contains("wrong") ||
        lowerMsg.contains("blocked") ||
        lowerMsg.contains("unable") ||
        lowerMsg.contains("timeout") ||
        lowerMsg.contains("could not") ||
        lowerMsg.contains("required") ||
        lowerMsg.contains("please enter") ||
        lowerMsg.contains("please select") ||
        lowerMsg.contains("something went wrong") ||
        lowerMsg.contains("something want wrong");

    bool actualWarning = isWarning ||
        (!actualError && (lowerMsg.contains("warning") || lowerMsg.contains("caution") || lowerMsg.contains("alert") || lowerMsg.contains("attention") || lowerMsg.contains("pending")));

    Get.snackbar(
      actualError
          ? "Error".tr
          : actualWarning
          ? "Warning".tr
          : "Success".tr,
      msg.tr,
      snackPosition: SnackPosition.TOP,
      backgroundColor: actualError
          ? Colors.redAccent.shade700
          : actualWarning
          ? Colors.amber.shade700
          : Colors.green.shade600,
      colorText: Colors.white,
      icon: Icon(
        actualError
            ? Icons.error_outline_rounded
            : actualWarning
            ? Icons.warning_amber_rounded
            : Icons.check_circle_outline_rounded,
        color: Colors.white,
      ),
      margin: const EdgeInsets.all(12),
      borderRadius: 10,
      duration: const Duration(seconds: 3),
    );
  }

  static void showLoader(String message) {
    EasyLoading.show(
      status: message.tr,
      dismissOnTap: false,
      maskType: EasyLoadingMaskType.clear,
    );
  }

  static void closeLoader() {
    EasyLoading.dismiss();
  }
}


// import 'package:flutter_easyloading/flutter_easyloading.dart';
// import 'package:get/get.dart';
//
// class ShowToastDialog {
//   static showToast(String? message, {EasyLoadingToastPosition position = EasyLoadingToastPosition.top}) {
//     EasyLoading.showToast(message!.tr, toastPosition: position);
//   }
//
//   static showLoader(String message) {
//     EasyLoading.show(
//       status: message.tr,
//       dismissOnTap: false,
//       maskType: EasyLoadingMaskType.clear,
//     );
//   }
//
//   static closeLoader() {
//     EasyLoading.dismiss();
//   }
// }


// import 'package:flutter_easyloading/flutter_easyloading.dart';
// import 'package:get/get.dart';
//
// class ShowToastDialog {
//   static showToast(String? message, {EasyLoadingToastPosition position = EasyLoadingToastPosition.top}) {
//     EasyLoading.showToast(message!.tr, toastPosition: position);
//   }
//
//   static showLoader(String message) {
//     EasyLoading.show(
//       status: message.tr,
//       dismissOnTap: false,
//       maskType: EasyLoadingMaskType.clear,
//     );
//   }
//
//   static showBlackLoader(String message) {
//     EasyLoading.show(
//       status: message.tr,
//       maskType: EasyLoadingMaskType.black,
//     );
//   }
//
//   static closeLoader() {
//     EasyLoading.dismiss();
//   }
// }
