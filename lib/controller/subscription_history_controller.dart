import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:cabme_driver/constant/constant.dart';
import 'package:cabme_driver/constant/show_toast_dialog.dart';
import 'package:cabme_driver/model/subscription_history_model.dart';
import 'package:cabme_driver/model/user_model.dart';
import 'package:cabme_driver/service/api.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class SubscriptionHistoryController extends GetxController {
  RxBool isLoading = true.obs;
  RxList<SubscriptionData> subscriptionHistoryList = <SubscriptionData>[].obs;
  Rx<UserModel> userModel = UserModel().obs;

  @override
  void onInit() {
    userModel.value = Constant.getUserData();
    getAllSubscriptionList();
    super.onInit();
  }

  Future<Null> getAllSubscriptionList() async {
    try {
      Map<String, String> bodyParams = {
        "driverId": userModel.value.userData!.id.toString(),
      };
      final response = await http.post(Uri.parse(API.getSubscriptionHistory), headers: API.header, body: jsonEncode(bodyParams));
      Map<String, dynamic> responseBody = json.decode(response.body);
      if (response.statusCode == 200 && responseBody['success'] == "success") {
        isLoading.value = false;
        SubscriptionHistoryModel model = SubscriptionHistoryModel.fromJson(responseBody);
        subscriptionHistoryList.value = model.data!;
        log("subscriptionHistoryList :: $responseBody");
        ShowToastDialog.closeLoader();
      } else {
        ShowToastDialog.closeLoader();
        isLoading.value = false;
      }
    } on TimeoutException catch (e) {
      isLoading.value = false;
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.message.toString());
    } on SocketException catch (e) {
      isLoading.value = false;
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.message.toString());
    } on Error catch (e) {
      isLoading.value = false;
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.toString());
    } catch (e) {
      isLoading.value = false;
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.toString());
    }
    return null;
  }
}
