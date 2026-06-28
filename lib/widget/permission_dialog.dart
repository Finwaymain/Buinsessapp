import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import '../constant/show_toast_dialog.dart';
import '../themes/constant_colors.dart';
import '../utils/dark_theme_provider.dart';

class LocationPermissionDisclosureDialog extends StatelessWidget {
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;

  const LocationPermissionDisclosureDialog({
    super.key,
    this.onAccept,
    this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDarkMode = themeChange.getThem();

    final bgColor = isDarkMode ? AppThemeData.surface50Dark : AppThemeData.surface50;
    final textColor = isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900;
    final mutedColor = isDarkMode ? AppThemeData.grey500Dark : AppThemeData.grey500;
    final accentColor = AppThemeData.primary200;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      backgroundColor: bgColor,
      title: Row(
        children: [
          Icon(
            Icons.location_on,
            color: accentColor,
            size: 28,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Location Access',
              style: TextStyle(
                fontFamily: AppThemeData.bold,
                fontSize: 20,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Fiinway Business collects location data to enable real-time ride tracking, route calculation, and booking assignments even when the app is closed or not in use.',
              style: TextStyle(
                fontFamily: AppThemeData.medium,
                fontSize: 15,
                color: textColor,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'How we use this information:',
              style: TextStyle(
                fontFamily: AppThemeData.bold,
                fontSize: 14,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            _buildFeatureItem(
              Icons.directions_car,
              'Assign Nearby Rides',
              'To match and send you trip requests based on your current physical location.',
              textColor,
              mutedColor,
            ),
            _buildFeatureItem(
              Icons.share_location,
              'Passenger Updates',
              'To show passengers your location in real-time while performing a trip.',
              textColor,
              mutedColor,
            ),
            _buildFeatureItem(
              Icons.map,
              'Route Navigation',
              'To calculate accurate distances, optimal routes, and trip fares.',
              textColor,
              mutedColor,
            ),
            const SizedBox(height: 12),
            Text(
              'Your location data is stored securely and is never shared with third parties for advertising purposes.',
              style: TextStyle(
                fontFamily: AppThemeData.regular,
                fontSize: 12,
                color: mutedColor,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      actions: <Widget>[
        TextButton(
          onPressed: onDecline ?? () {
            SystemNavigator.pop();
          },
          child: Text(
            'Decline',
            style: TextStyle(
              fontFamily: AppThemeData.medium,
              color: isDarkMode ? Colors.redAccent : Colors.red,
              fontSize: 15,
            ),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: accentColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
          onPressed: onAccept ?? () async {
            Get.back();
            PermissionStatus status = await Location().requestPermission();
            if (status == PermissionStatus.granted) {
              ShowToastDialog.showToast("Permission Granted");
            } else {
              ShowToastDialog.showToast("Permission Denied");
            }
          },
          child: Text(
            'Accept & Continue',
            style: TextStyle(
              fontFamily: AppThemeData.bold,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureItem(
    IconData icon,
    String title,
    String description,
    Color titleColor,
    Color descColor,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: AppThemeData.primary200,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: AppThemeData.semiBold,
                    fontSize: 13,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontFamily: AppThemeData.regular,
                    fontSize: 12,
                    color: descColor,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
