

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../../constant/constant.dart';
import '../../../../../service/api.dart';
import '../../../../../themes/constant_colors.dart';
import '../../../../../utils/Preferences.dart';

class QRController extends GetxController with GetTickerProviderStateMixin {
  // Animation Controllers
  late AnimationController scaleController;
  late AnimationController pulseController;
  late AnimationController fadeController;

  // Animations
  late Animation<double> scaleAnimation;
  late Animation<double> pulseAnimation;
  late Animation<double> fadeAnimation;

  // Loading states
  var isSharing = false.obs;
  var isSaving = false.obs;

  // Global key for capturing QR widget
  GlobalKey qrKey = GlobalKey();

  // QR Data (Reactive RxString so UI updates when backend refreshes)
  final qrData = ''.obs;

  /// Helper to generate a valid NPCI UPI Intent URI for a given account number
  static String buildUpiUri({required String acNo, String? name}) {
    final cleanAcNo = acNo.trim();
    if (cleanAcNo.isEmpty) return '';
    final displayName = (name != null && name.trim().isNotEmpty)
        ? "Fiinway - ${name.trim()}"
        : "Fiinway";
    final encodedPn = Uri.encodeComponent(displayName);
    final encodedTn = Uri.encodeComponent('Fiinway Wallet $cleanAcNo');
    return "upi://pay?pa=fiinway@icici&pn=$encodedPn&mc=5411&tr=$cleanAcNo&tn=$encodedTn&cu=INR";
  }

  /// Ensure the string is a valid UPI URI. If raw numeric ac_no is passed, format it into UPI URI.
  static String sanitizeUpiQr(String? raw, {String? acNo, String? name}) {
    final str = (raw ?? '').trim();
    if (str.startsWith('upi://pay') || (str.contains('pa=') && str.contains('tr='))) {
      return str;
    }
    final effectiveAc = str.isNotEmpty ? str : (acNo ?? '').trim();
    return buildUpiUri(acNo: effectiveAc, name: name);
  }

  @override
  void onInit() {
    super.onInit();
    final user = Constant.getUserData().userData;
    final fullName = "${user?.prenom ?? ''} ${user?.nom ?? ''}".trim();

    String initial = (user?.upiQrData != null && user!.upiQrData!.isNotEmpty)
        ? user.upiQrData!
        : '';

    // Check if arguments override QR data
    final args = Get.arguments;
    if (args != null && args is Map && args['qrData'] != null) {
      initial = args['qrData'].toString();
    }

    // Initialize with guaranteed UPI format so PhonePe/GPay can scan immediately
    qrData.value = sanitizeUpiQr(
      initial,
      acNo: user?.acNo,
      name: fullName,
    );

    print('QR Data initialized: "${qrData.value}"');

    _initializeAnimations();
    _startAnimations();
    _fetchFreshUpiQrData();
  }

