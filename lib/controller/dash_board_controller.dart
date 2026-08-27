import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:in_app_review/in_app_review.dart';
import 'package:location/location.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart' hide PermissionStatus;
import '../constant/constant.dart';
import '../constant/logdata.dart';
import '../constant/show_toast_dialog.dart';
import '../model/user_model.dart';
import '../page/auth_screens/phone_entry_screen.dart';
import '../page/features/Taxi/taxi_dashboard/taxi_dashboard.dart';
import '../page/my_profile/change_password_screen.dart';
import '../page/wallet/wallet_screen.dart';
import '../utils/onboarding_navigation.dart';
import '../page/my_profile/my_profile_screen.dart';
import '../page/web_view_screen/web_view_screen.dart';

import '../page/privacy_policy/privacy_policy_screen.dart';
import '../page/referral/referral_earn_screen.dart';
import '../page/referral/submit_aadhar_screen.dart';
import '../page/terms_of_service/terms_of_service_screen.dart';
import '../service/api.dart';
import '../service/app_version_service.dart';
import '../service/driver_kit_service.dart';
import '../utils/Preferences.dart';
import '../utils/onboarding_url.dart';
import '../utils/location_picker_helper.dart';
import '../widget/permission_dialog.dart';
import '../page/marketplace/view/marketplace_home_screen.dart';

class DashBoardController extends GetxController {
  Location location = Location();
  StreamSubscription<LocationData>? locationSubscription;

  bool _isLocationInitialized = false;

  void initLocationTracking() {
    final bool isLogin = Preferences.getBoolean(Preferences.isLogin) ?? false;
    if (!isLogin) return;
    if (_isLocationInitialized) return;
    _isLocationInitialized = true;

    ever(isActive, (bool active) {
      if (active) {
        getCurrentLocation();
        updateCurrentLocation();
      } else {
        locationSubscription?.cancel();
        updateActiveStatusInRTDB(false);
      }
    });

    if (isActive.value) {
      locationSubscription = location.onLocationChanged.listen((event) {});
      getCurrentLocation();
      updateCurrentLocation();
    }
  }

  @override
  void onInit() {
    final bool isLogin = Preferences.getBoolean(Preferences.isLogin);
    if (isLogin) {
      checkCallPermissions();
      getUsrData();
      getPaymentSettingData();
      initLocationTracking();
      fetchDriverServices();
      // Check for compulsory or optional Play Store updates for Driver Partners
      AppVersionService.checkAppVersion(appType: 'business');
      // Check for Driver Partner Welcome Kit & Popups
      final kitService = Get.isRegistered<DriverKitService>()
          ? Get.find<DriverKitService>()
          : Get.put(DriverKitService());
      kitService.fetchKitStatus();
    }
    super.onInit();
  }

  Future<void> checkCallPermissions() async {
    try {
      if (await Permission.ignoreBatteryOptimizations.isDenied) {
        await Permission.ignoreBatteryOptimizations.request();
      }
      if (await Permission.systemAlertWindow.isDenied) {
        await Permission.systemAlertWindow.request();
      }
    } catch (e) {
      log("Error checking call permissions: $e");
    }
  }

  Future<void> updateToken() async {
    if (userModel.value.userData == null) return;
    // use the returned token to send messages to users from your custom server
    String? token = await FirebaseMessaging.instance.getToken();

    if (token != null) {
      updateFCMToken(token);
    }
  }

  Future<void> getCurrentLocation() async {
    try {
      final hasAccess = await LocationPickerHelper.ensureLocationAccess(showPromptDialog: true);
      if (!hasAccess) return;

      LocationData locationVal = await location.getLocation();
      List<geocoding.Placemark> placeMarks = await geocoding.placemarkFromCoordinates(locationVal.latitude ?? 0.0, locationVal.longitude ?? 0.0);
      if (placeMarks.isNotEmpty) {
        String currentCountry = placeMarks.first.country?.toString().toUpperCase() ?? '';
        for (var i = 0; i < Constant.allTaxList.length; i++) {
          String? taxCountry = Constant.allTaxList[i].country;
          if (taxCountry != null && currentCountry == taxCountry.toUpperCase()) {
            Constant.taxList.add(Constant.allTaxList[i]);
          }
        }
      }
      print(Constant.taxList.length);
      setCurrentLocation(locationVal.latitude.toString(), locationVal.longitude.toString());
    } catch (e) {
      log("getCurrentLocation error in DashBoardController: $e");
    }
  }

