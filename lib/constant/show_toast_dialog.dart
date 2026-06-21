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
        msg.contains("Exception:")) {
      debugPrint("Silent Toast Blocked: $msg");
      return;
    }

    Get.snackbar(
      isError
          ? "Error"
          : isWarning
          ? "Warning"
          : "Success",
      msg,
      snackPosition: SnackPosition.TOP,
      backgroundColor: isError
          ? Colors.redAccent
          : isWarning
          ? Colors.amber
          : Colors.green,
      colorText: Colors.white,
      margin: const EdgeInsets.all(12),
      borderRadius: 8,
      duration: const Duration(seconds: 2),
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