  /// Asynchronously fetch the latest UPI QR payload from the backend
  Future<void> _fetchFreshUpiQrData() async {
    try {
      final user = Constant.getUserData().userData;
      final acNo = user?.acNo;
      if (acNo == null || acNo.isEmpty) return;

      final response = await http.post(
        Uri.parse(API.accountDetails),
        headers: API.header,
        body: jsonEncode({"ac_no": acNo}),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['res'] == 'success' && body['data'] != null) {
          final serverUpi = body['data']['upi_qr_data']?.toString();
          if (serverUpi != null && serverUpi.isNotEmpty) {
            qrData.value = serverUpi;
            print('QR Data updated from server: "$serverUpi"');

            // Save to cached user preferences
            final curUser = Constant.getUserData();
            if (curUser.userData != null) {
              curUser.userData!.upiQrData = serverUpi;
              Preferences.setString(Preferences.user, jsonEncode(curUser.toJson()));
            }
          }
        }
      }
    } catch (e) {
      print('Silent refresh of UPI QR failed: $e');
    }
  }

  void _initializeAnimations() {
    scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    scaleAnimation = CurvedAnimation(
      parent: scaleController,
      curve: Curves.elasticOut,
    );

    pulseAnimation = CurvedAnimation(
      parent: pulseController,
      curve: Curves.easeInOut,
    );

    fadeAnimation = CurvedAnimation(
      parent: fadeController,
      curve: Curves.easeOut,
    );
  }

  void _startAnimations() {
    scaleController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      fadeController.forward();
    });
    Future.delayed(const Duration(milliseconds: 1000), () {
      pulseController.repeat(reverse: true);
    });
  }

  Future<Uint8List?> _captureQrPngBytes() async {
    await Future.delayed(const Duration(milliseconds: 100));

    final boundary = qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) {
      _showErrorSnackbar('Unable to capture QR code');
      return null;
    }

    if (boundary.debugNeedsPaint) {
      await Future.delayed(const Duration(milliseconds: 50));
    }

    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = byteData?.buffer.asUint8List();

    if (pngBytes == null) {
      _showErrorSnackbar('Failed to generate QR image');
      return null;
    }

    return pngBytes;
  }

  Future<bool> _ensureGalleryAccess() async {
    if (await Gal.hasAccess(toAlbum: true)) {
      return true;
    }

    final granted = await Gal.requestAccess(toAlbum: true);
    if (granted) {
      return true;
    }

    _showErrorSnackbar('Allow photo access to save QR code to gallery');
    return false;
  }

  // Share QR Code functionality
  Future<void> shareQR() async {
    try {
      isSharing.value = true;
      HapticFeedback.lightImpact();

      final pngBytes = await _captureQrPngBytes();
      if (pngBytes == null) {
        return;
      }

      // Save to temporary directory
      final tempDir = await getTemporaryDirectory();
      final fileName = 'qr_code_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(pngBytes);

      // Verify file was created
      if (!await file.exists()) {
        _showErrorSnackbar('Failed to create temporary file');
        return;
      }

      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Scan this QR code to connect with me!',
        subject: 'My QR Code',
      );

      _showSuccessSnackbar('QR code shared successfully!');
    } catch (e) {
      print('Share error: $e'); // Debug print
      _showErrorSnackbar('Failed to share QR code: ${e.toString()}');
    } finally {
      isSharing.value = false;
    }
  }

  // Copy QR data to clipboard
  Future<void> copyQRData() async {
    try {
      HapticFeedback.lightImpact();

      // Check if QR data is available
      final dataToCopy = qrData.value;
      if (dataToCopy.isEmpty) {
        _showErrorSnackbar('No QR data available to copy');
        return;
      }

      // Copy to clipboard
      await Clipboard.setData(ClipboardData(text: dataToCopy));

      // Verify clipboard data
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      if (clipboardData?.text == dataToCopy) {
        _showSuccessSnackbar('QR data copied to clipboard!\n"${dataToCopy.length > 50 ? '${dataToCopy.substring(0, 50)}...' : dataToCopy}"');
      } else {
        _showErrorSnackbar('Failed to verify clipboard data');
      }

    } catch (e) {
      print('Clipboard error: $e'); // Debug print
      _showErrorSnackbar('Failed to copy QR data: ${e.toString()}');
    }
  }


  Future<void> saveQR() async {
    try {
      isSaving.value = true;
      HapticFeedback.lightImpact();

      final pngBytes = await _captureQrPngBytes();
      if (pngBytes == null) {
        return;
      }

      if (!await _ensureGalleryAccess()) {
        return;
      }

      final fileName = 'Fiinway_QR_${DateTime.now().millisecondsSinceEpoch}';
      await Gal.putImageBytes(pngBytes, name: fileName);

      _showSuccessSnackbar(
        Platform.isIOS ? 'QR code saved to Photos' : 'QR code saved to gallery',
      );
    } on GalException catch (e) {
      print('Save error: $e');
      _showErrorSnackbar(_galleryErrorMessage(e));
    } catch (e) {
      print('Save error: $e');
      _showErrorSnackbar('Failed to save QR code. Please try again.');
    } finally {
      isSaving.value = false;
    }
  }

  String _galleryErrorMessage(GalException e) {
    switch (e.type) {
      case GalExceptionType.accessDenied:
        return 'Photo access denied. Enable it in settings to save QR code.';
      case GalExceptionType.notEnoughSpace:
        return 'Not enough storage space to save QR code.';
      case GalExceptionType.notSupportedFormat:
        return 'Unsupported image format while saving QR code.';
      case GalExceptionType.unexpected:
        return 'Could not save QR code. Please try again.';
    }
  }




  // Navigate back
  void goBack() {
    HapticFeedback.lightImpact();
    Get.back();
  }

  // Show success snackbar
  void _showSuccessSnackbar(String message) {
    Get.snackbar(
      'Success',
      message,
      backgroundColor: AppThemeData.primary200.withValues(alpha: 0.9),
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      icon: const Icon(Icons.check_circle, color: Colors.white),
    );
  }

  // Show error snackbar
  void _showErrorSnackbar(String message) {
    Get.snackbar(
      'Error',
      message,
      backgroundColor: Colors.red.withValues(alpha: 0.9),
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      icon: const Icon(Icons.error, color: Colors.white),
    );
  }

  @override
  void onClose() {
    scaleController.dispose();
    pulseController.dispose();
    fadeController.dispose();
    super.onClose();
  }
}


