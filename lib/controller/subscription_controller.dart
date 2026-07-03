import 'dart:async';
import 'dart:math';

import 'package:cabme_driver/constant/constant.dart';
import 'package:cabme_driver/constant/logdata.dart';
import 'package:cabme_driver/constant/show_toast_dialog.dart';
import 'package:cabme_driver/controller/dash_board_controller.dart';
import 'package:cabme_driver/controller/payStackURLModel.dart';
import 'package:cabme_driver/model/payment_setting_model.dart';
import 'package:cabme_driver/model/razorpay_gen_userid_model.dart';
import 'package:cabme_driver/model/subscription_plan_model.dart';
import 'package:cabme_driver/model/trancation_model.dart';
import 'package:cabme_driver/model/user_model.dart';
import 'package:cabme_driver/service/api.dart';
import 'package:cabme_driver/utils/Preferences.dart';
import 'package:get/get.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_stripe/flutter_stripe.dart';

import '../page/MainDashBoard/screen/main_dashboard.dart';

class SubscriptionController extends GetxController {
  RxList<SubscriptionPlanData> subscriptionPlanList = <SubscriptionPlanData>[].obs;
  Rx<SubscriptionPlanData> selectedSubscriptionPlan = SubscriptionPlanData().obs;
  RxBool isLoading = true.obs;
  RxDouble totalAmount = 0.0.obs;
  Rx<UserModel> userModel = UserModel().obs;

  RxString selectedRadioTile = ''.obs;
  var paymentSettingModel = PaymentSettingModel().obs;

  RxBool wallet = false.obs;
  RxBool stripe = false.obs;
  RxBool razorPay = false.obs;
  RxBool paypal = false.obs;
  RxBool payStack = false.obs;
  RxBool flutterWave = false.obs;
  RxBool mercadoPago = false.obs;
  RxBool payFast = false.obs;
  RxBool xendit = false.obs;
  RxBool orangePay = false.obs;
  RxBool midtrans = false.obs;
  RxBool isSplashScreen = false.obs;

  @override
  void onInit() {
    getInitData();
    super.onInit();
  }

  RxString ref = ''.obs;
  Future<void> getInitData() async {
    await getUsrData();
    await getPaymentSettingData();
    await getSubscription();
    setFlutterwaveRef();
    if (paymentSettingModel.value.strip?.isEnabled == 'true') {
      Stripe.publishableKey = paymentSettingModel.value.strip!.key!;
      Stripe.merchantIdentifier = "Cabme";
      await Stripe.instance.applySettings();
    }
  }

  void setFlutterwaveRef() {
    Random numRef = Random();
    int year = DateTime.now().year;
    int refNumber = numRef.nextInt(20000);
    if (Platform.isAndroid) {
      ref.value = "AndroidRef$year$refNumber";
    } else if (Platform.isIOS) {
      ref.value = "IOSRef$year$refNumber";
    }
  }

  RxString totalEarn = '0.0'.obs;
  Future<void> getUsrData() async {
    userModel.value = Constant.getUserData();
    final response = await http.get(Uri.parse("${API.walletHistory}?id_diver=${Preferences.getInt(Preferences.userId)}"), headers: API.header);
    showLog("API :: URL :: ${API.walletHistory}?id_diver=${Preferences.getInt(Preferences.userId)}");
    showLog("API :: Request Header :: ${API.header.toString()} ");
    showLog("API :: responseStatus :: ${response.statusCode} ");
    showLog("API :: responseBody :: ${response.body} ");
    Map<String, dynamic> responseBody = json.decode(response.body);
    if (response.statusCode == 200 && responseBody['success'] == "success") {
      TruncationModel model = TruncationModel.fromJson(responseBody);
      totalEarn.value = model.totalEarnings!.toString();
      showLog("totalEarn.value :: ${totalEarn.value} ");
    } else if (response.statusCode == 200 && responseBody['success'] == "Failed") {
    } else {}
  }

