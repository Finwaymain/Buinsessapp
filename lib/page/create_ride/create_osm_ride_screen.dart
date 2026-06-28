import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cabme_driver/constant/constant.dart';
import 'package:cabme_driver/constant/logdata.dart';
import 'package:cabme_driver/constant/show_toast_dialog.dart';
import 'package:cabme_driver/controller/create_ride_controller.dart';
import 'package:cabme_driver/model/customer_model.dart';
import 'package:cabme_driver/model/tax_model.dart';
import 'package:cabme_driver/page/search_location_screen.dart';
import 'package:cabme_driver/themes/button_them.dart';
import 'package:cabme_driver/themes/constant_colors.dart';
import 'package:cabme_driver/themes/custom_dialog_box.dart';
import 'package:cabme_driver/themes/custom_widget.dart';
import 'package:cabme_driver/themes/text_field_them.dart';
import 'package:cabme_driver/utils/Preferences.dart';
import 'package:cabme_driver/utils/dark_theme_provider.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:text_scroll/text_scroll.dart';

class CreateOsmRideScreen extends StatefulWidget {
  const CreateOsmRideScreen({super.key});

  @override
  State<CreateOsmRideScreen> createState() => _CreateOsmRideScreenState();
}

class _CreateOsmRideScreenState extends State<CreateOsmRideScreen> {
  late MapController mapController;

  final TextEditingController departureController = TextEditingController();
  final TextEditingController destinationController = TextEditingController();

  final controller = Get.put(CreateRideController());
  final myKey = GlobalKey<DropdownSearchState<CustomerData>>();

  final Location currentLocation = Location();

  Map<String, GeoPoint> markers = <String, GeoPoint>{};

  Widget? departureIcon;
  Widget? destinationIcon;
  Widget? taxiIcon;
  Widget? stopIcon;

  GeoPoint? departureLatLong;
  GeoPoint? destinationLatLong;

  RoadInfo roadInfo = RoadInfo();

  @override
  void initState() {
    ShowToastDialog.showLoader("Please wait".tr);
    mapController = MapController(initPosition: GeoPoint(latitude: 20.9153, longitude: -100.7439));
    setIcons();
    super.initState();
  }

  Future<void> setIcons() async {
    departureIcon = Image.asset("assets/icons/pickup.png", width: 30, height: 30);

    destinationIcon = Image.asset("assets/icons/dropoff.png", width: 30, height: 30);

    taxiIcon = Image.asset("assets/images/ic_taxi.png", width: Platform.isIOS ? 30 : 40, height: Platform.isIOS ? 30 : 80, fit: BoxFit.cover);

    stopIcon = Image.asset("assets/icons/location.png", width: 30, height: 30);
  }

