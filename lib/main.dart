import 'package:flutter_callkit_incoming/entities/call_event.dart';
// ignore_for_file: empty_catches, must_be_immutable, unused_local_variable, deprecated_member_use

import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'package:cabme_driver/constant/constant.dart';
import 'package:cabme_driver/constant/show_toast_dialog.dart';
import 'package:cabme_driver/controller/dash_board_controller.dart';
import 'package:cabme_driver/controller/settings_controller.dart';
import 'package:cabme_driver/firebase_options.dart';
import 'package:cabme_driver/page/MainDashBoard/screen/main_dashboard.dart';
import 'package:cabme_driver/page/chats_screen/conversation_screen.dart';
import 'package:cabme_driver/page/features/SmartValue/AddPerson/controller/add_user_controller.dart';
import 'package:cabme_driver/page/features/SmartValue/MPinChange/controller/mpin_change_controller.dart';
import 'package:cabme_driver/service/api.dart';
import 'package:cabme_driver/service/localization_service.dart';
import 'package:cabme_driver/page/auth_screens/phone_entry_screen.dart';
import 'package:cabme_driver/themes/constant_colors.dart';
import 'package:cabme_driver/themes/styles.dart';
import 'package:cabme_driver/utils/dark_theme_provider.dart';
import 'package:cabme_driver/utils/Preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:cabme_driver/model/ride_model.dart';
import 'package:cabme_driver/page/new_ride_screens/incoming_ride_screen.dart';
import 'package:cabme_driver/page/route_view_screen/route_view_screen.dart';
import 'package:cabme_driver/page/route_view_screen/route_osm_view_screen.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/entities/android_params.dart';
import 'package:flutter_callkit_incoming/entities/ios_params.dart';
import 'package:flutter_callkit_incoming/entities/notification_params.dart';
import 'package:cabme_driver/controller/my_booking_controller.dart';
import 'package:cabme_driver/page/booking/my_booking_screen.dart';
import 'package:cabme_driver/page/booking/service_flow/service_booking_flow.dart';
import 'package:cabme_driver/service/in_app_sound_service.dart';



@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    log('Firebase initializeApp in background error: $e');
  }

  final bool isCancelled = message.data['tag'] == 'booking_taken' ||
      message.data['tag'] == 'booking_cancelled' ||
      message.data['statut'] == 'taken' ||
      message.data['statut'] == 'cancelled';

  if (isCancelled) {
    try {
      final bookingId = message.data['id_ride']?.toString() ??
          message.data['booking_id']?.toString() ??
          message.data['id']?.toString() ?? '';
      if (bookingId.isNotEmpty) {
        await FlutterCallkitIncoming.endCall(bookingId);
        final notifId = bookingId.hashCode & 0x7FFFFFFF;
        await NotificationService.cancelNotification(notifId);
      } else {
        await FlutterCallkitIncoming.endAllCalls();
      }
    } catch (e) {
      log('Error handling booking cancellation in background: $e');
    }
    return;
  }

  final bool isHomeService = message.data['type'] == 'homeservice' ||
      message.data['tag'] == 'homeservicerequest' ||
      message.data['tag'] == 'homeservicenotif' ||
      (message.data['booking_id'] != null && message.data['booking_id'].toString().isNotEmpty);

  final bool isRideRequest = message.data['statut'] == 'new' ||
      message.data['tag'] == 'ridenewrider' ||
      message.data['tag'] == 'parcelnew';

  if (isRideRequest) {
    try {
      final rideData = RideData.fromJson(message.data);
      if (rideData.id != null && rideData.id!.isNotEmpty && rideData.id != 'null') {
        await showCallkitIncoming(message.data);
      }
    } catch (e) {
      log('Error showing callkit in background for ride: $e');
    }
  } else if (isHomeService) {
    try {
      await showCallkitIncomingForHomeService(message.data);
    } catch (e) {
      log('Error showing callkit in background for home service: $e');
    }
  }

  try {
    await NotificationService.display(message);
  } catch (e) {
    log('Error displaying background notification: $e');
  }
}

