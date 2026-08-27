import 'dart:convert';
import 'package:cabme_driver/model/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Preferences {
  static const isFinishOnBoardingKey = "isFinishOnBoardingKeyData";
  static const languageCodeKey = "languageCodeKey";
  static const isLogin = "isLogin";
  static const user = "userData";
  static const userId = "userId";
  static const accesstoken = "accesstoken";
  static const admincommission = "admincommission";
  static const documentVerified = 'documentVerified';
  static const admincommissiontype = "admincommissiontype";
  static const paymentSetting = "paymentSetting";
  static const walletBalance = "walletBalance";
  static const driverCategoryId = "driverCategoryId";

  static SharedPreferences? _pref;

  static Future<void> setUserData(UserModel userModel) async {
    if (_pref != null) await _pref!.setString(user, jsonEncode(userModel));
  }

  static Future<void> initPref() async {
    try {
      _pref = await SharedPreferences.getInstance();
    } catch (_) {}
  }

  static bool getBoolean(String key) {
    if (_pref == null) return false;
    try {
      return _pref!.getBool(key) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> setBoolean(String key, bool value) async {
    if (_pref != null) await _pref!.setBool(key, value);
  }

  static String getString(String key) {
    if (_pref == null) return "";
    try {
      final val = _pref!.get(key);
      if (val == null) return "";
      return val.toString();
    } catch (_) {
      return "";
    }
  }

  static Future<void> setString(String key, String value) async {
    if (_pref != null) await _pref!.setString(key, value);
  }

  static Future<void> clearSharPreference() async {
    if (_pref != null) await _pref!.clear();
  }

  static Future<void> clearKeyData(String key) async {
    if (_pref != null) await _pref!.remove(key);
  }

  static int getInt(String key) {
    if (_pref == null) return 0;
    try {
      final val = _pref!.get(key);
      if (val == null) return 0;
      if (val is int) return val;
      return int.tryParse(val.toString()) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  static Future<void> setInt(String key, int value) async {
    if (_pref != null) await _pref!.setInt(key, value);
  }
}
