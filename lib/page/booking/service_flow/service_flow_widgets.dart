import 'dart:io';

import 'package:cabme_driver/constant/constant.dart';
import 'package:cabme_driver/model/driver_booking_model.dart';
import 'package:cabme_driver/themes/constant_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ServiceFlowScaffold extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget body;
  final Widget? bottomBar;
  final Color? headerColor;
  final bool showBack;

  const ServiceFlowScaffold({
    super.key,
    required this.title,
    this.subtitle,
    required this.body,
    this.bottomBar,
    this.headerColor,
    this.showBack = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppThemeData.grey50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: headerColor ?? Colors.white,
        surfaceTintColor: Colors.transparent,
        leading: showBack
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: () => Get.back(),
              )
            : null,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontFamily: AppThemeData.bold, fontSize: 17)),
            if (subtitle != null)
              Text(subtitle!, style: TextStyle(fontSize: 11, color: AppThemeData.grey500, fontFamily: AppThemeData.regular)),
          ],
        ),
      ),
      body: body,
      bottomNavigationBar: bottomBar,
    );
  }
}

class ServiceFlowCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const ServiceFlowCard({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: padding ?? const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppThemeData.grey200),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: child,
    );
  }
}

class CustomerHeaderCard extends StatelessWidget {
  final DriverBookingItem booking;
  final VoidCallback? onCall;

  const CustomerHeaderCard({super.key, required this.booking, this.onCall});

  @override
  Widget build(BuildContext context) {
    return ServiceFlowCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppThemeData.primary200.withValues(alpha: 0.12),
            backgroundImage: booking.customerPhoto.isNotEmpty ? NetworkImage(booking.customerPhoto) : null,
            child: booking.customerPhoto.isEmpty
                ? Text(booking.customerName.isNotEmpty ? booking.customerName[0].toUpperCase() : 'C',
                    style: TextStyle(fontFamily: AppThemeData.bold, color: AppThemeData.primary200))
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(booking.customerName, style: const TextStyle(fontFamily: AppThemeData.bold, fontSize: 16)),
                if (booking.customerPhone.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(booking.customerPhone, style: TextStyle(fontSize: 13, color: AppThemeData.grey500, fontFamily: AppThemeData.medium)),
                ],
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${booking.customerRating.toStringAsFixed(1)} (${booking.reviewCount} Reviews)',
                      style: TextStyle(fontSize: 12, color: AppThemeData.grey500),
                    ),
                  ],
                ),
                if (booking.distanceKm != null) ...[
                  const SizedBox(height: 4),
                  Text('${booking.distanceKm!.toStringAsFixed(1)} KM away'.tr,
                      style: TextStyle(fontSize: 12, color: AppThemeData.primary200, fontFamily: AppThemeData.semiBold)),
                ],
              ],
            ),
          ),
          if (onCall != null)
            InkWell(
              onTap: onCall,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppThemeData.primary200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.call_rounded, color: Colors.white, size: 20),
              ),
            ),
        ],
      ),
    );
  }
}

class ServiceItemsList extends StatelessWidget {
  final List<ServiceLineItem> items;
  final bool showPrices;
  final bool showCheckmarks;
  final void Function(int index)? onToggle;
  final bool Function(String name)? isExtraCheck;

  const ServiceItemsList({
    super.key,
    required this.items,
    this.showPrices = true,
    this.showCheckmarks = false,
    this.onToggle,
    this.isExtraCheck,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(items.length, (index) {
        final item = items[index];
        final isExtra = isExtraCheck != null ? isExtraCheck!(item.name) : false;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              if (showCheckmarks)
                InkWell(
                  onTap: onToggle == null ? null : () => onToggle!(index),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.completed ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                        color: item.completed ? AppThemeData.success300 : AppThemeData.grey400,
                        size: 20,
                      ),
                      if (!isExtra)
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Icon(Icons.lock_rounded, size: 12, color: AppThemeData.grey400),
                        ),
                    ],
                  ),
                ),
              if (showCheckmarks) const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: !isExtra ? AppThemeData.semiBold : AppThemeData.regular,
                  ),
                ),
              ),
              if (showPrices && item.price > 0)
                Text(
                  Constant().amountShow(amount: item.price.toStringAsFixed(0)),
                  style: const TextStyle(fontFamily: AppThemeData.semiBold, fontSize: 14),
                ),
            ],
          ),
        );
      }),
    );
  }
}

class FlowPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color? color;
  final IconData? icon;
  final bool outlined;

  const FlowPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.color,
    this.icon,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final btnColor = color ?? AppThemeData.primary200;
    if (outlined) {
      return OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon ?? Icons.close_rounded, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: btnColor,
          side: BorderSide(color: btnColor),
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon ?? Icons.check_rounded, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: btnColor,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class FlowSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color? color;
  final IconData? icon;

  const FlowSecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return FlowPrimaryButton(
      label: label,
      onPressed: onPressed,
      color: color,
      icon: icon,
      outlined: true,
    );
  }
}

class PhotoUploadRow extends StatelessWidget {
  final List<String> photos;
  final VoidCallback onAdd;
  final void Function(String path)? onRemove;
  final String label;

  const PhotoUploadRow({
    super.key,
    required this.photos,
    required this.onAdd,
    this.onRemove,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontFamily: AppThemeData.semiBold, fontSize: 14)),
        const SizedBox(height: 10),
        SizedBox(
          height: 88,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              ...photos.map(
                (path) => Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(File(path), width: 88, height: 88, fit: BoxFit.cover),
                      ),
                      if (onRemove != null)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: InkWell(
                            onTap: () => onRemove!(path),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                              child: const Icon(Icons.close, color: Colors.white, size: 14),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              InkWell(
                onTap: onAdd,
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: AppThemeData.grey100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppThemeData.grey200),
                  ),
                  child: Icon(Icons.add_a_photo_outlined, color: AppThemeData.grey500),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

Widget buildDetailRow(IconData icon, String label, String value, {Color? valueColor}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppThemeData.primary200),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11, color: AppThemeData.grey500, fontFamily: AppThemeData.medium)),
              const SizedBox(height: 2),
              Text(value, style: TextStyle(fontSize: 14, fontFamily: AppThemeData.regular, color: valueColor)),
            ],
          ),
        ),
      ],
    ),
  );
}
