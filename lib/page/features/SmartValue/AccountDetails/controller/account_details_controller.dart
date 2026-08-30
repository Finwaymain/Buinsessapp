import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../../../../constant/constant.dart';
import '../../../../../constant/logdata.dart';
import '../../../../../constant/show_toast_dialog.dart';
import '../../../../../controller/wallet_controller.dart';
import '../../../../../model/user_model.dart';
import '../../../../../service/api.dart';
import '../../../../../utils/Preferences.dart';
import '../model/account_details_model.dart';

class AccountDetailsController extends GetxController with GetTickerProviderStateMixin {
  AccountDetailsController({this.popOnError = true});

  final bool popOnError;

  var isFront = true.obs;
  var isLoading = false.obs;
  Rx<AccountDetailsModel?> accountDetailsModel = Rx<AccountDetailsModel?>(null);

  var liveWalletAmount = 0.0.obs;
  var liveEarnAmount = 0.0.obs;

  late AnimationController flipController;
  late AnimationController shimmerController;
  late Animation<double> flipAnimation;
  late Animation<double> shimmerAnimation;

  void resetCardState() {
    isFront.value = true;
    if (flipController.isAnimating) {
      flipController.stop();
    }
    flipController.value = 0;
  }

  @override
  void onInit() {
    super.onInit();

    flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    flipAnimation = Tween<double>(begin: 0, end: pi).animate(
      CurvedAnimation(parent: flipController, curve: Curves.easeInOut),
    );

    shimmerAnimation = Tween<double>(begin: -1, end: 2).animate(
      CurvedAnimation(parent: shimmerController, curve: Curves.easeInOut),
    );

    resetCardState();
    _applyCachedProfile();
    isLoading.value = accountDetailsModel.value == null;

    fetchLiveWallet();

    final acNo = Constant.getUserData().userData?.acNo;
    if (acNo != null && acNo.isNotEmpty) {
      getAccountDetails(acNo);
    } else {
      isLoading.value = false;
    }
  }

  Future<void> fetchLiveWallet() async {
    final userId = Preferences.getInt(Preferences.userId);
    if (userId <= 0) return;

    if (Get.isRegistered<WalletController>()) {
      final wCtrl = Get.find<WalletController>();
      if (wCtrl.walletAmount.value > 0 || wCtrl.earnAmount.value > 0) {
        liveWalletAmount.value = wCtrl.walletAmount.value;
        liveEarnAmount.value = wCtrl.earnAmount.value;
      }
    }

    try {
      final acNo = Constant.getUserData().userData?.acNo;
      final response = await http.post(
        Uri.parse(API.showWalletAmount),
        headers: API.header,
        body: jsonEncode({
          'ac_no': acNo ?? '',
          'user_id': userId,
          'driver_id': userId,
          'user_type': 'driver',
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body['res'] == 'success' && body['data'] != null) {
          final amt = double.tryParse(body['data']['amount']?.toString() ?? body['data']['wallet_amount']?.toString() ?? '0') ?? 0.0;
          final earned = double.tryParse(body['data']['earn_amount']?.toString() ?? body['data']['total_earnings']?.toString() ?? '0') ?? 0.0;
          liveWalletAmount.value = amt;
          liveEarnAmount.value = earned;
          return;
        }
      }
    } catch (_) {}

    try {
      final response = await http.get(
        Uri.parse("${API.wallet}?id_user=$userId&user_cat=driver"),
        headers: API.header,
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body['success'] == 'success' && body['data'] != null) {
          final amt = double.tryParse(body['data']['amount']?.toString() ?? '0') ?? 0.0;
          final earned = double.tryParse(body['data']['earn_amount']?.toString() ?? '0') ?? 0.0;
          liveWalletAmount.value = amt;
          liveEarnAmount.value = earned;
        }
      }
    } catch (_) {}
  }

  void flipCard() {
    if (isFront.value) {
      flipController.forward();
    } else {
      flipController.reverse();
    }
    isFront.value = !isFront.value;
  }

  String get holderName {
    final name = _profile()?.getFullName() ?? '';
    if (name.isNotEmpty) return name;

    final user = Constant.getUserData().userData;
    final fallback = '${user?.prenom ?? ''} ${user?.nom ?? ''}'.trim();
    return fallback.isNotEmpty ? fallback : 'N/A';
  }

