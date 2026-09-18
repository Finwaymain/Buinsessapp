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

/// Online/offline duty toggle applies to ride & transport & delivery drivers.
/// Home services providers (e.g. painter, plumber) manage bookings without it.
bool shouldShowOnlineStatus(UserData? userData) {
  if (userData == null) return false;

  if (userData.isHomeServiceProvider == true) return false;

  if (userData.parcelDelivery == 'yes' || userData.isDeliveryPartner == true) return true;

  final isTransport = parseProfileBool(userData.isTransportCategory);
  if (isTransport == true) return true;
  if (isTransport == false) return false;

  // Completed onboarding without transport flag → home services provider.
  if (userData.onboardingCompleted == 'yes') return false;

  // Pre-onboarding fallback: only transport drivers register a vehicle.
  return userData.statutVehicule == 'yes';
}

/// Returns true if driver's primary mode is Delivery & Logistics / Pickup / Food / Bike Rider
bool isDeliveryConsoleDriver(UserData? userData) {
  if (userData == null) return false;
  if (userData.primaryConsole == 'delivery') return true;
  if (userData.isDeliveryPartner == true) return true;
  if (userData.isBikeRider == true) return true;
  if (userData.parcelDelivery == 'yes') return true;

  final cats = userData.selectedCategories ?? [];
  for (final c in cats) {
    // 12885: Pickup, 12888: Delivery & Logistics, 12889: Food Delivery, 12890: Parcel Delivery, 12882: Bike Rider
    if (['12885', '12888', '12889', '12890', '12891', '12892', '12882'].contains(c.toString())) {
      return true;
    }
  }

  return false;
}
