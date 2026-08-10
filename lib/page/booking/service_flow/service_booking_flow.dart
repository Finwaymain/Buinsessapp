import 'package:cabme_driver/controller/my_booking_controller.dart';
import 'package:cabme_driver/controller/service_booking_flow_controller.dart';
import 'package:cabme_driver/model/driver_booking_model.dart';
import 'package:get/get.dart';

import 'service_active_job_screen.dart';
import 'service_booking_details_screen.dart';
import 'service_completion_screen.dart';
import 'service_incoming_request_screen.dart';
import 'service_payment_received_screen.dart';
import 'service_reached_location_screen.dart';

String serviceFlowTagFor(String bookingId) => 'service_flow_$bookingId';

ServiceBookingFlowController serviceFlowFor(String tag) {
  if (Get.isRegistered<ServiceBookingFlowController>(tag: tag)) {
    return Get.find<ServiceBookingFlowController>(tag: tag);
  }

  final bookingId = tag.replaceFirst('service_flow_', '');
  if (Get.isRegistered<MyBookingController>()) {
    final listController = Get.find<MyBookingController>();
    final item = listController.bookings.firstWhereOrNull((e) => e.id == bookingId);
    if (item != null) {
      return Get.put(
        ServiceBookingFlowController(booking: item, listController: listController),
        tag: tag,
        permanent: true,
      );
    }
  }

  throw Exception('Service booking flow not found for $tag. Please reopen the booking.');
}

void openServiceBookingFlow(DriverBookingItem item, MyBookingController listController) {
  final tag = serviceFlowTagFor(item.id);
  if (Get.isRegistered<ServiceBookingFlowController>(tag: tag)) {
    Get.delete<ServiceBookingFlowController>(tag: tag, force: true);
  }

  Get.put(
    ServiceBookingFlowController(booking: item, listController: listController),
    tag: tag,
    permanent: true,
  );

  if (item.isIncoming) {
    Get.to(() => ServiceIncomingRequestScreen(tag: tag));
    return;
  }
  if (item.isAccepted) {
    Get.to(() => ServiceBookingDetailsScreen(tag: tag));
    return;
  }
  if (item.isInProgress) {
    Get.to(() => ServiceActiveJobScreen(tag: tag));
    return;
  }
  if (item.isAwaitingPayment) {
    Get.to(() => ServiceCompletionScreen(tag: tag));
    return;
  }
  if (item.isCompleted) {
    Get.to(() => ServiceCompletionScreen(tag: tag));
    return;
  }
  Get.to(() => ServiceBookingDetailsScreen(tag: tag));
}

void resumeServiceFlowAfterAccept(String tag) {
  Get.off(() => ServiceBookingDetailsScreen(tag: tag));
}

void resumeServiceFlowAfterStart(String tag) {
  serviceFlowFor(tag);
  Get.back();
  Get.off(() => ServiceActiveJobScreen(tag: tag));
}

void resumeServiceFlowAfterComplete(String tag) {
  serviceFlowFor(tag);
  Get.off(() => ServiceCompletionScreen(tag: tag));
}
