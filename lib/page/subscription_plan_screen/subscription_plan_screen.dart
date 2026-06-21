// ignore_for_file: must_be_immutable

import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:cabme_driver/constant/constant.dart';
import 'package:cabme_driver/constant/logdata.dart';
import 'package:cabme_driver/constant/show_toast_dialog.dart';
import 'package:cabme_driver/controller/payStackURLModel.dart';
import 'package:cabme_driver/controller/subscription_controller.dart';
import 'package:cabme_driver/model/payment_setting_model.dart';
import 'package:cabme_driver/model/razorpay_gen_userid_model.dart';
import 'package:cabme_driver/model/stripe_failed_model.dart';
import 'package:cabme_driver/model/subscription_plan_model.dart';
import 'package:cabme_driver/model/user_model.dart';
import 'package:cabme_driver/model/xenditModel.dart';
import 'package:cabme_driver/page/wallet/mercadopago_screen.dart';
import 'package:cabme_driver/page/wallet/midtrans_screen.dart';
import 'package:cabme_driver/page/wallet/orangePayScreen.dart';
import 'package:cabme_driver/page/wallet/payStackScreen.dart';
import 'package:cabme_driver/page/wallet/payfast_screen.dart';
import 'package:cabme_driver/page/wallet/paystack_url_generator.dart';
import 'package:cabme_driver/page/wallet/xenditScreen.dart';
import 'package:cabme_driver/service/api.dart';
import 'package:cabme_driver/themes/app_bar_custom.dart';
import 'package:cabme_driver/themes/constant_colors.dart';
import 'package:cabme_driver/themes/radio_button.dart';
import 'package:cabme_driver/themes/responsive.dart';
import 'package:cabme_driver/utils/dark_theme_provider.dart';
import 'package:cabme_driver/utils/network_image_widget.dart';
import 'package:cabme_driver/widget/round_button_fill.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_paypal/flutter_paypal.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'dart:math' as maths;
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe1;
import 'package:http/http.dart' as http;

import '../../controller/wallet_controller.dart';

class SubscriptionPlanScreen extends StatelessWidget {
  final bool isbackButton;
  final bool? isSplashScreen;
  SubscriptionPlanScreen({super.key, required this.isbackButton, this.isSplashScreen});

