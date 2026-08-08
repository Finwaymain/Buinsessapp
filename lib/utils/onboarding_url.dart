import 'package:cabme_driver/constant/constant.dart';
import 'package:cabme_driver/utils/Preferences.dart';

class OnboardingUrl {
  static const String baseHost = 'https://fiinway.online';

  static String accessToken() {
    final fromPrefs = Preferences.getString(Preferences.accesstoken);
    if (fromPrefs.isNotEmpty) return fromPrefs;
    return Constant.getUserData().userData?.accesstoken ?? '';
  }

  static String driverId() {
    final fromPrefs = Preferences.getInt(Preferences.userId);
    if (fromPrefs != 0) return fromPrefs.toString();
    return Constant.getUserData().userData?.id ?? '';
  }

  static String build(
    String path, {
    Map<String, String> extra = const {},
  }) {
    final params = <String, String>{
      'accesstoken': accessToken(),
      'driver_id': driverId(),
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
