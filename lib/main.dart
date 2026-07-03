// ignore_for_file: empty_catches, must_be_immutable, unused_local_variable, deprecated_member_use

import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'package:cabme_driver/constant/constant.dart';
import 'package:cabme_driver/controller/dash_board_controller.dart';
import 'package:cabme_driver/controller/settings_controller.dart';
import 'package:cabme_driver/firebase_options.dart';
import 'package:cabme_driver/on_boarding_screen.dart';
import 'package:cabme_driver/page/MainDashBoard/screen/main_dashboard.dart';
import 'package:cabme_driver/page/chats_screen/conversation_screen.dart';
import 'package:cabme_driver/page/features/SmartValue/AddPerson/controller/add_user_controller.dart';
import 'package:cabme_driver/page/features/SmartValue/MPinChange/controller/mpin_change_controller.dart';
import 'package:cabme_driver/page/subscription_plan_screen/subscription_plan_screen.dart';
import 'package:cabme_driver/service/api.dart';
import 'package:cabme_driver/service/localization_service.dart';
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

class FirebaseService {
  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    await FirebaseAppCheck.instance.activate(
      webProvider: ReCaptchaV3Provider('recaptcha-v3-site-key'),
      androidProvider: AndroidProvider.playIntegrity,
      appleProvider: AppleProvider.appAttest,
    );
  }

  static Future<void> setupMessaging() async {
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
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

  static Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  static Future<void> setupInteractedMessage(BuildContext context) async {
    await NotificationService.initialize(context);
    await FirebaseMessaging.instance.subscribeToTopic("cabme_driver");

    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      // Handle initial message if needed
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.data['statut'] == 'new' || message.data['tag'] == 'ridenewrider') {
        try {
          final rideData = RideData.fromJson(message.data);
          if (rideData.id != null && rideData.id!.isNotEmpty && rideData.id != 'null') {
            Get.to(() => IncomingRideScreen(rideData: rideData));
          }
        } catch (e) {
          log('Error showing incoming ride screen: $e');
        }
      }
      if (message.notification != null) {
        NotificationService.display(message);
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      await _handleNotificationTap(message);
    });
  }

  static Future<void> _handleNotificationTap(RemoteMessage message) async {
    try {
      if (message.data['status'] == "done") {
        await Get.to(ConversationScreen(), arguments: {
          'receiverId': int.parse(json.decode(message.data['message'])['senderId'].toString()),
          'orderId': int.parse(json.decode(message.data['message'])['orderId'].toString()),
          'receiverName': json.decode(message.data['message'])['senderName'].toString(),
          'receiverPhoto': json.decode(message.data['message'])['senderPhoto'].toString(),
        });
      } else if (message.data['statut'] == "new" || message.data['tag'] == "ridenewrider") {
        try {
          final rideData = RideData.fromJson(message.data);
          if (rideData.id != null && rideData.id!.isNotEmpty && rideData.id != 'null') {
            await Get.to(() => IncomingRideScreen(rideData: rideData));
            return;
          }
        } catch (e) {
          log('Error parsing rideData on tap: $e');
        }
        await Get.to(MainDashboard());
      } else if (message.data['statut'] == "confirmed" || message.data['statut'] == "on ride") {
        try {
          final rideData = RideData.fromJson(message.data);
          if (rideData.id != null && rideData.id!.isNotEmpty && rideData.id != 'null') {
            var argumentData = {'type': rideData.statut, 'data': rideData};
            if (Constant.liveTrackingMapType == "inappmap") {
              if (Constant.selectedMapType == 'osm') {
                await Get.to(() => const RouteOsmViewScreen(), arguments: argumentData);
              } else {
                await Get.to(() => const RouteViewScreen(), arguments: argumentData);
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
        await Get.to(MainDashboard());
      } else if (message.data['statut'] == "rejected") {
        await Get.to(MainDashboard());
      } else if (message.data['type'] == "payment received") {
        DashBoardController dashBoardController = Get.put(DashBoardController());
        dashBoardController.selectedDrawerIndex.value = 4;
        await Get.to(MainDashboard());
      }
    } catch (e) {
      log('Error handling notification tap: $e');
    }
  }
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  static Future<void> initialize(BuildContext context) async {
    // General high-importance channel
    AndroidNotificationChannel generalChannel = const AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      importance: Importance.high,
    );

    // Dedicated ride-request channel — max importance, full-screen alert
    AndroidNotificationChannel rideChannel = AndroidNotificationChannel(
      'ride_requests',
      'New Ride Requests',
      description: 'Alerts for incoming ride requests',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 500, 200, 500, 200, 500]),
    );

    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    var iosInitializationSettings = const DarwinInitializationSettings();

    final InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid, iOS: iosInitializationSettings);

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) async {
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

    final android = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(generalChannel);
    await android?.createNotificationChannel(rideChannel);
  }

  static void display(RemoteMessage message) async {
    try {
      final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final isRideRequest = message.data['statut'] == 'new' || message.data['tag'] == 'ridenewrider';

      final NotificationDetails notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          isRideRequest ? 'ride_requests' : 'high_importance_channel',
          isRideRequest ? 'New Ride Requests' : 'High Importance Notifications',
          importance: Importance.max,
          priority: Priority.high,
          fullScreenIntent: isRideRequest,
          enableVibration: true,
          vibrationPattern: isRideRequest
              ? Int64List.fromList([0, 500, 200, 500, 200, 500])
              : null,
        ),
      );

      final title = message.notification?.title ?? message.data['title'] ?? 'Fiinway';
      final body = message.notification?.body ?? message.data['body'] ?? '';

      await _flutterLocalNotificationsPlugin.show(
        id,
        title,
        body,
        notificationDetails,
        payload: jsonEncode(message.data),
      );
    } on Exception catch (e) {
      log('Notification display error: $e');
    }
  }
}

class AppInitialization {
  static Future<void> initializeApp() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize preferences
    await Preferences.initPref();

    // Initialize Firebase
    await FirebaseService.initialize();

    // Set preferred orientations
    await _setOrientations();

    // Setup Firebase messaging
    await FirebaseService.setupMessaging();

    // Platform specific initialization
    await _platformSpecificInit();
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
          FirebaseService.firebaseMessagingBackgroundHandler);

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
    Get.put(DashBoardController());
    Get.lazyPut(() => AddUserController());
    Get.lazyPut(() => MPinChangeController());
  }
}

class AppRoutes {
  static Widget getInitialScreen(SettingsController controller) {
    // Check if language is selected
    if (Preferences.getString(Preferences.languageCodeKey).toString().isEmpty) {
      Preferences.setString(Preferences.languageCodeKey, 'en');
    }

    // Check if onboarding is finished
    if (!Preferences.getBoolean(Preferences.isFinishOnBoardingKey)) {
      return const OnBoardingScreen();
    }

    // Check if user is logged in
    if (Preferences.getBoolean(Preferences.isLogin)) {
      return MainDashboard();
    }

    // Default to MainDashboard
    return const MainDashboard();
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
            builder: EasyLoading.init(),
            home: GetX(
              init: SettingsController(),
              builder: (controller) {
                // Show loader while loading
                if (controller.isLoading.value == true) {
                  return Container(
                    child: Constant.loader(
                      context,
                      isDarkMode: themeProvider.getThem(),
                    ),
                  );
                }

                // Return initial screen based on app state
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
      API.header['accesstoken'] = Preferences.getString(Preferences.accesstoken);
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