  SubscriptionController controller = Get.put(SubscriptionController());
  Razorpay razorPayController = Razorpay();
  final walletController = Get.put(WalletController());
  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return GetX(
        init: SubscriptionController(),
        builder: (controller) {
          return WillPopScope(
            onWillPop: () async {
              return isbackButton;
            },
            child: Scaffold(
              appBar: AppbarCustom(
                isLeadingIcon: isbackButton == true ? false : true,
                title: '',
                elevation: 0,
                leading: SizedBox(),
              ),
              backgroundColor: themeChange.getThem() ? AppThemeData.surface50Dark : AppThemeData.surface50,
              body: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const SizedBox(
                        height: 10,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Choose Your Business Plan".tr,
                              style: TextStyle(
                                color: themeChange.getThem() ? AppThemeData.grey50 : AppThemeData.grey900,
                                fontSize: 24,
                                fontFamily: AppThemeData.semiBold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Select the most suitable business plan for your business to maximize your potential and access exclusive features.".tr,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: themeChange.getThem() ? AppThemeData.grey400 : AppThemeData.grey500,
                                fontSize: 16,
                                fontFamily: AppThemeData.regular,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 24,
                      ),
                      controller.isLoading.value
                          ? Constant.loader(context, isDarkMode: themeChange.getThem())
                          : controller.subscriptionPlanList.isEmpty
                              ? SizedBox(
                                  width: Responsive.width(100, context), height: Responsive.height(50, context), child: Constant.emptyView("Subscription plan not found.".tr))
                              : ListView.builder(
                                  physics: const NeverScrollableScrollPhysics(),
                                  shrinkWrap: true,
                                  primary: false,
                                  itemCount: controller.subscriptionPlanList.length,
                                  itemBuilder: (context, index) {
                                    final subscriptionPlanModel = controller.subscriptionPlanList[index];
                                    return SubscriptionPlanWidget(
                                      onContainClick: () {
                                        log("subscriptionPlanModel.price :: ${subscriptionPlanModel.price}");
                                        controller.selectedSubscriptionPlan.value = subscriptionPlanModel;
                                        controller.totalAmount.value = double.parse(subscriptionPlanModel.price ?? '0.0');
                                        controller.update();
                                      },
                                      onClick: () async {
                                        controller.isSplashScreen.value = isSplashScreen ?? false;
                                        controller.selectedSubscriptionPlan.value = subscriptionPlanModel;
                                        controller.totalAmount.value = double.parse(subscriptionPlanModel.price ?? '0.0');

                                        if (controller.selectedSubscriptionPlan.value.id == subscriptionPlanModel.id) {
                                          if (controller.selectedSubscriptionPlan.value.type == 'free' ||
                                              controller.selectedSubscriptionPlan.value.id == Constant.commissionSubscriptionID) {
                                            controller.selectedRadioTile.value = 'free';
                                            await controller.completeSubscription();
                                            controller.update();
                                          } else {
                                            paymentDialog(context, controller, themeChange.getThem());
                                          }
                                        }
                                      },
                                      type: 'Plan',
                                      subscriptionPlanModel: subscriptionPlanModel,
                                    );
                                  }),
                      const SizedBox(
                        height: 10,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        });
  }

  Future<dynamic> paymentDialog(BuildContext context, SubscriptionController controller, bool isDarkMode) {
    return showModalBottomSheet(
        elevation: 5,
        useRootNavigator: true,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(topLeft: Radius.circular(15), topRight: Radius.circular(15))),
        context: context,
        backgroundColor: isDarkMode == true ? AppThemeData.surface50Dark : AppThemeData.surface50,
        builder: (context) {
          return GetX<SubscriptionController>(
              init: SubscriptionController(),
              initState: (controller) {
                razorPayController.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
                razorPayController.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWaller);
                razorPayController.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
              },
              builder: (controller) {
                return SizedBox(
                  height: Get.height / 1.15,
                  child: SingleChildScrollView(
                    child: InkWell(
                      onTap: () {
                        FocusScope.of(context).unfocus();
                      },
                      child: Column(
                        children: [
                          Center(
                            child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 10),
                                height: 8,
                                width: 75,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(100),
                                  color: isDarkMode ? AppThemeData.grey300Dark : AppThemeData.grey300,
                                )),
                          ),
                          Row(
                            children: [
                              IconButton(
                                  onPressed: () {
                                    Get.back();
                                  },
                                  icon: Transform(
                                    alignment: Alignment.center,
                                    transform: Directionality.of(context) == TextDirection.rtl ? Matrix4.rotationY(3.14159) : Matrix4.identity(),
                                    child: SvgPicture.asset(
                                      'assets/icons/ic_left.svg',
                                      colorFilter: ColorFilter.mode(
                                        isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900,
                                        BlendMode.srcIn,
                                      ),
                                    ),
                                  )),
                            ],
                          ),
                          Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 15.0,
                                ),
                                child: RichText(
                                  text: TextSpan(
                                    text: "Select Payment Option".tr,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900,
                                      fontFamily: AppThemeData.medium,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: isDarkMode ? AppThemeData.grey300Dark : AppThemeData.grey300,
                                ),
                                color: isDarkMode ? AppThemeData.surface50Dark : AppThemeData.surface50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(children: [
                                RadioButtonCustom(
                                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
                                  image: "assets/icons/walltet_icons.png",
                                  name: 'Wallet',
                                  subtitle: '${"Your Balance : "}${Constant().amountShow(amount: controller.totalEarn.value)}',
                                  groupValue: controller.selectedRadioTile.value,
                                  isEnabled: controller.paymentSettingModel.value.myWallet!.isEnabled == "true" ? true : false,
                                  isSelected: controller.wallet.value,
                                  onClick: (String? value) {
                                    controller.wallet = true.obs;
                                    controller.stripe = false.obs;
                                    controller.razorPay = false.obs;
                                    controller.paypal = false.obs;
                                    controller.payStack = false.obs;
                                    controller.flutterWave = false.obs;
                                    controller.mercadoPago = false.obs;
                                    controller.payFast = false.obs;
                                    controller.xendit = false.obs;
                                    controller.midtrans = false.obs;
                                    controller.orangePay = false.obs;
                                    controller.selectedRadioTile.value = 'Wallet';
                                  },
                                ),
                                RadioButtonCustom(
                                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
                                  image: "assets/images/stripe.png",
                                  name: 'Stripe',
                                  groupValue: controller.selectedRadioTile.value,
                                  isEnabled: controller.paymentSettingModel.value.strip!.isEnabled == "true" ? true : false,
                                  isSelected: controller.stripe.value,
                                  onClick: (String? value) {
                                    controller.stripe = true.obs;
                                    controller.wallet = false.obs;
                                    controller.razorPay = false.obs;
                                    controller.paypal = false.obs;
                                    controller.payStack = false.obs;
                                    controller.flutterWave = false.obs;
                                    controller.mercadoPago = false.obs;
                                    controller.payFast = false.obs;
                                    controller.xendit = false.obs;
                                    controller.midtrans = false.obs;
                                    controller.orangePay = false.obs;
                                    controller.selectedRadioTile.value = value!;
                                  },
                                ),
                                RadioButtonCustom(
                                  isEnabled: controller.paymentSettingModel.value.payStack!.isEnabled == "true" ? true : false,
                                  name: 'PayStack',
                                  image: "assets/images/paystack.png",
                                  isSelected: controller.payStack.value,
                                  groupValue: controller.selectedRadioTile.value,
                                  onClick: (String? value) {
                                    controller.stripe = false.obs;
                                    controller.wallet = false.obs;
                                    controller.razorPay = false.obs;
                                    controller.paypal = false.obs;
                                    controller.payStack = true.obs;
                                    controller.flutterWave = false.obs;
                                    controller.mercadoPago = false.obs;
                                    controller.payFast = false.obs;
                                    controller.xendit = false.obs;
                                    controller.midtrans = false.obs;
                                    controller.orangePay = false.obs;
                                    controller.selectedRadioTile.value = value!;
                                  },
                                ),
                                RadioButtonCustom(
                                  isEnabled: controller.paymentSettingModel.value.flutterWave!.isEnabled == "true" ? true : false,
                                  name: 'FlutterWave',
                                  image: "assets/images/flutterwave.png",
                                  isSelected: controller.flutterWave.value,
                                  groupValue: controller.selectedRadioTile.value,
                                  onClick: (String? value) {
                                    controller.stripe = false.obs;
                                    controller.wallet = false.obs;
                                    controller.razorPay = false.obs;
                                    controller.paypal = false.obs;
                                    controller.payStack = false.obs;
                                    controller.flutterWave = true.obs;
                                    controller.mercadoPago = false.obs;
                                    controller.payFast = false.obs;
                                    controller.xendit = false.obs;
                                    controller.midtrans = false.obs;
                                    controller.orangePay = false.obs;
                                    controller.selectedRadioTile.value = value!;
                                  },
                                ),
                                RadioButtonCustom(
                                  isEnabled: controller.paymentSettingModel.value.razorpay!.isEnabled == "true" ? true : false,
                                  name: 'RazorPay',
                                  image: "assets/images/razorpay_@3x.png",
                                  isSelected: controller.razorPay.value,
                                  groupValue: controller.selectedRadioTile.value,
                                  onClick: (String? value) {
                                    controller.stripe = false.obs;
                                    controller.wallet = false.obs;
                                    controller.razorPay = true.obs;
                                    controller.paypal = false.obs;
                                    controller.payStack = false.obs;
                                    controller.flutterWave = false.obs;
                                    controller.mercadoPago = false.obs;
                                    controller.payFast = false.obs;
                                    controller.xendit = false.obs;
                                    controller.midtrans = false.obs;
                                    controller.orangePay = false.obs;
                                    controller.selectedRadioTile.value = value!;
                                  },
                                ),
                                RadioButtonCustom(
                                  isEnabled: controller.paymentSettingModel.value.payFast!.isEnabled == "true" ? true : false,
                                  name: 'PayFast',
                                  image: "assets/images/payfast.png",
                                  isSelected: controller.payFast.value,
                                  groupValue: controller.selectedRadioTile.value,
                                  onClick: (String? value) {
                                    controller.stripe = false.obs;
                                    controller.wallet = false.obs;
                                    controller.razorPay = false.obs;
                                    controller.paypal = false.obs;
                                    controller.payStack = false.obs;
                                    controller.flutterWave = false.obs;
                                    controller.mercadoPago = false.obs;
                                    controller.payFast = true.obs;
                                    controller.xendit = false.obs;
                                    controller.midtrans = false.obs;
                                    controller.orangePay = false.obs;
                                    controller.selectedRadioTile.value = value!;
                                  },
                                ),
                                RadioButtonCustom(
                                  isEnabled: controller.paymentSettingModel.value.mercadopago!.isEnabled == "true" ? true : false,
                                  name: 'MercadoPago',
                                  image: "assets/images/mercadopago.png",
                                  isSelected: controller.mercadoPago.value,
                                  groupValue: controller.selectedRadioTile.value,
                                  onClick: (String? value) {
                                    controller.stripe = false.obs;
                                    controller.wallet = false.obs;
                                    controller.razorPay = false.obs;
                                    controller.paypal = false.obs;
                                    controller.payStack = false.obs;
                                    controller.flutterWave = false.obs;
                                    controller.mercadoPago = true.obs;
                                    controller.payFast = false.obs;
                                    controller.xendit = false.obs;
                                    controller.midtrans = false.obs;
                                    controller.orangePay = false.obs;
                                    controller.selectedRadioTile.value = value!;
                                  },
                                ),
                                RadioButtonCustom(
                                  isEnabled: controller.paymentSettingModel.value.payPal!.isEnabled == "true" ? true : false,
                                  name: 'PayPal',
                                  image: "assets/images/paypal_@3x.png",
                                  isSelected: controller.paypal.value,
                                  groupValue: controller.selectedRadioTile.value,
                                  onClick: (String? value) {
                                    controller.stripe = false.obs;
                                    controller.wallet = false.obs;
                                    controller.razorPay = false.obs;
                                    controller.paypal = true.obs;
                                    controller.payStack = false.obs;
                                    controller.flutterWave = false.obs;
                                    controller.mercadoPago = false.obs;
                                    controller.payFast = false.obs;
                                    controller.xendit = false.obs;
                                    controller.midtrans = false.obs;
                                    controller.orangePay = false.obs;
                                    controller.selectedRadioTile.value = value!;
                                  },
                                ),
                                RadioButtonCustom(
                                  isEnabled: controller.paymentSettingModel.value.xendit!.isEnabled == "true" ? true : false,
                                  name: 'Xendit',
                                  image: "assets/images/xendit.png",
                                  isSelected: controller.xendit.value,
                                  groupValue: controller.selectedRadioTile.value,
                                  onClick: (String? value) {
                                    controller.stripe = false.obs;
                                    controller.wallet = false.obs;
                                    controller.razorPay = false.obs;
                                    controller.paypal = false.obs;
                                    controller.payStack = false.obs;
                                    controller.flutterWave = false.obs;
                                    controller.mercadoPago = false.obs;
                                    controller.payFast = false.obs;
                                    controller.xendit = true.obs;
                                    controller.midtrans = false.obs;
                                    controller.orangePay = false.obs;
                                    controller.selectedRadioTile.value = value!;
                                  },
                                ),
                                RadioButtonCustom(
                                  isEnabled: controller.paymentSettingModel.value.orangePay!.isEnabled == "true" ? true : false,
                                  name: 'Orange Pay',
                                  image: "assets/images/orangeMoney.png",
                                  isSelected: controller.orangePay.value,
                                  groupValue: controller.selectedRadioTile.value,
                                  onClick: (String? value) {
                                    controller.stripe = false.obs;
                                    controller.wallet = false.obs;
                                    controller.razorPay = false.obs;
                                    controller.paypal = false.obs;
                                    controller.payStack = false.obs;
                                    controller.flutterWave = false.obs;
                                    controller.mercadoPago = false.obs;
                                    controller.payFast = false.obs;
                                    controller.xendit = false.obs;
                                    controller.midtrans = false.obs;
                                    controller.orangePay = true.obs;
                                    controller.selectedRadioTile.value = value!;
                                  },
                                ),
                                RadioButtonCustom(
                                  borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(8), bottomRight: Radius.circular(8)),
                                  isBottomborderRemove: true,
                                  isEnabled: controller.paymentSettingModel.value.midtrans!.isEnabled == "true" ? true : false,
                                  name: 'Midtrans',
                                  image: "assets/images/midtrans.png",
                                  isSelected: controller.midtrans.value,
                                  groupValue: controller.selectedRadioTile.value,
                                  onClick: (String? value) {
                                    controller.stripe = false.obs;
                                    controller.wallet = false.obs;
                                    controller.razorPay = false.obs;
                                    controller.paypal = false.obs;
                                    controller.payStack = false.obs;
                                    controller.flutterWave = false.obs;
                                    controller.mercadoPago = false.obs;
                                    controller.payFast = false.obs;
                                    controller.xendit = false.obs;
                                    controller.midtrans = true.obs;
                                    controller.orangePay = false.obs;
                                    controller.selectedRadioTile.value = value!;
                                  },
                                ),
                              ]),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 15),
                            child: GestureDetector(
                              onTap: () async {
                                if (controller.selectedRadioTile.value == '') {
                                  ShowToastDialog.showToast("Please select payment method".tr);
                                  return;
                                } else {
                                  // Get.back();
                                  log("controller.selectedRadioTile.value :: ${controller.selectedRadioTile.value}");

                                  if (controller.selectedRadioTile.value == "Wallet") {
                                    if (double.parse(controller.totalEarn.value) >= controller.totalAmount.value) {
                                      await controller.completeSubscription();
                                    } else {
                                      ShowToastDialog.showToast("Insufficient wallet balance");
                                    }
                                  } else if (controller.selectedRadioTile.value == "Stripe") {
                                    stripe1.Stripe.publishableKey = controller.paymentSettingModel.value.strip?.key ?? '';
                                    stripe1.Stripe.merchantIdentifier = 'Cabme';
                                    await stripe1.Stripe.instance.applySettings();
                                    stripeMakePayment(amount: controller.totalAmount.value.toString());
                                  } else if (controller.selectedRadioTile.value == "RazorPay") {
                                    startRazorpayPayment();
                                  } else if (controller.selectedRadioTile.value == "PayPal") {
                                    paypalPaymentSheet(controller.totalAmount.value.toString(), context);
                                    // _paypalPayment();
                                  } else if (controller.selectedRadioTile.value == "PayStack") {
                                    payStackPayment(context);
                                  } else if (controller.selectedRadioTile.value == "FlutterWave") {
                                    flutterWaveInitiatePayment(context: context, amount: controller.totalAmount.value.toString(), user: controller.userModel.value);
                                  } else if (controller.selectedRadioTile.value == "PayFast") {
                                    payFastPayment(context);
                                  } else if (controller.selectedRadioTile.value == "MercadoPago") {
                                    mercadoPagoMakePayment(
                                      context: context,
                                      amount: controller.totalAmount.value.toString(),
                                      user: controller.userModel.value,
                                    );
                                  } else if (controller.selectedRadioTile.value == "Xendit") {
                                    xenditPayment(context, double.parse(controller.totalAmount.value.toString()));
                                  } else if (controller.selectedRadioTile.value == "Orange Pay") {
                                    orangeMakePayment(amount: controller.totalAmount.value.toString().toString(), context: context);
                                  } else if (controller.selectedRadioTile.value == "Midtrans") {
                                    midtransMakePayment(amount: controller.totalAmount.value.toString().toString(), context: context);
                                  } else {
                                    log("controller.selectedRadioTile.value :: 11 :: ${controller.selectedRadioTile.value}");
                                    ShowToastDialog.showToast("Please select payment method");
                                  }
                                }
                              },
                              child: Container(
                                height: 50,
                                decoration: BoxDecoration(
                                  color: AppThemeData.primary200,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                    child: Text(
                                  "CONTINUE".tr.toUpperCase(),
                                  style: const TextStyle(color: Colors.white),
                                )),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              });
        });
  }

  void _handleExternalWaller(ExternalWalletResponse response) {
    Get.back();
    showSnackBarAlert(
      message: "${"Payment Processing Via".tr} \n${response.walletName!}",
      color: Colors.blue.shade400,
    );
  }

  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    await controller.completeSubscription();
  }

  SnackbarController showSnackBarAlert({required String message, Color color = Colors.green}) {
    return Get.showSnackbar(GetSnackBar(
      isDismissible: true,
      message: message,
      backgroundColor: color,
      duration: const Duration(seconds: 8),
    ));
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    Get.back();
    showSnackBarAlert(
      message: "${"Payment Failed!!".tr}${jsonDecode(response.message!)['error']['description']}",
      color: Colors.red.shade400,
    );
  }

  Future<void> showLoadingAlert(BuildContext context, bool isDarkMode) {
    return showDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Constant.loader(context, isDarkMode: isDarkMode),
              Text('Please wait!!'.tr),
            ],
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                const SizedBox(
                  height: 15,
                ),
                Text(
                  'Please wait!! while completing Transaction'.tr,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(
                  height: 15,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  ///payFast

  void payFastPayment(context) {
    PayFast? payfast = controller.paymentSettingModel.value.payFast;
    PayStackURLGen.getPayHTML(payFastSettingData: payfast!, amount: double.parse(controller.totalAmount.value.toString().toString()).round().toString())
        .then((String? value) async {
      bool isDone = await Get.to(PayFastScreen(
        htmlData: value!,
        payFastSettingData: payfast,
      ));
      if (isDone) {
        await controller.completeSubscription();
      } else {
        Get.back();
        showSnackBarAlert(
          message: "Payment UnSuccessful!!".tr,
          color: Colors.red,
        );
      }
    });
  }

  /// Stripe Payment Gateway
  Map<String, dynamic>? paymentIntentData;

  Future<void> stripeMakePayment({required String amount}) async {
    try {
      paymentIntentData = await controller.createStripeIntent(amount: amount);

      if (paymentIntentData != null && paymentIntentData!.containsKey("error")) {
        Get.back();
        showSnackBarAlert(
          message: "Something went wrong, please contact admin.".tr,
          color: Colors.red.shade400,
        );
      } else {
        await stripe1.Stripe.instance
            .initPaymentSheet(
                paymentSheetParameters: stripe1.SetupPaymentSheetParameters(
              paymentIntentClientSecret: paymentIntentData!['client_secret'],
              allowsDelayedPaymentMethods: false,
              googlePay: stripe1.PaymentSheetGooglePay(
                merchantCountryCode: 'US',
                testEnv: controller.paymentSettingModel.value.strip!.isSandboxEnabled == 'true' ? true : false,
                currencyCode: "USD",
              ),
              customFlow: true,
              style: ThemeMode.system,
              appearance: stripe1.PaymentSheetAppearance(
                colors: stripe1.PaymentSheetAppearanceColors(
                  primary: AppThemeData.primary200,
                ),
              ),
              merchantDisplayName: 'Cabme',
            ))
            .then((value) {});

        displayStripePaymentSheet();
      }
    } catch (e, s) {
      Get.back();

      showSnackBarAlert(
        message: 'exception:$e \n$s',
        color: Colors.red,
      );
    }
  }

  Future<void> displayStripePaymentSheet() async {
    try {
      await stripe1.Stripe.instance.presentPaymentSheet().then((value) async {
        await controller.completeSubscription();
        paymentIntentData = null;
      });
    } on stripe1.StripeException catch (e) {
      Get.back();
      var lo1 = jsonEncode(e);
      var lo2 = jsonDecode(lo1);
      StripePayFailedModel lom = StripePayFailedModel.fromJson(lo2);
      showSnackBarAlert(
        message: lom.error.message,
        color: Colors.green,
      );
    } catch (e) {
      Get.back();
      showSnackBarAlert(
        message: e.toString(),
        color: Colors.green,
      );
    }
  }

  /// RazorPay Payment Gateway
  void startRazorpayPayment() {
    try {
      controller.createOrderRazorPay(amount: double.parse(controller.totalAmount.value.toString()).round()).then((value) {
        if (value != null) {
          CreateRazorPayOrderModel result = value;
          openCheckout(
            amount: controller.totalAmount.value.toString(),
            orderId: result.id,
          );
        } else {
          Get.back();
          showSnackBarAlert(
            message: "Something went wrong, please contact admin.".tr,
            color: Colors.red.shade400,
          );
        }
      });
    } catch (e) {
      Get.back();
      showSnackBarAlert(
        message: e.toString(),
        color: Colors.red.shade400,
      );
    }
  }

  void openCheckout({required amount, required orderId}) async {
    var options = {
      'key': controller.paymentSettingModel.value.razorpay!.key,
      'amount': amount * 100,
      'name': 'Cabme',
      'order_id': orderId,
      "currency": "INR",
      'description': 'wallet Topup',
      'retry': {'enabled': true, 'max_count': 1},
      'send_sms_hash': true,
      'prefill': {'contact': "8888888888", 'email': "demo@demo.com"},
      'external': {
        'wallets': ['paytm']
      }
    };

    try {
      razorPayController.open(options);
    } catch (e) {
      print('RazorPay Error : $e');
    }
  }

  Future<void> _startTransaction(
    context, {
    required String txnTokenBy,
    required orderId,
    required double amount,
  }) async {}

  ///MercadoPago Payment Method

  ///paypal
  ///
  void paypalPaymentSheet(String amount, context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (BuildContext context) => UsePaypal(
            sandboxMode: controller.paymentSettingModel.value.payPal!.isLive == "true" ? false : true,
            clientId: controller.paymentSettingModel.value.payPal!.appId ?? '',
            secretKey: controller.paymentSettingModel.value.payPal!.secretKey ?? '',
            returnURL: "com.parkme://paypalpay",
            cancelURL: "com.parkme://paypalpay",
            transactions: [
              {
                "amount": {
                  "total": amount,
                  "currency": "USD",
                  "details": {"subtotal": amount}
                },
              }
            ],
            note: "Contact us for any questions on your order.",
            onSuccess: (Map params) async {
              await controller.completeSubscription();
            },
            onError: (error) {
              log("onError1: $error");
              Get.back();
              Get.back();
              ShowToastDialog.showToast("Payment UnSuccessful!!");
            },
            onCancel: (params) {
              log("onError2: $params");
              Get.back();
              Get.back();
              ShowToastDialog.showToast("Payment UnSuccessful!!");
            }),
      ),
    );
  }

  ///PayStack Payment Method
  Future<void> payStackPayment(BuildContext context) async {
    var secretKey = controller.paymentSettingModel.value.payStack!.secretKey.toString();
    await controller
        .payStackURLGen(
      amount: controller.totalAmount.value.toString(),
      secretKey: secretKey,
    )
        .then((value) async {
      if (value != null) {
        PayStackUrlModel payStackModel = value;

        bool isDone = await Get.to(() => PayStackScreen(
          walletController: walletController,
              secretKey: secretKey,
              initialURl: payStackModel.data.authorizationUrl,
              amount: controller.totalAmount.value.toString(),
              reference: payStackModel.data.reference,
              callBackUrl: controller.paymentSettingModel.value.payStack!.callbackUrl.toString(),
            ));

        if (isDone) {
          await controller.completeSubscription();
        } else {
          showSnackBarAlert(message: "Payment UnSuccessful!!".tr, color: Colors.red);
        }
      } else {
        showSnackBarAlert(message: "Error while transaction!".tr, color: Colors.red);
      }
    });
  }

  Future<Null> mercadoPagoMakePayment({required BuildContext context, required String amount, required UserModel user}) async {
    final headers = {
      'Authorization': 'Bearer ${controller.paymentSettingModel.value.mercadopago?.accesstoken ?? ''}',
      'Content-Type': 'application/json',
    };

    final body = jsonEncode({
      "items": [
        {
          "title": "Test",
          "description": "Test Payment",
          "quantity": 1,
          "currency_id": "BRL",
          "unit_price": double.parse(amount),
        }
      ],
      "payer": {"email": user.userData?.email ?? ''},
      "back_urls": {
        "failure": "${API.baseUrl}payment/failure",
        "pending": "${API.baseUrl}payment/pending",
        "success": "${API.baseUrl}payment/success",
      },
      "auto_return": "approved" // Automatically return after payment is approved
    });

    final response = await http.post(
      Uri.parse("https://api.mercadopago.com/checkout/preferences"),
      headers: headers,
      body: body,
    );
    showLog("API :: URL :: https://api.mercadopago.com/checkout/preferences");
    showLog("API :: Request Body :: $body ");
    showLog("API :: Request Header :: $headers ");
    showLog("API :: Response Status :: ${response.statusCode} ");
    showLog("API :: Response Body :: ${response.body} ");
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      Get.to(MercadoPagoScreen(initialURl: controller.paymentSettingModel.value.mercadopago?.isSandboxEnabled == "false" ? data['init_point'] : data['sandbox_init_point']))!
          .then((value) async {
        if (value) {
          await controller.completeSubscription();
        } else {
          Get.back();
          ShowToastDialog.showToast("Payment UnSuccessful!!");
        }
      });
    } else {
      Get.back();
      print('Error creating preference: ${response.body}');
      return null;
    }
  }

  String? _ref;

  void setRef() {
    maths.Random numRef = maths.Random();
    int year = DateTime.now().year;
    int refNumber = numRef.nextInt(20000);
    if (Platform.isAndroid) {
      _ref = "AndroidRef$year$refNumber";
    } else if (Platform.isIOS) {
      _ref = "IOSRef$year$refNumber";
    }
  }

  ///FlutterWave Payment Method
  Future<Null> flutterWaveInitiatePayment({required BuildContext context, required String amount, required UserModel user}) async {
    final url = Uri.parse('https://api.flutterwave.com/v3/payments');
    final headers = {
      'Authorization': 'Bearer ${controller.paymentSettingModel.value.flutterWave?.secretKey}',
      'Content-Type': 'application/json',
    };

    final body = jsonEncode({
      "tx_ref": controller.ref.value,
      "amount": amount,
      "currency": "NGN",
      "redirect_url": "${API.baseUrl}payment/success",
      "payment_options": "ussd, card, barter, payattitude",
      "customer": {
        "email": user.userData?.email.toString(),
        "phonenumber": user.userData?.phone, // Add a real phone number
        "name": '${user.userData?.prenom} ${user.userData?.nom}', // Add a real customer name
      },
      "customizations": {
        "title": "Payment for Services",
        "description": "Payment for XYZ services",
      }
    });

    final response = await http.post(url, headers: headers, body: body);

    showLog("API :: URL :: $url");
    showLog("API :: Request Body :: $body");
    showLog("API :: Request Header :: ${{
      'Authorization': 'Bearer ${controller.paymentSettingModel.value.flutterWave?.secretKey}',
      'Content-Type': 'application/json',
    }.toString()} ");
    showLog("API :: responseStatus :: ${response.statusCode} ");
    showLog("API :: responseBody :: ${response.body} ");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      Get.to(MercadoPagoScreen(initialURl: data['data']['link']))!.then((value) async {
        if (value) {
          await controller.completeSubscription();
        } else {
          Get.back();
          ShowToastDialog.showToast("Payment UnSuccessful!!");
        }
      });
    } else {
      Get.back();
      ShowToastDialog.showToast("Payment UnSuccessful!!");
      return null;
    }
  }

  //XenditPayment
  Future<void> xenditPayment(context, amount) async {
    await createXenditInvoice(amount: amount).then((model) {
      if (model.id != null) {
        Get.to(() => XenditScreen(
                  initialURl: model.invoiceUrl ?? '',
                  transId: model.id ?? '',
                  apiKey: controller.paymentSettingModel.value.xendit!.key!.toString(),
                ))!
            .then((value) async {
          if (value == true) {
            await controller.completeSubscription();
          } else {
            Get.back();
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text("Payment Unsuccessful!!".tr),
              backgroundColor: Colors.red,
            ));
          }
        });
      }
    });
  }

  Future<XenditModel> createXenditInvoice({required var amount}) async {
    const url = 'https://api.xendit.co/v2/invoices';
    var headers = {
      'Content-Type': 'application/json',
      'Authorization': generateBasicAuthHeader(controller.paymentSettingModel.value.xendit!.key!.toString()),
      // 'Cookie': '__cf_bm=yERkrx3xDITyFGiou0bbKY1bi7xEwovHNwxV1vCNbVc-1724155511-1.0.1.1-jekyYQmPCwY6vIJ524K0V6_CEw6O.dAwOmQnHtwmaXO_MfTrdnmZMka0KZvjukQgXu5B.K_6FJm47SGOPeWviQ',
    };

    final body = jsonEncode({
      'external_id': DateTime.now().millisecondsSinceEpoch.toString(),
      'amount': amount,
      'payer_email': 'customer@domain.com',
      'description': 'Test - VA Successful invoice payment',
      'currency': 'IDR', //IDR, PHP, THB, VND, MYR
    });

    try {
      final response = await http.post(Uri.parse(url), headers: headers, body: body);
      showLog("API :: URL :: $url");
      showLog("API :: Request Body :: ${jsonEncode(body)}");
      showLog("API :: Request Header :: ${headers.toString()} ");
      showLog("API :: responseStatus :: ${response.statusCode} ");
      showLog("API :: responseBody :: ${response.body} ");

      if (response.statusCode == 200 || response.statusCode == 201) {
        XenditModel model = XenditModel.fromJson(jsonDecode(response.body));
        // Get.back();
        return model;
      } else {
        // Get.back();
        return XenditModel();
      }
    } catch (e) {
      // Get.back();
      return XenditModel();
    }
  }

  String generateBasicAuthHeader(String apiKey) {
    String credentials = '$apiKey:';
    String base64Encoded = base64Encode(utf8.encode(credentials));
    return 'Basic $base64Encoded';
  }