  // getDrawerItem() {
  //   drawerItems = [
  //     DrawerItem('All Rides'.tr, 'assets/icons/ic_car.svg',
  //         section: "${"Rides".tr}${(Constant.parcelActive.toString() == "yes" && userModel.value.userData?.parcelDelivery.toString() == "yes") ? " & Parcels:".tr : ":"}",
  //         navigate: () {
  //       Get.back();
  //     }),
  //     if (Constant.parcelActive.toString() == "yes" && userModel.value.userData?.parcelDelivery.toString() == "yes")
  //       DrawerItem('Parcel Service'.tr, 'assets/icons/ic_parcel_vehicle.svg', navigate: () {
  //         Get.back();
  //         Get.to(SearchParcelScreen());
  //       }),
  //     if (Constant.parcelActive.toString() == "yes" && userModel.value.userData?.parcelDelivery.toString() == "yes")
  //       DrawerItem('All Parcel'.tr, 'assets/icons/ic_all_car.svg', navigate: () {
  //         Get.back();
  //         Get.to(const AllParcelScreen());
  //       }),
  //     DrawerItem('Documents'.tr, 'assets/icons/ic_car.svg', section: 'Vehicle & Service Management:'.tr, navigate: () {
  //       Get.back();
  //       Get.to(DocumentStatusScreen());
  //     }),
  //     DrawerItem('Vehicle information'.tr, 'assets/icons/ic_parcel_vehicle.svg', navigate: () {
  //       Get.back();
  //       Get.to(const VehicleInfoScreen());
  //     }),
  //     DrawerItem('Car Service History'.tr, 'assets/icons/ic_all_car.svg', navigate: () {
  //       Get.back();
  //       Get.to(const CarServiceBookHistory());
  //     }),
  //     DrawerItem('My Profile'.tr, 'assets/icons/ic_profile.svg', section: 'Account & Financials:'.tr, navigate: () {
  //       Get.back();
  //       Get.to(MyProfileScreen());
  //     }),
  //     DrawerItem('My Earnings'.tr, 'assets/icons/ic_wallet.svg', navigate: () {
  //       Get.back();
  //       Get.to(WalletScreen());
  //     }),
  //     DrawerItem('Add Bank'.tr, 'assets/icons/ic_bank.svg', navigate: () {
  //       Get.back();
  //       Get.to(const ShowBankDetails());
  //     }),
  //     if (Constant.subscriptionModel == true || Constant.adminCommission?.statut == 'yes')
  //       DrawerItem('Subscription'.tr, 'assets/icons/ic_subscription.svg', section: "Subscription", navigate: () {
  //         Get.back();
  //         Get.delete<SubscriptionController>();
  //         Get.to(SubscriptionPlanScreen(
  //           isbackButton: true,
  //         ))?.then((value) {
  //           if (value == true) {
  //             getUsrData();
  //           }
  //         });
  //       }),
  //     DrawerItem('Subscription History'.tr, 'assets/icons/ic_history.svg', navigate: () {
  //       Get.back();
  //       Get.to(SubscriptionHistoryScreen());
  //     }),
  //     DrawerItem('Change Language'.tr, 'assets/icons/ic_lang.svg', section: 'Settings & Support:'.tr, navigate: () {
  //       Get.back();
  //       Get.to(const LocalizationScreens(intentType: "dashBoard"));
  //     }),
  //     DrawerItem('Terms of Service'.tr, 'assets/icons/ic_terms.svg', navigate: () {
  //       Get.back();
  //       Get.to(const TermsOfServiceScreen());
  //     }),
  //     DrawerItem('Privacy Policy'.tr, 'assets/icons/ic_privacy.svg', navigate: () {
  //       Get.back();
  //       Get.to(const PrivacyPolicyScreen());
  //     }),
  //     DrawerItem('Dark Mode'.tr, 'assets/icons/ic_dark.svg', isSwitch: true, navigate: () {
  //       Get.back();
  //     }),
  //     DrawerItem('Rate the App'.tr, 'assets/icons/ic_star_line.svg', section: 'Feedback & Support'.tr, navigate: () async {
  //       try {
  //         if (await inAppReview.isAvailable()) {
  //           inAppReview.requestReview();
  //         } else {
  //           inAppReview.openStoreListing();
  //         }
  //       } catch (e) {
  //         log("Error triggering in-app review: $e");
  //       }
  //     }),
  //     DrawerItem('Log Out'.tr, 'assets/icons/ic_logout.svg', navigate: () {
  //       Preferences.clearKeyData(Preferences.isLogin);
  //       Preferences.clearKeyData(Preferences.user);
  //       Preferences.clearKeyData(Preferences.userId);
  //       Get.offAll(PhoneEntryScreen(mode: 'signup'));
  //     }),
  //   ];
  // }