Future<void> showCallkitIncoming(Map<String, dynamic> data) async {
  final rideData = RideData.fromJson(data);
  CallKitParams callKitParams = CallKitParams(
    id: rideData.id ?? "unknown_id",
    nameCaller: '${rideData.prenom ?? ''} ${rideData.nom ?? ''}'.trim().isNotEmpty
        ? '${rideData.prenom ?? ''} ${rideData.nom ?? ''}'
        : 'New Customer',
    appName: 'Fiinway Driver',
    avatar: 'https://i.pravatar.cc/100', // You can use rideData.photoPath if available
    handle: '${rideData.departName ?? 'Pickup'} -> ${rideData.destinationName ?? 'Dropoff'}',
    type: 0,
    missedCallNotification: const NotificationParams(
      showNotification: true,
      isShowCallback: false,
      subtitle: 'Missed ride request',
      callbackText: 'View',
    ),
    extra: data,
    headers: <String, dynamic>{},
    android: const AndroidParams(
      isCustomNotification: true,
      isShowLogo: false,
      ringtonePath: 'ride_request_sound',
      backgroundColor: '#0955fa',
      actionColor: '#4CAF50',
      textColor: '#ffffff',
      textAccept: 'Accept',
      textDecline: 'Decline',
      isShowFullLockedScreen: false,
      isFullScreen: false,
    ),
    ios: const IOSParams(
      iconName: 'CallKitLogo',
      handleType: '',
      supportsVideo: false,
      maximumCallGroups: 2,
      maximumCallsPerCallGroup: 1,
      audioSessionMode: 'default',
      audioSessionActive: true,
      audioSessionPreferredSampleRate: 44100.0,
      audioSessionPreferredIOBufferDuration: 0.005,
      supportsDTMF: true,
      supportsHolding: true,
      supportsGrouping: false,
      supportsUngrouping: false,
      ringtonePath: 'ride_request_sound',
    ),
  );
  await FlutterCallkitIncoming.showCallkitIncoming(callKitParams);
}

Future<void> showCallkitIncomingForHomeService(Map<String, dynamic> data) async {
  final bookingId = data['booking_id']?.toString() ?? 'booking_${DateTime.now().millisecondsSinceEpoch}';
  final serviceName = data['service_name']?.toString() ?? 'Home Service Request';
  final address = data['service_address']?.toString() ?? data['address']?.toString() ?? 'Service Location';
  CallKitParams callKitParams = CallKitParams(
    id: bookingId,
    nameCaller: serviceName,
    appName: 'Fiinway Partner',
    avatar: 'https://i.pravatar.cc/100',
    handle: address,
    type: 0,
    missedCallNotification: const NotificationParams(
      showNotification: true,
      isShowCallback: false,
      subtitle: 'Missed booking request',
      callbackText: 'View',
    ),
    extra: data,
    headers: <String, dynamic>{},
    android: const AndroidParams(
      isCustomNotification: true,
      isShowLogo: false,
      ringtonePath: 'ride_request_sound',
      backgroundColor: '#0955fa',
      actionColor: '#4CAF50',
      textColor: '#ffffff',
      textAccept: 'Accept',
      textDecline: 'Decline',
      isShowFullLockedScreen: false,
      isFullScreen: false,
    ),
    ios: const IOSParams(
      iconName: 'CallKitLogo',
      handleType: '',
      supportsVideo: false,
      maximumCallGroups: 2,
      maximumCallsPerCallGroup: 1,
      audioSessionMode: 'default',
      audioSessionActive: true,
      audioSessionPreferredSampleRate: 44100.0,
      audioSessionPreferredIOBufferDuration: 0.005,
      supportsDTMF: true,
      supportsHolding: true,
      supportsGrouping: false,
      supportsUngrouping: false,
      ringtonePath: 'ride_request_sound',
    ),
  );
  await FlutterCallkitIncoming.showCallkitIncoming(callKitParams);
}

