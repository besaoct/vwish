import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vwish_domain/vwish_domain.dart';

class SessionRepository {
  final SharedPreferences _prefs;

  SessionRepository(this._prefs);

  static const _kResumePrefix = 'vwish_resume_';
  static const _kSubtitleDelayPrefix = 'vwish_sub_delay_';
  static const _kAudioDelayPrefix = 'vwish_audio_delay_';
  static const _kVideoAdjustPrefix = 'vwish_video_adjust_';
  static const _kGlobalVolume = 'vwish_global_volume';
  static const _kGlobalSpeed = 'vwish_global_speed';

  /// Save playback resume position for media ID
  Future<void> saveResumePosition(String mediaId, Duration position, Duration duration) async {
    // If within last 15s or 98% completed, clear resume (consider finished)
    if (duration > Duration.zero && (duration - position < const Duration(seconds: 15) || position.inMilliseconds / duration.inMilliseconds > 0.98)) {
      await _prefs.remove('$_kResumePrefix$mediaId');
      return;
    }

    // Only save if played at least 5s
    if (position.inSeconds >= 5) {
      await _prefs.setInt('$_kResumePrefix$mediaId', position.inMilliseconds);
    }
  }

  /// Retrieve saved resume position
  Duration? getResumePosition(String mediaId, Duration duration) {
    final ms = _prefs.getInt('$_kResumePrefix$mediaId');
    if (ms == null) return null;
    final pos = Duration(milliseconds: ms);
    if (duration > Duration.zero && pos >= duration) return null;
    return pos;
  }

  /// Subtitle delay sync per media
  Future<void> saveSubtitleDelay(String mediaId, Duration delay) async {
    await _prefs.setInt('$_kSubtitleDelayPrefix$mediaId', delay.inMilliseconds);
  }

  Duration getSubtitleDelay(String mediaId) {
    final ms = _prefs.getInt('$_kSubtitleDelayPrefix$mediaId');
    return ms != null ? Duration(milliseconds: ms) : Duration.zero;
  }

  /// Audio delay sync per media
  Future<void> saveAudioDelay(String mediaId, Duration delay) async {
    await _prefs.setInt('$_kAudioDelayPrefix$mediaId', delay.inMilliseconds);
  }

  Duration getAudioDelay(String mediaId) {
    final ms = _prefs.getInt('$_kAudioDelayPrefix$mediaId');
    return ms != null ? Duration(milliseconds: ms) : Duration.zero;
  }

  /// Video color adjustments per media
  Future<void> saveVideoAdjust(String mediaId, VideoAdjust adjust) async {
    await _prefs.setString('$_kVideoAdjustPrefix$mediaId', jsonEncode(adjust.toJson()));
  }

  VideoAdjust getVideoAdjust(String mediaId) {
    final raw = _prefs.getString('$_kVideoAdjustPrefix$mediaId');
    if (raw == null) return VideoAdjust.normal;
    try {
      return VideoAdjust.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return VideoAdjust.normal;
    }
  }

  /// Global volume setting
  Future<void> saveGlobalVolume(double volume) async {
    await _prefs.setDouble(_kGlobalVolume, volume);
  }

  double getGlobalVolume() {
    return _prefs.getDouble(_kGlobalVolume) ?? 100.0;
  }

  /// Global playback speed
  Future<void> saveGlobalSpeed(double speed) async {
    await _prefs.setDouble(_kGlobalSpeed, speed);
  }

  double getGlobalSpeed() {
    return _prefs.getDouble(_kGlobalSpeed) ?? 1.0;
  }
}