  String get mobile => _profile()?.phone ?? 'N/A';
  String get accountNumber => _profile()?.acNo ?? 'N/A';
  String get expDays => _profile()?.getDaysToStart()?.toString() ?? '0';
  String get expDate => _profile()?.getFormattedStartDate() ?? '00/00';

  String get accountType {
    final status = _profile()?.statut;
    return status == 'yes' ? 'Active Account' : 'Inactive Account';
  }

  String get cardType => 'PLATINUM';
  String get bank => 'Smart Value';
  String get cvv => _profile()?.mPin ?? '00/00';

  String get amount {
    if (liveWalletAmount.value > 0) {
      return liveWalletAmount.value.toStringAsFixed(2);
    }
    final rawAmt = _profile()?.amount;
    if (rawAmt != null && rawAmt.trim().isNotEmpty && rawAmt != 'null') {
      final parsed = double.tryParse(rawAmt) ?? 0.0;
      if (parsed > 0) return parsed.toStringAsFixed(2);
    }
    if (Get.isRegistered<WalletController>()) {
      final wCtrl = Get.find<WalletController>();
      if (wCtrl.walletAmount.value > 0) {
        return wCtrl.walletAmount.value.toStringAsFixed(2);
      }
    }
    final cached = Constant.getUserData().userData?.amount;
    if (cached != null && cached.trim().isNotEmpty && cached != 'null') {
      final parsed = double.tryParse(cached) ?? 0.0;
      if (parsed > 0) return parsed.toStringAsFixed(2);
    }
    return '0.00';
  }

  String get earnAmount {
    if (liveEarnAmount.value > 0) {
      return liveEarnAmount.value.toStringAsFixed(2);
    }
    final val = _profile()?.earnAmount;
    if (val != null && val.trim().isNotEmpty && val != 'null') {
      final parsed = double.tryParse(val) ?? 0.0;
      if (parsed > 0) return parsed.toStringAsFixed(2);
    }
    if (Get.isRegistered<WalletController>()) {
      final wCtrl = Get.find<WalletController>();
      if (wCtrl.earnAmount.value > 0) {
        return wCtrl.earnAmount.value.toStringAsFixed(2);
      }
    }
    final cached = Constant.getUserData().userData?.earnAmount;
    if (cached != null && cached.trim().isNotEmpty && cached != 'null') {
      final parsed = double.tryParse(cached) ?? 0.0;
      if (parsed > 0) return parsed.toStringAsFixed(2);
    }
    return "0.00";
  }

  bool get hasCashback => cashbackText.isNotEmpty;

  String get cashbackText {
    final profileData = _profile();
    
    // 1. Try percentage / perSender from driver profile / schedules
    String rawVal = profileData?.percentage?.trim() ?? '';
    if (rawVal.isEmpty || rawVal == '0' || rawVal == '0.0' || rawVal == '0.00' || rawVal == 'null') {
      rawVal = profileData?.perSender?.trim() ?? '';
    }
    
    // 2. Check driver's active subscription plan cashback
    if (rawVal.isEmpty || rawVal == '0' || rawVal == '0.0' || rawVal == '0.00' || rawVal == 'null') {
      final user = Constant.getUserData().userData;
      if (user?.percentage != null &&
          user!.percentage!.trim().isNotEmpty &&
          user.percentage != '0' &&
          user.percentage != '0.0' &&
          user.percentage != '0.00' &&
          user.percentage != 'null') {
        rawVal = user.percentage!.trim();
      }
    }

    if (rawVal.isEmpty || rawVal == '0' || rawVal == '0.0' || rawVal == '0.00' || rawVal == 'null') {
      return '';
    }

    // If already contains % symbol
    if (rawVal.contains('%')) {
      final clean = rawVal.replaceAll('Cashback', '').replaceAll('cashback', '').trim();
      return '$clean Cashback';
    }

    // If contains rupee symbol or Rs or starts with ₹
    if (rawVal.contains('₹') || rawVal.toLowerCase().contains('rs')) {
      final clean = rawVal.replaceAll('Cashback', '').replaceAll('cashback', '').trim();
      return '$clean Cashback';
    }

    // Parse numeric value
    final numVal = double.tryParse(rawVal);
    if (numVal != null) {
      if (numVal <= 0) return '';
      final formattedNum = (numVal % 1 == 0) ? numVal.toInt().toString() : numVal.toString();
      // If admin entered a flat amount (like 50, 100, 25) or > 10
      if (numVal > 10) {
        return '₹$formattedNum Cashback';
      }
      // If <= 10, by default it is a percentage (e.g. 1%, 2%, 5%)
      return '$formattedNum% Cashback';
    }

    return '$rawVal Cashback';
  }

