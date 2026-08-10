import 'package:cabme_driver/model/user_model.dart' show UserData, parseProfileBool;

/// Home-service-only drivers use the web onboarding dashboard.
/// Transport, delivery, and parcel drivers stay on the native app shell.
bool shouldUseWebDashboard(UserData? userData) {
  if (userData == null) return false;
  if (userData.onboardingCompleted != 'yes') return false;
  if (parseProfileBool(userData.isTransportCategory) == true) return false;
  if (userData.parcelDelivery == 'yes') return false;
  return true;
}

/// Online/offline duty toggle applies to ride & transport drivers only.
/// Home services providers (e.g. painter, plumber) manage bookings without it.
bool shouldShowOnlineStatus(UserData? userData) {
  if (userData == null) return false;

  if (userData.isHomeServiceProvider == true) return false;

  if (userData.parcelDelivery == 'yes') return true;

  final isTransport = parseProfileBool(userData.isTransportCategory);
  if (isTransport == true) return true;
  if (isTransport == false) return false;

  // Completed onboarding without transport flag → home services provider.
  if (userData.onboardingCompleted == 'yes') return false;

  // Pre-onboarding fallback: only transport drivers register a vehicle.
  return userData.statutVehicule == 'yes';
}
