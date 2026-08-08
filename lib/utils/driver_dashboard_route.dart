import 'package:cabme_driver/model/user_model.dart';

/// Home-service-only drivers use the web onboarding dashboard.
/// Transport, delivery, and parcel drivers stay on the native app shell.
bool shouldUseWebDashboard(UserData? userData) {
  if (userData == null) return false;
  if (userData.onboardingCompleted != 'yes') return false;
  if (userData.isTransportCategory == true) return false;
  if (userData.parcelDelivery == 'yes') return false;
  return true;
}