//Orangepay payment
  static String accessToken = '';
  static String payToken = '';
  static String orderId = '';
  static String amount = '';

  Future<void> orangeMakePayment({required String amount, required BuildContext context}) async {
    reset();

    var paymentURL = await fetchToken(context: context, orderId: DateTime.now().millisecondsSinceEpoch.toString(), amount: amount, currency: 'USD');

    if (paymentURL.toString() != '') {
      Get.to(() => OrangeMoneyScreen(
                initialURl: paymentURL,
                accessToken: accessToken,
                amount: amount,
                orangePay: controller.paymentSettingModel.value.orangePay!,
                orderId: orderId,
                payToken: payToken,
              ))!
          .then((value) async {
        if (value == true) {
          await controller.completeSubscription();
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Payment Unsuccessful!!".tr),
        backgroundColor: Colors.red,
      ));
    }
  }

  Future fetchToken({required String orderId, required String currency, required BuildContext context, required String amount}) async {
    String apiUrl = 'https://api.orange.com/oauth/v3/token';
    Map<String, String> requestBody = {
      'grant_type': 'client_credentials',
    };

    var response = await http.post(Uri.parse(apiUrl),
        headers: <String, String>{
          'Authorization': "Basic ${controller.paymentSettingModel.value.orangePay!.key!}",
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: requestBody);

    showLog("API :: URL :: $apiUrl");
    showLog("API :: Request Body :: ${jsonEncode(requestBody)}");
    showLog("API :: Request Header :: ${{
      'Authorization': "Basic ${controller.paymentSettingModel.value.orangePay!.key!}",
      'Content-Type': 'application/x-www-form-urlencoded',
      'Accept': 'application/json',
    }.toString()} ");
    showLog("API :: responseStatus :: ${response.statusCode} ");
    showLog("API :: responseBody :: ${response.body} ");

    if (response.statusCode == 200) {
      Map<String, dynamic> responseData = jsonDecode(response.body);

      accessToken = responseData['access_token'];
      // ignore: use_build_context_synchronously
      return await webpayment(context: context, amountData: amount, currency: currency, orderIdData: orderId);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: Color(0xff635bff),
          content: Text(
            "Something went wrong, please contact admin.".tr,
            style: TextStyle(fontSize: 17),
          )));

      return '';
    }
  }

  Future webpayment({required String orderIdData, required BuildContext context, required String currency, required String amountData}) async {
    orderId = orderIdData;
    amount = amountData;
    String apiUrl = controller.paymentSettingModel.value.orangePay!.isSandboxEnabled! == "true"
        ? 'https://api.orange.com/orange-money-webpay/dev/v1/webpayment'
        : 'https://api.orange.com/orange-money-webpay/cm/v1/webpayment';
    Map<String, String> requestBody = {
      "merchant_key": controller.paymentSettingModel.value.orangePay!.merchantKey ?? '',
      "currency": controller.paymentSettingModel.value.orangePay!.isSandboxEnabled == "true" ? "OUV" : currency,
      "order_id": orderId,
      "amount": amount,
      "reference": 'Y-Note Test',
      "lang": "en",
      "return_url": controller.paymentSettingModel.value.orangePay!.returnUrl!.toString(),
      "cancel_url": controller.paymentSettingModel.value.orangePay!.cancelUrl!.toString(),
      "notif_url": controller.paymentSettingModel.value.orangePay!.notifUrl!.toString(),
    };

    var response = await http.post(
      Uri.parse(apiUrl),
      headers: <String, String>{'Authorization': 'Bearer $accessToken', 'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: json.encode(requestBody),
    );

    showLog("API :: URL :: $apiUrl");
    showLog("API :: Request Body :: ${jsonEncode(requestBody)}");
    showLog("API :: Request Header :: ${{'Authorization': 'Bearer $accessToken', 'Content-Type': 'application/json', 'Accept': 'application/json'}.toString()} ");
    showLog("API :: responseStatus :: ${response.statusCode} ");
    showLog("API :: responseBody :: ${response.body} ");
    if (response.statusCode == 201) {
      Get.back();
      Map<String, dynamic> responseData = jsonDecode(response.body);
      if (responseData['message'] == 'OK') {
        payToken = responseData['pay_token'];
        return responseData['payment_url'];
      } else {
        return '';
      }
    } else {
      Get.back();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: Color(0xff635bff),
          content: Text(
            "Something went wrong, please contact admin.".tr,
            style: TextStyle(fontSize: 17),
          )));
      return '';
    }
  }

  static void reset() {
    accessToken = '';
    payToken = '';
    orderId = '';
    amount = '';
  }

