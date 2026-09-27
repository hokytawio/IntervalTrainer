import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Bridge to the native Android foreground service (WorkoutService.kt).
/// Keeps the app alive with the screen locked and shows a notification
/// with a live countdown and Pause / Skip / Stop buttons.
class WorkoutNotification {
  static const _ch = MethodChannel('interval_trainer/service');

  /// Called with 'pause', 'skip' or 'stop' when a notification button is tapped.
  static void Function(String action)? onAction;

  static bool get _supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static bool _initialized = false;

  static void _init() {
    if (_initialized || !_supported) return;
    _initialized = true;
    _ch.setMethodCallHandler((call) async {
      if (call.method == 'action' && call.arguments is String) {
        onAction?.call(call.arguments as String);
      }
      return null;
    });
  }

  static Future<void> _call(String method, [Map<String, Object?>? args]) async {
    if (!_supported) return;
    _init();
    try {
      await _ch.invokeMethod(method, args);
    } on MissingPluginException {
      // Native side not installed (e.g. running in a test): ignore.
    } on PlatformException catch (e) {
      debugPrint('WorkoutNotification.$method failed: ${e.message}');
    }
  }

  /// Asks for notification permission (Android 13+). Safe to call every time.
  static Future<void> requestPermission() => _call('requestNotifications');

  /// [endAt] is when the current phase ends (ms since epoch); the notification
  /// counts down to it by itself, so it doesn't need an update every second.
  static Future<void> start({
    required String title,
    required String text,
    required int endAt,
    bool paused = false,
  }) =>
      _call('start',
          {'title': title, 'text': text, 'endAt': endAt, 'paused': paused});

  static Future<void> update({
    required String title,
    required String text,
    required int endAt,
    bool paused = false,
  }) =>
      _call('update',
          {'title': title, 'text': text, 'endAt': endAt, 'paused': paused});

  static Future<void> stop() => _call('stop');
}