  Rx<UserModel> userModel = UserModel().obs;

  /// Returns true only if the driver's profile was actually refreshed from
  /// the server. Callers that gate a decision on fields like statutVehicule
  /// (e.g. the "Go Online" toggle) must check this — otherwise a network
  /// hiccup silently falls back to the local cache, which can still reflect
  /// the driver's state from before they registered a vehicle.
  Future<bool> getUsrData() async {
    userModel.value = Constant.getUserData();
    if (userModel.value.userData == null) return false;

    // Initialize active status and location tracking based on cached data
    isActive.value = userModel.value.userData!.online == "yes" ? true : false;
    initLocationTracking();

    bool refreshed = false;
    try {
      Map<String, String> bodyParams = {
        'phone': userModel.value.userData!.phone.toString(),
        'user_cat': "driver",
        'email': userModel.value.userData!.email.toString(),
        'login_type': userModel.value.userData!.loginType.toString(),
      };
      final response = await http.post(Uri.parse(API.getProfileByPhone), headers: API.header, body: jsonEncode(bodyParams));
      showLog("API :: URL :: ${API.getProfileByPhone} ");
      showLog("API :: Request Body :: ${jsonEncode(bodyParams)} ");
      showLog("API :: responseBody :: ${response.body} ");
      Map<String, dynamic> responseBodyPhone = json.decode(response.body);
      if (response.statusCode == 200 && responseBodyPhone['success'] == "success") {
        log("userModel.value.userData!.online :: ${response.body.toString()}");
        ShowToastDialog.closeLoader();
        UserModel? value = UserModel.fromJson(responseBodyPhone);
        await Preferences.setString(Preferences.user, jsonEncode(value));
        userModel.value = value;
        isActive.value = userModel.value.userData!.online == "yes" ? true : false;
        initLocationTracking();
        refreshed = true;
      } else if (response.statusCode == 200 && responseBodyPhone['success'] != "success") {
        if (responseBodyPhone['error'] == 'Driver Not Found') {
          Preferences.clearKeyData(Preferences.isLogin);
          Preferences.clearKeyData(Preferences.user);
          Preferences.clearKeyData(Preferences.userId);
          ShowToastDialog.showToast('An admin has deleted your account. You no longer have access.'.tr);
          Get.offAll(PhoneEntryScreen(mode: 'signup'));
        }
      }
    } catch (e) {
      log("Error in getUsrData: $e");
      ShowToastDialog.closeLoader();
    }
    log("Constant.parcelActive :: ${Constant.parcelActive.toString() == "yes"}  || ${userModel.value.userData?.parcelDelivery.toString() == "yes"}");
    getDrawerItems();
    updateToken();
    // Fetch latest wallet balance
    await getWalletBalance();
    // Refresh Driver Kit Status
    if (Get.isRegistered<DriverKitService>()) {
      Get.find<DriverKitService>().fetchKitStatus();
    }
    return refreshed;
  }

