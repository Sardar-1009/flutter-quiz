import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // Инициализируем таймзоны для правильного расписания
    tz.initializeTimeZones();
    // По умолчанию ставим местную зону (по вашему времени)
    // Можно использовать 'Asia/Almaty' или 'Asia/Bishkek' 
    tz.setLocalLocation(tz.getLocation('Asia/Almaty'));

    const AndroidInitializationSettings androidInitSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosInitSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidInitSettings,
      iOS: iosInitSettings,
    );

    await _localNotifications.initialize(settings: initSettings);

    // Запрашиваем права для Android 13+ (POST_NOTIFICATIONS)
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // Запрашиваем права на точные будильники (Android 12+)
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestExactAlarmsPermission();

    // Планируем уведомления
    await _scheduleDailyNotifications();
  }

  Future<void> _scheduleDailyNotifications() async {
    // Сначала отменяем все старые, чтобы не плодить дубликаты
    await _localNotifications.cancelAll();

    // 1. Утро
    await _scheduleDaily(
      id: 1,
      hour: 9,
      minute: 0,
      title: 'Доброе утро! ☀️',
      body: 'Пора размять мозги. Ждем тебя в приложении!',
    );

    // 2. Обед
    await _scheduleDaily(
      id: 2,
      hour: 13,
      minute: 0,
      title: 'Обеденный перерыв 🍔',
      body: 'Отличное время для парочки вопросов по Flutter.',
    );

    // 3. После обеда
    await _scheduleDaily(
      id: 3,
      hour: 16,
      minute: 30,
      title: 'Небольшая пауза ☕',
      body: 'Пора поучиться! Новые тесты уже ждут.',
    );

    // 4. Вечер
    await _scheduleDaily(
      id: 4,
      hour: 20,
      minute: 0,
      title: 'Вечерняя тренировка 🧠',
      body: 'Проверь свои знания перед сном.',
    );

    // 5. Выходные (только по субботам)
    await _scheduleWeekly(
      id: 5,
      day: DateTime.saturday,
      hour: 11,
      minute: 0,
      title: 'Выходные с пользой 💻',
      body: 'Не повод забывать про код! Давай пройдем один квиз.',
    );
  }

  Future<void> _scheduleDaily({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    await _localNotifications.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: _nextInstanceOfTime(hour, minute),
      notificationDetails: _notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> _scheduleWeekly({
    required int id,
    required int day,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    await _localNotifications.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: _nextInstanceOfDayAndTime(day, hour, minute),
      notificationDetails: _notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  NotificationDetails _notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'quiz_reminders', // ID канала
        'Напоминания об учебе', // Имя канала
        channelDescription: 'Уведомления с призывом пройти тесты',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  tz.TZDateTime _nextInstanceOfDayAndTime(int day, int hour, int minute) {
    tz.TZDateTime scheduledDate = _nextInstanceOfTime(hour, minute);
    while (scheduledDate.weekday != day) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}