//Midtrans payment
  Future<void> midtransMakePayment({required String amount, required BuildContext context}) async {
    await createPaymentLink(amount: amount).then((url) {
      if (url != '') {
        Get.to(() => MidtransScreen(
                  initialURl: url,
                ))!
            .then((value) async {
          if (value == true) {
            await controller.completeSubscription();
          } else {
            Get.back();
            showSnackBarAlert(
              message: "Payment Unsuccessful!!".tr,
              color: Colors.red,
            );
            // ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            //   content: Text("Payment Unsuccessful!!".tr),
            //   backgroundColor: Colors.red,
            // ));
          }
        });
      }
    });
  }

  Future<String> createPaymentLink({required var amount}) async {
    var ordersId = DateTime.now().millisecondsSinceEpoch.toString();
    final url = Uri.parse(controller.paymentSettingModel.value.midtrans!.isSandboxEnabled!.toString() == "true"
        ? 'https://api.sandbox.midtrans.com/v1/payment-links'
        : 'https://api.midtrans.com/v1/payment-links');

    final response = await http.post(
      url,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': generateBasicAuthHeader(controller.paymentSettingModel.value.midtrans!.key!),
      },
      body: jsonEncode({
        'transaction_details': {
          'order_id': ordersId,
          'gross_amount': double.parse(amount.toString()).toInt(),
        },
        'usage_limit': 2,
        "callbacks": {"finish": "https://www.google.com?merchant_order_id=$ordersId"},
      }),
    );
    showLog("API :: URL :: $url");
    showLog("API :: Request Body :: ${jsonEncode({
          'transaction_details': {
            'order_id': ordersId,
            'gross_amount': double.parse(amount.toString()).toInt(),
          },
          'usage_limit': 2,
          "callbacks": {"finish": "https://www.google.com?merchant_order_id=$ordersId"},
        })}");
    showLog("API :: Request Header :: ${{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': generateBasicAuthHeader(controller.paymentSettingModel.value.midtrans!.key!),
    }.toString()} ");
    showLog("API :: responseStatus :: ${response.statusCode} ");
    showLog("API :: responseBody :: ${response.body} ");
    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseData = jsonDecode(response.body);
      // Get.back();
      print('Payment link created: ${responseData['payment_url']}');
      return responseData['payment_url'];
    } else {
      // Get.back();
      return '';
    }
  }
}