class FirebaseService {
  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e) {
      log('Firebase initialization error: $e');
    }

    try {
      await FirebaseAppCheck.instance.activate(
        webProvider: ReCaptchaV3Provider('recaptcha-v3-site-key'),
        androidProvider: AndroidProvider.debug,
        appleProvider: AppleProvider.appAttest,
      ).timeout(const Duration(seconds: 4));
    } catch (e) {
      log('Firebase App Check error: $e');
    }
  }

  static Future<void> setupMessaging() async {
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
  }



  static Future<void> setupInteractedMessage(BuildContext context) async {
    await NotificationService.initialize(context);
    await FirebaseMessaging.instance.subscribeToTopic("cabme_driver");

    // Handle CallKit events (Accept / Decline)
    

    FlutterCallkitIncoming.onEvent.listen((event) async {
      if (event is CallEventActionCallAccept) {
        final extra = event.callKitParams.extra;
        if (extra != null) {
          final Map<String, dynamic> data = Map<String, dynamic>.from(extra);
          RemoteMessage msg = RemoteMessage(data: data);
          await _handleNotificationTap(msg);
        }
      } else if (event is CallEventActionCallDecline) {
        // Handle decline if needed, or simply let it close
      }
    });

    // Check for active calls if app started from Callkit Accept
    var activeCalls = await FlutterCallkitIncoming.activeCalls();
    if (activeCalls is List && activeCalls.isNotEmpty) {
      final extra = activeCalls.first.extra;
      if (extra != null) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(extra);
        RemoteMessage msg = RemoteMessage(data: data);
        await _handleNotificationTap(msg);
      }
    }

    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      log('Handling initialMessage from terminated state: ${initialMessage.data}');
      _handleNotificationTap(initialMessage);
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log('Firebase onMessage received: ${message.data}');

      final bool isCancelled = message.data['tag'] == 'booking_taken' ||
          message.data['tag'] == 'booking_cancelled' ||
          message.data['statut'] == 'taken' ||
          message.data['statut'] == 'cancelled';

      if (isCancelled) {
        InAppSoundService.stop();
        final bookingId = message.data['id_ride']?.toString() ??
            message.data['booking_id']?.toString() ??
            message.data['id']?.toString() ?? '';
        if (bookingId.isNotEmpty) {
          FlutterCallkitIncoming.endCall(bookingId);
          final notifId = bookingId.hashCode & 0x7FFFFFFF;
          NotificationService.cancelNotification(notifId);
        } else {
          FlutterCallkitIncoming.endAllCalls();
        }

        if (Get.currentRoute.contains('IncomingRideScreen') || Get.isDialogOpen == true) {
          Get.back();
          ShowToastDialog.showToast("This booking was accepted by another provider.".tr);
        }
        return;
      }

      final bool isHomeService = message.data['type'] == 'homeservice' ||
          message.data['tag'] == 'homeservicerequest' ||
          message.data['tag'] == 'homeservicenotif' ||
          (message.data['booking_id'] != null && message.data['booking_id'].toString().isNotEmpty);

      final bool isRideRequest = message.data['statut'] == 'new' ||
          message.data['tag'] == 'ridenewrider' ||
          message.data['tag'] == 'parcelnew';

      if (isHomeService) {
        InAppSoundService.playIncomingBookingAlert();
        if (Get.isRegistered<MyBookingController>()) {
          Get.find<MyBookingController>().fetchBookings(showLoader: false);
        }
        showCallkitIncomingForHomeService(message.data);
        NotificationService.display(message);
        return;
      }

      if (isRideRequest) {
        try {
          final rideData = RideData.fromJson(message.data);
          if (rideData.id != null &&
              rideData.id!.isNotEmpty &&
              rideData.id != 'null') {
            InAppSoundService.playIncomingBookingAlert();
            showCallkitIncoming(message.data);
          }
        } catch (e) {
          log('Error showing callkit incoming screen: $e');
        }
      }
      if (message.notification != null || isRideRequest) {
        NotificationService.display(message);
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      await _handleNotificationTap(message);
    });
  }

  static Future<void> _handleNotificationTap(RemoteMessage message) async {
    try {
      log('Handling notification tap: ${message.data}');

      // 1. Prioritize Home Service / Booking notifications
      final bool isHomeService = message.data['type'] == "homeservice" ||
          message.data['tag'] == "homeservicerequest" ||
          message.data['tag'] == "homeservicenotif" ||
          (message.data['booking_id'] != null && message.data['booking_id'].toString().isNotEmpty);

      if (isHomeService) {
        final bookingId = message.data['booking_id']?.toString() ?? '';
        final myBookingCtrl = Get.isRegistered<MyBookingController>()
            ? Get.find<MyBookingController>()
            : Get.put(MyBookingController());
        if (bookingId.isNotEmpty) {
          final booking = await myBookingCtrl.fetchSingleBooking(bookingId);
          if (booking != null) {
            openServiceBookingFlow(booking, myBookingCtrl);
            return;
          }
        }
        await Get.to(() => const MyBookingScreen(initialTab: 0));
        return;
      }

      // 2. Chat / Conversation notifications
      if (message.data['status'] == "done") {
        await Get.to(ConversationScreen(), arguments: {
          'receiverId': int.parse(
              json.decode(message.data['message'])['senderId'].toString()),
          'orderId': int.parse(
              json.decode(message.data['message'])['orderId'].toString()),
          'receiverName':
              json.decode(message.data['message'])['senderName'].toString(),
          'receiverPhoto':
              json.decode(message.data['message'])['senderPhoto'].toString(),
        });
        return;
      }

      // 3. New Ride Request (Taxi)
      if (message.data['statut'] == "new" ||
          message.data['tag'] == "ridenewrider") {
        try {
          final rideData = RideData.fromJson(message.data);
          if (rideData.id != null &&
              rideData.id!.isNotEmpty &&
              rideData.id != 'null') {
            await Get.to(() => IncomingRideScreen(rideData: rideData));
            return;
          }
        } catch (e) {
          log('Error parsing rideData on tap: $e');
        }
        await Get.to(() => const MainDashboard());
        return;
      }

      // 4. Confirmed / On Ride (Taxi)
      if (message.data['statut'] == "confirmed" ||
          message.data['statut'] == "on ride") {
        try {
          final rideData = RideData.fromJson(message.data);
          if (rideData.id != null &&
              rideData.id!.isNotEmpty &&
              rideData.id != 'null') {
            var argumentData = {'type': rideData.statut, 'data': rideData};
            if (Constant.liveTrackingMapType == "inappmap") {
              if (Constant.selectedMapType == 'osm') {
                await Get.to(() => const RouteOsmViewScreen(),
                    arguments: argumentData);
              } else {
                await Get.to(() => const RouteViewScreen(),
                    arguments: argumentData);
              }
            } else {
              Constant.redirectMap(
                latitude: double.parse(rideData.latitudeArrivee!),
                longLatitude: double.parse(rideData.longitudeArrivee!),
                name: rideData.destinationName!,
              );
            }
            return;
          }
        } catch (e) {
          log('Error parsing rideData on confirmed/on ride tap: $e');
        }
        await Get.to(() => const MainDashboard());
        return;
      }

      if (message.data['statut'] == "rejected") {
        await Get.to(() => const MainDashboard());
        return;
      }

      if (message.data['type'] == "payment received") {
        DashBoardController dashBoardController =
            Get.put(DashBoardController());
        dashBoardController.selectedDrawerIndex.value = 4;
        await Get.to(() => const MainDashboard());
        return;
      }

      await Get.to(() => const MainDashboard());
    } catch (e) {
      log('Error handling notification tap: $e');
    }
  }
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin
      _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> initialize([BuildContext? context]) async {
    if (_initialized) return;

    // General high-importance channel
    AndroidNotificationChannel generalChannel =
        const AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      importance: Importance.high,
    );

    // Dedicated request channel — max importance, custom alert sound
    AndroidNotificationChannel rideChannel = AndroidNotificationChannel(
      'ride_requests',
      'New Ride & Booking Requests',
      description: 'Alerts for incoming ride and home service booking requests',
      importance: Importance.max,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound('ride_request_sound'),
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 500, 200, 500, 200, 500]),
    );

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    var iosInitializationSettings = const DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final InitializationSettings initializationSettings =
        InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: iosInitializationSettings);

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onDidReceiveNotificationResponse:
            (NotificationResponse response) async {
      if (response.payload != null && response.payload!.isNotEmpty) {
        try {
          Map<String, dynamic> data = jsonDecode(response.payload!);
          RemoteMessage msg = RemoteMessage(data: data);
          await FirebaseService._handleNotificationTap(msg);
        } catch (e) {
          log('Error handling local notification tap response: $e');
        }
      }
    });

    final android =
        _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(generalChannel);
    await android?.createNotificationChannel(rideChannel);
    _initialized = true;
  }

  static Future<void> cancelNotification(int id) async {
    try {
      await initialize();
      await _flutterLocalNotificationsPlugin.cancel(id);
    } catch (e) {
      log('Error cancelling notification: $e');
    }
  }

  static Future<void> display(RemoteMessage message) async {
    try {
      await initialize();

      final isHomeService = message.data['type'] == 'homeservice' ||
          message.data['tag'] == 'homeservicerequest' ||
          message.data['tag'] == 'homeservicenotif' ||
          (message.data['booking_id'] != null && message.data['booking_id'].toString().isNotEmpty);

      final isRideRequest = message.data['statut'] == 'new' ||
          message.data['tag'] == 'ridenewrider' ||
          message.data['tag'] == 'parcelnew';

      final bool isAlert = isHomeService || isRideRequest;

      final bookingId = message.data['id_ride']?.toString() ??
          message.data['booking_id']?.toString() ??
          message.data['id']?.toString() ?? '';
      final int id = bookingId.isNotEmpty
          ? (bookingId.hashCode & 0x7FFFFFFF)
          : (DateTime.now().millisecondsSinceEpoch ~/ 1000);

      String title =
          message.notification?.title ?? message.data['title'] ?? '';
      String body = message.notification?.body ?? message.data['body'] ?? '';

      if (title.isEmpty) {
        if (isHomeService) {
          title = 'New Service Booking Request!';
          final sName = message.data['service_name'] ?? 'Home Service';
          body = 'New request for $sName. Tap to view and accept.';
        } else if (isRideRequest) {
          final isParcel = message.data['tag'] == 'parcelnew';
          title = isParcel ? 'New Parcel Delivery Request!' : 'New Ride Request!';
          final depart = message.data['depart_name'] ?? '';
          final dest = message.data['destination_name'] ?? '';
          body = depart.isNotEmpty ? '$depart -> $dest' : 'Tap to view and accept.';
        } else {
          title = 'Fiinway';
        }
      }

      final NotificationDetails notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          isAlert ? 'ride_requests' : 'high_importance_channel',
          isAlert ? 'New Ride & Booking Requests' : 'High Importance Notifications',
          channelDescription: isAlert
              ? 'Alerts for incoming ride and booking requests'
              : 'General notifications',
          importance: isAlert ? Importance.max : Importance.high,
          priority: isAlert ? Priority.max : Priority.high,
          sound: isAlert
              ? const RawResourceAndroidNotificationSound('ride_request_sound')
              : null,
          fullScreenIntent: false, // NO full-screen takeover per instruction
          autoCancel: true,
          ongoing: false,
          visibility: isAlert
              ? NotificationVisibility.public
              : NotificationVisibility.private,
          ticker: isAlert ? 'New booking request arrived' : null,
          enableVibration: true,
          vibrationPattern: isAlert
              ? Int64List.fromList([0, 500, 200, 500, 200, 500])
              : null,
          playSound: true,
          category: isAlert
              ? AndroidNotificationCategory.call
              : AndroidNotificationCategory.message,
        ),
        iOS: DarwinNotificationDetails(
          sound: isAlert ? 'ride_request_sound.caf' : 'default',
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      await _flutterLocalNotificationsPlugin.show(
        id,
        title,
        body,
        notificationDetails,
        payload: jsonEncode(message.data),
      );
    } catch (e) {
      log('Notification display error: $e');
    }
  }
}