  Future<void> getWalletBalance() async {
    try {
      final response = await http.get(
        Uri.parse("${API.wallet}?id_user=${Preferences.getInt(Preferences.userId)}&user_cat=driver"),
        headers: API.header,
      );
      showLog("API :: URL :: ${API.wallet}?id_user=${Preferences.getInt(Preferences.userId)}&user_cat=driver");
      showLog("API :: responseStatus :: ${response.statusCode} ");
      showLog("API :: responseBody :: ${response.body} ");
      Map<String, dynamic> responseBody = json.decode(response.body);

      if (response.statusCode == 200 && responseBody['success'] == "success") {
        // Update wallet amount in user model
        if (userModel.value.userData != null) {
          userModel.value.userData!.amount = responseBody['data']['amount']?.toString() ?? userModel.value.userData!.amount;
          userModel.value.userData!.earnAmount = responseBody['data']['earn_amount']?.toString() ?? userModel.value.userData!.earnAmount;
          // Save updated user data
          await Preferences.setString(Preferences.user, jsonEncode(userModel.value));
        }
      }
    } catch (e) {
      log("Error in getWalletBalance: $e");
    }
  }

  RxString todayEarnings = "0".obs;
  RxString todayBookings = "0".obs;
  RxString driverRating = "0.0".obs;
  RxInt driverRatingCount = 0.obs;
  RxString pendingRequestsCount = "0".obs;
  Rx<Map<String, dynamic>?> activeService = Rx<Map<String, dynamic>?>(null);
  RxBool isStatsLoading = false.obs;

  Future<void> fetchDashboardStats() async {
    final driverId = Preferences.getInt(Preferences.userId);
    if (driverId == 0) return;
    isStatsLoading.value = true;
    try {
      final response = await http.get(
        Uri.parse("${API.driverDashboardStats}/?driver_id=$driverId"),
        headers: API.header,
      );
      final body = json.decode(response.body);
      if (response.statusCode == 200 && body['success'].toString().toLowerCase() == 'success') {
        final data = body['data'];
        todayEarnings.value = data['today_earnings']?.toString() ?? "0";
        todayBookings.value = data['today_bookings']?.toString() ?? "0";
        driverRating.value = data['rating']?.toString() ?? "0.0";
        driverRatingCount.value = int.tryParse(data['rating_count']?.toString() ?? "0") ?? 0;
        pendingRequestsCount.value = data['pending_requests']?.toString() ?? "0";
        activeService.value = data['active_service'] as Map<String, dynamic>?;
      }
    } catch (e) {
      log("Error in fetchDashboardStats: $e");
    } finally {
      isStatsLoading.value = false;
    }
  }

  RxBool isActive = true.obs;
  RxInt selectedDrawerIndex = 0.obs;
  var drawerItems = [];
  final InAppReview inAppReview = InAppReview.instance;

  Future<void> updateLocationInRTDB({
    required String latitude,
    required String longitude,
    required String rotation,
    required bool active,
  }) async {
    try {
      final String driverId = Preferences.getInt(Preferences.userId).toString();
      if (driverId.isEmpty || driverId == "0") return;

      final DatabaseReference driverRef = FirebaseDatabase.instance.ref("drivers/$driverId");
      await driverRef.set({
        "driver_latitude": latitude,
        "driver_longitude": longitude,
        "rotation": rotation,
        "active": active,
        "updatedAt": ServerValue.timestamp,
      });
    } catch (e) {
      showLog("Firebase RTDB Error: $e");
    }
  }

  Future<void> updateActiveStatusInRTDB(bool active) async {
    try {
      final String driverId = Preferences.getInt(Preferences.userId).toString();
      if (driverId.isEmpty || driverId == "0") return;

      final DatabaseReference driverRef = FirebaseDatabase.instance.ref("drivers/$driverId");
      await driverRef.update({
        "active": active,
        "updatedAt": ServerValue.timestamp,
      });
    } catch (e) {
      showLog("Firebase RTDB Error: $e");
    }
  }

