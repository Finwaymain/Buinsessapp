// ignore_for_file: must_be_immutable, library_prefixes, deprecated_member_use

import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:cabme_driver/constant/constant.dart';
import 'package:cabme_driver/constant/logdata.dart';
import 'package:cabme_driver/constant/show_toast_dialog.dart';
import 'package:cabme_driver/controller/dash_board_controller.dart';
import 'package:cabme_driver/controller/payStackURLModel.dart';
import 'package:cabme_driver/controller/wallet_controller.dart';
import 'package:cabme_driver/model/parcel_model.dart';
import 'package:cabme_driver/model/payment_setting_model.dart';
import 'package:cabme_driver/model/razorpay_gen_userid_model.dart';
import 'package:cabme_driver/model/ride_model.dart';
import 'package:cabme_driver/model/stripe_failed_model.dart';
import 'package:cabme_driver/model/trancation_model.dart';
import 'package:cabme_driver/model/user_model.dart';
import 'package:cabme_driver/model/xenditModel.dart';
import 'package:cabme_driver/page/add_bank_details/add_bank_account.dart';
import 'package:cabme_driver/page/auth_screens/phone_entry_screen.dart';
import 'package:cabme_driver/page/completed/trip_history_screen.dart';
import 'package:cabme_driver/page/parcel_service/parcel_details_screen.dart';
import 'package:cabme_driver/page/wallet/mercadopago_screen.dart';
import 'package:cabme_driver/page/wallet/midtrans_screen.dart';
import 'package:cabme_driver/page/wallet/orangePayScreen.dart';
import 'package:cabme_driver/page/wallet/payStackScreen.dart';
import 'package:cabme_driver/page/wallet/payfast_screen.dart';
import 'package:cabme_driver/page/wallet/paystack_url_generator.dart';
import 'package:cabme_driver/page/wallet/widgets/wallet_main_content.dart';
import 'package:cabme_driver/page/wallet/xenditScreen.dart';
import 'package:cabme_driver/service/api.dart';
import 'package:cabme_driver/themes/app_bar_custom.dart';
import 'package:cabme_driver/themes/button_them.dart';
import 'package:cabme_driver/themes/constant_colors.dart';
import 'package:cabme_driver/themes/custom_widget.dart';
import 'package:cabme_driver/themes/radio_button.dart';
import 'package:cabme_driver/themes/text_field_them.dart';
import 'package:cabme_driver/utils/Preferences.dart';
import 'package:cabme_driver/utils/dark_theme_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_paypal/flutter_paypal.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'dart:math' as maths;
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_stripe/flutter_stripe.dart' as stripe1;

import 'package:webview_flutter/webview_flutter.dart';
import 'package:cabme_driver/utils/onboarding_url.dart';
import 'package:cabme_driver/page/web_view_screen/web_view_screen.dart';
import 'package:cabme_driver/page/features/SmartValue/AccountDetails/view/account_details.dart';
import 'package:cabme_driver/page/features/SmartValue/MyQR/view/my_qr_view.dart';
import 'package:cabme_driver/page/features/SmartValue/Payout/view/payout_screen.dart';
import 'package:cabme_driver/page/features/SmartValue/ScanAndTransfer/view/scanner_and_transfer_screen.dart';
import 'package:cabme_driver/page/subscription_plan_screen/business_premium_plan_screen.dart';

class WalletScreen extends StatelessWidget {
  final bool isTab;
  final int initialIndex;
  WalletScreen({super.key, this.isTab = false, this.initialIndex = 0});

  final Razorpay razorPayController = Razorpay();

  static final GlobalKey<FormState> _walletFormKey = GlobalKey<FormState>();
  final controllerDashBoard = Get.put(DashBoardController());
  final walletController = Get.put(WalletController());
  WebViewController? activeWebViewController;

