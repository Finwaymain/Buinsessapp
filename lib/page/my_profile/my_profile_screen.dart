import 'dart:io';

import 'package:cabme_driver/constant/constant.dart';
import 'package:cabme_driver/constant/show_toast_dialog.dart';
import 'package:cabme_driver/controller/auth_otp_controller.dart';
import 'package:cabme_driver/controller/dash_board_controller.dart';
import 'package:cabme_driver/controller/my_profile_controller.dart';
import 'package:cabme_driver/model/user_model.dart';
import 'package:cabme_driver/page/auth_screens/phone_entry_screen.dart';
import 'package:cabme_driver/page/my_profile/change_password_screen.dart';
import 'package:cabme_driver/page/my_profile/edit_profile_screen.dart';
import 'package:cabme_driver/utils/onboarding_navigation.dart';
import 'package:cabme_driver/themes/app_bar_custom.dart';
import 'package:cabme_driver/themes/constant_colors.dart';
import 'package:cabme_driver/utils/Preferences.dart';
import 'package:cabme_driver/utils/dark_theme_provider.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class MyProfileScreen extends StatelessWidget {
  MyProfileScreen({super.key});

  final dashboardController = Get.put(DashBoardController());

  void _openCategoryEditor() {
    openDriverOnboardingEditor(
      mode: 'edit_profile',
      title: 'Edit Profile & Services'.tr,
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.getThem();

    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final primaryColor = AppThemeData.primary200;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return GetX<MyProfileController>(
      init: MyProfileController(),
      builder: (myProfileController) {
        UserModel userModel = Constant.getUserData();
        final uData = userModel.userData;

        final fullName = "${uData?.prenom ?? ''} ${uData?.nom ?? ''}".trim();
        final displayName = fullName.isNotEmpty ? fullName : "Driver Partner".tr;
        final phone = uData?.phone ?? '';
        final alternatePhone = uData?.alternatePhone ?? '';
        final email = uData?.email ?? '';
        final address = uData?.address ?? '';
        final acNo = uData?.acNo ?? '';
        final isOnline = uData?.online == 'yes';
        final isVerified = uData?.isVerified == '1' || uData?.isVerified == 'yes' || uData?.statut == 'yes';

        // Vehicle info
        final vBrand = uData?.brand ?? '';
        final vModel = uData?.model ?? '';
        final vPlate = uData?.numberplate ?? '';
        final vColor = uData?.color ?? '';
        final hasVehicle = vPlate.isNotEmpty || vBrand.isNotEmpty;

        // Financial & stats
        final walletAmount = uData?.amount ?? '0.00';
        final earnings = uData?.earnAmount ?? '0.00';
        final kycStatus = (uData?.kycStatus ?? (isVerified ? 'Approved' : 'Pending')).capitalizeFirst ?? 'Pending';

        // Bank info
        final bankName = uData?.bankName ?? '';
        final accountNo = uData?.accountNo ?? '';
        final ifscCode = uData?.ifscCode ?? '';
        final holderName = uData?.holderName ?? '';
        final hasBank = accountNo.isNotEmpty || bankName.isNotEmpty;

        // Categories / services
        final selectedCategories = uData?.selectedCategories ?? [];

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppbarCustom(title: 'My Profile'.tr),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ==========================================
                // 1. HERO PROFILE CARD
                // ==========================================
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Avatar & Edit Camera Button
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: primaryColor, width: 2.5),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(100),
                              child: myProfileController.profileImage.isEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: "https://cabme.siswebapp.com/assets/images/placeholder_image.jpg",
                                      height: 90,
                                      width: 90,
                                      fit: BoxFit.cover,
                                      errorWidget: (context, url, error) => Image.asset(
                                        "assets/images/appIcon.png",
                                        height: 90,
                                        width: 90,
                                      ),
                                    )
                                  : CachedNetworkImage(
                                      imageUrl: myProfileController.profileImage.toString(),
                                      height: 90,
                                      width: 90,
                                      fit: BoxFit.cover,
                                      errorWidget: (context, url, error) => Image.asset(
                                        "assets/images/appIcon.png",
                                        height: 90,
                                        width: 90,
                                      ),
                                    ),
                            ),
                          ),
                          InkWell(
                            onTap: () => _buildImageBottomSheet(context, myProfileController, isDark),
                            child: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: primaryColor,
                                shape: BoxShape.circle,
                                border: Border.all(color: cardBg, width: 2),
                              ),
                              child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Driver Name
                      Text(
                        displayName,
                        style: TextStyle(
                          fontFamily: AppThemeData.bold,
                          fontSize: 20,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Account Number
                      if (acNo.isNotEmpty)
                        Text(
                          "Account #$acNo",
                          style: TextStyle(
                            fontFamily: AppThemeData.medium,
                            fontSize: 13,
                            color: textSecondary,
                          ),
                        ),

                      const SizedBox(height: 12),

                      // Status Badges Row
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          // Live Online / Offline Status
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isOnline
                                  ? const Color(0xFF10B981).withValues(alpha: 0.15)
                                  : Colors.grey.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: isOnline ? const Color(0xFF10B981) : Colors.grey,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isOnline ? "Online".tr : "Offline".tr,
                                  style: TextStyle(
                                    fontFamily: AppThemeData.bold,
                                    fontSize: 11.5,
                                    color: isOnline ? const Color(0xFF10B981) : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Verification Status
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isVerified
                                  ? primaryColor.withValues(alpha: 0.15)
                                  : const Color(0xFFF59E0B).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isVerified ? Icons.verified_rounded : Icons.pending_actions_rounded,
                                  size: 13,
                                  color: isVerified ? primaryColor : const Color(0xFFF59E0B),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  isVerified ? "Verified Partner".tr : "Verification Pending".tr,
                                  style: TextStyle(
                                    fontFamily: AppThemeData.bold,
                                    fontSize: 11.5,
                                    color: isVerified ? primaryColor : const Color(0xFFF59E0B),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Star Rating
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.star_rounded, size: 14, color: Color(0xFFD97706)),
                                SizedBox(width: 4),
                                Text(
                                  "4.9",
                                  style: TextStyle(
                                    fontFamily: AppThemeData.bold,
                                    fontSize: 11.5,
                                    color: Color(0xFFD97706),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // ==========================================
                // 2. QUICK METRICS OVERVIEW (4 STAT CARDS)
                // ==========================================
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        title: "Wallet Balance".tr,
                        value: Constant().amountShow(amount: walletAmount),
                        icon: Icons.account_balance_wallet_rounded,
                        iconColor: const Color(0xFF3B82F6),
                        cardBg: cardBg,
                        borderColor: borderColor,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricCard(
                        title: "Total Earnings".tr,
                        value: Constant().amountShow(amount: earnings),
                        icon: Icons.trending_up_rounded,
                        iconColor: const Color(0xFF10B981),
                        cardBg: cardBg,
                        borderColor: borderColor,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        title: "KYC Status".tr,
                        value: kycStatus,
                        icon: Icons.badge_rounded,
                        iconColor: isVerified ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                        cardBg: cardBg,
                        borderColor: borderColor,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricCard(
                        title: "Role".tr,
                        value: (uData?.userCat ?? 'Driver').capitalizeFirst ?? 'Driver',
                        icon: Icons.work_outline_rounded,
                        iconColor: primaryColor,
                        cardBg: cardBg,
                        borderColor: borderColor,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ==========================================
                // 3. ENROLLED SERVICES & CATEGORIES
                // ==========================================
                _buildSectionHeader(
                  title: "Enrolled Services & Categories".tr,
                  textPrimary: textPrimary,
                  actionText: "Edit".tr,
                  onAction: _openCategoryEditor,
                  primaryColor: primaryColor,
                ),
                const SizedBox(height: 10),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Active Roles & Services".tr,
                            style: TextStyle(
                              fontFamily: AppThemeData.bold,
                              fontSize: 14,
                              color: textPrimary,
                            ),
                          ),
                          InkWell(
                            onTap: _openCategoryEditor,
                            child: Row(
                              children: [
                                Icon(Icons.edit_rounded, size: 14, color: primaryColor),
                                const SizedBox(width: 4),
                                Text(
                                  "Manage Services".tr,
                                  style: TextStyle(
                                    fontFamily: AppThemeData.bold,
                                    fontSize: 12,
                                    color: primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (selectedCategories.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: selectedCategories.map((catName) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle_rounded, size: 14, color: primaryColor),
                                  const SizedBox(width: 6),
                                  Text(
                                    catName,
                                    style: TextStyle(
                                      fontFamily: AppThemeData.medium,
                                      fontSize: 12.5,
                                      color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        )
                      else
                        InkWell(
                          onTap: _openCategoryEditor,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_circle_outline_rounded, color: primaryColor, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  "Select services & categories you provide".tr,
                                  style: TextStyle(
                                    fontFamily: AppThemeData.bold,
                                    fontSize: 13,
                                    color: primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ==========================================
                // 4. VEHICLE DETAILS (IF REGISTERED)
                // ==========================================
                if (hasVehicle) ...[
                  _buildSectionHeader(
                    title: "Vehicle Details".tr,
                    textPrimary: textPrimary,
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow(
                          icon: Icons.directions_car_rounded,
                          label: "Vehicle Model".tr,
                          value: "$vBrand $vModel".trim(),
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                        ),
                        if (vPlate.isNotEmpty) ...[
                          Divider(color: borderColor, height: 20),
                          _buildInfoRow(
                            icon: Icons.pin_rounded,
                            label: "License Plate / Number".tr,
                            value: vPlate,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                          ),
                        ],
                        if (vColor.isNotEmpty) ...[
                          Divider(color: borderColor, height: 20),
                          _buildInfoRow(
                            icon: Icons.color_lens_rounded,
                            label: "Color".tr,
                            value: vColor,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // ==========================================
                // 5. CONTACT & PERSONAL INFORMATION
                // ==========================================
                _buildSectionHeader(
                  title: "Personal & Contact Information".tr,
                  textPrimary: textPrimary,
                  actionText: "Edit Profile".tr,
                  onAction: () => Get.to(() => EditProfileScreen()),
                  primaryColor: primaryColor,
                ),
                const SizedBox(height: 10),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow(
                        icon: Icons.phone_rounded,
                        label: "Primary Phone".tr,
                        value: phone.isNotEmpty ? phone : "Not Provided".tr,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),
                      if (alternatePhone.isNotEmpty) ...[
                        Divider(color: borderColor, height: 20),
                        _buildInfoRow(
                          icon: Icons.phone_android_rounded,
                          label: "Alternate Phone".tr,
                          value: alternatePhone,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                        ),
                      ],
                      if (email.isNotEmpty) ...[
                        Divider(color: borderColor, height: 20),
                        _buildInfoRow(
                          icon: Icons.email_rounded,
                          label: "Email Address".tr,
                          value: email,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                        ),
                      ],
                      if (address.isNotEmpty) ...[
                        Divider(color: borderColor, height: 20),
                        _buildInfoRow(
                          icon: Icons.location_on_rounded,
                          label: "Service Address".tr,
                          value: address,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ==========================================
                // 6. REFERRAL CODE
                // ==========================================
                _buildSectionHeader(
                  title: "Referral Code".tr,
                  textPrimary: textPrimary,
                ),
                const SizedBox(height: 10),
                _ReferralCodeCard(
                  userId: uData?.id?.toString() ?? '',
                  userCat: 'driver',
                  cardBg: cardBg,
                  borderColor: borderColor,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  primaryColor: primaryColor,
                  isDark: isDark,
                ),

                const SizedBox(height: 20),

                // ==========================================
                // 7. DOCUMENT VERIFICATION STATUS
                // ==========================================
                _buildSectionHeader(
                  title: "Document Verification Status".tr,
                  textPrimary: textPrimary,
                ),
                const SizedBox(height: 10),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    children: [
                      _buildDocStatusRow(
                        title: "Driving License".tr,
                        status: uData?.statutLicence,
                        textPrimary: textPrimary,
                        primaryColor: primaryColor,
                      ),
                      Divider(color: borderColor, height: 20),
                      _buildDocStatusRow(
                        title: "National ID / CNIB".tr,
                        status: uData?.statutNic,
                        textPrimary: textPrimary,
                        primaryColor: primaryColor,
                      ),
                      Divider(color: borderColor, height: 20),
                      _buildDocStatusRow(
                        title: "Vehicle RC / Document".tr,
                        status: uData?.statutVehicule,
                        textPrimary: textPrimary,
                        primaryColor: primaryColor,
                      ),
                      Divider(color: borderColor, height: 20),
                      _buildDocStatusRow(
                        title: "Roadworthy / Insurance".tr,
                        status: uData?.statutRoadWorthy,
                        textPrimary: textPrimary,
                        primaryColor: primaryColor,
                      ),
                    ],
                  ),
                ),

                // ==========================================
                // 7. BANK & PAYOUT DETAILS (IF PRESENT)
                // ==========================================
                if (hasBank) ...[
                  const SizedBox(height: 20),
                  _buildSectionHeader(
                    title: "Bank & Payout Information".tr,
                    textPrimary: textPrimary,
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      children: [
                        if (bankName.isNotEmpty)
                          _buildInfoRow(
                            icon: Icons.account_balance_rounded,
                            label: "Bank Name".tr,
                            value: bankName,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                          ),
                        if (accountNo.isNotEmpty) ...[
                          Divider(color: borderColor, height: 20),
                          _buildInfoRow(
                            icon: Icons.credit_card_rounded,
                            label: "Account Number".tr,
                            value: accountNo.length > 4 ? "•••• •••• ${accountNo.substring(accountNo.length - 4)}" : accountNo,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                          ),
                        ],
                        if (ifscCode.isNotEmpty) ...[
                          Divider(color: borderColor, height: 20),
                          _buildInfoRow(
                            icon: Icons.numbers_rounded,
                            label: "IFSC Code".tr,
                            value: ifscCode,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                          ),
                        ],
                        if (holderName.isNotEmpty) ...[
                          Divider(color: borderColor, height: 20),
                          _buildInfoRow(
                            icon: Icons.person_outline_rounded,
                            label: "Holder Name".tr,
                            value: holderName,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // ==========================================
                // 8. SETTINGS & ACCOUNT ACTIONS
                // ==========================================
                _buildSectionHeader(
                  title: "Settings & Security".tr,
                  textPrimary: textPrimary,
                ),
                const SizedBox(height: 10),

                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: cardBg,
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    children: [
                      _buildActionTile(
                        isDark: isDark,
                        title: "Edit Profile & Services".tr,
                        icon: Icons.category_outlined,
                        onTap: _openCategoryEditor,
                        textPrimary: textPrimary,
                      ),
                      Divider(color: borderColor, height: 1),
                      _buildActionTile(
                        isDark: isDark,
                        title: "Edit Personal Details".tr,
                        icon: Icons.person_outline_rounded,
                        onTap: () => Get.to(() => EditProfileScreen()),
                        textPrimary: textPrimary,
                      ),
                      Divider(color: borderColor, height: 1),
                      _buildActionTile(
                        isDark: isDark,
                        title: "Change Password / Security".tr,
                        icon: Icons.lock_outline_rounded,
                        onTap: () => Get.to(() => ChangePasswordScreen()),
                        textPrimary: textPrimary,
                      ),
                      Divider(color: borderColor, height: 1),
                      _buildActionTile(
                        isDark: isDark,
                        title: "Delete Account".tr,
                        icon: Icons.delete_outline_rounded,
                        iconColor: AppThemeData.error50,
                        textColor: AppThemeData.error50,
                        showArrow: false,
                        onTap: () => _confirmDeleteAccount(context, myProfileController),
                        textPrimary: textPrimary,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- Helper Widgets ---

  Widget _buildSectionHeader({
    required String title,
    required Color textPrimary,
    String? actionText,
    VoidCallback? onAction,
    Color? primaryColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontFamily: AppThemeData.bold,
            fontSize: 15,
            color: textPrimary,
          ),
        ),
        if (actionText != null && onAction != null && primaryColor != null)
          InkWell(
            onTap: onAction,
            child: Text(
              actionText,
              style: TextStyle(
                fontFamily: AppThemeData.bold,
                fontSize: 12.5,
                color: primaryColor,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color cardBg,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: AppThemeData.bold,
              fontSize: 16,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: AppThemeData.medium,
              fontSize: 11.5,
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: AppThemeData.regular,
                  fontSize: 11.5,
                  color: textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontFamily: AppThemeData.medium,
                  fontSize: 13.5,
                  color: textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDocStatusRow({
    required String title,
    required String? status,
    required Color textPrimary,
    required Color primaryColor,
  }) {
    final isApproved = status == 'yes' || status == 'approved' || status == '1';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontFamily: AppThemeData.medium,
            fontSize: 13.5,
            color: textPrimary,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
          decoration: BoxDecoration(
            color: isApproved
                ? const Color(0xFF10B981).withValues(alpha: 0.12)
                : const Color(0xFFF59E0B).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isApproved ? Icons.check_circle_rounded : Icons.hourglass_top_rounded,
                size: 13,
                color: isApproved ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
              ),
              const SizedBox(width: 4),
              Text(
                isApproved ? "Verified".tr : "Pending".tr,
                style: TextStyle(
                  fontFamily: AppThemeData.bold,
                  fontSize: 11,
                  color: isApproved ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required bool isDark,
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    required Color textPrimary,
    Color? iconColor,
    Color? textColor,
    bool showArrow = true,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: iconColor ?? (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)), size: 20),
      title: Text(
        title,
        style: TextStyle(
          fontFamily: AppThemeData.medium,
          fontSize: 14,
          color: textColor ?? textPrimary,
        ),
      ),
      trailing: showArrow
          ? Icon(Icons.arrow_forward_ios_rounded, size: 14, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8))
          : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }

  void _buildImageBottomSheet(BuildContext context, MyProfileController controller, bool isDark) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Change Profile Photo".tr,
                  style: TextStyle(
                    fontFamily: AppThemeData.bold,
                    fontSize: 16,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Icon(Icons.camera_alt_rounded, color: AppThemeData.primary200),
                  title: Text("Take Photo".tr, style: const TextStyle(fontFamily: AppThemeData.medium)),
                  onTap: () async {
                    Get.back();
                    final ImagePicker picker = ImagePicker();
                    final XFile? image = await picker.pickImage(source: ImageSource.camera, imageQuality: 75);
                    if (image != null) {
                      controller.uploadPhoto(File(image.path)).then((value) {
                        if (value != null) controller.getUsrData();
                      });
                    }
                  },
                ),
                ListTile(
                  leading: Icon(Icons.photo_library_rounded, color: AppThemeData.primary200),
                  title: Text("Choose from Gallery".tr, style: const TextStyle(fontFamily: AppThemeData.medium)),
                  onTap: () async {
                    Get.back();
                    final ImagePicker picker = ImagePicker();
                    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
                    if (image != null) {
                      controller.uploadPhoto(File(image.path)).then((value) {
                        if (value != null) controller.getUsrData();
                      });
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDeleteAccount(BuildContext context, MyProfileController myProfileController) async {
    await showDialog(
      context: context,
      useSafeArea: true,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Are you sure you want to delete account?'.tr,
            style: const TextStyle(fontFamily: AppThemeData.bold, fontSize: 16),
          ),
          content: Text(
            'This action cannot be undone. All your driver data will be permanently deleted.'.tr,
            style: const TextStyle(fontFamily: AppThemeData.regular, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text('Cancel'.tr, style: const TextStyle(fontFamily: AppThemeData.medium, color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppThemeData.error50,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                myProfileController.deleteAccount(myProfileController.userID.toString()).then((value) {
                  if (value != null && value["success"] == "success") {
                    ShowToastDialog.showToast(value['message']);
                    Get.back();
                    Preferences.clearSharPreference();
                    Get.offAll(PhoneEntryScreen(mode: 'signup'));
                  }
                });
              },
              child: Text('Delete'.tr, style: const TextStyle(fontFamily: AppThemeData.bold, color: Colors.white)),
            ),
          ],
        );     },
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// REFERRAL CODE CARD (shown in profile — lets user apply a referral code
// if they missed it during registration)
// ══════════════════════════════════════════════════════════════════════════════
class _ReferralCodeCard extends StatefulWidget {
  final String userId;
  final String userCat;
  final Color cardBg;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color primaryColor;
  final bool isDark;

  const _ReferralCodeCard({
    required this.userId,
    required this.userCat,
    required this.cardBg,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.primaryColor,
    required this.isDark,
  });

  @override
  State<_ReferralCodeCard> createState() => _ReferralCodeCardState();
}

class _ReferralCodeCardState extends State<_ReferralCodeCard> {
  final _codeController = TextEditingController();
  bool _applying = false;
  bool _applied = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _apply() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      ShowToastDialog.showToast('Please enter a referral code'.tr);
      return;
    }
    setState(() => _applying = true);
    final controller = Get.put(AuthOtpController());
    final ok = await controller.applyReferralCode(
      widget.userId,
      code,
      userCat: widget.userCat,
    );
    setState(() {
      _applying = false;
      if (ok) _applied = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final inputBg = widget.isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: widget.primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.card_giftcard_rounded, color: widget.primaryColor, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enter Referral Code'.tr,
                      style: TextStyle(
                        fontFamily: AppThemeData.bold,
                        fontSize: 14,
                        color: widget.textPrimary,
                      ),
                    ),
                    Text(
                      'Reward the friend who invited you'.tr,
                      style: TextStyle(
                        fontFamily: AppThemeData.regular,
                        fontSize: 12,
                        color: widget.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (_applied) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.green, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Referral code applied successfully!'.tr,
                    style: const TextStyle(
                      fontFamily: AppThemeData.medium,
                      fontSize: 13,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _codeController,
                    textCapitalization: TextCapitalization.characters,
                    style: TextStyle(
                      fontFamily: AppThemeData.medium,
                      color: widget.textPrimary,
                      fontSize: 14,
                      letterSpacing: 1.5,
                    ),
                    decoration: InputDecoration(
                      hintText: 'e.g. ab3f2'.tr,
                      hintStyle: TextStyle(
                        fontFamily: AppThemeData.regular,
                        color: widget.textSecondary,
                        fontSize: 13,
                        letterSpacing: 0,
                      ),
                      filled: true,
                      fillColor: inputBg,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: widget.borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: widget.borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: widget.primaryColor, width: 1.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _applying ? null : _apply,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: _applying
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text('Apply'.tr, style: const TextStyle(color: Colors.white, fontFamily: AppThemeData.bold, fontSize: 13)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'You can only apply a referral code once.'.tr,
              style: TextStyle(fontFamily: AppThemeData.regular, fontSize: 11, color: widget.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}
