import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(settings: initSettings);

    final androidImplementation =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
    }
  }

  static Future<void> showTestNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'study_reminders_channel',
      'Study Reminders',
      channelDescription: 'Hourly reminders for pending study tasks',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _notifications.show(
      id: 999,
      title: 'Notification System Verified! 🔔',
      body:
          'Study Brahmastra notifications are active and working correctly on your device.',
      notificationDetails: notificationDetails,
    );
  }

  static Future<void> scheduleHourlyReminder(int pendingCount) async {
    await _notifications.cancel(id: 0);

    if (pendingCount == 0) return;

    const androidDetails = AndroidNotificationDetails(
      'study_reminders_channel',
      'Study Reminders',
      channelDescription: 'Hourly reminders for pending study tasks',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _notifications.periodicallyShow(
      id: 0,
      title: 'Study Brahmastra Reminder 📚',
      body:
          'You have $pendingCount pending study task(s). Keep up the momentum!',
      repeatInterval: RepeatInterval.hourly,
      notificationDetails: notificationDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }
}
