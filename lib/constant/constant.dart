// ignore_for_file: body_might_complete_normally_catch_error

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cabme_driver/model/parcel_model.dart';
import 'package:cabme_driver/model/payment_setting_model.dart';
import 'package:cabme_driver/model/ride_model.dart';
import 'package:cabme_driver/model/settings_model.dart';
import 'package:cabme_driver/model/tax_model.dart';
import 'package:cabme_driver/model/user_model.dart';
import 'package:cabme_driver/page/chats_screen/conversation_screen.dart';
import 'package:cabme_driver/themes/constant_colors.dart';
import 'package:cabme_driver/utils/Preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_google_places_hoc081098/flutter_google_places_hoc081098.dart';
import 'package:flutter_google_places_hoc081098/google_maps_webservice_places.dart';
import 'package:get/get.dart';
import 'package:get_thumbnail_video/index.dart';
import 'package:get_thumbnail_video/video_thumbnail.dart';
import 'package:google_api_headers/google_api_headers.dart';
import 'package:location/location.dart';
import 'package:map_launcher/map_launcher.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import 'package:video_compress/video_compress.dart';

import 'show_toast_dialog.dart';

class Constant {
  static String? appName = "Fiinway Business";
  static String? kGoogleApiKey = "AIzaSyAxZaszdbtbO75kvNjSYm1LjW2Sk59D9C8";
  static String? rideOtp = "yes";
  static String? appVersion = "0.0";
  static String? minimumWalletBalance = "0";
  static String? decimal = "2";
  static String? currency = "\$";
  static String? commissionSubscriptionID = "1";
  static bool? subscriptionModel = false;
  static bool symbolAtRight = false;
  static List<TaxModel> taxList = [];
  static List<TaxModel> allTaxList = [];
  static AdminCommission? adminCommission;

  // static String? taxValue = "0.0";
  // static String? taxType = 'Percentage';
  // static String? taxName = 'Tax';
  static String? distanceUnit = "KM";
  static String? contactUsEmail = "";
  static String? minimumWithdrawalAmount = "0";
  static String? contactUsAddress = "";
  static String? contactUsPhone = "";
  static String? deliveryChargeParcel = "";
  static String? parcelActive = "";
  static String? parcelPerWeightCharge = "";
  static CollectionReference conversation = FirebaseFirestore.instance.collection('conversation');

  // static CollectionReference locationUpdate = FirebaseFirestore.instance.collection('ride_location_update');
  static CollectionReference driverLocationUpdate = FirebaseFirestore.instance.collection('driver_location_update');
  static LocationData? currentLocation;
  static String liveTrackingMapType = "google";
  static String selectedMapType = 'google';

  static String driverLocationUpdateUnit = "10";

  static String? jsonNotificationFileURL = "";
  static String? senderId = "";
  static String? placeholderUrl = "";

  static PaymentSettingModel getPaymentSetting() {
    final String user = Preferences.getString(Preferences.paymentSetting);
    if (user.isNotEmpty) {
      Map<String, dynamic> userMap = jsonDecode(user);
      return PaymentSettingModel.fromJson(userMap);
    }
    return PaymentSettingModel();
  }

  static String getUuid() {
    var uuid = const Uuid();
    return uuid.v1();
  }

  static UserModel getUserData() {
    final String user = Preferences.getString(Preferences.user);
    if(user.isEmpty) return UserModel();
    Map<String, dynamic> userMap = json.decode(user);
    return UserModel.fromJson(userMap);
  }