  _refreshAPI() {
    walletController.getAmount();
    if (activeWebViewController != null) {
      activeWebViewController!.runJavaScript("if (window.refreshWalletData) { window.refreshWalletData(); } else { location.reload(); }");
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.getThem();
    final String walletUrl = OnboardingUrl.build('/wallet', extra: {
      'user_type': 'driver',
      'theme': isDark ? 'dark' : 'light',
    });

    return Scaffold(
      appBar: isTab
          ? null
          : AppbarCustom(
              title: 'Smart Value'.tr,
              elevation: 0,
              actions: [
                IconButton(
                  icon: Icon(
                    Icons.refresh_rounded,
                    color: themeChange.getThem() ? Colors.white : AppThemeData.grey900,
                  ),
                  onPressed: () {
                    _refreshAPI();
                    ShowToastDialog.showToast('Refreshing...'.tr);
                  },
                ),
              ],
            ),
      backgroundColor: themeChange.getThem() ? AppThemeData.grey50Dark : AppThemeData.grey50,
      body: SafeArea(
        top: !isTab,
        child: WebViewScreen(
          url: walletUrl,
          title: 'Smart Value',
          showAppBar: false,
          onBridgeAction: (data) {
            if (data['_controller'] is WebViewController) {
              activeWebViewController = data['_controller'] as WebViewController;
            }
            final action = data['action'];
            if (action == 'topup') {
              if (!Preferences.getBoolean(Preferences.isLogin)) {
                Get.to(() => PhoneEntryScreen(mode: 'signup'));
              } else {
                walletController.amountController.value.clear();
                addToWalletAmount(context, walletController, themeChange.getThem());
              }
            } else if (action == 'withdraw') {
              if (!Preferences.getBoolean(Preferences.isLogin)) {
                Get.to(() => PhoneEntryScreen(mode: 'signup'));
              } else {
                walletController.getBankDetails().then((value) {
                  if (value == null) {
                    ShowToastDialog.showToast('Please Update bank Details');
                  } else {
                    buildShowBottomSheet(context, walletController, themeChange.getThem());
                  }
                });
              }
            } else if (action == 'bank') {
              showModalBottomSheet(
                isDismissible: true,
                isScrollControlled: true,
                context: context,
                backgroundColor: themeChange.getThem() ? AppThemeData.grey50Dark : AppThemeData.grey50,
                builder: (context) => const AddBankAccount(),
              );
            } else if (action == 'payout') {
              Get.to(() => PayoutScreen());
            } else if (action == 'transfer' || action == 'scan') {
              Get.to(() => ScannerAndTransferScreen());
            } else if (action == 'my_qr') {
              Get.to(() => MyQRScreen());
            } else if (action == 'account_details') {
              Get.to(() => AccountDetails());
            } else if (action == 'upgrade_plan') {
              Get.to(() => const BusinessPremiumPlanScreen());
            }
          },
        ),
      ),
    );
  }


  InkWell showRideTransaction(TansactionData data, bool isDarkMode) {
    return InkWell(
      onTap: () {
        if (data.orderType != null && data.orderType.toString() == "ride") {
          Get.to(const TripHistoryScreen(), arguments: {
            "rideData": RideData.fromJson(data.toJson()),
          });
        } else if (data.orderType != null && data.orderType.toString() == "parcel") {
          Get.to(() => const ParcelDetailsScreen(), arguments: {
            "parcelData": ParcelData.fromJson(data.toJson()),
          });
        } else {}
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: data.orderType != null && data.orderType.toString() == "ride"
                  ? data.amount!.toString().contains('-')
                      ? SvgPicture.asset('assets/icons/ic_arrow_down.svg')
                      : SvgPicture.asset('assets/icons/ic_arrow_up.svg')
                  : data.orderType != null && data.orderType.toString() == "parcel"
                      ? data.transactionAmount!.toString().contains('-')
                          ? SvgPicture.asset('assets/icons/ic_arrow_down.svg')
                          : SvgPicture.asset('assets/icons/ic_arrow_up.svg')
                      : SvgPicture.asset('assets/icons/ic_arrow_up.svg'),
            ),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                data.planId != null && data.planId != ''
                    ? Text(
                        'Subscription Amount Debited'.tr,
                        style: TextStyle(
                          color: isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900,
                          fontFamily: AppThemeData.medium,
                        ),
                      )
                    : data.orderType != null && data.orderType.toString() == "ride"
                        ? Row(
                            children: [
                              Text(
                                data.amount!.toString().contains('-') ? "Admin Commission Debited".tr : "Booking Amount credited".tr,
                                style: TextStyle(
                                  color: isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900,
                                  fontFamily: AppThemeData.medium,
                                ),
                              )
                            ],
                          )
                        : data.orderType != null && data.orderType.toString() == "parcel"
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data.transactionAmount!.toString().contains('-') ? "Admin Commission Debited".tr : "Parcel Amount credited".tr,
                                    style: TextStyle(
                                      color: isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900,
                                      fontFamily: AppThemeData.medium,
                                    ),
                                  ),
                                ],
                              )
                            : Text(
                                "${"Wallet Topup Via".tr} ${data.libelle}",
                                style: TextStyle(
                                  color: isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900,
                                  fontFamily: AppThemeData.medium,
                                  fontSize: 16,
                                ),
                              ),
                Text(
                  data.creer != null ? data.creer.toString() : data.createdAt.toString(),
                  style: const TextStyle(
                    fontFamily: AppThemeData.medium,
                    fontSize: 12,
                  ),
                ),
              ]),
            ),
            data.planId != null && data.planId != ''
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Text(
                      "-${Constant().amountShowWithoutSymbol(amount: data.amount!.toString())}",
                      style: TextStyle(fontFamily: AppThemeData.medium, fontSize: 16, color: AppThemeData.error50),
                    ),
                  )
                : data.orderType != null && data.orderType.toString() == "ride"
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: Text(
                          data.amount!.toString().contains('-')
                              ? "-${Constant().amountShowWithoutSymbol(amount: data.amount!.split("-").last.toString())}"
                              : data.amount!.isNotEmpty
                                  ? Constant().amountShowWithoutSymbol(
                                      amount:
                                          "${double.parse(data.amount!.toString()) + double.parse(data.adminCommission!.isNotEmpty ? data.adminCommission!.toString() : "0.0")}")
                                  : "",
                          style: TextStyle(
                              fontFamily: AppThemeData.medium, fontSize: 16, color: data.amount!.toString().contains('-') ? AppThemeData.error50 : AppThemeData.success300),
                        ),
                      )
                    : data.orderType != null && data.orderType.toString() == "parcel"
                        ? Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: Text(
                              data.transactionAmount!.toString().contains('-')
                                  ? "-${Constant().amountShowWithoutSymbol(amount: data.transactionAmount!.split("-").last.toString())}"
                                  : data.transactionAmount!.isNotEmpty
                                      ? Constant().amountShowWithoutSymbol(
                                          amount:
                                              "${double.parse(data.transactionAmount!.toString()) + double.parse(data.adminCommission!.isNotEmpty ? data.adminCommission!.toString() : "0.0")}")
                                      : "",
                              style: TextStyle(
                                  fontFamily: AppThemeData.medium,
                                  fontSize: 16,
                                  color: data.transactionAmount!.toString().contains('-') ? AppThemeData.error50 : AppThemeData.success300),
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: Text(
                              Constant().amountShowWithoutSymbol(amount: double.parse(data.amount!.toString()).toString()),
                              style: TextStyle(fontFamily: AppThemeData.medium, fontSize: 16, color: AppThemeData.success300),
                            ),
                          ),
          ],
        ),
      ),
    );
  }

  Future<dynamic> buildShowBottomSheet(BuildContext context, WalletController controller, bool isDarkModel) {
    return showModalBottomSheet(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(topRight: Radius.circular(15), topLeft: Radius.circular(15))),
        context: context,
        isDismissible: true,
        isScrollControlled: true,
        builder: (context) {
          return StatefulBuilder(builder: (context, setState) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10),
              child: Padding(
                padding: MediaQuery.of(context).viewInsets,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 10),
                          height: 10,
                          width: 75,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(100),
                            color: isDarkModel ? AppThemeData.grey300Dark : AppThemeData.grey300,
                          )),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    InkWell(
                        onTap: () {
                          Get.back();
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                          child: Transform(
                            alignment: Alignment.center,
                            transform: Directionality.of(context) == TextDirection.rtl ? Matrix4.rotationY(3.14159) : Matrix4.identity(),
                            child: SvgPicture.asset(
                              'assets/icons/ic_left.svg',
                              colorFilter: ColorFilter.mode(
                                isDarkModel ? AppThemeData.grey900Dark : AppThemeData.grey900,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                        )),
                    const SizedBox(
                      height: 20,
                    ),
                    Text(
                      "Withdrawal Amount".tr,
                      style: TextStyle(
                        fontSize: 18,
                        color: isDarkModel ? AppThemeData.grey800Dark : AppThemeData.grey800,
                        fontFamily: AppThemeData.medium,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Container(
                      decoration: BoxDecoration(
                          color: isDarkModel ? AppThemeData.surface50Dark : AppThemeData.surface50,
                          border: Border.all(
                            color: isDarkModel ? AppThemeData.grey200Dark : AppThemeData.grey200,
                          ),
                          borderRadius: BorderRadius.circular(8)),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: TextFieldWithoutBorderWidget(
                              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                              isBorderEnable: false,
                              controller: walletController.amountController.value,
                              textInputType: TextInputType.number,
                              prefix: IconButton(onPressed: () {}, icon: Text(Constant.currency.toString())),
                              hintText: 'Amount'.tr,
                            ),
                          ),
                          dividerCust(isDarkMode: isDarkModel),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: TextFieldWithoutBorderWidget(
                              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                              isBorderEnable: false,
                              controller: walletController.noteController.value,
                              textInputType: TextInputType.text,
                              hintText: 'Add Note'.tr,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Text(
                        "Bank Details".tr,
                        style: TextStyle(
                          fontSize: 18,
                          color: isDarkModel ? AppThemeData.grey800Dark : AppThemeData.grey800,
                          fontFamily: AppThemeData.medium,
                        ),
                      ),
                    ),
                    controller.bankDetails.accountNo != null
                        ? Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: InkWell(
                              onTap: () {
                                showModalBottomSheet(
                                    isDismissible: true,
                                    isScrollControlled: true,
                                    context: context,
                                    backgroundColor: isDarkModel ? AppThemeData.grey50Dark : AppThemeData.grey50,
                                    builder: (context) {
                                      return const AddBankAccount();
                                    });
                              },
                              child: Container(
                                width: MediaQuery.of(context).size.width,
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0XFFFDEBE7), // Blueish
                                        Color(0XFFFFF4E6), // Lighter Blue
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  child: Stack(children: [
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              controller.bankDetails.bankName.toString(),
                                              style: TextStyle(
                                                color: AppThemeData.secondary200,
                                                fontSize: 18,
                                                fontFamily: AppThemeData.semiBold,
                                              ),
                                            ),
                                            Text(
                                              controller.bankDetails.branchName.toString(),
                                              style: TextStyle(
                                                color: AppThemeData.secondary300,
                                                fontSize: 12,
                                                fontFamily: AppThemeData.regular,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.only(top: 8),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                controller.bankDetails.holderName.toString(),
                                                style: TextStyle(
                                                  color: AppThemeData.secondary300,
                                                  fontSize: 12,
                                                  fontFamily: AppThemeData.regular,
                                                ),
                                              ),
                                              Text(
                                                controller.bankDetails.accountNo.toString(),
                                                style: TextStyle(
                                                  color: AppThemeData.secondary300,
                                                  fontSize: 12,
                                                  fontFamily: AppThemeData.regular,
                                                  letterSpacing: 2,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: Opacity(
                                        opacity: 0.10,
                                        child: Image.asset(
                                          'assets/icons/ic_bank_bg.png',
                                          height: 70,
                                          width: 70,
                                        ),
                                      ),
                                    ),
                                  ]),
                                ),
                              ),
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: ButtonThem.buildBorderButton(
                              context,
                              title: 'Add bank'.tr,
                              txtColor: AppThemeData.primary400,
                              onPress: () {
                                showModalBottomSheet(
                                    isDismissible: true,
                                    isScrollControlled: true,
                                    context: context,
                                    backgroundColor: isDarkModel ? AppThemeData.grey50Dark : AppThemeData.grey50,
                                    builder: (context) {
                                      return const AddBankAccount();
                                    });
                              },
                              btnColor: Colors.transparent,
                              btnBorderColor: isDarkModel ? AppThemeData.grey200Dark : AppThemeData.grey200,
                            )),
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 5),
                          child: ButtonThem.buildButton(
                            context,
                            title: 'Withdraw'.tr,
                            btnHeight: 45,
                            btnWidthRatio: 0.9,
                            btnColor: AppThemeData.primary200,
                            txtColor: Colors.white,
                            onPress: () async {
                              if (controller.bankDetails.bankName.toString() != 'null') {
                                if (walletController.amountController.value.text.isNotEmpty) {
                                  double reqAmt = double.tryParse(walletController.amountController.value.text) ?? 0.0;
                                  double userBal = walletController.walletAmount.value;
                                  if (reqAmt > userBal) {
                                    ShowToastDialog.showToast('Withdrawal amount (₹$reqAmt) exceeds available balance of ₹$userBal');
                                    return;
                                  }
                                  if (double.parse(Constant.minimumWithdrawalAmount.toString()) > reqAmt) {
                                    ShowToastDialog.showToast(
                                        '${'Withdraw amount must be greater or equal to'.tr}${Constant().amountShow(amount: Constant.minimumWithdrawalAmount.toString())}');
                                  } else {
                                    Map<String, dynamic> bodyParams = {
                                      'driver_id': Preferences.getInt(Preferences.userId),
                                      'amount': walletController.amountController.value.text,
                                      'note': walletController.noteController.value.text,
                                    };
                                    controller.setWithdrawals(bodyParams).then((value) {
                                      if (value != null && value) {
                                        ShowToastDialog.showToast('Amount Withdrawals request successfully');
                                      }
                                    });
                                    Get.back();
                                  }
                                } else {
                                  ShowToastDialog.showToast('Please enter amount');
                                }
                              } else {
                                ShowToastDialog.showToast('Please add bank details');
                              }
                            },
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            );
          });
        });
  }

  Future<dynamic> addToWalletAmount(BuildContext context, WalletController walletController, bool isDarkMode) {
    return showModalBottomSheet(
        elevation: 5,
        useRootNavigator: true,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(topLeft: Radius.circular(15), topRight: Radius.circular(15))),
        context: context,
        backgroundColor: isDarkMode == true ? AppThemeData.surface50Dark : AppThemeData.surface50,
        builder: (context) {
          return GetX<WalletController>(
              init: WalletController(),
              initState: (controller) {
                razorPayController.clear();
                razorPayController.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
                razorPayController.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWaller);
                razorPayController.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
              },
              builder: (controller) {
                return SizedBox(
                  height: Get.height / 1.1,
                  child: SingleChildScrollView(
                    child: InkWell(
                      onTap: () {
                        FocusScope.of(context).unfocus();
                      },
                      child: Form(
                        key: _walletFormKey,
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
                                  padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10),
                                  child: RichText(
                                    text: TextSpan(
                                      text: "Topup Wallet".tr,
                                      style: TextStyle(
                                        fontSize: 20,
                                        color: isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900,
                                        fontFamily: AppThemeData.medium,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10),
                              child: TextFieldWidget(
                                validators: (v) {
                                  if (v == null || v.isEmpty) {
                                    return 'Please enter the topup amount'.tr;
                                  } else {
                                    return null;
                                  }
                                },
                                contentPadding: const EdgeInsets.all(15),
                                prefix: IconButton(onPressed: () {}, icon: Text(Constant.currency ?? '')),
                                radius: BorderRadius.circular(6),
                                hintText: "Enter Amount".tr,
                                controller: walletController.amountController.value,
                                textInputType: TextInputType.text,
                                inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly], //,
                              ),
                            ),
                            const SizedBox(height: 10),
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
                                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8), bottomLeft: Radius.circular(8), bottomRight: Radius.circular(8)),
                                    isBottomborderRemove: true,
                                    isEnabled: true,
                                    name: 'UPI',
                                    image: "assets/images/razorpay_@3x.png",
                                    isSelected: controller.razorPay.value,
                                    groupValue: walletController.selectedRadioTile!.value,
                                    onClick: (String? value) {
                                      controller.stripe = false.obs;
                                      controller.razorPay = true.obs;

                                      controller.paypal = false.obs;
                                      controller.payStack = false.obs;
                                      controller.flutterWave = false.obs;
                                      controller.mercadoPago = false.obs;
                                      controller.payFast = false.obs;
                                      controller.xendit = false.obs;
                                      controller.midtrans = false.obs;
                                      controller.orangePay = false.obs;
                                      walletController.selectedRadioTile!.value = 'RazorPay';
                                    },
                                  ),
                                ]),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 15),
                              child: GestureDetector(
                                onTap: () async {
                                  if (_walletFormKey.currentState!.validate()) {
                                    if (walletController.selectedRadioTile?.value == null || walletController.selectedRadioTile?.value == '') {
                                      ShowToastDialog.showToast("Please select payment method".tr);
                                      return;
                                    } else {
                                      Get.back();
                                      

                                      if (walletController.selectedRadioTile!.value == "Stripe") {
                                        stripe1.Stripe.publishableKey = controller.paymentSettingModel.value.strip?.key ?? '';
                                        stripe1.Stripe.merchantIdentifier = 'Cabme';
                                        await stripe1.Stripe.instance.applySettings();
                                        stripeMakePayment(amount: walletController.amountController.value.text);
                                      } else if (walletController.selectedRadioTile!.value == "RazorPay") {
                                        startRazorpayPayment();
                                      } else if (walletController.selectedRadioTile!.value == "PayPal") {
                                        paypalPaymentSheet(walletController.amountController.value.text, context);
                                        // _paypalPayment();
                                      } else if (walletController.selectedRadioTile!.value == "PayStack") {
                                        payStackPayment(context);
                                      } else if (walletController.selectedRadioTile!.value == "FlutterWave") {
                                        flutterWaveInitiatePayment(
                                            context: context, amount: walletController.amountController.value.text, user: walletController.userModel.value, controller: controller);
                                      } else if (walletController.selectedRadioTile!.value == "PayFast") {
                                        payFastPayment(context);
                                      } else if (walletController.selectedRadioTile!.value == "MercadoPago") {
                                        mercadoPagoMakePayment(
                                            context: context, amount: walletController.amountController.value.text, user: walletController.userModel.value, controller: controller);
                                      } else if (walletController.selectedRadioTile!.value == "Xendit") {
                                        xenditPayment(context, double.parse(walletController.amountController.value.text), walletController);
                                      } else if (walletController.selectedRadioTile!.value == "Orange Pay") {
                                        orangeMakePayment(amount: walletController.amountController.value.text.toString(), context: context, controller: walletController);
                                      } else if (walletController.selectedRadioTile!.value == "Midtrans") {
                                        midtransMakePayment(amount: walletController.amountController.value.text.toString(), context: context, controller: walletController);
                                      } else {
                                        ShowToastDialog.showToast("Please select payment method");
                                      }
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
                  ),
                );
              });
        });
  }

  void _handleExternalWaller(ExternalWalletResponse response) {
    razorPayController.clear();
    ShowToastDialog.closeLoader();
    while (Get.isDialogOpen == true || Get.isBottomSheetOpen == true) {
      Get.back();
    }
    showSnackBarAlert(
      message: "${"Payment Processing Via".tr} \n${response.walletName!}",
      color: Colors.blue.shade400,
    );
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    razorPayController.clear();
    ShowToastDialog.closeLoader();
    while (Get.isDialogOpen == true || Get.isBottomSheetOpen == true) {
      Get.back();
    }
    walletController.setAmount(walletController.amountController.value.text).then((value) {
      ShowToastDialog.closeLoader();
      if (value != null) {
        showSnackBarAlert(
          message: "Payment Successful!!".tr,
          color: Colors.green.shade400,
        );
        _refreshAPI();
      }
    });
  }

  SnackbarController showSnackBarAlert({required String message, Color color = Colors.green}) {
    return Get.showSnackbar(GetSnackBar(
      isDismissible: true,
      message: message,
      backgroundColor: color,
      duration: const Duration(seconds: 2),
    ));
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    razorPayController.clear();
    ShowToastDialog.closeLoader();
    while (Get.isDialogOpen == true || Get.isBottomSheetOpen == true) {
      Get.back();
    }
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
    PayFast? payfast = walletController.paymentSettingModel.value.payFast;
    PayStackURLGen.getPayHTML(payFastSettingData: payfast!, amount: double.parse(walletController.amountController.value.text.toString()).round().toString())
        .then((String? value) async {
      bool isDone = await Get.to(PayFastScreen(
        htmlData: value!,
        payFastSettingData: payfast,
      ));
      if (isDone) {
        Get.back();
        walletController.setAmount(walletController.amountController.value.text).then((value) {
          if (value != null) {
            showSnackBarAlert(
              message: "Payment Successful!!".tr,
              color: Colors.green.shade400,
            );
            _refreshAPI();
          }
        });
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
      if (walletController.paymentSettingModel.value.strip?.isEnabled == 'true') {
        stripe1.Stripe.publishableKey = walletController.paymentSettingModel.value.strip!.key!;
        stripe1.Stripe.merchantIdentifier = "Cabme";
        await stripe1.Stripe.instance.applySettings();
      }
      paymentIntentData = await walletController.createStripeIntent(amount: amount);

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
                testEnv: true, // testEnv: walletController.paymentSettingModel.value.strip!.isSandboxEnabled == 'true' ? true : false,
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
      await stripe1.Stripe.instance.presentPaymentSheet().then((value) {
        Get.back();
        walletController.setAmount(walletController.amountController.value.text).then((value) {
          if (value != null) {
            _refreshAPI();
          }
        });
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
      walletController.createOrderRazorPay(amount: double.parse(walletController.amountController.value.text).round()).then((value) {
        if (value != null) {
          CreateRazorPayOrderModel result = value;
          openCheckout(
            amount: walletController.amountController.value.text,
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
    final driverData = Constant.getUserData().userData;
    final driverPhone = driverData?.phone ?? "";
    final driverEmail = driverData?.email ?? "";

    var options = {
      'key': walletController.paymentSettingModel.value.razorpay!.key,
      'amount': amount * 100,
      'name': 'Fiinway',
      'order_id': orderId,
      "currency": "INR",
      'description': 'Fiinway Wallet Top-up',
      'retry': {'enabled': true, 'max_count': 1},
      'send_sms_hash': true,
      'prefill': {
        if (driverPhone.isNotEmpty) 'contact': driverPhone,
        if (driverEmail.isNotEmpty) 'email': driverEmail,
      },
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
            sandboxMode: walletController.paymentSettingModel.value.payPal!.isLive == "true" ? false : true,
            clientId: walletController.paymentSettingModel.value.payPal!.appId ?? '',
            secretKey: walletController.paymentSettingModel.value.payPal!.secretKey ?? '',
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
              log("onSuccess1: $params");
              walletController.setAmount(walletController.amountController.value.text).then((value) {
                if (value != null) {
                  showSnackBarAlert(
                    message: "Payment Successful!!".tr,
                    color: Colors.green.shade400,
                  );
                  _refreshAPI();
                }
              });
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
    var secretKey = walletController.paymentSettingModel.value.payStack!.secretKey.toString();
    await walletController
        .payStackURLGen(
      amount: walletController.amountController.value.text,
      secretKey: secretKey,
    )
        .then((value) async {
      if (value != null) {
        PayStackUrlModel payStackModel = value;

        bool isDone = await Get.to(() => PayStackScreen(
          walletController: walletController,
              secretKey: secretKey,
              initialURl: payStackModel.data.authorizationUrl,
              amount: walletController.amountController.value.text,
              reference: payStackModel.data.reference,
              callBackUrl: walletController.paymentSettingModel.value.payStack!.callbackUrl.toString(),
            ));
        Get.back();

        if (isDone) {
          walletController.setAmount(walletController.amountController.value.text).then((value) {
            if (value != null) {
              showSnackBarAlert(
                message: "Payment Successful!!".tr,
                color: Colors.green.shade400,
              );
              _refreshAPI();
            }
          });
        } else {
          Get.back();
          showSnackBarAlert(message: "Payment UnSuccessful!!".tr, color: Colors.red);
        }
      } else {
        showSnackBarAlert(message: "Error while transaction!".tr, color: Colors.red);
      }
    });
  }

  Future<Null> mercadoPagoMakePayment({required BuildContext context, required String amount, required UserModel user, required WalletController controller}) async {
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
          Get.back();
          walletController.setAmount(walletController.amountController.value.text).then((value) {
            if (value != null) {
              showSnackBarAlert(
                message: "Payment Successful!!".tr,
                color: Colors.green.shade400,
              );
              _refreshAPI();
            }
          });
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
  Future<Null> flutterWaveInitiatePayment({required BuildContext context, required String amount, required UserModel user, required WalletController controller}) async {
    final url = Uri.parse('https://api.flutterwave.com/v3/payments');
    final headers = {
      'Authorization': 'Bearer ${walletController.paymentSettingModel.value.flutterWave?.secretKey}',
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
      'Authorization': 'Bearer ${walletController.paymentSettingModel.value.flutterWave?.secretKey}',
      'Content-Type': 'application/json',
    }.toString()} ");
    showLog("API :: responseStatus :: ${response.statusCode} ");
    showLog("API :: responseBody :: ${response.body} ");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      Get.to(MercadoPagoScreen(initialURl: data['data']['link']))!.then((value) async {
        if (value) {
          Get.back();
          walletController.setAmount(walletController.amountController.value.text).then((value) {
            if (value != null) {
              showSnackBarAlert(
                message: "Payment Successful!!".tr,
                color: Colors.green.shade400,
              );
              _refreshAPI();
            }
          });
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
  Future<void> xenditPayment(context, amount, WalletController controller) async {
    await createXenditInvoice(amount: amount, controller: controller).then((model) {
      if (model.id != null) {
        Get.to(() => XenditScreen(
                  initialURl: model.invoiceUrl ?? '',
                  transId: model.id ?? '',
                  apiKey: controller.paymentSettingModel.value.xendit!.key!.toString(),
                ))!
            .then((value) {
          if (value == true) {
            Get.back();
            walletController.setAmount(walletController.amountController.value.text).then((value) {
              if (value != null) {
                showSnackBarAlert(
                  message: "Payment Successful!!".tr,
                  color: Colors.green.shade400,
                );
                _refreshAPI();
              }
            });
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

  Future<XenditModel> createXenditInvoice({required var amount, required WalletController controller}) async {
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

  Future<void> orangeMakePayment({required String amount, required BuildContext context, required WalletController controller}) async {
    reset();

    var paymentURL = await fetchToken(context: context, orderId: DateTime.now().millisecondsSinceEpoch.toString(), amount: amount, currency: 'USD', controller: controller);

    if (paymentURL.toString() != '') {
      Get.to(() => OrangeMoneyScreen(
                initialURl: paymentURL,
                accessToken: accessToken,
                amount: amount,
                orangePay: controller.paymentSettingModel.value.orangePay!,
                orderId: orderId,
                payToken: payToken,
              ))!
          .then((value) {
        if (value == true) {
          Get.back();
          walletController.setAmount(walletController.amountController.value.text).then((value) {
            if (value != null) {
              showSnackBarAlert(
                message: "Payment Successful!!".tr,
                color: Colors.green.shade400,
              );
              _refreshAPI();
            }
          });
        }
      });
    } else {
      Get.back();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Payment Unsuccessful!!".tr),
        backgroundColor: Colors.red,
      ));
    }
  }

  Future fetchToken({required String orderId, required String currency, required BuildContext context, required String amount, required WalletController controller}) async {
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
      return await webpayment(context: context, amountData: amount, currency: currency, orderIdData: orderId, controller: controller);
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

  Future webpayment(
      {required String orderIdData, required BuildContext context, required String currency, required String amountData, required WalletController controller}) async {
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

  Future<void> midtransMakePayment({required String amount, required BuildContext context, required WalletController controller}) async {
    await createPaymentLink(amount: amount, controller: controller).then((url) {
      if (url != '') {
        Get.to(() => MidtransScreen(
                  initialURl: url,
                ))!
            .then((value) async {
          if (value == true) {
            walletController.setAmount(walletController.amountController.value.text).then((value) {
              if (value != null) {
                Get.back();
                showSnackBarAlert(
                  message: "Payment Successful!!".tr,
                  color: Colors.red,
                );
                _refreshAPI();
              }
            });
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

  Future<String> createPaymentLink({required var amount, required WalletController controller}) async {
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
