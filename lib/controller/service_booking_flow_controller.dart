import 'dart:async';

import 'package:cabme_driver/constant/constant.dart';
import 'package:cabme_driver/controller/my_booking_controller.dart';
import 'package:cabme_driver/model/driver_booking_model.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class ServiceBookingFlowController extends GetxController {
  ServiceBookingFlowController({
    required DriverBookingItem booking,
    required this.listController,
  })  : booking = booking,
        currentBooking = booking.obs {
    _initItems(booking);
    if (booking.isInProgress) {
      startedAt.value = DateTime.now();
      _startTimer();
    }
  }

  final DriverBookingItem booking;
  final MyBookingController listController;

  final Rx<DriverBookingItem> currentBooking;
  final RxList<ServiceLineItem> serviceItems = <ServiceLineItem>[].obs;
  final RxList<String> extraServices = <String>[].obs;
  final RxList<String> beforePhotos = <String>[].obs;
  final RxList<String> afterPhotos = <String>[].obs;
  final RxString workSummary = ''.obs;
  final RxDouble materialCost = 0.0.obs;
  final RxDouble visitingCharge = 0.0.obs;
  final RxDouble platformFeeStored = 0.0.obs;
  final RxBool isPaused = false.obs;
  final Rx<DateTime?> startedAt = Rx<DateTime?>(null);
  final RxInt elapsedSeconds = 0.obs;

  Timer? _timer;
  final _picker = ImagePicker();

  static bool isVisitingLine(String name) {
    final n = name.toLowerCase();
    return n.contains('visit') && n.contains('charge');
  }

  void _initItems(DriverBookingItem item) {
    final rawItems = item.serviceItems.isNotEmpty
        ? item.serviceItems
        : [ServiceLineItem(name: item.categoryLabel, price: item.amount)];
    _assignServiceItems(rawItems);
    _distributePrices();
    _syncStoredFees();
  }

  void _assignServiceItems(List<ServiceLineItem> rawItems) {
    final labour = <ServiceLineItem>[];
    var visit = visitingCharge.value;
    for (final entry in rawItems) {
      if (isVisitingLine(entry.name)) {
        if (entry.price > visit) visit = entry.price;
      } else {
        labour.add(entry);
      }
    }
    if (visit > 0) visitingCharge.value = visit;
    serviceItems.assignAll(labour);
    _syncStoredFees();
  }

  void _syncStoredFees() {
    final amount = currentBooking.value.amount > 0 ? currentBooking.value.amount : booking.amount;
    if (amount <= 0) return;
    final labour = serviceItems.fold<double>(0, (t, e) => t + e.price);
    final remainder = amount - labour - visitingCharge.value - materialCost.value;
    if (remainder > 0 && platformFeeStored.value <= 0) {
      platformFeeStored.value = remainder;
    }
  }

  void _distributePrices() {
    final amount = currentBooking.value.amount > 0 ? currentBooking.value.amount : booking.amount;
    if (serviceItems.isEmpty || amount <= 0) return;
    final withoutPrice = serviceItems.where((e) => e.price <= 0).length;
    if (withoutPrice == 0) return;
    final distributable = amount - visitingCharge.value - materialCost.value - platformFeeStored.value;
    if (distributable <= 0) return;
    final each = distributable / serviceItems.length;
    serviceItems.assignAll(serviceItems.map((e) => e.price > 0 ? e : e.copyWith(price: each)));
  }

  List<ServiceLineItem> get extraAddedItems {
    final extras = extraServices.toSet();
    return serviceItems.where((e) => extras.contains(e.name)).toList();
  }

  double get labourTotal {
    final sum = serviceItems.fold<double>(0, (t, e) => t + e.price);
    if (sum > 0) return sum;
    final bookingAmount = currentBooking.value.amount > 0 ? currentBooking.value.amount : booking.amount;
    final base = bookingAmount - visitingCharge.value - materialCost.value - platformFeeStored.value;
    return base > 0 ? base : bookingAmount;
  }

  double get billSubtotal => labourTotal + materialCost.value + visitingCharge.value;

  double get billTotal => billSubtotal + platformFeeStored.value;

  double get subTotal => billSubtotal;

  double get platformFee => platformFeeStored.value;

  double get totalBill => billTotal;

  String get elapsedLabel {
    final s = elapsedSeconds.value;
    final h = (s ~/ 3600).toString().padLeft(2, '0');
    final m = ((s % 3600) ~/ 60).toString().padLeft(2, '0');
    final sec = (s % 60).toString().padLeft(2, '0');
    return '$h:$m:$sec';
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!isPaused.value && startedAt.value != null) {
        elapsedSeconds.value = DateTime.now().difference(startedAt.value!).inSeconds;
      }
    });
  }

  void togglePause() {
    isPaused.toggle();
  }

  void toggleServiceDone(int index) {
    if (index < 0 || index >= serviceItems.length) return;
    final item = serviceItems[index];
    serviceItems[index] = item.copyWith(completed: !item.completed);
    serviceItems.refresh();
  }

  void addExtraService(String name, {double price = 0}) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    if (serviceItems.any((e) => e.name.toLowerCase() == trimmed.toLowerCase())) {
      Get.snackbar('Already Added'.tr, 'This service is already in the list.'.tr);
      return;
    }
    extraServices.add(trimmed);
    serviceItems.add(ServiceLineItem(name: trimmed, price: price, completed: true));
  }

  void removeExtraService(String name) {
    extraServices.remove(name);
    serviceItems.removeWhere((e) => e.name == name);
    serviceItems.refresh();
  }

  Future<void> pickPhoto({required bool before}) async {
    final file = await _picker.pickImage(source: ImageSource.camera, imageQuality: 75);
    if (file == null) return;
    if (before) {
      beforePhotos.add(file.path);
    } else {
      afterPhotos.add(file.path);
    }
  }

  void removePhoto(String path, {required bool before}) {
    if (before) {
      beforePhotos.remove(path);
    } else {
      afterPhotos.remove(path);
    }
  }

  Future<void> openNavigation() async {
    final lat = currentBooking.value.lat;
    final lng = currentBooking.value.lng;
    if (lat == null || lng == null || lat.isEmpty || lng.isEmpty) {
      Get.snackbar('Navigation'.tr, 'Customer location is not available for this booking.'.tr);
      return;
    }
    try {
      await Constant.launchMapURl(lat, lng);
    } catch (e) {
      Get.snackbar('Navigation'.tr, e.toString());
    }
  }

  Future<void> callCustomer() async {
    final phone = currentBooking.value.customerPhone;
    if (phone.isEmpty) return;
    await Constant.makePhoneCall(phone);
  }

  Future<bool> acceptBooking() async {
    final ok = await listController.updateServiceStatus(currentBooking.value.id, 'accepted');
    if (ok) await _refreshCurrent();
    return ok;
  }

  Future<bool> rejectBooking() async {
    return listController.updateServiceStatus(currentBooking.value.id, 'rejected');
  }

  static String normalizeOtp(String raw) => raw.replaceAll(RegExp(r'\D'), '');

  Future<bool> verifyOtpAndStart(String otp) async {
    final normalized = normalizeOtp(otp);
    if (normalized.length < 4) {
      Get.snackbar('OTP Required'.tr, 'Please enter the 4-digit OTP from customer.'.tr);
      return false;
    }
    final ok = await listController.updateServiceStatus(
      currentBooking.value.id,
      'in_progress',
      otp: normalized,
    );
    if (ok) {
      startedAt.value = DateTime.now();
      elapsedSeconds.value = 0;
      _startTimer();
      await _refreshCurrent();
    }
    return ok;
  }

  Map<String, dynamic> buildBillPayload() {
    return {
      'material_cost': materialCost.value,
      'visiting_charge': visitingCharge.value,
      'platform_fee': platformFeeStored.value,
      'service_items': serviceItems
          .map((e) => {
                'name': e.name,
                'price': e.price,
                'quantity': e.quantity,
                'completed': e.completed,
              })
          .toList(),
    };
  }

  Future<bool> requestPayment() async {
    final ok = await listController.updateServiceStatus(
      currentBooking.value.id,
      'awaiting_payment',
      billPayload: buildBillPayload(),
    );
    if (ok) await _refreshCurrent();
    return ok;
  }

  Future<bool> completeJob() async {
    _timer?.cancel();
    final ok = await listController.updateServiceStatus(currentBooking.value.id, 'completed');
    if (ok) await _refreshCurrent();
    return ok;
  }

  Future<void> _refreshCurrent() async {
    await listController.fetchBookings();
    final updated = listController.bookings.firstWhereOrNull((e) => e.id == booking.id);
    if (updated != null) {
      currentBooking.value = updated;
      if (updated.serviceItems.isNotEmpty) {
        _assignServiceItems(updated.serviceItems);
      }
      _distributePrices();
    }
  }

  int get completedServiceCount => serviceItems.where((e) => e.completed).length;

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }
}
