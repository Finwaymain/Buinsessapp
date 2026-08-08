import 'package:cabme_driver/themes/constant_colors.dart';
import 'package:cabme_driver/utils/dark_theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../vehicle_registration_style.dart';

/// Numbered step tabs matching the onboarding wizard:
/// Step 1: Business Category
/// Step 2: Profession
/// Step 3: Documents
class StepProgress extends StatelessWidget {
  final int currentStep; // 1-indexed
  final int totalSteps;

  const StepProgress({super.key, required this.currentStep, this.totalSteps = 3});

  static const List<String> stepNames = [
    'Business Category',
    'Profession',
    'Documents',
  ];

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDarkMode = themeChange.getThem();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Step $currentStep of $totalSteps".tr,
              style: TextStyle(
                fontFamily: AppThemeData.semiBold,
                fontSize: 12.5,
                color: isDarkMode ? AppThemeData.grey500Dark : AppThemeData.grey500,
              ),
            ),
            if (currentStep <= stepNames.length)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: kVehicleRegAccent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  stepNames[currentStep - 1].tr,
                  style: const TextStyle(
                    fontFamily: AppThemeData.bold,
                    fontSize: 11.5,
                    color: kVehicleRegAccent,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: List.generate(totalSteps * 2 - 1, (i) {
            if (i.isOdd) {
              final leftStep = (i ~/ 2) + 1;
              final done = leftStep < currentStep;
              return Expanded(
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: done ? kVehicleRegAccent : Colors.grey.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }
            final step = (i ~/ 2) + 1;
            final isDone = step < currentStep;
            final isActive = step == currentStep;
            return Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (isDone || isActive) ? kVehicleRegAccent : Colors.grey.withOpacity(0.2),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: kVehicleRegAccent.withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                '$step',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(stepNames.length, (index) {
            final isCurrent = index + 1 == currentStep;
            final isPassed = index + 1 < currentStep;
            return Expanded(
              child: Text(
                stepNames[index].tr,
                textAlign: index == 0
                    ? TextAlign.left
                    : index == stepNames.length - 1
                        ? TextAlign.right
                        : TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: (isCurrent || isPassed) ? AppThemeData.bold : AppThemeData.regular,
                  fontSize: 11,
                  color: isCurrent
                      ? kVehicleRegAccent
                      : (isPassed
                          ? (isDarkMode ? AppThemeData.grey50Dark : AppThemeData.grey900)
                          : (isDarkMode ? AppThemeData.grey400Dark : AppThemeData.grey500)),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