class SubscriptionPlanWidget extends StatelessWidget {
  final Function() onClick;
  final Function() onContainClick;
  final String type;
  final SubscriptionPlanData subscriptionPlanModel;

  const SubscriptionPlanWidget({super.key, required this.onClick, required this.type, required this.subscriptionPlanModel, required this.onContainClick});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);

    return GetX(
        init: SubscriptionController(),
        builder: (controller) {
          return InkWell(
            splashColor: Colors.transparent,
            onTap: onContainClick,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: themeChange.getThem() ? AppThemeData.grey800 : AppThemeData.grey200),
                color: controller.selectedSubscriptionPlan.value.id == subscriptionPlanModel.id
                    ? themeChange.getThem()
                        ? AppThemeData.grey300Dark
                        : AppThemeData.grey800
                    : themeChange.getThem()
                        ? AppThemeData.grey900
                        : AppThemeData.grey50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        NetworkImageWidget(
                          imageUrl: subscriptionPlanModel.image ?? '',
                          fit: BoxFit.cover,
                          width: 50,
                          height: 50,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                subscriptionPlanModel.name ?? '',
                                style: TextStyle(
                                  color: controller.selectedSubscriptionPlan.value.id == subscriptionPlanModel.id
                                      ? AppThemeData.grey50
                                      : themeChange.getThem()
                                          ? AppThemeData.grey50
                                          : AppThemeData.grey900,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: AppThemeData.semiBold,
                                ),
                              ),
                              Text(
                                "${subscriptionPlanModel.description}",
                                maxLines: 2,
                                softWrap: true,
                                style: TextStyle(
                                  fontFamily: AppThemeData.regular,
                                  fontSize: 14,
                                  color: AppThemeData.grey400,
                                ),
                              ),
                            ],
                          ),
                        ),
                        controller.userModel.value.userData!.subscriptionPlanId == subscriptionPlanModel.id
                            ? RoundedButtonFill(
                                title: "Active".tr,
                                width: 18,
                                height: 4,
                                color: AppThemeData.success300,
                                textColor: AppThemeData.grey50,
                                onPress: () async {},
                              )
                            : SizedBox(),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subscriptionPlanModel.type == "free" ? "Free" : Constant().amountShow(amount: double.parse(subscriptionPlanModel.price ?? '0.0').toString()),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: controller.selectedSubscriptionPlan.value.id == subscriptionPlanModel.id
                                ? AppThemeData.grey50
                                : themeChange.getThem()
                                    ? AppThemeData.grey200
                                    : AppThemeData.grey800,
                            fontFamily: AppThemeData.semiBold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subscriptionPlanModel.expiryDay == "-1" ? "Lifetime" : "${subscriptionPlanModel.expiryDay} Days",
                          style: TextStyle(
                            fontFamily: AppThemeData.medium,
                            fontSize: 14,
                            color: controller.selectedSubscriptionPlan.value.id == subscriptionPlanModel.id
                                ? AppThemeData.grey50
                                : themeChange.getThem()
                                    ? AppThemeData.grey200
                                    : AppThemeData.grey800,
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                    Divider(
                        color: controller.selectedSubscriptionPlan.value.id == subscriptionPlanModel.id
                            ? AppThemeData.grey200Dark
                            : themeChange.getThem()
                                ? AppThemeData.grey800
                                : AppThemeData.grey200),
                    const SizedBox(height: 10),
                    if (subscriptionPlanModel.id == Constant.commissionSubscriptionID)
                      Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              Text('•  ',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontFamily: AppThemeData.medium,
                                    color: controller.selectedSubscriptionPlan.value.id == subscriptionPlanModel.id
                                        ? AppThemeData.grey50
                                        : themeChange.getThem()
                                            ? AppThemeData.grey200
                                            : AppThemeData.grey800,
                                  )),
                              Expanded(
                                child: Text(
                                    controller.userModel.value.userData!.adminCommission != null
                                        ? "Pay a commission of ${controller.userModel.value.userData!.adminCommission!.type == 'Percentage' ? "${controller.userModel.value.userData!.adminCommission!.value} %" : "${Constant().amountShow(amount: controller.userModel.value.userData!.adminCommission!.value)} Flat"} ${"on each booking".tr}"
                                            .tr
                                        : "Pay a commission of ${Constant.adminCommission?.type == 'Percentage' ? "${Constant.adminCommission?.value} %" : "${Constant().amountShow(amount: Constant.adminCommission?.value)} Flat"} ${"on each booking".tr}"
                                            .tr,
                                    maxLines: 2,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontFamily: AppThemeData.regular,
                                      color: controller.selectedSubscriptionPlan.value.id == subscriptionPlanModel.id
                                          ? AppThemeData.grey50
                                          : themeChange.getThem()
                                              ? AppThemeData.grey200
                                              : AppThemeData.grey800,
                                    )),
                              ),
                            ],
                          )),
                    ListView.builder(
                      shrinkWrap: true,
                      itemCount: subscriptionPlanModel.planPoints?.length,
                      itemBuilder: (BuildContext? context, int index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              Text('•  ',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontFamily: AppThemeData.medium,
                                    color: controller.selectedSubscriptionPlan.value.id == subscriptionPlanModel.id
                                        ? AppThemeData.grey50
                                        : themeChange.getThem()
                                            ? AppThemeData.grey200
                                            : AppThemeData.grey800,
                                  )),
                              Expanded(
                                child: Text(subscriptionPlanModel.planPoints?[index] ?? '',
                                    maxLines: 2,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontFamily: AppThemeData.regular,
                                      color: controller.selectedSubscriptionPlan.value.id == subscriptionPlanModel.id
                                          ? AppThemeData.grey50
                                          : themeChange.getThem()
                                              ? AppThemeData.grey200
                                              : AppThemeData.grey800,
                                    )),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    Divider(
                        color: controller.selectedSubscriptionPlan.value.id == subscriptionPlanModel.id
                            ? AppThemeData.grey200Dark
                            : themeChange.getThem()
                                ? AppThemeData.grey800
                                : AppThemeData.grey200),
                    const SizedBox(height: 10),
                    Text('Accept booking limits : ${subscriptionPlanModel.bookingLimit == '-1' ? 'Unlimited' : subscriptionPlanModel.bookingLimit ?? '0'}',
                        textAlign: TextAlign.end,
                        maxLines: 2,
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: AppThemeData.regular,
                          color: controller.selectedSubscriptionPlan.value.id == subscriptionPlanModel.id
                              ? AppThemeData.grey50
                              : themeChange.getThem()
                                  ? AppThemeData.grey200
                                  : AppThemeData.grey800,
                        )),
                    const SizedBox(height: 20),
                    RoundedButtonFill(
                      radius: 14,
                      textColor: controller.selectedSubscriptionPlan.value.id == subscriptionPlanModel.id
                          ? AppThemeData.grey200
                          : themeChange.getThem()
                              ? AppThemeData.grey200
                              : AppThemeData.grey500,
                      title: controller.userModel.value.userData!.subscriptionPlanId == subscriptionPlanModel.id
                          ? "Renew"
                          : controller.selectedSubscriptionPlan.value.id == subscriptionPlanModel.id
                              ? "Active".tr
                              : "Select Plan".tr,
                      color: controller.selectedSubscriptionPlan.value.id == subscriptionPlanModel.id
                          ? AppThemeData.secondary300
                          : themeChange.getThem()
                              ? AppThemeData.grey200Dark
                              : AppThemeData.grey200,
                      width: 80,
                      height: 5,
                      onPress: onClick,
                    ),
                  ],
                ),
              ),
            ),
          );
        });
  }
}