  static Widget emptyView(String msg) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Image.asset('assets/images/empty_placeholde.png'),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 100),
          child: Text(
            msg.tr,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  static Color statusParcelColor(ParcelData data) {
    return data.status == "new"
        ? AppThemeData.primary50
        : data.status == "confirmed"
            ? AppThemeData.info50
            : data.status == "on ride"
                ? AppThemeData.secondary50
                : data.status == "onride"
                    ? AppThemeData.secondary50
                    : data.status == "completed"
                        ? AppThemeData.success50
                        : AppThemeData.error50;
  }

  static Color statusParcelTextColor(ParcelData data) {
    return data.status == "new"
        ? AppThemeData.primary200
        : data.status == "confirmed"
            ? AppThemeData.info300
            : data.status == "on ride"
                ? AppThemeData.secondary200
                : data.status == "onride"
                    ? AppThemeData.secondary200
                    : data.status == "completed"
                        ? AppThemeData.success300
                        : AppThemeData.error200;
  }

  static Color statusColor(RideData data) {
    return data.statut == "new"
        ? AppThemeData.primary50
        : data.statut == "confirmed"
            ? AppThemeData.info50
            : data.statut == "on ride"
                ? AppThemeData.secondary50
                : data.statut == "onride"
                    ? AppThemeData.secondary50
                    : data.statut == "completed"
                        ? AppThemeData.success50
                        : AppThemeData.error50;
  }

  static Color statusTextColor(RideData data) {
    return data.statut == "new"
        ? AppThemeData.primary200
        : data.statut == "confirmed"
            ? AppThemeData.info300
            : data.statut == "on ride"
                ? AppThemeData.secondary200
                : data.statut == "onride"
                    ? AppThemeData.secondary200
                    : data.statut == "completed"
                        ? AppThemeData.success300
                        : AppThemeData.error200;
  }

  String amountShow({required String? amount}) {
    String amountdata = (amount == 'null' || amount == '' || amount == null) ? '0' : amount;
    String currency = Constant.currency ?? "\$";
    int decimal = 2;
    try {
      if (Constant.decimal != null) {
        decimal = int.parse(Constant.decimal!);
      }
    } catch (_) {}
    try {
      double parsedAmount = double.parse(amountdata.toString());
      if (Constant.symbolAtRight == true) {
        return "${parsedAmount.toStringAsFixed(decimal)}$currency";
      } else {
        return "$currency${parsedAmount.toStringAsFixed(decimal)}";
      }
    } catch (e) {
      return "${currency}0.00";
    }
  }

  static Widget loader(context, {required bool isDarkMode, Color? loadingcolor, Color? bgColor}) {
    return Center(
      child: Container(
        width: 40,
        height: 40,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: bgColor ?? (isDarkMode ? AppThemeData.surface50Dark : AppThemeData.surface50), borderRadius: BorderRadius.circular(50)),
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(loadingcolor ?? AppThemeData.primary200),
          strokeWidth: 3,
        ),
      ),
    );
  }

  static Future<void> makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    await launchUrl(launchUri);
  }

  static Future<void> launchMapURl(String? latitude, String? longLatitude) async {
    String appleUrl = 'https://maps.apple.com/?saddr=&daddr=$latitude,$longLatitude&directionsmode=driving';
    String googleUrl = 'https://www.google.com/maps/search/?api=1&query=$latitude,$longLatitude';

    if (Platform.isIOS) {
      if (await canLaunchUrl(Uri.parse(appleUrl))) {
        await canLaunchUrl(Uri.parse(appleUrl));
      }
    } else {
      if (await canLaunchUrl(Uri.parse(googleUrl))) {
        await canLaunchUrl(Uri.parse(googleUrl));
      } else {
        throw 'Could not open the map.';
      }
    }
  }

  static Future<Url> uploadChatImageToFireStorage(File image) async {
    ShowToastDialog.showLoader('Uploading image...');
    var uniqueID = const Uuid().v4();
    Reference upload = FirebaseStorage.instance.ref().child('images/$uniqueID.png');
    UploadTask uploadTask = upload.putFile(image);

    uploadTask.snapshotEvents.listen((event) {
      ShowToastDialog.showLoader('Uploading image ${(event.bytesTransferred.toDouble() / 1000).toStringAsFixed(2)} /'
          '${(event.totalBytes.toDouble() / 1000).toStringAsFixed(2)} '
          'KB');
    });
    uploadTask.whenComplete(() {}).catchError((onError) {
      ShowToastDialog.closeLoader();
    });
    var storageRef = (await uploadTask.whenComplete(() {})).ref;
    var downloadUrl = await storageRef.getDownloadURL();
    var metaData = await storageRef.getMetadata();
    ShowToastDialog.closeLoader();
    return Url(mime: metaData.contentType ?? 'image', url: downloadUrl.toString());
  }

  static Future<ChatVideoContainer?> uploadChatVideoToFireStorage(File video) async {
    try {
      ShowToastDialog.showLoader("Uploading video...");
      final String uniqueID = const Uuid().v4();
      final Reference videoRef = FirebaseStorage.instance.ref('videos/$uniqueID.mp4');
      final UploadTask uploadTask = videoRef.putFile(
        video,
        SettableMetadata(contentType: 'video/mp4'),
      );
      await uploadTask;
      final String videoUrl = await videoRef.getDownloadURL();
      ShowToastDialog.showLoader("Generating thumbnail...");
      final Uint8List thumbnailBytes = await VideoThumbnail.thumbnailData(
        video: video.path,
        imageFormat: ImageFormat.JPEG,
        maxHeight: 200,
        maxWidth: 200,
        quality: 75,
      );

      if (thumbnailBytes == null || thumbnailBytes.isEmpty) {
        throw Exception("Failed to generate thumbnail.");
      }

      final String thumbnailID = const Uuid().v4();
      final Reference thumbnailRef = FirebaseStorage.instance.ref('thumbnails/$thumbnailID.jpg');
      final UploadTask thumbnailUploadTask = thumbnailRef.putData(
        thumbnailBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      await thumbnailUploadTask;
      final String thumbnailUrl = await thumbnailRef.getDownloadURL();
      var metaData = await thumbnailRef.getMetadata();
      ShowToastDialog.closeLoader();

      return ChatVideoContainer(videoUrl: Url(url: videoUrl.toString(), mime: metaData.contentType ?? 'video', videoThumbnail: thumbnailUrl), thumbnailUrl: thumbnailUrl);
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Error: ${e.toString()}");
      return null;
    }
  }

  static Future<File> _compressVideo(File file) async {
    MediaInfo? info = await VideoCompress.compressVideo(file.path, quality: VideoQuality.DefaultQuality, deleteOrigin: false, includeAudio: true, frameRate: 24);
    if (info != null) {
      File compressedVideo = File(info.path!);
      return compressedVideo;
    } else {
      return file;
    }
  }

  static Future<String> uploadVideoThumbnailToFireStorage(File file) async {
    var uniqueID = const Uuid().v4();
    Reference upload = FirebaseStorage.instance.ref().child('thumbnails/$uniqueID.png');
    UploadTask uploadTask = upload.putFile(file);
    var downloadUrl = await (await uploadTask.whenComplete(() {})).ref.getDownloadURL();
    return downloadUrl.toString();
  }

  static Future<void> redirectMap({required String name, required double latitude, required double longLatitude}) async {
    if (Constant.liveTrackingMapType == "google") {
      bool? isAvailable = await MapLauncher.isMapAvailable(MapType.google);
      if (isAvailable == true) {
        await MapLauncher.showDirections(
          mapType: MapType.google,
          directionsMode: DirectionsMode.driving,
          destinationTitle: name,
          destination: Coords(latitude, longLatitude),
        );
      } else {
        ShowToastDialog.showToast("Google map is not installed");
      }
    } else if (Constant.liveTrackingMapType == "googleGo") {
      bool? isAvailable = await MapLauncher.isMapAvailable(MapType.googleGo);
      if (isAvailable == true) {
        await MapLauncher.showDirections(
          mapType: MapType.googleGo,
          directionsMode: DirectionsMode.driving,
          destinationTitle: name,
          destination: Coords(latitude, longLatitude),
        );
      } else {
        ShowToastDialog.showToast("Google Go map is not installed");
      }
    } else if (Constant.liveTrackingMapType == "waze") {
      bool? isAvailable = await MapLauncher.isMapAvailable(MapType.waze);
      if (isAvailable == true) {
        await MapLauncher.showDirections(
          mapType: MapType.waze,
          directionsMode: DirectionsMode.driving,
          destinationTitle: name,
          destination: Coords(latitude, longLatitude),
        );
      } else {
        ShowToastDialog.showToast("Waze is not installed");
      }
    } else if (Constant.liveTrackingMapType == "mapswithme") {
      bool? isAvailable = await MapLauncher.isMapAvailable(MapType.mapswithme);
      if (isAvailable == true) {
        await MapLauncher.showDirections(
          mapType: MapType.mapswithme,
          directionsMode: DirectionsMode.driving,
          destinationTitle: name,
          destination: Coords(latitude, longLatitude),
        );
      } else {
        ShowToastDialog.showToast("Mapswithme is not installed");
      }
    } else if (Constant.liveTrackingMapType == "yandexNavi") {
      bool? isAvailable = await MapLauncher.isMapAvailable(MapType.yandexNavi);
      if (isAvailable == true) {
        await MapLauncher.showDirections(
          mapType: MapType.yandexNavi,
          directionsMode: DirectionsMode.driving,
          destinationTitle: name,
          destination: Coords(latitude, longLatitude),
        );
      } else {
        ShowToastDialog.showToast("YandexNavi is not installed");
      }
    } else if (Constant.liveTrackingMapType == "yandexMaps") {
      bool? isAvailable = await MapLauncher.isMapAvailable(MapType.yandexMaps);
      if (isAvailable == true) {
        await MapLauncher.showDirections(
          mapType: MapType.yandexMaps,
          directionsMode: DirectionsMode.driving,
          destinationTitle: name,
          destination: Coords(latitude, longLatitude),
        );
      } else {
        ShowToastDialog.showToast("yandexMaps map is not installed");
      }
    }
  }

  Future<PlacesDetailsResponse?> handlePressButton(BuildContext context) async {
    void onError(response) {
      ShowToastDialog.showToast(response.errorMessage ?? 'Unknown error');
    }

    // show input autocomplete with selected mode
    // then get the Prediction selected
    final p = await PlacesAutocomplete.show(
        context: context,
        apiKey: Constant.kGoogleApiKey,
        onError: onError,
        mode: Mode.overlay,
        language: 'fr',
        components: [],
        resultTextStyle: Theme.of(context).textTheme.titleMedium);

    if (p == null) {
      return null;
    }

    // get detail (lat/lng)
    final places = GoogleMapsPlaces(
      apiKey: Constant.kGoogleApiKey,
      apiHeaders: await const GoogleApiHeaders().getHeaders(),
    );

    final detail = await places.getDetailsByPlaceId(p.placeId!);

    return detail;
  }

  String capitalizeWords(String input) {
    if (input.isEmpty) return input;
    if (input == 'onride') {
      return 'On Ride';
    } else if (input == 'driver_rejected') {
      return 'Rejected';
    } else {
      List<String> words = input.split(' ');
      List<String> capitalizedWords = words.map((word) {
        if (word.isEmpty) return word;
        return word[0].toUpperCase() + word.substring(1).toLowerCase();
      }).toList();
      return capitalizedWords.join(' ').replaceAll('_', ' ');
    }
  }
}

class Url {
  String mime;

  String url;

  String? videoThumbnail;

  Url({this.mime = '', this.url = '', this.videoThumbnail});

  factory Url.fromJson(Map<dynamic, dynamic> parsedJson) {
    return Url(mime: parsedJson['mime'] ?? '', url: parsedJson['url'] ?? '', videoThumbnail: parsedJson['videoThumbnail'] ?? '');
  }

  Map<String, dynamic> toJson() {
    return {'mime': mime, 'url': url, 'videoThumbnail': videoThumbnail};
  }
}

extension StringExtension on String {
  String capitalizeString() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