  Future<void> updateCurrentLocation() async {
    if (userModel.value.userData == null) return;
    if (isActive.value) {
      PermissionStatus permissionStatus = await location.hasPermission();
      if (permissionStatus == PermissionStatus.granted) {
        _enableBackgroundLocationTracking();
      } else {
        Get.dialog(
          LocationPermissionDisclosureDialog(
            onAccept: () async {
              Get.back();
              PermissionStatus newStatus = await location.requestPermission();
              if (newStatus == PermissionStatus.granted) {
                _enableBackgroundLocationTracking();
              } else {
                ShowToastDialog.showToast("Permission Denied");
                isActive.value = false;
              }
            },
            onDecline: () {
              Get.back();
              ShowToastDialog.showToast("Permission Denied");
              isActive.value = false;
            },
          ),
          barrierDismissible: false,
        );
      }
    } else {
      locationSubscription?.cancel();
      updateActiveStatusInRTDB(false);
    }
  }

  void _enableBackgroundLocationTracking() {
    location.enableBackgroundMode(enable: true).catchError((e) { log("Error enabling background mode: $e"); return false; });
    location.changeSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: double.parse(Constant.driverLocationUpdateUnit.toString()),
    );
    locationSubscription?.cancel();
    locationSubscription = location.onLocationChanged.listen((locationData) {
      LocationData currentLocation = locationData;
      Constant.currentLocation = locationData;
      updateLocationInRTDB(
        latitude: currentLocation.latitude.toString(),
        longitude: currentLocation.longitude.toString(),
        rotation: currentLocation.heading.toString(),
        active: true,
      );
      setCurrentLocation(currentLocation.latitude.toString(), currentLocation.longitude.toString());
    });
  }

  // deleteCurrentOrderLocation() {