class AppInitialization {
  static Future<void> initializeApp() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize preferences
    try {
      await Preferences.initPref();
    } catch (e) {
      log('Preferences init error: $e');
    }

    // Initialize Firebase
    try {
      await FirebaseService.initialize();
    } catch (e) {
      log('FirebaseService init error: $e');
    }

    // Set preferred orientations
    try {
      await _setOrientations();
    } catch (_) {}

    // Setup Firebase messaging
    try {
      await FirebaseService.setupMessaging();
    } catch (e) {
      log('FirebaseService messaging error: $e');
    }

    // Platform specific initialization
    try {
      await _platformSpecificInit();
    } catch (e) {
      log('Platform specific init error: $e');
    }
  }

  static Future<void> _setOrientations() async {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  static Future<void> _platformSpecificInit() async {
    if (!Platform.isIOS) {
      // Set background message handler
      FirebaseMessaging.onBackgroundMessage(
          firebaseMessagingBackgroundHandler);

      // Android Maps configuration
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      if (androidInfo.version.sdkInt > 28) {
        AndroidGoogleMapsFlutter.useAndroidViewSurface = true;
      }
      
    }
  }
}

class ThemeService with WidgetsBindingObserver {
  DarkThemeProvider themeChangeProvider = DarkThemeProvider();