//
//
// import 'dart:io';
// import 'dart:ui' as ui;
//
// import 'package:flutter/material.dart';
// import 'package:flutter/rendering.dart';
// import 'package:flutter/services.dart';
// import 'package:get/get.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:share_plus/share_plus.dart';
//
// import '../../../../../themes/constant_colors.dart';
//
// class QRController extends GetxController with GetTickerProviderStateMixin {
//   // Animation Controllers
//   late AnimationController scaleController;
//   late AnimationController pulseController;
//   late AnimationController fadeController;
//
//   // Animations
//   late Animation<double> scaleAnimation;
//   late Animation<double> pulseAnimation;
//   late Animation<double> fadeAnimation;
//
//   // Loading states
//   var isSharing = false.obs;
//   var isSaving = false.obs;
//
//   // Global key for capturing QR widget
//   GlobalKey qrKey = GlobalKey();
//
//   // QR Data
//   String qrData = 'https://www.linkedin.com/in/programmerfiroz/';
//
//   @override
//   void onInit() {
//     super.onInit();
//
//     // Get QR data from arguments with better handling
//     final args = Get.arguments;
//     if (args != null && args is Map) {
//       qrData = args['qrData']?.toString() ?? '';
//     }
//
//     // Debug print to check QR data
//     print('QR Data received: "$qrData"'); // Debug print
//
//     if (qrData.isEmpty) {
//       print('Warning: QR data is empty!'); // Debug print
//       // You can set a default value or show error
//       // qrData = 'https://example.com/default';
//     }
//
//     _initializeAnimations();
//     _startAnimations();
//   }
//
//   void _initializeAnimations() {
//     scaleController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 800),
//     );
//
//     pulseController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 2000),
//     );
//
//     fadeController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 600),
//     );
//
//     scaleAnimation = CurvedAnimation(
//       parent: scaleController,
//       curve: Curves.elasticOut,
//     );
//
//     pulseAnimation = CurvedAnimation(
//       parent: pulseController,
//       curve: Curves.easeInOut,
//     );
//
//     fadeAnimation = CurvedAnimation(
//       parent: fadeController,
//       curve: Curves.easeOut,
//     );
//   }
//
//   void _startAnimations() {
//     scaleController.forward();
//     Future.delayed(const Duration(milliseconds: 300), () {
//       fadeController.forward();
//     });
//     Future.delayed(const Duration(milliseconds: 1000), () {
//       pulseController.repeat(reverse: true);
//     });
//   }
//
//   // Share QR Code functionality
//   Future<void> shareQR() async {
//     try {
//       isSharing.value = true;
//       HapticFeedback.lightImpact();
//
//       // Wait a frame to ensure UI is updated
//       await Future.delayed(const Duration(milliseconds: 100));
//
//       // Capture QR widget as image
//       final boundary = qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
//       if (boundary == null) {
//         _showErrorSnackbar('Unable to capture QR code');
//         return;
//       }
//
//       final image = await boundary.toImage(pixelRatio: 3.0);
//       final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
//       final pngBytes = byteData?.buffer.asUint8List();
//
//       if (pngBytes == null) {
//         _showErrorSnackbar('Failed to generate QR image');
//         return;
//       }
//
//       // Save to temporary directory
//       final tempDir = await getTemporaryDirectory();
//       final fileName = 'qr_code_${DateTime.now().millisecondsSinceEpoch}.png';
//       final file = File('${tempDir.path}/$fileName');
//       await file.writeAsBytes(pngBytes);
//
//       // Verify file was created
//       if (!await file.exists()) {
//         _showErrorSnackbar('Failed to create temporary file');
//         return;
//       }
//
//       // Share the file
//       final result = await Share.shareXFiles(
//         [XFile(file.path)],
//         text: 'Scan this QR code to connect with me!',
//         subject: 'My QR Code',
//       );
//
//       _showSuccessSnackbar('QR code shared successfully!');
//     } catch (e) {
//       print('Share error: $e'); // Debug print
//       _showErrorSnackbar('Failed to share QR code: ${e.toString()}');
//     } finally {
//       isSharing.value = false;
//     }
//   }
//
//   // Copy QR data to clipboard
//   Future<void> copyQRData() async {
//     try {
//       HapticFeedback.lightImpact();
//
//       // Check if QR data is available
//       if (qrData.isEmpty) {
//         _showErrorSnackbar('No QR data available to copy');
//         return;
//       }
//
//       // Copy to clipboard
//       await Clipboard.setData(ClipboardData(text: qrData));
//
//       // Verify clipboard data
//       final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
//       if (clipboardData?.text == qrData) {
//         _showSuccessSnackbar('QR data copied to clipboard!\n"${qrData.length > 50 ? qrData.substring(0, 50) + '...' : qrData}"');
//       } else {
//         _showErrorSnackbar('Failed to verify clipboard data');
//       }
//
//     } catch (e) {
//       print('Clipboard error: $e'); // Debug print
//       _showErrorSnackbar('Failed to copy QR data: ${e.toString()}');
//     }
//   }
//
//
//   // Replace your saveQR() method with this simpler version
//   Future<void> saveQR() async {
//     try {
//       isSaving.value = true;
//       HapticFeedback.lightImpact();
//
//       await Future.delayed(const Duration(milliseconds: 100));
//
//       // Capture QR widget as image
//       final boundary = qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
//       if (boundary == null) {
//         _showErrorSnackbar('Unable to capture QR code');
//         return;
//       }
//
//       final image = await boundary.toImage(pixelRatio: 3.0);
//       final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
//       final pngBytes = byteData?.buffer.asUint8List();
//
//       if (pngBytes == null) {
//         _showErrorSnackbar('Failed to generate QR image');
//         return;
//       }
//
//       // Request permission first
//       final hasPermission = await _requestBasicStoragePermission();
//       if (!hasPermission) {
//         _showErrorSnackbar('Storage permission required to save QR code');
//         return;
//       }
//
//       // Save to Downloads folder (Android) or Documents (iOS)
//       Directory? directory;
//       String folderName = '';
//
//       if (Platform.isAndroid) {
//         // Try to save to Downloads folder
//         directory = Directory('/storage/emulated/0/Download');
//         folderName = 'Downloads';
//
//         // If Downloads doesn't exist or is not accessible, use app directory
//         if (!await directory.exists()) {
//           directory = await getExternalStorageDirectory();
//           folderName = 'App Storage';
//         }
//       } else {
//         // iOS - use Documents directory
//         directory = await getApplicationDocumentsDirectory();
//         folderName = 'Documents';
//       }
//
//       if (directory == null) {
//         _showErrorSnackbar('Unable to access storage directory');
//         return;
//       }
//
//       // Create QR_Codes subfolder
//       final qrCodesDir = Directory('${directory.path}/QR_Codes');
//       await qrCodesDir.create(recursive: true);
//
//       // Save file
//       final fileName = 'QR_Code_${DateTime.now().millisecondsSinceEpoch}.png';
//       final file = File('${qrCodesDir.path}/$fileName');
//
//       await file.writeAsBytes(pngBytes);
//
//       // Verify file was saved
//       if (await file.exists()) {
//         final fileSize = await file.length();
//         _showSuccessSnackbar(
//             'QR saved successfully!\n'
//                 'Location: $folderName/QR_Codes/\n'
//                 'Size: ${(fileSize / 1024).toStringAsFixed(1)} KB'
//         );
//       } else {
//         _showErrorSnackbar('Failed to save QR code');
//       }
//
//     } catch (e) {
//       print('Save error: $e');
//       _showErrorSnackbar('Error saving QR: ${e.toString()}');
//     } finally {
//       isSaving.value = false;
//     }
//   }
//
// // Simplified permission request
//   Future<bool> _requestBasicStoragePermission() async {
//     if (Platform.isAndroid) {
//       try {
//         final status = await Permission.storage.request();
//         return status.isGranted;
//       } catch (e) {
//         print('Permission error: $e');
//         return false;
//       }
//     }
//     return true; // iOS doesn't need permission for app documents
//   }
//
//
//
//
//   // Navigate back
//   void goBack() {
//     HapticFeedback.lightImpact();
//     Get.back();
//   }
//
//   // Show success snackbar
//   void _showSuccessSnackbar(String message) {
//     Get.snackbar(
//       'Success',
//       message,
//       backgroundColor: AppThemeData.primary200.withOpacity(0.9),
//       colorText: Colors.white,
//       snackPosition: SnackPosition.BOTTOM,
//       duration: const Duration(seconds: 2),
//       margin: const EdgeInsets.all(16),
//       borderRadius: 12,
//       icon: const Icon(Icons.check_circle, color: Colors.white),
//     );
//   }
//
//   // Show error snackbar
//   void _showErrorSnackbar(String message) {
//     Get.snackbar(
//       'Error',
//       message,
//       backgroundColor: Colors.red.withOpacity(0.9),
//       colorText: Colors.white,
//       snackPosition: SnackPosition.BOTTOM,
//       duration: const Duration(seconds: 3),
//       margin: const EdgeInsets.all(16),
//       borderRadius: 12,
//       icon: const Icon(Icons.error, color: Colors.white),
//     );
//   }
//
//   @override
//   void onClose() {
//     scaleController.dispose();
//     pulseController.dispose();
//     fadeController.dispose();
//     super.onClose();
//   }
// }
