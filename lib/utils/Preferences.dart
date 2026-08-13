// ignore_for_file: file_names

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

  static late SharedPreferences pref;

  static Future<void> setUserData(UserModel userModel) async {
    await pref.setString(user, jsonEncode(userModel));
  }

  static Future<void> initPref() async {
    pref = await SharedPreferences.getInstance();
  }

  static bool getBoolean(String key) {
    return pref.getBool(key) ?? false;
  }

  static Future<void> setBoolean(String key, bool value) async {
    await pref.setBool(key, value);
  }

  static String getString(String key) {
    try {
      final val = pref.get(key);
      if (val == null) return "";
      return val.toString();
    } catch (_) {
      return "";
    }
  }

  static Future<void> setString(String key, String value) async {
    await pref.setString(key, value);
  }

  static Future<void> clearSharPreference() async {
    await pref.clear();
  }

  static Future<void> clearKeyData(String key) async {
    await pref.remove(key);
  }

  static int getInt(String key) {
    try {
      final val = pref.get(key);
      if (val == null) return 0;
      if (val is int) return val;
      return int.tryParse(val.toString()) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  static Future<void> setInt(String key, int value) async {
    await pref.setInt(key, value);
  }
}
