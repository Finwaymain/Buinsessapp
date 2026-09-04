import 'package:flutter_test/flutter_test.dart';

// Represents user data returned from the API / stored in UserModel
class DriverProfileState {
  final String? onboardingCompleted;
  final bool? isHomeServiceProvider;
  final bool? isTransportCategory;
  final String? isVerified; // 'yes', 'no', '1', '0'
  final String? statut; // 'yes', 'no'
  final String? statutVehicule; // 'yes', 'no'
  final List<dynamic> selectedCategories;

  DriverProfileState({
    required this.onboardingCompleted,
    required this.isHomeServiceProvider,
    required this.isTransportCategory,
    required this.isVerified,
    required this.statut,
    required this.statutVehicule,
    required this.selectedCategories,
  });

  bool get isOnboarded => onboardingCompleted == 'yes';

  bool get isHomeService => isHomeServiceProvider == true;

  // The exact logic used on HomeScreen, ProfileScreen, and DashBoard
  bool get isVerifiedDriver =>
      isOnboarded &&
      (isHomeService || isVerified == '1' || isVerified == 'yes') &&
      statut == 'yes';

  // Dashboard action resolution
  String get dashboardStatusDisplay {
    if (!isOnboarded) {
      return 'COMPLETE_ONBOARDING';
    } else if (isVerifiedDriver) {
      return 'VERIFIED';
    } else {
      return 'PENDING_VERIFICATION';
    }
  }

  // Pending verification banner
  bool get showsPendingVerificationBanner =>
      isOnboarded && !isHomeService && isVerified != 'yes';

  // Can driver toggle online
  String? validateCanGoOnline() {
    if (!isOnboarded) {
      return 'REDIRECT_ONBOARDING';
    }
    if (!isHomeService && (isVerified != 'yes' && isVerified != '1')) {
      return 'PENDING_APPROVAL';
    }
    if (!isHomeService && statutVehicule == 'no') {
      return 'VEHICLE_REQUIRED';
    }
    return 'ALLOWED';
  }
}

void main() {
  group('Driver Verification & Onboarding Flow Tests', () {
    test('Scenario 1: Freshly registered driver (Pre-onboarding) MUST NOT be verified', () {
      final newDriver = DriverProfileState(
        onboardingCompleted: 'no',
        isHomeServiceProvider: false,
        isTransportCategory: false,
        isVerified: 'no',
        statut: 'no',
        statutVehicule: 'no',
        selectedCategories: [],
      );

      expect(newDriver.isOnboarded, isFalse);
      expect(newDriver.isVerifiedDriver, isFalse,
          reason: 'Pre-onboarding driver must NEVER be verified');
      expect(newDriver.dashboardStatusDisplay, equals('COMPLETE_ONBOARDING'),
          reason: 'Must show Complete Onboarding button on dashboard');
      expect(newDriver.showsPendingVerificationBanner, isFalse);
      expect(newDriver.validateCanGoOnline(), equals('REDIRECT_ONBOARDING'));
    });

    test('Scenario 1b: Pre-onboarding driver with legacy is_verified=1 in DB MUST NOT show Verified', () {
      final legacyDriver = DriverProfileState(
        onboardingCompleted: 'no',
        isHomeServiceProvider: false,
        isTransportCategory: false,
        isVerified: '1',
        statut: 'yes',
        statutVehicule: 'no',
        selectedCategories: [],
      );

      expect(legacyDriver.isOnboarded, isFalse);
      expect(legacyDriver.isVerifiedDriver, isFalse,
          reason: 'Must not be verified if onboarding is not completed');
      expect(legacyDriver.dashboardStatusDisplay, equals('COMPLETE_ONBOARDING'));
      expect(legacyDriver.validateCanGoOnline(), equals('REDIRECT_ONBOARDING'));
    });

    test('Scenario 2: Driver onboarded + selects Home Service -> AUTO-VERIFIED without admin approval', () {
      final homeServiceDriver = DriverProfileState(
        onboardingCompleted: 'yes',
        isHomeServiceProvider: true,
        isTransportCategory: false,
        isVerified: 'yes',
        statut: 'yes',
        statutVehicule: 'yes',
        selectedCategories: [
          {'id': 10, 'title': 'Home Cleaning'}
        ],
      );

      expect(homeServiceDriver.isOnboarded, isTrue);
      expect(homeServiceDriver.isHomeService, isTrue);
      expect(homeServiceDriver.isVerifiedDriver, isTrue,
          reason: 'Home service driver must be auto-verified');
      expect(homeServiceDriver.dashboardStatusDisplay, equals('VERIFIED'));
      expect(homeServiceDriver.showsPendingVerificationBanner, isFalse,
          reason: 'Home service does NOT require admin approval banner');
      expect(homeServiceDriver.validateCanGoOnline(), equals('ALLOWED'));
    });

    test('Scenario 3: Driver onboarded + selects Cab/Parcel -> REQUIRES ADMIN APPROVAL (Pending)', () {
      final cabDriverPending = DriverProfileState(
        onboardingCompleted: 'yes',
        isHomeServiceProvider: false,
        isTransportCategory: true,
        isVerified: 'no',
        statut: 'no',
        statutVehicule: 'yes',
        selectedCategories: [
          {'id': 1, 'title': 'Cab Service'}
        ],
      );

      expect(cabDriverPending.isOnboarded, isTrue);
      expect(cabDriverPending.isHomeService, isFalse);
      expect(cabDriverPending.isVerifiedDriver, isFalse,
          reason: 'Cab driver awaiting admin approval must NOT be verified');
      expect(cabDriverPending.dashboardStatusDisplay, equals('PENDING_VERIFICATION'));
      expect(cabDriverPending.showsPendingVerificationBanner, isTrue,
          reason: 'Must show 24-48h pending approval banner');
      expect(cabDriverPending.validateCanGoOnline(), equals('PENDING_APPROVAL'));
    });

    test('Scenario 4: Driver onboarded + selects Cab/Parcel -> ADMIN APPROVES -> Verified', () {
      final cabDriverApproved = DriverProfileState(
        onboardingCompleted: 'yes',
        isHomeServiceProvider: false,
        isTransportCategory: true,
        isVerified: 'yes',
        statut: 'yes',
        statutVehicule: 'yes',
        selectedCategories: [
          {'id': 1, 'title': 'Cab Service'}
        ],
      );

      expect(cabDriverApproved.isOnboarded, isTrue);
      expect(cabDriverApproved.isHomeService, isFalse);
      expect(cabDriverApproved.isVerifiedDriver, isTrue,
          reason: 'Cab driver approved by admin must be verified');
      expect(cabDriverApproved.dashboardStatusDisplay, equals('VERIFIED'));
      expect(cabDriverApproved.showsPendingVerificationBanner, isFalse);
      expect(cabDriverApproved.validateCanGoOnline(), equals('ALLOWED'));
    });

    test('Scenario 5: Driver onboarded + Cab/Parcel approved, but vehicle not approved -> blocked', () {
      final cabDriverNoVehicle = DriverProfileState(
        onboardingCompleted: 'yes',
        isHomeServiceProvider: false,
        isTransportCategory: true,
        isVerified: 'yes',
        statut: 'yes',
        statutVehicule: 'no',
        selectedCategories: [
          {'id': 1, 'title': 'Cab Service'}
        ],
      );

      expect(cabDriverNoVehicle.isOnboarded, isTrue);
      expect(cabDriverNoVehicle.validateCanGoOnline(), equals('VEHICLE_REQUIRED'));
    });
  });
}
