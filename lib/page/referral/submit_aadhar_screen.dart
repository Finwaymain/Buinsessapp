import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../../constant/constant.dart';
import '../../../service/api.dart';
import '../../../themes/constant_colors.dart';
import '../../../utils/Preferences.dart';
import '../../../utils/dark_theme_provider.dart';
import '../../../constant/show_toast_dialog.dart';
import '../auth_screens/phone_entry_screen.dart';
import 'partner_webview_screen.dart';

class SubmitAadharScreen extends StatefulWidget {
  const SubmitAadharScreen({super.key});

  @override
  State<SubmitAadharScreen> createState() => _SubmitAadharScreenState();
}

class _SubmitAadharScreenState extends State<SubmitAadharScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _aadharController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _aadharController.dispose();
    super.dispose();
  }

  Future<void> _submitAadhar() async {
    if (!_formKey.currentState!.validate()) return;

    final isLogin = Preferences.getBoolean(Preferences.isLogin) ?? false;
    if (!isLogin) {
      Get.to(() => PhoneEntryScreen(mode: 'signup'));
      return;
    }

    String driverId = Preferences.getString(Preferences.userId);
    if (driverId.isEmpty) {
      final intId = Preferences.getInt(Preferences.userId);
      if (intId > 0) {
        driverId = intId.toString();
      }
    }
    if (driverId.isEmpty) {
      final userObj = Constant.getUserData();
      if (userObj.userData?.id != null) {
        driverId = userObj.userData!.id.toString();
      }
    }

    if (driverId.isEmpty || driverId == "0") {
      ShowToastDialog.showToast('Please login to continue.'.tr);
      Get.to(() => PhoneEntryScreen(mode: 'signup'));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(API.submitAadhar),
        headers: API.header,
        body: json.encode({
          'driver_id': driverId,
          'id_user': driverId,
          'id_conducteur': driverId,
          'user_id': driverId,
          'aadhar_number': _aadharController.text.trim(),
        }),
      );

      final resData = json.decode(response.body);

      if (response.statusCode == 200 && (resData['success'] == true || resData['res'] == 'success')) {
        final aadharNum = resData['aadhar_number'] ?? _aadharController.text.trim();
        await Preferences.setString('user_aadhar_number', aadharNum);
        await Preferences.setString('driver_aadhar_number', aadharNum);

        ShowToastDialog.showToast('Aadhaar verified successfully! Welcome Partner.'.tr);

        if (mounted) {
          Get.off(
            () => const PartnerWebViewScreen(
              title: 'Partner Dashboard',
              urlPath: 'partner-dashboard',
              userType: 'driver',
            ),
            transition: Transition.rightToLeftWithFade,
          );
        }
      } else {
        final msg = resData['message'] ?? resData['msg'] ?? 'Failed to submit Aadhaar number. Please try again.'.tr;
        ShowToastDialog.showToast(msg);
      }
    } catch (e) {
      ShowToastDialog.showToast('Network error. Please try again.'.tr);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<DarkThemeProvider>(context).getThem();

    return Scaffold(
      backgroundColor: isDark ? AppThemeData.surface50Dark : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? AppThemeData.surface50Dark : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? Colors.white : AppThemeData.grey900,
            size: 20,
          ),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Join as a Partner'.tr,
          style: TextStyle(
            color: isDark ? Colors.white : AppThemeData.grey900,
            fontFamily: AppThemeData.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Hero Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      colors: [
                        AppThemeData.primary200,
                        AppThemeData.primary200.withValues(alpha: 0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppThemeData.primary200.withValues(alpha: 0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.handshake_rounded, color: Colors.white, size: 48),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Become a Fiinway Partner'.tr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: AppThemeData.bold,
                          fontSize: 22,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Enter your 12-digit Aadhaar number to verify identity and unlock your Partner Dashboard with exclusive referral earnings.'.tr,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // Form Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.badge_rounded, color: AppThemeData.primary200, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            'Aadhaar Verification'.tr,
                            style: TextStyle(
                              fontFamily: AppThemeData.bold,
                              fontSize: 16,
                              color: isDark ? Colors.white : AppThemeData.grey900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _aadharController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(12),
                        ],
                        style: TextStyle(
                          fontSize: 16,
                          letterSpacing: 2.0,
                          fontFamily: AppThemeData.medium,
                          color: isDark ? Colors.white : AppThemeData.grey900,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter 12-digit Aadhaar Number'.tr,
                          hintStyle: TextStyle(
                            letterSpacing: 0,
                            fontSize: 14,
                            color: isDark ? AppThemeData.grey400Dark : AppThemeData.grey400,
                          ),
                          prefixIcon: Icon(Icons.credit_card_rounded, color: AppThemeData.primary200),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: isDark ? AppThemeData.grey500Dark : AppThemeData.grey200),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: isDark ? AppThemeData.grey500Dark : AppThemeData.grey200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppThemeData.primary200, width: 2),
                          ),
                          filled: true,
                          fillColor: isDark ? AppThemeData.surface50Dark : const Color(0xFFF8FAFC),
                        ),
                        validator: (value) {
                          final val = (value ?? '').trim();
                          if (val.isEmpty) {
                            return 'Please enter your Aadhaar number'.tr;
                          }
                          if (val.length != 12) {
                            return 'Aadhaar number must be exactly 12 digits'.tr;
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // Submit Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitAadhar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppThemeData.primary200,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          'Verify & Proceed'.tr,
                          style: const TextStyle(
                            fontSize: 16,
                            fontFamily: AppThemeData.bold,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
