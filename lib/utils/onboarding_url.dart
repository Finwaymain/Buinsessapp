import 'dart:convert';
import 'package:cabme_driver/constant/constant.dart';
import 'package:cabme_driver/utils/Preferences.dart';

class OnboardingUrl {
  static const String baseHost = 'https://api.fiinway.com';

  static String accessToken() {
    final fromPrefs = Preferences.getString(Preferences.accesstoken);
    if (fromPrefs.isNotEmpty) return fromPrefs;
    return Constant.getUserData().userData?.accesstoken ?? '';
  }

  static String driverId() {
    final fromPrefs = Preferences.getInt(Preferences.userId);
    if (fromPrefs != 0) return fromPrefs.toString();
    final strId = Preferences.getString(Preferences.userId);
    if (strId.isNotEmpty && strId != "0") return strId;
    return Constant.getUserData().userData?.id ?? '';
  }

  static String phone() {
    final fromUser = Constant.getUserData().userData?.phone ?? '';
    if (fromUser.isNotEmpty) return fromUser;
    final userStr = Preferences.getString(Preferences.user);
    if (userStr.isNotEmpty) {
      try {
        final map = jsonDecode(userStr);
        return (map['phone'] ?? map['userData']?['phone'] ?? '').toString();
      } catch (_) {}
    }
    return '';
  }

  static String driverName() {
    final user = Constant.getUserData().userData;
    if (user != null) {
      final prenom = user.prenom ?? '';
      final nom = user.nom ?? '';
      final full = '$prenom $nom'.trim();
      if (full.isNotEmpty) return full;
    }
    final userStr = Preferences.getString(Preferences.user);
    if (userStr.isNotEmpty) {
      try {
        final map = jsonDecode(userStr);
        final name = (map['name'] ?? map['userData']?['name'] ?? map['prenom'] ?? map['userData']?['prenom'] ?? '').toString();
        if (name.isNotEmpty) return name;
      } catch (_) {}
    }
    return '';
  }

  static String walletBalance() {
    final user = Constant.getUserData().userData;
    if (user != null && user.amount != null) {
      return user.amount.toString();
    }
    final userStr = Preferences.getString(Preferences.user);
    if (userStr.isNotEmpty) {
      try {
        final map = jsonDecode(userStr);
        final amt = (map['amount'] ?? map['userData']?['amount'] ?? '').toString();
        if (amt.isNotEmpty) return amt;
      } catch (_) {}
    }
    return '0';
  }

  static String pocketNumber() {
    final user = Constant.getUserData().userData;
    if (user != null && (user.acNo?.isNotEmpty ?? false)) {
      return user.acNo!;
    }
    final userStr = Preferences.getString(Preferences.user);
    if (userStr.isNotEmpty) {
      try {
        final map = jsonDecode(userStr);
        final ac = (map['ac_no'] ?? map['userData']?['ac_no'] ?? map['pocket_number'] ?? map['userData']?['pocket_number'] ?? '').toString();
        if (ac.isNotEmpty) return ac;
      } catch (_) {}
    }
    return '';
  }

  static String build(
    String path, {
    Map<String, String> extra = const {},
  }) {
    final params = <String, String>{
      'accesstoken': accessToken(),
      'token': accessToken(),
      'driver_id': driverId(),
      'id_driver': driverId(),
      'user_id': driverId(),
      'id_user': driverId(),
      'phone': phone(),
      'mobile': phone(),
      'name': driverName(),
      'username': driverName(),
      'customer_name': driverName(),
      'wallet_balance': walletBalance(),
      'balance': walletBalance(),
      'pocket_number': pocketNumber(),
      'ac_no': pocketNumber(),
      'acNo': pocketNumber(),
      'user_type': 'driver',
      'user_cat': 'driver',
      ...extra,
    };

    final query = params.entries
        .where((entry) => entry.value.isNotEmpty)
        .map(
          (entry) =>
              '${Uri.encodeComponent(entry.key)}=${Uri.encodeComponent(entry.value)}',
        )
        .join('&');

    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return query.isEmpty ? '$baseHost$normalizedPath' : '$baseHost$normalizedPath?$query';
  }
}
