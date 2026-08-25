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

  static String build(
    String path, {
    Map<String, String> extra = const {},
  }) {
    final params = <String, String>{
      'accesstoken': accessToken(),
      'driver_id': driverId(),
      'id_driver': driverId(),
      'phone': phone(),
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
