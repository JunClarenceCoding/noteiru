import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationHelper {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static const _weekdayMap = {
    'Monday': 1, 'Tuesday': 2, 'Wednesday': 3, 'Thursday': 4,
    'Friday': 5, 'Saturday': 6, 'Sunday': 7,
  };

  static Future<void> init() async {
    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(initSettings);

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    // Request notification permission (Android 13+)
    await androidPlugin?.requestNotificationsPermission();

    // Request exact alarm permission (Android 12+) — needed for scheduled weekly reminders
    await androidPlugin?.requestExactAlarmsPermission();
  }

  // Schedules a weekly repeating notification for a given anime
  static Future<void> scheduleWeeklyReminder({
    required int animeId,
    required String animeTitle,
    required String weekday, // "Monday".."Sunday"
  }) async {
    final targetWeekday = _weekdayMap[weekday];
    if (targetWeekday == null) return;

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local, now.year, now.month, now.day, 18, 0, // 6:00 PM on the chosen day
    );

    while (scheduledDate.weekday != targetWeekday || scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

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
          importance: Importance.defaultImportance,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  static Future<void> cancelReminder(int animeId) async {
    await _plugin.cancel(animeId);
  }
}