  void initialize() {
    WidgetsBinding.instance.addObserver(this);
    getCurrentAppTheme();
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    getCurrentAppTheme();
  }

  void getCurrentAppTheme() async {
    themeChangeProvider.darkTheme =
        await themeChangeProvider.darkThemePreference.getTheme();
  }

  DarkThemeProvider get provider => themeChangeProvider;
}

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(SettingsController());
    Get.lazyPut(() => DashBoardController());
    Get.lazyPut(() => AddUserController());
    Get.lazyPut(() => MPinChangeController());
  }
}

class AppRoutes {
  static Widget getInitialScreen(SettingsController controller) {
    // Ensure default language code
    if (Preferences.getString(Preferences.languageCodeKey).toString().isEmpty) {
      Preferences.setString(Preferences.languageCodeKey, 'en');
    }

    // Check login status & user ID
    final bool isLogin = Preferences.getBoolean(Preferences.isLogin);
    final String userId = Preferences.getString(Preferences.userId);

    if (isLogin && userId.isNotEmpty) {
      return MainDashboard();
    }

    // On fresh install or when not logged in, go straight to native PhoneEntryScreen
    return const PhoneEntryScreen(mode: 'signup');
  }
}

void main() async {
  // Initialize the app
  await AppInitialization.initializeApp();

  // Run the app
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ThemeService _themeService = ThemeService();

  @override
  void initState() {
    super.initState();
    _themeService.initialize();
  }

  @override
  void dispose() {
    _themeService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Setup Firebase messaging interactions
    FirebaseService.setupInteractedMessage(context);

    // Setup localization and API header
    _setupLocalizationAndAPI();

    return ChangeNotifierProvider(
      create: (_) => _themeService.provider,
      child: Consumer<DarkThemeProvider>(
        builder: (context, themeProvider, child) {
          return GetMaterialApp(
            title: Constant.appName!.tr,
            debugShowCheckedModeBanner: false,
            theme: Styles.themeData(
              themeProvider.darkTheme == 0
                  ? true
                  : themeProvider.darkTheme == 1
                      ? false
                      : themeProvider.getSystemThem(),
              context,
            ),
            locale: LocalizationService.locale,
            fallbackLocale: LocalizationService.locale,
            translations: LocalizationService(),
            initialBinding: InitialBinding(),
            builder: (context, child) {
              final easyLoadingBuilder = EasyLoading.init();
              final builtChild = easyLoadingBuilder(context, child);
              return SafeArea(
                top: false,
                bottom: true,
                child: builtChild,
              );
            },
            home: GetX<SettingsController>(
              init: SettingsController(),
              builder: (controller) {
                if (controller.isLoading.value) {
                  return Scaffold(
                    backgroundColor: themeProvider.getThem() ? AppThemeData.surface50Dark : AppThemeData.surface50,
                    body: Constant.loader(
                      context,
                      isDarkMode: themeProvider.getThem(),
                    ),
                  );
                }

                return AppRoutes.getInitialScreen(controller);
              },
            ),
          );
        },
      ),
    );
  }

  void _setupLocalizationAndAPI() {
    Future.delayed(const Duration(seconds: 3), () {
      String languageCode = Preferences.getString(Preferences.languageCodeKey);
      if (languageCode.isNotEmpty) {
        LocalizationService().changeLocale(languageCode);
      }
      API.header['accesstoken'] =
          Preferences.getString(Preferences.accesstoken);
    });
  }
}

