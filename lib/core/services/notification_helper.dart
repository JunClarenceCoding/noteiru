import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:flutter_timezone/flutter_timezone.dart';

class NotificationHelper {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static const _weekdayMap = {
    'Monday': 1, 'Tuesday': 2, 'Wednesday': 3, 'Thursday': 4,
    'Friday': 5, 'Saturday': 6, 'Sunday': 7,
  };

  static Future<void> init() async {
    tz_data.initializeTimeZones();

    final String currentTimeZone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(currentTimeZone));

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(initSettings);

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.requestExactAlarmsPermission();
  }

  static Future<void> scheduleWeeklyReminder({
    required int animeId,
    required String animeTitle,
    required String weekday,
    String? time, // "HH:mm" format, defaults to 08:00 if null
  }) async {
    final targetWeekday = _weekdayMap[weekday];
    if (targetWeekday == null) return;

    int hour = 8;
    int minute = 0;
    if (time != null) {
      final parts = time.split(':');
      hour = int.tryParse(parts[0]) ?? 8;
      minute = int.tryParse(parts[1]) ?? 0;
    }

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local, now.year, now.month, now.day, hour, minute,
    );

    while (scheduledDate.weekday != targetWeekday || scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    try {
      await _plugin.zonedSchedule(
        animeId,
        'New episode reminder',
        'It might be time for a new episode of $animeTitle!',
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'anime_reminders',
            'Anime reminders',
            channelDescription: 'Weekly reminders for anime release days',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e, stack) {
      debugPrint('Failed to schedule notification: $e');
      debugPrint('$stack');
    }
  }

  static Future<void> cancelReminder(int animeId) async {
    await _plugin.cancel(animeId);
  }
}