  Future<dynamic> getPaymentSettingData() async {
    try {
      final response = await http.get(Uri.parse(API.paymentSetting), headers: API.header);
      showLog("API :: URL :: ${API.paymentSetting} ");
      showLog("API :: Request Header :: ${API.header.toString()} ");
      showLog("API :: responseStatus :: ${response.statusCode} ");
      showLog("API :: responseBody :: ${response.body} ");
      Map<String, dynamic> responseBody = json.decode(response.body);
      if (response.statusCode == 200 && responseBody['success'] == "success") {
        await Preferences.setString(Preferences.paymentSetting, jsonEncode(responseBody));
        paymentSettingModel.value = Constant.getPaymentSetting();
      } else if (response.statusCode == 200 && responseBody['success'] == "Failed") {
      } else {}
    } on TimeoutException catch (e) {
      ShowToastDialog.showToast(e.message.toString());
    } on SocketException catch (e) {
      ShowToastDialog.showToast(e.message.toString());
    } on Error catch (e) {
      ShowToastDialog.showToast(e.toString());
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.toString());
    }
    return null;
  }

  Future<bool> completeSubscription() async {
    try {
      ShowToastDialog.showLoader("Please wait");
      Map<String, String> bodyParams = {
        "planId": selectedSubscriptionPlan.value.id.toString(),
        "driverId": userModel.value.userData!.id.toString(),
        "paymentType": selectedRadioTile.value
      };
      final response = await http.post(Uri.parse(API.setSubscription), headers: API.header, body: jsonEncode(bodyParams));
      showLog("API :: URL :: ${API.setSubscription} ");
      showLog("API :: Request Body :: ${jsonEncode(bodyParams)} ");
      showLog("API :: responseStatus :: ${response.statusCode} ");
      showLog("API :: responseBody :: ${response.body} ");

      Map<String, dynamic> responseBody = json.decode(response.body);
      if (response.statusCode == 200 && responseBody['success'] == "success") {
        userModel.value.userData?.subscriptionPlan = selectedSubscriptionPlan.value;
        userModel.value.userData?.subscriptionPlanId = selectedSubscriptionPlan.value.id;
        await Preferences.setString(Preferences.user, jsonEncode(userModel.value));
        dynamic argumentData = Get.arguments;
        if (argumentData != null || isSplashScreen.value == true) {
          isSplashScreen.value = false;
          ShowToastDialog.closeLoader();
          ShowToastDialog.showToast(responseBody['message']);
          Get.offAll(MainDashboard());
        } else {
          DashBoardController dashcontroller = Get.put(DashBoardController());
          await dashcontroller.getUsrData();
          ShowToastDialog.closeLoader();
          ShowToastDialog.showToast(responseBody['message']);
          Get.offAll(MainDashboard());
        }
        return true;
      } else if (response.statusCode == 200 && responseBody['success'] == "Failed") {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast(responseBody['error']);
      } else {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast(responseBody['error'] ?? 'Something went wrong. Please try again later');
        throw Exception('Failed to load album');
      }
    } on TimeoutException catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.message.toString());
    } on SocketException catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.message.toString());
    } on Error catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.toString());
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.toString());
    }
    return false;
  }

  Future<dynamic> getSubscription() async {
    try {
      print("getSubscription: URL = ${API.getSubscriptionPlans}");
      print("getSubscription: Headers = ${API.header}");
      final response = await http.get(Uri.parse(API.getSubscriptionPlans), headers: API.header);
      print("getSubscription: Status Code = ${response.statusCode}");
      print("getSubscription: Response Body = ${response.body}");
      Map<String, dynamic> responseBody = json.decode(response.body);
      if (response.statusCode == 200 && responseBody['success'] == "success") {
        isLoading.value = false;
        SubscriptionPlanModel model = SubscriptionPlanModel.fromJson(responseBody);
        if (model.data?.isNotEmpty == true) {
          List<SubscriptionPlanData> subscriptionPlanData = model.data!;
          subscriptionPlanData.sort((a, b) {
            final aPlace = int.tryParse(a.place ?? '') ?? 0;
            final bPlace = int.tryParse(b.place ?? '') ?? 0;
            return aPlace.compareTo(bPlace);
          });
          
          subscriptionPlanList.clear();

          if (Constant.subscriptionModel == true && Constant.adminCommission?.statut == 'no') {
            for (var subscriptionPlan in subscriptionPlanData) {
              if (subscriptionPlan.name != 'Commission Base Plan') {
                subscriptionPlanList.add(subscriptionPlan);
              }
            }
          } else if (Constant.subscriptionModel == false && Constant.adminCommission?.statut == 'yes') {
            for (var subscriptionPlan in subscriptionPlanData) {
              if (subscriptionPlan.name == 'Commission Base Plan') {
                subscriptionPlanList.add(subscriptionPlan);
              }
            }
          } else {
            subscriptionPlanList.addAll(subscriptionPlanData);
          }

          if (userModel.value.userData?.subscriptionPlanId != null && userModel.value.userData?.id != null) {
            for (int i = 0; i < subscriptionPlanList.length; i++) {
              if (subscriptionPlanList[i].id == userModel.value.userData!.subscriptionPlanId) {
                selectedSubscriptionPlan.value = subscriptionPlanList[i];
              }
            }
          } else {
            selectedSubscriptionPlan.value = model.data!.first;
          }
        }
        ShowToastDialog.closeLoader();
      } else {
        print("getSubscription: failed on status or success field. success = ${responseBody['success']}");
        ShowToastDialog.closeLoader();
        isLoading.value = false;
      }
    } on TimeoutException catch (e) {
      print("getSubscription TimeoutException: $e");
      isLoading.value = false;
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.message.toString());
    } on SocketException catch (e) {
      print("getSubscription SocketException: $e");
      isLoading.value = false;
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.message.toString());
    } on Error catch (e) {
      print("getSubscription Error: $e");
      isLoading.value = false;
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.toString());
    } catch (e) {
      print("getSubscription Exception: $e");
      isLoading.value = false;
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.toString());
    }
    return null;
  }

  ///payStack
  Future<dynamic> payStackURLGen({required String amount, required secretKey}) async {
    const url = "https://api.paystack.co/transaction/initialize";

    try {
      final response = await http.post(Uri.parse(url), body: {
        "email": "demo@email.com",
        "amount": (double.parse(amount) * 100).toString(),
        "currency": "NGN",
      }, headers: {
        "Authorization": "Bearer $secretKey",
      });

      final responseBody = json.decode(response.body);
      if (response.statusCode == 200 && responseBody['status'] == true) {
        return PayStackUrlModel.fromJson(responseBody);
      } else if (response.statusCode == 200 && responseBody['status'] == null) {
        ShowToastDialog.showToast(responseBody['error'] ?? 'Something went wrong. Please try again later');
      } else {
        ShowToastDialog.showToast(responseBody['error'] ?? 'Something went wrong. Please try again later');
      }
    } on TimeoutException catch (e) {
      ShowToastDialog.showToast(e.message.toString());
    } on SocketException catch (e) {
      ShowToastDialog.showToast(e.message.toString());
    } on Error catch (e) {
      ShowToastDialog.showToast(e.toString());
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.toString());
    }
  }

  ///Stripe
  Future<dynamic> createStripeIntent({required String amount}) async {
    try {
      Map<String, dynamic> body = {
        'amount': ((double.parse(amount) * 100).round()).toString(),
        'currency': "USD",
        'payment_method_types[]': 'card',
        "description": "${Preferences.getInt(Preferences.userId)} Wallet Topup",
        "shipping[name]": "${Preferences.getInt(Preferences.userId)} ${Preferences.getInt(Preferences.userId)}",
        "shipping[address][line1]": "510 Townsend St",
        "shipping[address][postal_code]": "98140",
        "shipping[address][city]": "San Francisco",
        "shipping[address][state]": "CA",
        "shipping[address][country]": "US",
      };
      var stripeSecret = paymentSettingModel.value.strip!.secretKey;

      var response = await http.post(Uri.parse('https://api.stripe.com/v1/payment_intents'),
          body: body, headers: {'Authorization': 'Bearer $stripeSecret', 'Content-Type': 'application/x-www-form-urlencoded'});
      showLog("API :: URL :: https://api.stripe.com/v1/payment_intents");
      showLog("API :: Request Body :: ${jsonEncode(body)} ");
      showLog("API :: Request Header :: ${{'Authorization': 'Bearer $stripeSecret', 'Content-Type': 'application/x-www-form-urlencoded'}.toString()} ");
      showLog("API :: responseStatus :: ${response.statusCode} ");
      showLog("API :: responseBody :: ${response.body} ");
      return jsonDecode(response.body);
    } catch (e) {
      print("=====$e");
    }
  }

  ///razorPay
  Future<CreateRazorPayOrderModel?> createOrderRazorPay({required int amount, bool isTopup = false}) async {
    final String orderId = "${Preferences.getInt(Preferences.userId)}_${DateTime.now().microsecondsSinceEpoch}";

    const url = "${API.baseUrl}payments/razorpay/createorder";

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'apikey': API.apiKey,
          'accesstoken': Preferences.getString(Preferences.accesstoken),
        },
        body: {
          "amount": (amount * 100).toString(),
          "receipt_id": orderId,
          "currency": "INR",
          "razorpaykey": paymentSettingModel.value.razorpay!.key,
          "razorPaySecret": paymentSettingModel.value.razorpay!.secretKey,
          "isSandBoxEnabled": paymentSettingModel.value.razorpay!.isSandboxEnabled,
        },
      );
      showLog("API :: URL :: $url");
      showLog("API :: Request Body :: ${jsonEncode({
            "amount": (amount * 100).toString(),
            "receipt_id": orderId,
            "currency": "INR",
            "razorpaykey": paymentSettingModel.value.razorpay!.key,
            "razorPaySecret": paymentSettingModel.value.razorpay!.secretKey,
            "isSandBoxEnabled": paymentSettingModel.value.razorpay!.isSandboxEnabled,
          })} ");
      showLog("API :: Request Header :: ${{
        'apikey': API.apiKey,
        'accesstoken': Preferences.getString(Preferences.accesstoken),
      }.toString()} ");
      showLog("API :: responseStatus :: ${response.statusCode} ");
      showLog("API :: responseBody :: ${response.body} ");
      final responseBody = json.decode(response.body);

      if (response.statusCode == 200 && responseBody['id'] != null) {
        return CreateRazorPayOrderModel.fromJson(responseBody);
      } else if (response.statusCode == 200 && responseBody['id'] == null) {
        ShowToastDialog.showToast(responseBody['error'] ?? 'Something went wrong. Please try again later');
      } else {
        ShowToastDialog.showToast(responseBody['error'] ?? 'Something went wrong. Please try again later');
        throw Exception('Failed to load album');
      }
    } on TimeoutException catch (e) {
      ShowToastDialog.showToast(e.message.toString());
    } on SocketException catch (e) {
      ShowToastDialog.showToast(e.message.toString());
    } on Error catch (e) {
      ShowToastDialog.showToast(e.toString());
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.toString());
    }
    return null;
  }
}
