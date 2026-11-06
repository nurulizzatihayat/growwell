import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class GrowthReminders {
  static const _channel = MethodChannel('growwell/growth_reminders');
  static final _notifications = FlutterLocalNotificationsPlugin();
  static bool get supported => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static Future<void> cancelLegacy() async {
    if (!supported) return;
    try {
      await _notifications.initialize(settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher')));
      await _notifications.cancel(id: 731002);
    } catch (_) {
      // The new reminder is scheduled separately; retry on the next launch.
    }
  }

  static Future<bool> schedule({required int childId, required String childName, required String latestDate}) async {
    if (!supported) return false;
    await _notifications.initialize(settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher')));
    // Remove the old fixed-date reminder if it was enabled previously.
    await _notifications.cancel(id: 731002);
    final android = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final allowed = await android?.requestNotificationsPermission();
    await _channel.invokeMethod<void>('schedule', {'childId': childId, 'name': childName, 'date': latestDate});
    return allowed != false;
  }
}
