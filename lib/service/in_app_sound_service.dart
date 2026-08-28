import 'dart:developer';
import 'package:audioplayers/audioplayers.dart';

class InAppSoundService {
  static AudioPlayer? _player;

  static AudioPlayer get _audioPlayer {
    _player ??= AudioPlayer();
    return _player!;
  }

  static Future<void> playIncomingBookingAlert() async {
    try {
      await _audioPlayer.stop();

      try {
        await _audioPlayer.setAudioContext(
          AudioContext(
            android: const AudioContextAndroid(
              isSpeakerphoneOn: true,
              stayAwake: true,
              contentType: AndroidContentType.sonification,
              usageType: AndroidUsageType.alarm,
              audioFocus: AndroidAudioFocus.gainTransientExclusive,
            ),
            iOS: AudioContextIOS(
              category: AVAudioSessionCategory.playback,
              options: const {
                AVAudioSessionOptions.defaultToSpeaker,
              },
            ),
          ),
        );
      } catch (ctxErr) {
        log("InAppSoundService setAudioContext error: $ctxErr");
      }

      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.setReleaseMode(ReleaseMode.stop);
      await _audioPlayer.play(AssetSource('audio/incoming_booking_request.mp3'));
    } catch (e) {
      log("InAppSoundService playIncomingBookingAlert error: $e");
    }
  }

  static Future<void> stop() async {
    try {
      if (_player != null) {
        await _player!.stop();
      }
    } catch (e) {
      log("InAppSoundService stop error: $e");
    }
  }
}