//   RideData? rideData = Constant.getCurrentRideData();
//   if (rideData != null) {
//     String orderId = "";
//     if (rideData.rideType! == 'driver') {
//       orderId = '${rideData.idUserApp}-${rideData.id}-${rideData.idConducteur}';
//     } else {
//       orderId = (double.parse(rideData.idUserApp.toString()) < double.parse(rideData.idConducteur!))
//           ? '${rideData.idUserApp}-${rideData.id}-${rideData.idConducteur}'
//           : '${rideData.idConducteur}-${rideData.id}-${rideData.idUserApp}';
//     }
//     Location location = Location();
//     location.enableBackgroundMode(enable: false);
//     Constant.locationUpdate.doc(orderId).delete().then((value) async {
//       await updateCurrentLocation(data: rideData);
//       Preferences.clearKeyData(Preferences.currentRideData);
//       locationSubscription.cancel();
//     });
//   }
// }

  Future<dynamic> setCurrentLocation(String latitude, String longitude) async {
    try {
      if (userModel.value.userData == null) return null;
      Map<String, dynamic> bodyParams = {
        'id_user': Preferences.getInt(Preferences.userId),
        'user_cat': userModel.value.userData!.userCat,
        'latitude': latitude,
        'longitude': longitude
      };
      final response = await http.post(Uri.parse(API.updateLocation), headers: API.header, body: jsonEncode(bodyParams));
      showLog("API :: URL :: ${API.updateLocation} ");
      showLog("API :: Request Body :: ${jsonEncode(bodyParams)} ");
      showLog("API :: Request Header :: ${API.header.toString()} ");
      showLog("API :: responseStatus :: ${response.statusCode} ");
      showLog("API :: responseBody :: ${response.body} ");
      Map<String, dynamic> responseBody = json.decode(response.body);
      if (response.statusCode == 200) {
        return responseBody;
      } else if (response.statusCode == 401) {
        Preferences.clearKeyData(Preferences.isLogin);
        Preferences.clearKeyData(Preferences.user);
        Preferences.clearKeyData(Preferences.userId);
        ShowToastDialog.showToast('An admin has deleted your account. You no longer have access.'.tr);
        Get.offAll(PhoneEntryScreen(mode: 'signup'));
      }
    } on TimeoutException catch (e) {
      ShowToastDialog.showToast(e.message.toString());
    } on SocketException catch (e) {
      ShowToastDialog.showToast(e.message.toString());
    } on Error catch (e) {
      ShowToastDialog.showToast(e.toString());
    } catch (e) {
      ShowToastDialog.showToast(e.toString());
    }
    return null;
  }

  Future<dynamic> updateFCMToken(String token) async {
    try {
      if (userModel.value.userData == null) return null;
      String userId = Preferences.getString(Preferences.userId);
      if (userId.isEmpty || userId == "0") {
        userId = userModel.value.userData!.id ?? "";
      }
      String phone = userModel.value.userData!.phone ?? "";

      Map<String, dynamic> bodyParams = {
        'user_id': userId,
        'driver_id': userId,
        'phone': phone,
        'fcm_id': token,
        'device_id': "",
        'user_cat': userModel.value.userData!.userCat ?? "driver"
      };
      final response = await http.post(Uri.parse(API.updateToken), headers: API.header, body: jsonEncode(bodyParams));
      showLog("API :: URL :: ${API.updateToken} ");
      showLog("API :: Request Body :: ${jsonEncode(bodyParams)} ");
      showLog("API :: Request Header :: ${API.header.toString()} ");
      showLog("API :: responseStatus :: ${response.statusCode} ");
      showLog("API :: responseBody :: ${response.body} ");
      Map<String, dynamic> responseBody = json.decode(response.body);
      if (response.statusCode == 200) {
        return responseBody;
      } else {}
    } on TimeoutException catch (e) {
      ShowToastDialog.showToast(e.message.toString());
    } on SocketException catch (e) {
      ShowToastDialog.showToast(e.message.toString());
    } on Error catch (e) {
      ShowToastDialog.showToast(e.toString());
    } catch (e) {
      ShowToastDialog.showToast(e.toString());
    }
    return null;
  }

  Future<dynamic> changeOnlineStatus(bodyParams) async {
    try {
      ShowToastDialog.showLoader("Please wait");
      final response = await http.post(Uri.parse(API.changeStatus), headers: API.header, body: jsonEncode(bodyParams));
      showLog("API :: URL :: ${API.changeStatus} ");
      showLog("API :: Request Body :: ${jsonEncode(bodyParams)} ");
      showLog("API :: Request Header :: ${API.header.toString()} ");
      showLog("API :: responseStatus :: ${response.statusCode} ");
      showLog("API :: responseBody :: ${response.body} ");
      Map<String, dynamic> responseBody = json.decode(response.body);
      print("====>");
      print(response.statusCode);
      print(response.body);
      if (response.statusCode == 200) {
        ShowToastDialog.closeLoader();
        return responseBody;
      } else {
        ShowToastDialog.closeLoader();
      }
    } on TimeoutException catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.message.toString());
    } on SocketException catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.message.toString());
    } on Error catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.toString());
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.toString());
    }
    return null;
  }

  Future<dynamic> getPaymentSettingData() async {
    try {
      final response = await http.get(Uri.parse(API.paymentSetting), headers: API.header);
      showLog("API :: URL :: ${API.paymentSetting} ");
      showLog("API :: Request Header :: ${API.header.toString()} ");
      showLog("API :: responseStatus :: ${response.statusCode} ");
      showLog("API :: responseBody :: ${response.body} ");
      Map<String, dynamic> responseBody = json.decode(response.body);
      if (response.statusCode == 200 && responseBody['success'] == "success") {
        Preferences.setString(Preferences.paymentSetting, jsonEncode(responseBody));
      } else if (response.statusCode == 200 && responseBody['success'] == "Failed") {
      } else {}
    } on TimeoutException catch (e) {
      ShowToastDialog.showToast(e.message.toString());
    } on SocketException catch (e) {
      ShowToastDialog.showToast(e.message.toString());
    } on Error catch (e) {
      ShowToastDialog.showToast(e.toString());
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.toString());
    }
    return null;
  }

  Future<void> onSelectItem(int index,bool isLogin) async {
    Get.back();
    if (index >= drawerItems.length) return;
    var item = drawerItems[index];
    final bool hasAadhar = (Preferences.getString('user_aadhar_number') ?? Preferences.getString('driver_aadhar_number') ?? '').isNotEmpty;
    final String partnerTitle = hasAadhar ? 'Partner Dashboard'.tr : 'Join as a Partner'.tr;

    if (item.title == 'Wallet'.tr || item.title == 'Smart Value'.tr || item.title == 'My Profile'.tr || item.title == 'Update Categories'.tr || item.title == 'Join as Partner'.tr || item.title == 'Join as a Partner'.tr || item.title == 'Partner Dashboard'.tr || item.title == 'Change Password'.tr || item.title == 'Refer a Friend'.tr || item.title == 'Marketplace'.tr) {
      if (!isLogin) {
        Get.to(PhoneEntryScreen(mode: 'signup'));
        return;
      }
    }
    if (item.title == 'Wallet'.tr || item.title == 'Smart Value'.tr) {
      Get.to(WalletScreen());
    } else if (item.title == 'My Profile'.tr) {
      Get.to(MyProfileScreen());
    } else if (item.title == 'Marketplace'.tr) {
      final url = OnboardingUrl.build('/onboarding/marketplace.html');
      Get.to(() => WebViewScreen(url: url, title: 'Marketplace'.tr));
    } else if (item.title == 'Food Ordering'.tr || item.title == 'Food Order'.tr) {
      final url = OnboardingUrl.build('/onboarding/food.html');
      Get.to(() => WebViewScreen(url: url, title: 'Food Ordering'.tr));
    } else if (item.title == 'Update Categories'.tr) {
      openDriverOnboardingEditor(
        mode: 'edit_profile',
        title: 'Edit Profile & Services'.tr,
      );
    } else if (item.title == 'Change Password'.tr) {
      Get.to(ChangePasswordScreen());
    } else if (item.title == 'Refer a Friend'.tr || item.title == 'Join as a Partner'.tr || item.title == 'Join as Partner'.tr || item.title == 'Partner Dashboard'.tr || item.title == partnerTitle) {
      Get.to(() => const ReferralEarnScreen());
    } else if (item.title == 'Terms & Conditions'.tr) {
      Get.to(const TermsOfServiceScreen());
    } else if (item.title == 'Privacy & Policy'.tr) {
      Get.to(const PrivacyPolicyScreen());
    } else if (item.title == 'Rate the App'.tr) {
      try {
        final Uri marketUri = Uri.parse("market://details?id=com.fiinwaybusiness");
        final Uri playStoreUri = Uri.parse("https://play.google.com/store/apps/details?id=com.fiinwaybusiness");
        if (await canLaunchUrl(marketUri)) {
          await launchUrl(marketUri, mode: LaunchMode.externalApplication);
        } else if (await canLaunchUrl(playStoreUri)) {
          await launchUrl(playStoreUri, mode: LaunchMode.externalApplication);
        } else {
          await launchUrl(playStoreUri);
        }
      } catch (e) {
        log("Error opening play store for rating: $e");
        try {
          final Uri fallbackUri = Uri.parse("https://play.google.com/store/apps/details?id=com.fiinwaybusiness");
          await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
        } catch (_) {}
      }
    } else if (item.title == 'Log Out'.tr) {
      ShowToastDialog.showLoader("Logging out...".tr);
      try {
        final driverId = Preferences.getInt(Preferences.userId);
        if (driverId != 0) {
          await changeOnlineStatus({'id_driver': driverId, 'online': 'no'});
        }
      } catch (_) {}
      try {
        await updateFCMToken('');
      } catch (_) {}
      try {
        await FirebaseMessaging.instance.unsubscribeFromTopic('cabme_driver');
        await FirebaseMessaging.instance.deleteToken();
      } catch (_) {}
      ShowToastDialog.closeLoader();
      Preferences.clearKeyData(Preferences.isLogin);
      Preferences.clearKeyData(Preferences.user);
      Preferences.clearKeyData(Preferences.userId);
      Get.offAll(PhoneEntryScreen(mode: 'signup'));
    } else {
      selectedDrawerIndex.value = index;
    }
  }

  void getDrawerItems() {
    final bool hasAadhar = (Preferences.getString('user_aadhar_number') ?? Preferences.getString('driver_aadhar_number') ?? '').isNotEmpty;
    final String partnerTitle = hasAadhar ? 'Partner Dashboard'.tr : 'Join as a Partner'.tr;
    final String partnerDesc = hasAadhar 
        ? 'Manage your partner team, view earnings and rewards'.tr 
        : 'Submit Aadhaar to become a partner and earn rewards'.tr;

    drawerItems = [
      DrawerItem(
        title: 'Home'.tr,
        description: '',
        icon: 'assets/icons/ic_map.svg',
      ),
      DrawerItem(
        title: 'Marketplace'.tr,
        description: 'Buy and sell goods with other users and drivers',
        icon: 'assets/icons/ic_all_car.svg',
        section: 'Services'.tr,
      ),
      DrawerItem(
        title: 'Smart Value'.tr,
        description: 'Manage transactions, view balance and earnings',
        icon: 'assets/icons/ic_wallet.svg',
        section: 'Account & Payments'.tr,
      ),
      DrawerItem(
        title: 'My Profile'.tr,
        description: 'View and update your personal profile details',
        icon: 'assets/icons/ic_profile.svg',
      ),
      DrawerItem(
        title: partnerTitle,
        description: partnerDesc,
        icon: 'assets/icons/ic_refer.svg',
      ),
      DrawerItem(
        title: 'Change Password'.tr,
        description: 'Update your password for better account security',
        icon: 'assets/icons/ic_lock.svg',
      ),
      DrawerItem(
        title: 'Terms & Conditions'.tr,
        description: 'Read detailed user agreement and policies',
        icon: 'assets/icons/ic_terms.svg',
        section: 'App Settings'.tr,
      ),
      DrawerItem(
        title: 'Privacy & Policy'.tr,
        description: 'Learn how we use and protect data',
        icon: 'assets/icons/ic_privacy.svg',
      ),
      DrawerItem(
        title: 'Dark Mode'.tr,
        description: '',
        icon: 'assets/icons/ic_dark.svg',
        isSwitch: true,
      ),
      DrawerItem(
        title: 'Rate the App'.tr,
        description: 'Give feedback and rate your app experience',
        icon: 'assets/icons/ic_star_line.svg',
        section: 'Feedback & Support'.tr,
      ),
      DrawerItem(
        title: 'Log Out'.tr,
        description: 'Sign out and return to login screen',
        icon: 'assets/icons/ic_logout.svg',
      ),
    ];
  }

  RxList<dynamic> driverServices = <dynamic>[].obs;
  RxBool isLoadingServices = false.obs;

  Future<void> fetchDriverServices() async {
    try {
      final String driverId = Preferences.getInt(Preferences.userId).toString();
      if (driverId.isEmpty || driverId == "0") return;

      isLoadingServices.value = true;
      final response = await http.get(
        Uri.parse("${API.getDriverServices}?driver_id=$driverId"),
        headers: API.header,
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> responseBody = json.decode(response.body);
        if (responseBody['success'] == "success") {
          driverServices.value = responseBody['data'] ?? [];
        }
      }
    } catch (e) {
      log("Error fetching driver services: $e");
    } finally {
      isLoadingServices.value = false;
    }
  }

  Future<bool> toggleService(dynamic categoryId, String statut) async {
    try {
      final String driverId = Preferences.getInt(Preferences.userId).toString();
      if (driverId.isEmpty || driverId == "0") return false;

      ShowToastDialog.showLoader("Please wait");
      final response = await http.post(
        Uri.parse(API.toggleDriverService),
        headers: API.header,
        body: jsonEncode({
          'driver_id': driverId,
          'category_id': categoryId,
          'statut': statut,
        }),
      );

      ShowToastDialog.closeLoader();
      if (response.statusCode == 200) {
        Map<String, dynamic> responseBody = json.decode(response.body);
        if (responseBody['success'] == "success") {
          // Find the service and update its status locally
          for (var service in driverServices) {
            if (service['category_id'] == categoryId || service['subcategory_id'] == categoryId) {
              service['statut'] = statut;
            }
          }
          driverServices.refresh();
          return true;
        }
      }
    } catch (e) {
      ShowToastDialog.closeLoader();
      log("Error toggling service: $e");
    }
    return false;
  }
}