//
// import 'dart:convert';
// import 'dart:io';
// import 'package:cabme_driver/constant/constant.dart';
// import 'package:cabme_driver/controller/dash_board_controller.dart';
// import 'package:cabme_driver/controller/settings_controller.dart';
// import 'package:cabme_driver/firebase_options.dart';
// import 'package:cabme_driver/on_boarding_screen.dart';
// import 'package:cabme_driver/page/MainDashBoard/screen/main_dashboard.dart';
// import 'package:cabme_driver/page/auth_screens/phone_entry_screen.dart';
// import 'package:cabme_driver/page/features/Taxi/taxi_dashboard/taxi_dashboard.dart';
// import 'package:cabme_driver/service/api.dart';
// import 'package:cabme_driver/themes/styles.dart';
// import 'package:cabme_driver/utils/dark_theme_provider.dart';
// import 'package:device_info_plus/device_info_plus.dart';

// import 'package:firebase_app_check/firebase_app_check.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_easyloading/flutter_easyloading.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:get/get.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:provider/provider.dart';
// import 'page/chats_screen/conversation_screen.dart';
// import 'page/localization_screens/localization_screen.dart';
// import 'page/subscription_plan_screen/subscription_plan_screen.dart';
// import 'service/localization_service.dart';
// import 'utils/Preferences.dart';
//
// Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//     await Firebase.initializeApp(
//         options: DefaultFirebaseOptions.currentPlatform
//     );
// }
//
// void main() async {
//     WidgetsFlutterBinding.ensureInitialized();
//
//     await Preferences.initPref();
//
//     await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
//     await FirebaseAppCheck.instance.activate(
//         webProvider: ReCaptchaV3Provider('recaptcha-v3-site-key'),
//         androidProvider: AndroidProvider.playIntegrity,
//         appleProvider: AppleProvider.appAttest
//     );
//     await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
//         alert: true,
//         badge: true,
//         sound: true
//     );
//
//     var request = await FirebaseMessaging.instance.requestPermission(
//         alert: true,
//         announcement: false,
//         badge: true,
//         carPlay: false,
//         criticalAlert: false,
//         provisional: false,
//         sound: true
//     );
//
//     if (!Platform.isIOS) {
//         FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
//         DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
//         AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
//         if (androidInfo.version.sdkInt > 28) {
//             AndroidGoogleMapsFlutter.useAndroidViewSurface = true;
//         }
//     }
//
//     runApp(MyApp());
// }
//
// class MyApp extends StatefulWidget {
//     MyApp({super.key});
//
//     @override
//     State<MyApp> createState() => _MyAppState();
// }
//
// class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
//     @override
//     void initState() {
//         WidgetsBinding.instance.addObserver(this);
//         getCurrentAppTheme();
//         setupInteractedMessage(context);
//         Future.delayed(const Duration(seconds: 3), () {
//                 if (Preferences.getString(Preferences.languageCodeKey).toString().isNotEmpty) {
//                     LocalizationService().changeLocale(Preferences.getString(Preferences.languageCodeKey).toString());
//                 }
//                 API.header['accesstoken'] = Preferences.getString(Preferences.accesstoken);
//             }
//         );
//         super.initState();
//     }
//
//     DarkThemeProvider themeChangeProvider = DarkThemeProvider();
//
//     @override
//     void didChangeAppLifecycleState(AppLifecycleState state) {
//         getCurrentAppTheme();
//     }
//
//     void getCurrentAppTheme() async {
//         themeChangeProvider.darkTheme = await themeChangeProvider.darkThemePreference.getTheme();
//     }
//
//     Future<void> setupInteractedMessage(BuildContext context) async {
//         initialize(context);
//         await FirebaseMessaging.instance.subscribeToTopic("cabme_driver");
//
//         RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
//
//         if (initialMessage != null) {}
//
//         FirebaseMessaging.onMessage.listen((RemoteMessage message) {
//                 if (message.notification != null) {
//                     display(message);
//                 }
//             }
//         );
//
//         FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
//                 if (message.notification != null) {
//                     if (message.data['status'] == "done") {
//                         await Get.to(ConversationScreen(), arguments: {
//                                 'receiverId': int.parse(json.decode(message.data['message'])['senderId'].toString()),
//                                 'orderId': int.parse(json.decode(message.data['message'])['orderId'].toString()),
//                                 'receiverName': json.decode(message.data['message'])['senderName'].toString(),
//                                 'receiverPhoto': json.decode(message.data['message'])['senderPhoto'].toString()
//                             }
//                         );
//                     }
//                     else if (message.data['statut'] == "new" && message.data['statut'] == "rejected") {
//                         await Get.to(MainDashboard());
//                     }
//                     else if (message.data['type'] == "payment received") {
//                         DashBoardController dashBoardController = Get.put(DashBoardController());
//                         dashBoardController.selectedDrawerIndex.value = 4;
//                         await Get.to(MainDashboard());
//                     }
//                 }
//             }
//         );
//     }
//
//     Future<void> initialize(BuildContext context) async {
//         AndroidNotificationChannel channel = const AndroidNotificationChannel(
//             'high_importance_channel', // id
//             'High Importance Notifications', // title
//             importance: Importance.high
//         );
//
//         const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
//         var iosInitializationSettings = const DarwinInitializationSettings();
//         final InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid, iOS: iosInitializationSettings);
//         await FlutterLocalNotificationsPlugin().initialize(initializationSettings, onDidReceiveNotificationResponse: (payload) async {}
//         );
//
//         await FlutterLocalNotificationsPlugin().resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel);
//     }
//
//     void display(RemoteMessage message) async {
//         try {
//             final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
//             const NotificationDetails notificationDetails = NotificationDetails(
//                 android: AndroidNotificationDetails(
//                     "01",
//                     "cabme-driver",
//                     importance: Importance.max,
//                     priority: Priority.high
//                 ));
//
//             await FlutterLocalNotificationsPlugin().show(
//                 id,
//                 message.notification!.title,
//                 message.notification!.body,
//                 notificationDetails,
//                 payload: jsonEncode(message.data)
//             );
//         }
//         on Exception {}
//     }
//
//     GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
//
//     // This widget is the root of your application.
//     @override
//     Widget build(BuildContext context) {
//         return ChangeNotifierProvider(create: (_) {
//                 return themeChangeProvider;
//             }, child: Consumer<DarkThemeProvider>(builder: (context, value, child) {
//                     return GetMaterialApp(
//                         title: "${Constant.appName}".tr,
//                         debugShowCheckedModeBanner: false,
//                         theme: Styles.themeData(
//                             themeChangeProvider.darkTheme == 0
//                                 ? true
//                                 : themeChangeProvider.darkTheme == 1
//                                     ? false
//                                     : themeChangeProvider.getSystemThem(),
//                             context),
//                         locale: LocalizationService.locale,
//                         fallbackLocale: LocalizationService.locale,
//                         translations: LocalizationService(),
//                         builder: EasyLoading.init(),
//                         home: GetX(
//                             init: SettingsController(),
//                             builder: (controller) {
//                                 final themeChange = Provider.of<DarkThemeProvider>(context);
//                                 return controller.isLoading.value == true
//                                     ? Container(child: Constant.loader(context, isDarkMode: themeChange.getThem()))
//                                     : Preferences.getString(Preferences.languageCodeKey).toString().isEmpty
//                                         ? const LocalizationScreens(intentType: "main")
//                                         : Preferences.getBoolean(Preferences.isFinishOnBoardingKey)
//                                             ? Preferences.getBoolean(Preferences.isLogin)
//                                                 ? controller.checkStatus()
//                                                     ? MainDashboard()
//                                                     // ? DashBoard()
//                                                     : SubscriptionPlanScreen(
//                                                         isbackButton: false,
//                                                         isSplashScreen: true
//                                                     )
//                                                 // : PhoneEntryScreen(mode: 'signup')
//                                                 : const MainDashboard()
//                                             : const OnBoardingScreen();
//                             }
//                         )
//                     );
//                 }
//             ));
//     }
// }