  void getCurrentLocation(bool isDepartureSet, bool isDarkMode) async {
    if (isDepartureSet) {
      PermissionStatus permissionStatus = await currentLocation.hasPermission();
      if (permissionStatus == PermissionStatus.denied) {
        permissionStatus = await currentLocation.requestPermission();
      }
      if (permissionStatus != PermissionStatus.granted) {
        print("Location permission denied in create osm ride screen");
        return;
      }
      GeoPoint location = await mapController.myLocation();
      String url = 'https://nominatim.openstreetmap.org/reverse?format=json&lat=${location.latitude}&lon=${location.longitude}&zoom=18&addressdetails=1';

      var addressData = <String, dynamic>{};
      var package = Platform.isAndroid ? 'com.cabme.driver' : 'com.cabme.driver.ios';
      http.Response response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': package,
        },
      );
      showLog("API :: URL :: $url");
      showLog("API :: Request Header :: ${{
        'User-Agent': package,
      }.toString()} ");
      showLog("API :: responseStatus :: ${response.statusCode} ");
      showLog("API :: responseBody :: ${response.body} ");
      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);
        addressData = data;
      }

      departureController.text = addressData['display_name'] ?? '';
      setState(() {
        setDepartureMarker(GeoPoint(latitude: location.latitude, longitude: location.longitude), isDarkMode);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return Scaffold(
      backgroundColor: ConstantColors.background,
      body: Stack(
        children: [
          OSMFlutter(
              controller: mapController,
              osmOption: OSMOption(
                userTrackingOption: const UserTrackingOption(
                  enableTracking: false,
                  unFollowUser: false,
                ),
                zoomOption: const ZoomOption(
                  initZoom: 14,
                  minZoomLevel: 2,
                  maxZoomLevel: 19,
                  stepZoom: 1.0,
                ),
                roadConfiguration: RoadOption(
                  roadWidth: Platform.isIOS ? 50 : 10,
                  roadColor: Colors.blue,
                  roadBorderWidth: Platform.isIOS ? 15 : 10, // Set the road border width (outline)
                  roadBorderColor: Colors.black, // Border color
                  zoomInto: true,
                ),
              ),
              onMapIsReady: (active) async {
                if (active) {
                  getCurrentLocation(active, themeChange.getThem());
                  ShowToastDialog.closeLoader();
                }
              }),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () {
                    Get.back();
                  },
                  icon: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(
                      Icons.arrow_back_ios,
                      color: AppThemeData.grey900,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  child: Container(
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: themeChange.getThem() ? AppThemeData.surface50Dark : AppThemeData.surface50),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10),
                      child: Column(
                        children: [
                          Builder(builder: (context) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 00),
                              child: Row(
                                children: [
                                  SvgPicture.asset(
                                    'assets/icons/ic_location_map.svg',
                                    colorFilter: ColorFilter.mode(
                                      themeChange.getThem() ? AppThemeData.grey500Dark : AppThemeData.grey300Dark,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                  Expanded(
                                    child: InkWell(
                                      onTap: () async {
                                        Get.to(const AddressSearchScreen())?.then((value) {
                                          if (value != null) {
                                            SearchInfo place = value;
                                            departureController.text = place.address.toString();
                                            setDepartureMarker(GeoPoint(latitude: place.point!.latitude, longitude: place.point!.longitude), themeChange.getThem());
                                          }
                                        });
                                      },
                                      child: buildTextField(
                                        isDarkMode: themeChange.getThem(),
                                        title: "Departure".tr,
                                        textController: departureController,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      getCurrentLocation(true, themeChange.getThem());
                                    },
                                    autofocus: false,
                                    icon: const Icon(
                                      Icons.my_location_outlined,
                                      size: 18,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                          ReorderableListView(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            children: <Widget>[
                              for (int index = 0; index < controller.multiStopListNew.length; index += 1)
                                Container(
                                  key: ValueKey(controller.multiStopListNew[index]),
                                  child: Column(
                                    children: [
                                      InkWell(
                                          onTap: () async {
                                            Get.to(const AddressSearchScreen())?.then((value) {
                                              if (value != null) {
                                                SearchInfo place = value;
                                                controller.multiStopListNew[index].editingController.text = place.address.toString();
                                                controller.multiStopListNew[index].latitude = place.point!.latitude.toString();
                                                controller.multiStopListNew[index].longitude = place.point!.longitude.toString();
                                                setStopMarker(GeoPoint(latitude: place.point!.latitude, longitude: place.point!.longitude), index, themeChange.getThem());
                                              }
                                            });
                                          },
                                          child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 6),
                                              child: Text(
                                                String.fromCharCode(index + 65),
                                                style: TextStyle(fontSize: 16, color: ConstantColors.hintTextColor),
                                              ),
                                            ),
                                            Expanded(
                                              child: buildTextField(
                                                isDarkMode: themeChange.getThem(),
                                                title: "Where do you want to stop ?".tr,
                                                textController: controller.multiStopListNew[index].editingController,
                                              ),
                                            ),
                                            const SizedBox(
                                              width: 5,
                                            ),
                                            IconButton(
                                              onPressed: () {
                                                controller.removeStops(index);
                                                markers.remove("Stop $index");
                                                getDirections();
                                              },
                                              icon: Icon(
                                                Icons.close,
                                                size: 20,
                                                color: ConstantColors.hintTextColor,
                                              ),
                                            )
                                          ])),
                                    ],
                                  ),
                                ),
                            ],
                            onReorder: (int oldIndex, int newIndex) {
                              setState(() {
                                if (oldIndex < newIndex) {
                                  newIndex -= 1;
                                }
                                final AddStopModel item = controller.multiStopListNew.removeAt(oldIndex);
                                controller.multiStopListNew.insert(newIndex, item);
                              });
                            },
                          ),
                          Row(
                            children: [
                              SvgPicture.asset(
                                'assets/icons/ic_location_map.svg',
                                colorFilter: ColorFilter.mode(
                                  themeChange.getThem() ? AppThemeData.grey500Dark : AppThemeData.grey300Dark,
                                  BlendMode.srcIn,
                                ),
                              ),
                              Expanded(
                                child: InkWell(
                                  onTap: () async {
                                    Get.to(const AddressSearchScreen())?.then((value) {
                                      if (value != null) {
                                        SearchInfo place = value;
                                        destinationController.text = place.address.toString();

                                        setDestinationMarker(
                                          GeoPoint(latitude: place.point?.latitude ?? 0, longitude: place.point?.longitude ?? 0),
                                          themeChange.getThem(),
                                        );
                                      }
                                    });
                                  },
                                  child: buildTextField(
                                    isDarkMode: themeChange.getThem(),
                                    title: "Where do you want to stop ?".tr,
                                    textController: destinationController,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: dividerCust(isDarkMode: themeChange.getThem()),
                          ),
                          InkWell(
                            onTap: () {
                              controller.addStops();
                              setState(() {});
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.add_circle,
                                    color: themeChange.getThem() ? AppThemeData.grey500Dark : AppThemeData.grey500,
                                  ),
                                  const SizedBox(
                                    width: 5,
                                  ),
                                  Text('Add stop'.tr,
                                      style: TextStyle(
                                        color: themeChange.getThem() ? AppThemeData.grey500Dark : AppThemeData.grey500,
                                        fontSize: 16,
                                        fontFamily: AppThemeData.regular,
                                      )),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Future<void> setDepartureMarker(GeoPoint departure, isDarkMode) async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (markers.containsKey('Departure')) {
        await mapController.removeMarker(markers['Departure']!);
      }

      await mapController
          .addMarker(departure,
              markerIcon: MarkerIcon(iconWidget: departureIcon),
              angle: pi / 3,
              iconAnchor: IconAnchor(
                anchor: Anchor.top,
              ))
          .then((v) {
        markers['Departure'] = departure;
      });

      departureLatLong = departure;

      // _controller?.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(target: LatLng(departure.latitude, departure.longitude), zoom: 18)));
      if (departureLatLong != null && destinationLatLong != null) {
        getDirections();
        conformationBottomSheet(context, isDarkMode);
      } else {
        await mapController.moveTo(departure, animate: true);
      }
    });
  }

  Future<void> setDestinationMarker(GeoPoint destination, bool isDarkMode) async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (markers.containsKey('Destination')) {
        await mapController.removeMarker(markers['Destination']!);
      }

      mapController
          .addMarker(destination,
              markerIcon: MarkerIcon(iconWidget: destinationIcon),
              angle: pi / 3,
              iconAnchor: IconAnchor(
                anchor: Anchor.top,
              ))
          .then((v) {
        markers['Destination'] = destination;
      });

      destinationLatLong = destination;

      if (departureLatLong != null && destinationLatLong != null) {
        getDirections();
        conformationBottomSheet(context, isDarkMode);
      }
    });
  }

  Future<void> setStopMarker(GeoPoint destination, int index, bool isDarkMode) async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (markers.containsKey('Stop $index')) {
        await mapController.removeMarker(markers['Stop $index']!);
      }

      mapController
          .addMarker(destination,
              markerIcon: MarkerIcon(iconWidget: stopIcon),
              angle: pi / 3,
              iconAnchor: IconAnchor(
                anchor: Anchor.top,
              ))
          .then((v) {
        markers['Stop $index'] = destination;
      });

      if (departureLatLong != null && destinationLatLong != null) {
        getDirections();
        conformationBottomSheet(context, isDarkMode);
      }
    });
  }

  Widget buildTextField({required title, required TextEditingController textController, required bool isDarkMode}) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: TextField(
        controller: textController,
        textInputAction: TextInputAction.done,
        style: TextStyle(color: isDarkMode == true ? AppThemeData.grey900Dark : AppThemeData.grey900),
        decoration: InputDecoration(
          hintStyle: TextStyle(
            fontSize: 16,
            color: isDarkMode ? AppThemeData.grey500Dark : AppThemeData.grey500,
            fontFamily: AppThemeData.regular,
          ),
          hintText: title,
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
          enabled: false,
        ),
      ),
    );
  }

  Future<void> getDirections() async {
    await mapController.removeLastRoad();
    roadInfo = await mapController.drawRoad(
      GeoPoint(latitude: departureLatLong?.latitude ?? 0, longitude: departureLatLong?.longitude ?? 0),
      GeoPoint(latitude: destinationLatLong?.latitude ?? 0, longitude: destinationLatLong?.longitude ?? 0),
      roadType: RoadType.car,
      roadOption: RoadOption(
        roadWidth: Platform.isIOS ? 50 : 10,
        roadColor: Colors.blue,
        roadBorderWidth: Platform.isIOS ? 15 : 10, // Set the road border width (outline)
        roadBorderColor: Colors.black, // Border color
        zoomInto: true,
      ),
    );
    setState(() {});
    updateCameraLocation(
        source: GeoPoint(latitude: departureLatLong?.latitude ?? 0, longitude: departureLatLong?.longitude ?? 0),
        destination: GeoPoint(latitude: destinationLatLong?.latitude ?? 0, longitude: destinationLatLong?.longitude ?? 0),
        mapController: mapController);
    setState(() {});
    // await mapController.moveTo(
    //   GeoPoint(latitude: departureLatLong!.latitude, longitude: departureLatLong!.longitude),
    //   animate: true,
    // );
  }

  Future<dynamic> conformationBottomSheet(BuildContext context, bool isDarkMode) {
    return showModalBottomSheet(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(topRight: Radius.circular(15), topLeft: Radius.circular(15))),
        context: context,
        isDismissible: false,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return StatefulBuilder(builder: (context, setState) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 20),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: ButtonThem.buildIconButton(context,
                        icon: Icons.arrow_back_ios,
                        iconColor: isDarkMode ? AppThemeData.grey900 : AppThemeData.grey900Dark,
                        btnHeight: 40,
                        btnWidthRatio: 0.25,
                        title: "Back".tr,
                        btnColor: AppThemeData.primary200,
                        txtColor: isDarkMode ? AppThemeData.grey900 : AppThemeData.grey900Dark, onPress: () {
                      Get.back();
                    }),
                  ),
                  Expanded(
                    child: ButtonThem.buildButton(context,
                        btnHeight: 40,
                        title: "Continue".tr,
                        btnColor: AppThemeData.primary200,
                        txtColor: isDarkMode ? AppThemeData.grey900 : AppThemeData.grey900Dark, onPress: () async {
                      controller.checkBalance().then((value) async {
                        if (value == true) {
                          if (roadInfo.distance != null) {
                            // if (Constant.distanceUnit == "KM") {
                            //   controller.distance.value = roadInfo.distance! / 1000.00;
                            // } else {
                            //   controller.distance.value = roadInfo.distance! / 1609.34;
                            // }
                            controller.distance.value = roadInfo.distance!;
                            int hours = double.parse(roadInfo.duration.toString()) ~/ 3600;
                            int minutes = ((double.parse(roadInfo.duration.toString()) % 3600) / 60).round();
                            controller.duration.value = '$hours hours $minutes minutes';

                            Get.back();
                            tripOptionBottomSheet(context, isDarkMode);
                          }
                        } else {
                          ShowToastDialog.showToast(
                              "Your wallet balance must be".tr + Constant().amountShow(amount: Constant.minimumWalletBalance!.toString()) + 'to book ride.'.tr);
                        }
                      });
                    }),
                  ),
                ],
              ),
            );
          });
        });
  }

  final passengerFirstNameController = TextEditingController();
  final passengerLastNameController = TextEditingController();
  final passengerEmailController = TextEditingController();
  final passengerNumberController = TextEditingController();
  final passengerController = TextEditingController();

  Future<dynamic> tripOptionBottomSheet(BuildContext context, bool isDarkMode) {
    return showModalBottomSheet(
        context: context,
        isDismissible: false,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return Container(
            decoration: BoxDecoration(
              color: isDarkMode ? AppThemeData.surface50Dark : AppThemeData.surface50,
              borderRadius: const BorderRadius.all(Radius.circular(15)),
            ),
            margin: const EdgeInsets.all(10),
            child: StatefulBuilder(builder: (context, setState) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 20),
                child: Padding(
                  padding: MediaQuery.of(context).viewInsets,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Customer Info".tr,
                              style: TextStyle(fontSize: 18, fontFamily: AppThemeData.medium, color: isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900),
                            ),
                            Visibility(
                              visible: controller.createUser.value,
                              child: InkWell(
                                onTap: () {
                                  controller.createUser.value = false;
                                  passengerFirstNameController.clear();
                                  passengerLastNameController.clear();
                                  passengerEmailController.clear();
                                  passengerNumberController.clear();
                                  passengerController.clear();
                                  setState(() {});
                                },
                                child: Text(
                                  "Select user".tr,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: isDarkMode ? AppThemeData.grey500Dark : AppThemeData.grey500,
                                    fontFamily: AppThemeData.medium,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Visibility(
                        visible: !controller.createUser.value,
                        child: Column(
                          children: [
                            Row(
                              children: [
                                // Expanded(
                                //   child: Padding(
                                //     padding: const EdgeInsets.all(8.0),
                                //     child: DropdownSearch<CustomerData>(
                                //       key: myKey,
                                //
                                //       popupProps: PopupProps.dialog(
                                //         showSearchBox: true,
                                //         showSelectedItems: true,
                                //         searchFieldProps: TextFieldProps(
                                //           cursorColor: AppThemeData.primary200,
                                //           decoration: InputDecoration(
                                //             contentPadding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                                //             border: const OutlineInputBorder(
                                //               borderSide: BorderSide(color: Colors.grey, width: 1.0),
                                //             ),
                                //             hintText: "Search user".tr,
                                //           ),
                                //         ),
                                //       ),
                                //       dropdownDecoratorProps: DropDownDecoratorProps(
                                //         dropdownSearchDecoration: InputDecoration(
                                //           contentPadding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                                //           border: OutlineInputBorder(
                                //             borderRadius: BorderRadius.circular(0),
                                //             borderSide: BorderSide(color: isDarkMode ? AppThemeData.grey200Dark : AppThemeData.grey200, width: 1.0),
                                //           ),
                                //           focusedBorder: OutlineInputBorder(
                                //             borderRadius: BorderRadius.circular(0),
                                //             borderSide: BorderSide(color: isDarkMode ? AppThemeData.grey200Dark : AppThemeData.grey200, width: 1.0),
                                //           ),
                                //           disabledBorder: OutlineInputBorder(
                                //             borderRadius: BorderRadius.circular(0),
                                //             borderSide: BorderSide(color: isDarkMode ? AppThemeData.grey200Dark : AppThemeData.grey200, width: 1.0),
                                //           ),
                                //           enabledBorder: OutlineInputBorder(
                                //             borderRadius: BorderRadius.circular(0),
                                //             borderSide: BorderSide(color: isDarkMode ? AppThemeData.grey200Dark : AppThemeData.grey200, width: 1.0),
                                //           ),
                                //           hintText: "Select user".tr,
                                //           hintStyle: TextStyle(
                                //             fontSize: 16,
                                //             color: isDarkMode ? AppThemeData.grey500Dark : AppThemeData.grey500,
                                //             fontFamily: AppThemeData.regular,
                                //           ),
                                //         ),
                                //       ),
                                //
                                //       compareFn: (item1, item2) => item1.fullName() == item2.fullName(),
                                //       itemAsString: (CustomerData u) => u.userAsString(),
                                //       onChanged: (CustomerData? value) async {
                                //         controller.selectedUser = value;
                                //         passengerFirstNameController.text = value!.prenom!;
                                //         passengerLastNameController.text = value.nom!;
                                //         passengerEmailController.text = value.email!;
                                //         passengerNumberController.text = value.phone!;
                                //       },
                                //       items: controller.userList,
                                //       selectedItem: controller.selectedUser,
                                //
                                //       // filterFn: (user, filter) =>
                                //       //     user.userFilterByCreationDate(filter),
                                //     ),
                                //
                                //     // DropdownButtonFormField(
                                //     //     isExpanded: true,
                                //     //     decoration: const InputDecoration(
                                //     //       contentPadding:
                                //     //           EdgeInsets.symmetric(
                                //     //               vertical: 11,
                                //     //               horizontal: 8),
                                //     //       focusedBorder: OutlineInputBorder(
                                //     //         borderSide: BorderSide(
                                //     //             color: Colors.grey,
                                //     //             width: 1.0),
                                //     //       ),
                                //     //       enabledBorder: OutlineInputBorder(
                                //     //         borderSide: BorderSide(
                                //     //             color: Colors.grey,
                                //     //             width: 1.0),
                                //     //       ),
                                //     //       errorBorder: OutlineInputBorder(
                                //     //         borderSide: BorderSide(
                                //     //             color: Colors.grey,
                                //     //             width: 1.0),
                                //     //       ),
                                //     //       border: OutlineInputBorder(
                                //     //         borderSide: BorderSide(
                                //     //             color: Colors.grey,
                                //     //             width: 1.0),
                                //     //       ),
                                //     //       isDense: true,
                                //     //     ),
                                //     //     onChanged: (CustomerData? value) {
                                //     //       controller.selectedUser = value;
                                //     //       passengerFirstNameController
                                //     //           .text = value!.nom!;
                                //     //       passengerLastNameController.text =
                                //     //           value.prenom!;
                                //     //       passengerEmailController.text =
                                //     //           value.email!;
                                //     //       passengerNumberController.text =
                                //     //           value.phone!;
                                //     //     },
                                //     //     hint: const Text("Select user"),
                                //     //     items:
                                //     //         controller.userList.map((item) {
                                //     //       return DropdownMenuItem(
                                //     //         value: item,
                                //     //         child: Text(
                                //     //           "${item.nom} ${item.prenom}",
                                //     //         ),
                                //     //       );
                                //     //     }).toList()),
                                //   ),
                                // ),

                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: DropdownSearch<CustomerData>(
                                      key: myKey,

                                      // new v6 API → items must be a function
                                      items: (String? filter, _) {
                                        return controller.userList;
                                      },

                                      popupProps: PopupProps.dialog(
                                        showSearchBox: true,
                                        showSelectedItems: true,
                                        searchFieldProps: TextFieldProps(
                                          cursorColor: AppThemeData.primary200,
                                          decoration: InputDecoration(
                                            contentPadding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                                            border: const OutlineInputBorder(
                                              borderSide: BorderSide(color: Colors.grey, width: 1.0),
                                            ),
                                            hintText: "Search user".tr,
                                          ),
                                        ),
                                      ),

                                      // use decoratorProps (new name)
                                      decoratorProps: DropDownDecoratorProps(
                                        decoration: InputDecoration(
                                          contentPadding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(0),
                                            borderSide: BorderSide(
                                              color: isDarkMode ? AppThemeData.grey200Dark : AppThemeData.grey200,
                                              width: 1.0,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(0),
                                            borderSide: BorderSide(
                                              color: isDarkMode ? AppThemeData.grey200Dark : AppThemeData.grey200,
                                              width: 1.0,
                                            ),
                                          ),
                                          hintText: "Select user".tr,
                                          hintStyle: TextStyle(
                                            fontSize: 16,
                                            color: isDarkMode ? AppThemeData.grey500Dark : AppThemeData.grey500,
                                            fontFamily: AppThemeData.regular,
                                          ),
                                        ),
                                      ),

                                      itemAsString: (CustomerData u) => u.userAsString(),
                                      compareFn: (a, b) => a.fullName() == b.fullName(),

                                      onChanged: (CustomerData? value) {
                                        controller.selectedUser = value;
                                        passengerFirstNameController.text = value?.prenom ?? '';
                                        passengerLastNameController.text = value?.nom ?? '';
                                        passengerEmailController.text = value?.email ?? '';
                                        passengerNumberController.text = value?.phone ?? '';
                                      },

                                      selectedItem: controller.selectedUser,
                                    ),
                                  ),
                                ),

                                Expanded(
                                  child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: TextFieldWidget(
                                        hintText: 'No. of passenger'.tr,
                                        controller: passengerController,
                                      )),
                                ),
                              ],
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                            InkWell(
                              onTap: () {
                                controller.selectedUser = null;
                                controller.createUser.value = true;
                                passengerFirstNameController.clear();
                                passengerLastNameController.clear();
                                passengerEmailController.clear();
                                passengerNumberController.clear();
                                passengerController.clear();
                                setState(() {});
                              },
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.add_circle,
                                    color: isDarkMode ? AppThemeData.grey500Dark : AppThemeData.grey500,
                                  ),
                                  const SizedBox(
                                    width: 5,
                                  ),
                                  Text(
                                    'Create user'.tr,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                          ],
                        ),
                      ),
                      Visibility(
                        visible: controller.createUser.value,
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: TextFieldWidget(
                                        controller: passengerFirstNameController,
                                        hintText: 'First name'.tr,
                                      )),
                                ),
                                Expanded(
                                  child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: TextFieldWidget(
                                        controller: passengerLastNameController,
                                        hintText: 'Last name'.tr,
                                      )),
                                ),
                              ],
                            ),
                            Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: TextFieldWidget(
                                  controller: passengerEmailController,
                                  hintText: 'email'.tr,
                                )),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: TextFieldWidget(hintText: 'Phone number'.tr, controller: passengerNumberController),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: TextFieldWidget(hintText: 'No. of passenger'.tr, controller: passengerController),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              child: ButtonThem.buildIconButton(context,
                                  icon: Icons.arrow_back_ios,
                                  iconColor: isDarkMode ? AppThemeData.grey900 : AppThemeData.grey900Dark,
                                  btnHeight: 40,
                                  btnWidthRatio: 0.25,
                                  title: "Back".tr,
                                  btnColor: AppThemeData.primary200,
                                  txtColor: isDarkMode ? AppThemeData.grey900 : AppThemeData.grey900Dark, onPress: () {
                                Get.back();
                              }),
                            ),
                            Expanded(
                              child: ButtonThem.buildButton(context,
                                  btnWidthRatio: 0.25,
                                  btnHeight: 40,
                                  title: "BOOK NOW".tr,
                                  btnColor: AppThemeData.primary200,
                                  txtColor: isDarkMode ? AppThemeData.grey900 : AppThemeData.grey900Dark, onPress: () async {
                                if ((passengerFirstNameController.text.isEmpty ||
                                        passengerLastNameController.text.isEmpty ||
                                        passengerNumberController.text.isEmpty ||
                                        passengerEmailController.text.isEmpty) &&
                                    controller.selectedUser == null) {
                                  ShowToastDialog.showToast("Please Enter Details".tr);
                                } else if (passengerController.text.isEmpty) {
                                  ShowToastDialog.showToast("Please Enter Details".tr);
                                } else {
                                  double cout = 0.0;

                                  if (controller.distance.value > double.parse(controller.vehicleData!.minimumDeliveryChargesWithin!)) {
                                    cout = (controller.distance.value * double.parse(controller.vehicleData!.deliveryCharges!)).toDouble();
                                  } else {
                                    cout = double.parse(controller.vehicleData!.minimumDeliveryCharges.toString());
                                  }
                                  for (var i = 0; i < Constant.taxList.length; i++) {
                                    if (Constant.taxList[i].statut == 'yes') {
                                      if (Constant.taxList[i].type == "Fixed") {
                                        controller.taxAmount.value += double.parse(Constant.taxList[i].value.toString());
                                      } else {
                                        controller.taxAmount.value += (cout * double.parse(Constant.taxList[i].value!.toString())) / 100;
                                      }
                                    }
                                  }
                                  Get.back();
                                  conformDataBottomSheet(context, cout, isDarkMode);
                                }
                              }),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          );
        });
  }

  Future<dynamic> conformDataBottomSheet(BuildContext context, double tripPrice, bool isDarkMode) {
    return showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        isDismissible: false,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return Container(
            decoration: BoxDecoration(color: isDarkMode ? AppThemeData.surface50Dark : AppThemeData.surface50, borderRadius: BorderRadius.all(Radius.circular(15))),
            margin: const EdgeInsets.all(10),
            child: StatefulBuilder(builder: (context, setState) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 15),
                child: Obx(
                  () => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20.0),
                        child: Row(
                          children: [
                            Expanded(child: buildDetails(isDarkMode: isDarkMode, title: "Cash".tr, value: 'Payment method'.tr)),
                            const SizedBox(
                              width: 10,
                            ),
                            Expanded(
                                child: buildDetails(
                                    isScroll: true,
                                    isDarkMode: isDarkMode,
                                    title: "${controller.distance.value.toStringAsFixed(int.parse(Constant.decimal!))}${Constant.distanceUnit}",
                                    value: 'Distance'.tr)),
                            const SizedBox(
                              width: 10,
                            ),
                            Expanded(child: buildDetails(isScroll: true, isDarkMode: isDarkMode, title: controller.duration.value, value: 'Duration'.tr)),
                            const SizedBox(
                              width: 10,
                            ),
                            Expanded(
                                child: buildDetails(
                              isScroll: true,
                              isDarkMode: isDarkMode,
                              title: Constant().amountShow(amount: tripPrice.toString()),
                              value: 'Trip Price'.tr,
                            )),
                          ],
                        ),
                      ),
                      ListView.builder(
                        itemCount: Constant.taxList.length,
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          TaxModel taxModel = Constant.taxList[index];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                            title: Text(
                              '${taxModel.libelle.toString()} (${taxModel.type == "Fixed" ? Constant().amountShow(amount: taxModel.value) : "${taxModel.value}%"})',
                              style: TextStyle(
                                fontFamily: AppThemeData.medium,
                                color: isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900,
                                fontSize: 16,
                              ),
                            ),
                            trailing: Text(Constant().amountShow(amount: controller.calculateTax(taxModel: taxModel, tripPrice: tripPrice).toString()),
                                style: TextStyle(
                                  fontFamily: AppThemeData.medium,
                                  color: isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900,
                                  fontSize: 16,
                                )),
                          );
                        },
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      dividerCust(isDarkMode: isDarkMode),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Total amount:".tr,
                                style: TextStyle(
                                  letterSpacing: 1.0,
                                  fontFamily: AppThemeData.medium,
                                  fontSize: 16,
                                  color: isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900,
                                )),
                            Text(Constant().amountShow(amount: (tripPrice + controller.taxAmount.value).toString()),
                                style: TextStyle(
                                  letterSpacing: 1.0,
                                  fontFamily: AppThemeData.medium,
                                  fontSize: 16,
                                  color: isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900,
                                ))
                          ],
                        ),
                      ),
                      dividerCust(isDarkMode: isDarkMode),
                      const SizedBox(
                        height: 10,
                      ),
                      Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: ButtonThem.buildIconButton(context,
                                icon: Icons.arrow_back_ios,
                                iconColor: isDarkMode ? AppThemeData.grey900 : AppThemeData.grey900Dark,
                                btnHeight: 40,
                                btnWidthRatio: 0.25,
                                title: "Back".tr,
                                btnColor: AppThemeData.primary200,
                                txtColor: isDarkMode ? AppThemeData.grey900 : AppThemeData.grey900Dark, onPress: () async {
                              Get.back();
                              tripOptionBottomSheet(context, isDarkMode);
                            }),
                          ),
                          Expanded(
                            child: ButtonThem.buildButton(context,
                                btnHeight: 40,
                                title: "BOOK NOW".tr,
                                btnColor: AppThemeData.primary200,
                                txtColor: isDarkMode ? AppThemeData.grey900 : AppThemeData.grey900Dark, onPress: () {
                              List stopsList = [];
                              for (var i = 0; i < controller.multiStopListNew.length; i++) {
                                if (controller.multiStopListNew[i].latitude != '' &&
                                    controller.multiStopListNew[i].longitude != '' &&
                                    controller.multiStopListNew[i].editingController.text.isNotEmpty) {
                                  stopsList.add({
                                    "latitude": controller.multiStopListNew[i].latitude.toString(),
                                    "longitude": controller.multiStopListNew[i].longitude.toString(),
                                    "location": controller.multiStopListNew[i].editingController.text.toString()
                                  });
                                }
                              }
                              Map<String, dynamic> bodyParams = {
                                'user_id': controller.selectedUser != null ? controller.selectedUser!.id! : DateTime.now().millisecondsSinceEpoch,
                                'lat1': departureLatLong!.latitude.toString(),
                                'lng1': departureLatLong!.longitude.toString(),
                                'lat2': destinationLatLong!.latitude.toString(),
                                'lng2': destinationLatLong!.longitude.toString(),
                                'cout': tripPrice.toString(),
                                'distance': controller.distance.toString(),
                                'distance_unit': Constant.distanceUnit.toString(),
                                'duree': controller.duration.toString(),
                                'id_conducteur': Preferences.getInt(Preferences.userId).toString(),
                                'id_payment': controller.paymentMethodId.value,
                                'depart_name': departureController.text,
                                'destination_name': destinationController.text,
                                'stops': stopsList,
                                'place': '',
                                'number_poeple': passengerController.text,
                                'image': '',
                                'image_name': "",
                                'user_detail': {
                                  'name': "${passengerFirstNameController.text} ${passengerLastNameController.text}",
                                  'phone': passengerNumberController.text.toString(),
                                  'email': passengerEmailController.text.toString()
                                },
                                'ride_type': "driver",
                                'statut_round': 'no',
                                'trip_objective': "",
                                'age_children1': "",
                                'age_children2': "",
                                'age_children3': "",
                              };

                              controller.bookRide(bodyParams).then((value) {
                                if (value != null) {
                                  if (value['success'] == "success") {
                                    Get.back();
                                    getDirections();
                                    setIcons();
                                    departureController.clear();
                                    destinationController.clear();
                                    mapController.removeLastRoad();
                                    List<GeoPoint> allGeoPoints = markers.values.toList();
                                    mapController.removeMarkers(allGeoPoints);
                                    departureLatLong = null;
                                    destinationLatLong = null;

                                    passengerFirstNameController.clear();
                                    passengerLastNameController.clear();
                                    passengerEmailController.clear();
                                    passengerController.clear();
                                    passengerNumberController.clear();
                                    tripPrice = 0.0;
                                    markers.clear();

                                    showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return CustomDialogBox(
                                            text: "Ok".tr,
                                            title: "",
                                            descriptions: "Your booking is confirmed".tr,
                                            onPress: () {
                                              Get.back();
                                              Get.back();
                                            },
                                            img: Image.asset('assets/images/green_checked.png'),
                                          );
                                        });
                                  }
                                }
                              });
                            }),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          );
        });
  }

  Column buildDetails({title, value, required bool isDarkMode, bool? isScroll = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        isScroll == false
            ? Text(title.toString().padLeft(2, '0'),
                style: TextStyle(
                  fontFamily: AppThemeData.semiBold,
                  color: AppThemeData.primary200,
                  fontSize: 18,
                ))
            : TextScroll(title.toString(),
                mode: TextScrollMode.bouncing,
                pauseBetween: const Duration(seconds: 2),
                style: TextStyle(
                  fontFamily: AppThemeData.semiBold,
                  color: AppThemeData.primary200,
                  fontSize: 18,
                )),
        const SizedBox(
          height: 2,
        ),
        Text(value,
            maxLines: 1,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppThemeData.regular,
              color: isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900,
              fontSize: 12,
            )),
      ],
    );
  }

  Future<void> updateCameraLocation({required GeoPoint source, required GeoPoint destination, required MapController mapController}) async {
    BoundingBox bounds;

    if (source.latitude > destination.latitude && source.longitude > destination.longitude) {
      bounds = BoundingBox(
        north: source.latitude,
        south: destination.latitude,
        east: source.longitude,
        west: destination.longitude,
      );
    } else if (source.longitude > destination.longitude) {
      bounds = BoundingBox(
        north: destination.latitude,
        south: source.latitude,
        east: source.longitude,
        west: destination.longitude,
      );
    } else if (source.latitude > destination.latitude) {
      bounds = BoundingBox(
        north: source.latitude,
        south: destination.latitude,
        east: destination.longitude,
        west: source.longitude,
      );
    } else {
      bounds = BoundingBox(
        north: destination.latitude,
        south: source.latitude,
        east: destination.longitude,
        west: source.longitude,
      );
    }

    await mapController.zoomToBoundingBox(bounds, paddinInPixel: 300);

    // Verify the camera location
    await checkCameraLocation(bounds, mapController);
  }

  Future<void> checkCameraLocation(BoundingBox bounds, MapController mapController) async {
    // await mapController.rotateMapCamera(0);
    BoundingBox currentBounds = await mapController.bounds;

    if (currentBounds.north == -90 || currentBounds.south == -90) {
      return checkCameraLocation(bounds, mapController);
    }
  }
}
