import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:cabme_driver/constant/constant.dart';
import 'package:cabme_driver/constant/show_toast_dialog.dart';
import 'package:cabme_driver/controller/new_ride_controller.dart';
import 'package:cabme_driver/model/ride_model.dart';
import 'package:cabme_driver/themes/constant_colors.dart';
import 'package:cabme_driver/themes/custom_dialog_box.dart';
import 'package:cabme_driver/utils/Preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cabme_driver/page/MainDashBoard/screen/main_dashboard.dart';
import 'package:cabme_driver/page/route_view_screen/route_view_screen.dart';
import 'package:cabme_driver/page/route_view_screen/route_osm_view_screen.dart';
import 'package:http/http.dart' as http;
import 'package:cabme_driver/service/api.dart';

class IncomingRideScreen extends StatefulWidget {
  final RideData rideData;
  const IncomingRideScreen({super.key, required this.rideData});

  @override
  State<IncomingRideScreen> createState() => _IncomingRideScreenState();
}

class _IncomingRideScreenState extends State<IncomingRideScreen> with TickerProviderStateMixin {
  final NewRideController controller = Get.put(NewRideController());
  
  late AnimationController _pulseController;
  late AnimationController _countdownController;
  
  int _secondsRemaining = 30;
  Timer? _timer;
  
  double _dragPosition = 0.0;
  final double _sliderHeight = 60.0;
  bool _isAccepted = false;