  Map<String, dynamic> _userJson(UserData user) => {
        'id': user.id,
        'ac_no': user.acNo,
        'nom': user.nom,
        'prenom': user.prenom,
        'holder_name': '${user.prenom ?? ''} ${user.nom ?? ''}'.trim(),
        'phone': user.phone,
        'm_pin': user.mPin,
        'statut': user.statut,
        'amount': user.amount,
        'earn_amount': user.earnAmount,
        'start_date': user.startDate,
      };

  AccountData? _profile() {
    if (accountDetailsModel.value?.data != null) {
      return accountDetailsModel.value!.data;
    }
    final user = Constant.getUserData().userData;
    if (user == null) return null;
    return AccountData.fromJson(_userJson(user));
  }

  void _applyCachedProfile() {
    final user = Constant.getUserData().userData;
    if (user == null) return;

    accountDetailsModel.value = AccountDetailsModel(
      res: 'success',
      msg: 'Cached profile',
      data: AccountData.fromJson(_userJson(user)),
    );
  }

  Future<AccountDetailsModel?> getAccountDetails(String accountNumber) async {
    final showBlockingLoader = accountDetailsModel.value == null;
    if (showBlockingLoader) {
      isLoading.value = true;
    }

    try {
      final response = await http
          .post(
            Uri.parse(API.accountDetails),
            headers: API.header,
            body: jsonEncode({'ac_no': accountNumber}),
          )
          .timeout(const Duration(seconds: 30));

      showLog('getAccountDetails => ${response.body}');

      if (response.statusCode == 200) {
        final model = AccountDetailsModel.fromJson(json.decode(response.body));
        if (model.res == 'success') {
          accountDetailsModel.value = model;
          isLoading.value = false;
          return model;
        }

        _applyCachedProfile();
        isLoading.value = false;
        if (popOnError) {
          Get.back();
          ShowToastDialog.showToast(model.msg ?? 'Account not found', isError: true);
        }
        return accountDetailsModel.value;
      }

      _applyCachedProfile();
      isLoading.value = false;
      if (popOnError) ShowToastDialog.showToast('Server error. Please try again.');
      return accountDetailsModel.value;
    } on TimeoutException catch (e) {
      _applyCachedProfile();
      isLoading.value = false;
      showLog('getAccountDetails timeout :: $e');
      if (popOnError) ShowToastDialog.showToast('Request timeout. Please try again.');
      return accountDetailsModel.value;
    } on SocketException catch (e) {
      _applyCachedProfile();
      isLoading.value = false;
      showLog('getAccountDetails socket :: $e');
      if (popOnError) ShowToastDialog.showToast('Network error. Please check your connection.');
      return accountDetailsModel.value;
    } catch (e) {
      _applyCachedProfile();
      isLoading.value = false;
      showLog('getAccountDetails error :: $e');
      if (popOnError) ShowToastDialog.showToast('Failed to fetch account details. Please try again.');
      return accountDetailsModel.value;
    }
  }

  String get totalAmount {
    try {
      final amt = double.tryParse(amount) ?? 0.0;
      final earned = double.tryParse(earnAmount) ?? 0.0;
      final total = amt + earned;
      if (total > 0) {
        return total.toStringAsFixed(2);
      }
      if (amt > 0) return amt.toStringAsFixed(2);
      if (earned > 0) return earned.toStringAsFixed(2);
      return '0.00';
    } catch (_) {
      return '0.00';
    }
  }

  @override
  void onClose() {
    flipController.dispose();
    shimmerController.dispose();
    super.onClose();
  }
}
