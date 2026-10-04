import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vwish_domain/vwish_domain.dart';
import 'package:vwish_platform/vwish_platform.dart';
import 'package:vwish_ui_kit/vwish_ui_kit.dart';
import '../controllers/providers.dart';
import '../library/media_picker.dart';

/// Height the bottom control bar occupies above the safe area, plus a small gap.
double playerControlsReserve(BuildContext context) => context.isTouchPlatform ? 118 : 98;

/// Whether this window draws its own [VwishTitleBar] (desktop, outside touch layouts).
bool hasDesktopWindowChrome(BuildContext context) => PlatformBridge.isDesktop && !context.isTouchPlatform;

/// Above the control bar; on short (landscape phone) screens just below the top bar instead, so it
/// can't cover the centre play button.
void showPlayerToast(BuildContext context, String message, {VwishToastKind kind = VwishToastKind.info}) {
  final short = MediaQuery.sizeOf(context).height < 560;
  VwishToast.show(
    context,
    message,
    kind: kind,
    // On desktop the controls' top bar sits under the window title bar and ends at about 84.
    topOffset: short ? (hasDesktopWindowChrome(context) ? VwishTitleBar.height + 52 : 64) : null,
    bottomOffset: playerControlsReserve(context),
  );
}

/// True once something was opened; the engine may report playback before the controller knows the source.
bool playerHasMedia(PlayerState state) =>
    state.currentSource != null || state.status != PlaybackStatus.idle;

/// Picks videos and plays them, or appends them to the queue when [append] is true.
Future<void> openVideoFiles(BuildContext context, WidgetRef ref, {bool append = false}) async {
  final List<MediaRef> refs;
  try {
    refs = await pickVideoRefs();
  } on MediaPickerException catch (e) {
    if (context.mounted) {
      showPlayerToast(context, e.message, kind: VwishToastKind.error);
    }
    return;
  }
  if (refs.isEmpty) return;
  final queueCtrl = ref.read(queueControllerProvider.notifier);
  if (append) {
    await queueCtrl.addToQueue(refs);
  } else {
    await queueCtrl.playFrom(refs);
  }
}

String formatPlaybackDuration(Duration d) {
  final hours = d.inHours;
  final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
}

String formatPlaybackSpeed(double speed) {
  final fixed = speed.toStringAsFixed(2);
  final trimmed = fixed.replaceFirst(RegExp(r'\.?0+$'), '');
  return '${trimmed}x';
}

String playerErrorMessage(PlayerError error) {
  return switch (error) {
    FileNotFound() => "Couldn't find this video. It may have been moved or deleted.",
    UnsupportedFormat() => "This video's format isn't supported.",
    DecoderInitFailed() => 'Hardware decoding failed, so Vwish switched to software decoding.',
    NetworkUnreachable() => "Can't reach this stream. Check your connection and try again.",
    YtdlpFailed() => "Couldn't load this online video. Check the link and try again.",
    PermissionDenied() => "Vwish doesn't have permission to open this video.",
    AudioDeviceLost() => 'The audio device was disconnected.',
    AudioOutputUnavailable() => 'No audio output available',
    PlaybackWarning() || GenericPlayerError() => "Couldn't play this video.",
  };
}

/// Problems playback recovers from are informational, not failures.
VwishToastKind playerErrorToastKind(PlayerError error) => switch (error) {
      AudioOutputUnavailable() || DecoderInitFailed() || PlaybackWarning() => VwishToastKind.info,
      _ => VwishToastKind.error,
    };

/// Orientation policy: phones keep the library upright, the player follows the device (or the
/// orientation the rotate button locked), and tablets rotate freely everywhere.
abstract final class PlayerOrientation {
  static Orientation? _forced;

  /// The player screen currently in charge. A player that is still closing must not undo the
  /// orientation of one opened after it.
  static Object? _owner;

  static StreamSubscription<DeviceOrientation>? _deviceSub;
  static DeviceOrientation _held = DeviceOrientation.portraitUp;

  static bool get _isPhone {
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    return (view.physicalSize / view.devicePixelRatio).shortestSide < 600;
  }

  /// On iPhone the player follows how the phone is held, one orientation at a time. Handing iOS
  /// several orientations at once makes it flash through the last landscape before settling.
  static bool get _followsDevice => defaultTargetPlatform == TargetPlatform.iOS && _isPhone;

  static bool _isLandscape(DeviceOrientation o) =>
      o == DeviceOrientation.landscapeLeft || o == DeviceOrientation.landscapeRight;

  static Future<void> applyAppDefault() =>
      SystemChrome.setPreferredOrientations(_isPhone ? const [DeviceOrientation.portraitUp] : const []);

  static Future<void> enter(Object owner) {
    _owner = owner;
    _forced = null;
    if (_followsDevice) {
      // Stays as it is (upright) until the stream reports the phone is held otherwise.
      _deviceSub ??= PlatformBridge.deviceOrientations.listen(_onDeviceOrientation, onError: (Object _) {});
      return Future<void>.value();
    }
    return SystemChrome.setPreferredOrientations(const []);
  }

  static void _onDeviceOrientation(DeviceOrientation held) {
    // iPhones never show the interface upside down.
    if (held == DeviceOrientation.portraitDown || _owner == null) return;
    _held = held;
    final forced = _forced;
    if (forced != null) {
      // The rotate button's choice holds until the phone is turned to match it.
      if (_isLandscape(held) != (forced == Orientation.landscape)) return;
      _forced = null;
    }
    SystemChrome.setPreferredOrientations([held]);
  }

  /// Flips between portrait and landscape and holds it there regardless of how the device is held.
  static Future<void> toggle(Orientation current) {
    final next = (_forced ?? current) == Orientation.landscape ? Orientation.portrait : Orientation.landscape;
    _forced = next;
    if (next == Orientation.portrait) {
      return SystemChrome.setPreferredOrientations(const [DeviceOrientation.portraitUp]);
    }
    return SystemChrome.setPreferredOrientations(
      _followsDevice
          ? [_isLandscape(_held) ? _held : DeviceOrientation.landscapeLeft]
          : const [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight],
    );
  }

  /// Restoring the app default also rotates a phone back upright, however the player was held.
  /// Does nothing once [owner] has released or another player has entered.
  static Future<void> release(Object owner) {
    if (!identical(_owner, owner)) return Future<void>.value();
    _owner = null;
    _forced = null;
    _deviceSub?.cancel();
    _deviceSub = null;
    return applyAppDefault();
  }
}