  Future<void> _loadRideDetails() async {
    try {
      final url = "${API.rideDetails}?ride_id=${widget.rideData.id}&user_type=driver";
      final response = await http.get(Uri.parse(url), headers: API.header);
      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        if (responseBody['success'] == "success" && responseBody['data'] != null) {
          final enriched = RideData.fromJson(responseBody['data']);
          if (mounted) {
            setState(() {
              widget.rideData.nom = enriched.nom;
              widget.rideData.prenom = enriched.prenom;
              widget.rideData.phone = enriched.phone;
              widget.rideData.photoPath = enriched.photoPath;
              widget.rideData.moyenne = enriched.moyenneDriver ?? enriched.moyenne;
              widget.rideData.moyenneDriver = enriched.moyenneDriver;
              widget.rideData.departName = enriched.departName;
              widget.rideData.destinationName = enriched.destinationName;
              widget.rideData.latitudeDepart = enriched.latitudeDepart;
              widget.rideData.longitudeDepart = enriched.longitudeDepart;
              widget.rideData.latitudeArrivee = enriched.latitudeArrivee;
              widget.rideData.longitudeArrivee = enriched.longitudeArrivee;
              widget.rideData.montant = enriched.montant;
              widget.rideData.distance = enriched.distance;
              widget.rideData.distanceUnit = enriched.distanceUnit;
              widget.rideData.duree = enriched.duree;
              widget.rideData.numberPoeple = enriched.numberPoeple;
            });
          }
        }
      }
    } catch (e) {
      log('Error loading ride details: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _loadRideDetails();
    
    // Fetch settings for timer if possible
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _countdownController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    );
    
    // Animation value is synced per-tick by the timer below (see _timer)
    _countdownController.value = 1.0;
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_secondsRemaining > 1) {
          _secondsRemaining--;
          // Sync animation value with actual remaining time
          _countdownController.value = _secondsRemaining / 30.0;
        } else {
          _secondsRemaining = 0;
          _countdownController.value = 0.0;
          _timer?.cancel();
          _handleTimeout();
        }
      });
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _countdownController.dispose();
    _timer?.cancel();
    try {
      const MethodChannel('com.fiinwaybusiness/ride_overlay')
          .invokeMethod('dismissRideOverlay');
    } catch (e) {
      log('Error dismissing ride overlay on screen dispose: $e');
    }
    super.dispose();
  }

  void _handleTimeout() {
    if (_isAccepted) return;
    ShowToastDialog.showToast("Ride request expired");
    _declineRide(reason: "Time out - no response");
  }

  /// Opens Google Maps navigation to the passenger pickup location.
  Future<void> _navigateToPickup() async {
    if (Constant.liveTrackingMapType == "inappmap") {
      var argumentData = {'type': 'confirmed', 'data': widget.rideData};
      if (Constant.selectedMapType == 'osm') {
        Get.to(() => const RouteOsmViewScreen(), arguments: argumentData);
      } else {
        Get.to(() => const RouteViewScreen(), arguments: argumentData);
      }
    } else {
      final lat = widget.rideData.latitudeDepart ?? '0';
      final lng = widget.rideData.longitudeDepart ?? '0';
      final label = Uri.encodeComponent(widget.rideData.departName ?? 'Pickup');
      final uri = Uri.parse('google.navigation:q=$lat,$lng&mode=d');
      final fallback = Uri.parse('https://maps.google.com/?q=$lat,$lng&label=$label&navigate=yes');
      try {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        } else {
          await launchUrl(fallback, mode: LaunchMode.externalApplication);
        }
      } catch (e) {
        ShowToastDialog.showToast('Could not open navigation app');
      }
    }
  }

  void _declineRide({String reason = "Rejected by driver"}) async {
    _timer?.cancel();
    _pulseController.stop();
    _countdownController.stop();

    try {
      const MethodChannel('com.fiinwaybusiness/ride_overlay')
          .invokeMethod('dismissRideOverlay');
    } catch (_) {}

    final driverId = Preferences.getInt(Preferences.userId).toString();
    final driverName = '${widget.rideData.prenomConducteur ?? ''} ${widget.rideData.nomConducteur ?? ''}'.trim();

    Map<String, String> bodyParams = {
      'id_ride': widget.rideData.id?.toString() ?? '',
      'id_user': widget.rideData.idUserApp?.toString() ?? '',
      'name': driverName.isNotEmpty ? driverName : 'Driver',
      'from_id': driverId,
      'user_cat': 'driver',
      'reason': reason,
    };

    try {
      await controller.canceledRide(bodyParams);
    } catch (e) {
      log('Error declining ride: $e');
    }

    controller.getNewRide();

    if (Get.context != null && Navigator.canPop(Get.context!)) {
      Get.back();
    } else {
      Get.offAll(() => const MainDashboard());
    }
  }

  void _acceptRide() {
    if (_isAccepted) return;
    setState(() {
      _isAccepted = true;
    });

    // Use driver's live GPS position, fall back to ride departure only if unavailable
    final double driverLat = Constant.currentLocation?.latitude ?? double.tryParse(widget.rideData.latitudeDepart ?? '0') ?? 0.0;
    final double driverLng = Constant.currentLocation?.longitude ?? double.tryParse(widget.rideData.longitudeDepart ?? '0') ?? 0.0;

    Map<String, String> bodyParams = {
      'id_ride': widget.rideData.id.toString(),
      'id_user': widget.rideData.idUserApp.toString(),
      'driver_name': '${widget.rideData.prenomConducteur ?? ''} ${widget.rideData.nomConducteur ?? ''}',
      'lat_conducteur': driverLat.toString(),
      'lng_conducteur': driverLng.toString(),
      'lat_client': widget.rideData.latitudeArrivee.toString(),
      'lng_client': widget.rideData.longitudeArrivee.toString(),
      'from_id': Preferences.getInt(Preferences.userId).toString(),
    };

    controller.confirmedRide(bodyParams).then((value) {
      if (value != null && mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return CustomDialogBox(
              title: "Confirmed Successfully".tr,
              descriptions: "Ride Successfully confirmed.".tr,
              text: "Ok".tr,
              onPress: () {
                Get.back(); // close dialog
                Get.back(); // close IncomingRideScreen
                
                // Immediately transition to active ride view
                widget.rideData.statut = "confirmed";
                var argumentData = {'type': 'confirmed', 'data': widget.rideData};
                if (Constant.liveTrackingMapType == "inappmap") {
                  if (Constant.selectedMapType == 'osm') {
                    Get.to(() => const RouteOsmViewScreen(), arguments: argumentData);
                  } else {
                    Get.to(() => const RouteViewScreen(), arguments: argumentData);
                  }
                } else {
                  Constant.redirectMap(
                    latitude: double.parse(widget.rideData.latitudeArrivee!),
                    longLatitude: double.parse(widget.rideData.longitudeArrivee!),
                    name: widget.rideData.destinationName!,
                  );
                }
              },
              img: Image.asset('assets/images/green_checked.png'),
            );
          },
        );
      } else {
        setState(() {
          _isAccepted = false;
          _dragPosition = 0.0;
        });
        controller.getNewRide();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final double maxDrag = MediaQuery.of(context).size.width - 32 - 50; // padding & handle size
    
    return Scaffold(
      backgroundColor: AppThemeData.surface50Dark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppThemeData.primary400.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppThemeData.primary400,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "INCOMING REQUEST",
                          style: TextStyle(
                            color: AppThemeData.primary400,
                            fontSize: 12,
                            fontFamily: AppThemeData.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Circular Ticking Timer
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 46,
                        height: 46,
                        child: AnimatedBuilder(
                          animation: _countdownController,
                          builder: (context, child) {
                            return CircularProgressIndicator(
                              value: _countdownController.value,
                              strokeWidth: 4,
                              backgroundColor: AppThemeData.grey300Dark,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _secondsRemaining > 10 ? AppThemeData.success300 : AppThemeData.warning200
                              ),
                            );
                          },
                        ),
                      ),
                      Text(
                        "$_secondsRemaining",
                        style: TextStyle(
                          color: AppThemeData.grey900Dark,
                          fontSize: 16,
                          fontFamily: AppThemeData.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 32),

              // Animated Pulsing Map/Location Icon Container
              Expanded(
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Pulse rings
                      ...List.generate(3, (index) {
                        return AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            double scale = 1.0 + (_pulseController.value * 0.8) + (index * 0.4);
                            double opacity = (1.0 - _pulseController.value) * 0.4;
                            if (scale > 2.2) scale = 2.2;
                            return Transform.scale(
                              scale: scale,
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppThemeData.primary200.withValues(alpha: opacity.clamp(0.0, 1.0)),
                                ),
                              ),
                            );
                          },
                        );
                      }),
                      
                      // Central Badge
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppThemeData.primary200,
                          boxShadow: [
                            BoxShadow(
                              color: AppThemeData.primary200.withValues(alpha: 0.4),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.local_taxi_rounded,
                          size: 52,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Ride Info Panel
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppThemeData.grey100Dark,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppThemeData.grey300Dark, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Price & Distance row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "EST. FARE",
                              style: TextStyle(
                                color: AppThemeData.grey500Dark,
                                fontSize: 11,
                                fontFamily: AppThemeData.medium,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              Constant().amountShow(amount: widget.rideData.montant.toString()),
                              style: TextStyle(
                                color: AppThemeData.primary200,
                                fontSize: 28,
                                fontFamily: AppThemeData.bold,
                              ),
                            ),
                          ],
                        ),
                        
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppThemeData.surface50Dark,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              Text(
                                "${widget.rideData.distance} ${widget.rideData.distanceUnit ?? 'km'}",
                                style: TextStyle(
                                  color: AppThemeData.grey900Dark,
                                  fontSize: 16,
                                  fontFamily: AppThemeData.bold,
                                ),
                              ),
                              Text(
                                widget.rideData.duree ?? "0 min",
                                style: TextStyle(
                                  color: AppThemeData.grey500Dark,
                                  fontSize: 12,
                                  fontFamily: AppThemeData.regular,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(color: Colors.white10),
                    ),

                    // Pickup and Dropoff timeline
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            Icon(Icons.circle, size: 14, color: AppThemeData.success300),
                            Container(
                              width: 2,
                              height: 36,
                              color: AppThemeData.grey300Dark,
                            ),
                            Icon(Icons.location_on_rounded, size: 16, color: AppThemeData.warning200),
                          ],
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "PICKUP",
                                style: TextStyle(
                                  color: AppThemeData.success300,
                                  fontSize: 10,
                                  fontFamily: AppThemeData.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.rideData.departName ?? "",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: AppThemeData.grey900Dark,
                                  fontSize: 14,
                                  fontFamily: AppThemeData.medium,
                                ),
                              ),
                              const SizedBox(height: 18),
                              Text(
                                "DROP-OFF",
                                style: TextStyle(
                                  color: AppThemeData.warning200,
                                  fontSize: 10,
                                  fontFamily: AppThemeData.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.rideData.destinationName ?? "",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: AppThemeData.grey900Dark,
                                  fontSize: 14,
                                  fontFamily: AppThemeData.medium,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(color: Colors.white10),
                    ),

                    // Passenger Info
                    Row(
                      children: [
                        ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: widget.rideData.photoPath ?? "",
                            height: 42,
                            width: 42,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: AppThemeData.surface50Dark,
                              child: const CircularProgressIndicator(strokeWidth: 2),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: AppThemeData.surface50Dark,
                              child: Icon(Icons.person, color: AppThemeData.grey500Dark),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${widget.rideData.prenom ?? ''} ${widget.rideData.nom ?? ''}".trim().isNotEmpty
                                    ? "${widget.rideData.prenom ?? ''} ${widget.rideData.nom ?? ''}"
                                    : "Passenger",
                                style: TextStyle(
                                  color: AppThemeData.grey900Dark,
                                  fontSize: 15,
                                  fontFamily: AppThemeData.bold,
                                ),
                              ),
                              Row(
                                children: [
                                  Icon(Icons.star_rounded, size: 14, color: AppThemeData.primary200),
                                  const SizedBox(width: 2),
                                  Text(
                                    widget.rideData.moyenne ?? "5.0",
                                    style: TextStyle(
                                      color: AppThemeData.grey500Dark,
                                      fontSize: 12,
                                      fontFamily: AppThemeData.medium,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        Text(
                          "${widget.rideData.numberPoeple ?? '1'} Pax",
                          style: TextStyle(
                            color: AppThemeData.primary400,
                            fontSize: 14,
                            fontFamily: AppThemeData.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Navigate + Decline row
              Row(
                children: [
                  // Navigate to Pickup
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _navigateToPickup,
                      icon: Icon(Icons.navigation_rounded, size: 16, color: AppThemeData.primary200),
                      label: Text(
                        "NAVIGATE",
                        style: TextStyle(
                          color: AppThemeData.primary200,
                          fontSize: 12,
                          fontFamily: AppThemeData.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: AppThemeData.primary200.withValues(alpha: 0.5)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Decline
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _declineRide(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: AppThemeData.warning200.withValues(alpha: 0.5)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(
                        "DECLINE",
                        style: TextStyle(
                          color: AppThemeData.warning200,
                          fontSize: 12,
                          fontFamily: AppThemeData.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Interactive Swipe-to-Accept Slider
              GestureDetector(
                onHorizontalDragUpdate: (details) {
                  if (_isAccepted) return;
                  setState(() {
                    _dragPosition = (_dragPosition + details.delta.dx).clamp(0.0, maxDrag);
                  });
                },
                onHorizontalDragEnd: (details) {
                  if (_isAccepted) return;
                  if (_dragPosition >= maxDrag * 0.85) {
                    // Trigger Accept
                    setState(() {
                      _dragPosition = maxDrag;
                    });
                    _acceptRide();
                  } else {
                    // Snap back
                    setState(() {
                      _dragPosition = 0.0;
                    });
                  }
                },
                child: Container(
                  height: _sliderHeight,
                  decoration: BoxDecoration(
                    color: AppThemeData.grey100Dark,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: AppThemeData.grey300Dark),
                  ),
                  child: Stack(
                    children: [
                      // Text background
                      Center(
                        child: Text(
                          _isAccepted ? "ACCEPTING RIDE..." : "SWIPE TO ACCEPT",
                          style: TextStyle(
                            color: _isAccepted ? AppThemeData.success300 : AppThemeData.grey500Dark,
                            fontSize: 14,
                            fontFamily: AppThemeData.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      
                      // Swipe Handle
                      Positioned(
                        left: _dragPosition + 4,
                        top: 4,
                        bottom: 4,
                        child: Container(
                          width: _sliderHeight - 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppThemeData.success300,
                            boxShadow: [
                              BoxShadow(
                                color: AppThemeData.success300.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(2, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
