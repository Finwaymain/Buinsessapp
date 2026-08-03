import 'package:cabme_driver/themes/constant_colors.dart';
import 'package:cabme_driver/utils/dark_theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../vehicle_registration_style.dart';

/// Numbered step circles + connecting lines, matching the "Step X of 3"
/// header used across the vehicle registration wizard's reference mockup.
class StepProgress extends StatelessWidget {
  final int currentStep; // 1-indexed
  final int totalSteps;

  const StepProgress({super.key, required this.currentStep, required this.totalSteps});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDarkMode = themeChange.getThem();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Step $currentStep of $totalSteps".tr,
          style: TextStyle(fontFamily: AppThemeData.medium, fontSize: 12, color: isDarkMode ? AppThemeData.grey500Dark : AppThemeData.grey500),
        ),
        const SizedBox(height: 10),
        Row(
          children: List.generate(totalSteps * 2 - 1, (i) {
            if (i.isOdd) {
              final leftStep = (i ~/ 2) + 1;
              final done = leftStep < currentStep;
              return Expanded(
                child: Container(height: 2, color: done ? kVehicleRegAccent : Colors.grey.withValues(alpha: 0.25)),
              );
            }
            final step = (i ~/ 2) + 1;
            final isDone = step < currentStep;
            final isActive = step == currentStep;
            return Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (isDone || isActive) ? kVehicleRegAccent : Colors.grey.withValues(alpha: 0.2),
              ),
              child: Text(
                '$step',
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            );
          }),
        ),
      ],
    );
  }
}
