import 'dart:convert';
import 'package:cabme_driver/constant/logdata.dart';
import 'package:cabme_driver/model/food_order_model.dart';
import 'package:cabme_driver/service/api.dart';
import 'package:http/http.dart' as http;

class FoodRiderService {
  static Future<List<FoodOrderData>> getIncomingOrders({
    double? lat,
    double? lng,
    double radiusKm = 15.0,
  }) async {
    try {
      final url = "${API.foodRiderIncoming}?latitude=${lat ?? ''}&longitude=${lng ?? ''}&radius_km=$radiusKm";
      showLog("FoodRiderService :: Incoming URL :: $url");
      final response = await http.get(Uri.parse(url), headers: API.header);
      showLog("FoodRiderService :: Incoming Status :: ${response.statusCode}");
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body['success'] == true) {
          final model = FoodOrderModel.fromJson(body);
          return model.data ?? [];
        }
      }
    } catch (e) {
      showLog("FoodRiderService :: Incoming Error :: $e");
    }
    return [];
  }

  static Future<Map<String, dynamic>?> acceptOrder(
    int orderId, {
    required int riderId,
    required String riderName,
    required String riderPhone,
  }) async {
    try {
      final url = "${API.foodRiderAccept}$orderId/accept";
      final body = {
        "rider_id": riderId,
        "rider_name": riderName,
        "rider_phone": riderPhone,
      };
      showLog("FoodRiderService :: Accept URL :: $url, Body :: $body");
      final response = await http.post(
        Uri.parse(url),
        headers: API.header,
        body: jsonEncode(body),
      );
      showLog("FoodRiderService :: Accept Status :: ${response.statusCode}, Response :: ${response.body}");
      final resBody = json.decode(response.body);
      return resBody;
    } catch (e) {
      showLog("FoodRiderService :: Accept Error :: $e");
      return null;
    }
  }

  static Future<List<FoodOrderData>> getActiveOrders(int riderId) async {
    try {
      final url = "${API.foodRiderActive}?rider_id=$riderId";
      showLog("FoodRiderService :: Active URL :: $url");
      final response = await http.get(Uri.parse(url), headers: API.header);
      showLog("FoodRiderService :: Active Status :: ${response.statusCode}");
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body['success'] == true) {
          final model = FoodOrderModel.fromJson(body);
          return model.data ?? [];
        }
      }
    } catch (e) {
      showLog("FoodRiderService :: Active Error :: $e");
    }
    return [];
  }

  static Future<Map<String, dynamic>?> updateOrderStatus(
    int orderId, {
    required int riderId,
    required String status,
    String? pickupOtp,
    String? deliveryOtp,
  }) async {
    try {
      final url = "${API.foodRiderStatus}$orderId/status";
      final Map<String, dynamic> body = {
        "rider_id": riderId,
        "status": status,
      };
      if (pickupOtp != null && pickupOtp.isNotEmpty) {
        body["pickup_otp"] = pickupOtp;
      }
      if (deliveryOtp != null && deliveryOtp.isNotEmpty) {
        body["delivery_otp"] = deliveryOtp;
      }
      showLog("FoodRiderService :: Update Status URL :: $url, Body :: $body");
      final response = await http.post(
        Uri.parse(url),
        headers: API.header,
        body: jsonEncode(body),
      );
      showLog("FoodRiderService :: Update Status Response :: ${response.body}");
      final resBody = json.decode(response.body);
      return resBody;
    } catch (e) {
      showLog("FoodRiderService :: Update Status Error :: $e");
      return null;
    }
  }
}
