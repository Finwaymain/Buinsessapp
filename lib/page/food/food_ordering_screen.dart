import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cabme_driver/themes/constant_colors.dart';
import 'package:cabme_driver/utils/onboarding_url.dart';
import 'package:cabme_driver/page/web_view_screen/web_view_screen.dart';

class FoodOrderingScreen extends StatefulWidget {
  const FoodOrderingScreen({super.key});

  @override
  State<FoodOrderingScreen> createState() => _FoodOrderingScreenState();
}

class _FoodOrderingScreenState extends State<FoodOrderingScreen> {
  String? _foodUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initFoodUrl();
  }

  Future<void> _initFoodUrl() async {
    String lat = '';
    String lng = '';
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      Position? position;
      if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
        try {
          position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
            timeLimit: const Duration(seconds: 8),
          );
        } catch (_) {}
      }
      position ??= await Geolocator.getLastKnownPosition();
      if (position != null) {
        lat = position.latitude.toString();
        lng = position.longitude.toString();
      }
    } catch (_) {}

    final url = OnboardingUrl.build(
      '/onboarding/food.html',
      extra: {
        if (lat.isNotEmpty) 'lat': lat,
        if (lng.isNotEmpty) 'lng': lng,
        if (lat.isNotEmpty) 'latitude': lat,
        if (lng.isNotEmpty) 'longitude': lng,
      },
    );

    if (mounted) {
      setState(() {
        _foodUrl = url;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _foodUrl == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Food Ordering'.tr),
          backgroundColor: AppThemeData.primary200,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return WebViewScreen(
      url: _foodUrl!,
      title: 'Food Ordering'.tr,
      showAppBar: true,
    );
  }
}
