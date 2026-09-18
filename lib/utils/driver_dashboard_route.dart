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

  // If driver's primary console is taxi, they are a ride/transport driver
  if (userData.primaryConsole == 'taxi') return false;

  // If driver has Transport category and primary is not explicitly delivery, ride console takes precedence
  final isTransport = parseProfileBool(userData.isTransportCategory);
  if (isTransport == true && userData.primaryConsole != 'delivery') return false;

  // Explicit delivery console
  if (userData.primaryConsole == 'delivery') return true;

  // Delivery partner (and not transport)
  if (userData.isDeliveryPartner == true && isTransport != true) return true;

  // If categories are present, only return true if not a transport driver
  if (isTransport != true) {
    if (userData.isBikeRider == true) return true;
    final cats = userData.selectedCategories ?? [];
    for (final c in cats) {
      // 12885: Pickup, 12888: Delivery & Logistics, 12889: Food Delivery, 12890: Parcel Delivery, 12891: Pickup & Drop
      if (['12885', '12888', '12889', '12890', '12891', '12892'].contains(c.toString())) {
        return true;
      }
    }
  }

  return false;
}
