import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../screens/view_task_screen.dart';
import '../db/db_helper.dart';
import '../models/task_model.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  static const String channelName = 'Task Notifications';
  static const String channelDescription = 'Reminders for your tasks';

  // ✅ Initialize the notification service
  Future<void> init() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Karachi'));

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final initSettings =
    InitializationSettings(android: androidInit, iOS: iosInit);

    await flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        if (response.payload != null && response.payload!.isNotEmpty) {
          _handleNotificationTap(response.payload!);
        }
      },
    );

    // Request notification permission
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }

    // Create initial channel for default sound
    await _createOrUpdateChannel();
  }

  // ✅ Handle notification tap
  Future<void> _handleNotificationTap(String payload) async {
    if (payload.startsWith('task:')) {
      final parts = payload.split(':');
      if (parts.length > 1) {
        final taskId = int.tryParse(parts[1]);
        if (taskId != null && navigatorKey.currentState != null) {
          // Load task from database
          final task = await DBHelper.instance.getTaskById(taskId);
          if (task != null) {
            navigatorKey.currentState!.push(
              MaterialPageRoute(
                builder: (_) => ViewTaskScreen(task: task),
              ),
            );
          }
        }
      }
    }
  }

  // ✅ Create or update channel with selected sound
  Future<void> _createOrUpdateChannel({String? soundName}) async {
    final prefs = await SharedPreferences.getInstance();
    final chosenSound = soundName ?? prefs.getString('notificationSound') ?? 'ding';
    final channelId = 'task_channel_$chosenSound';

    final androidChannel = AndroidNotificationChannel(
      channelId,
      channelName,
      description: channelDescription,
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound(chosenSound),
    );

    final androidPlugin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    // Delete old channels (except new one)
    final channels = await androidPlugin?.getNotificationChannels();
    if (channels != null) {
      for (var ch in channels) {
        if (ch.id.startsWith('task_channel_') && ch.id != channelId) {
          await androidPlugin?.deleteNotificationChannel(ch.id);
        }
      }
    }

    await androidPlugin?.createNotificationChannel(androidChannel);
  }

  // ✅ Update sound dynamically (call after user changes sound)
  Future<void> updateNotificationSound(String soundName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('notificationSound', soundName);
    await _createOrUpdateChannel(soundName: soundName);
  }

  // ✅ Schedule notification
  Future<int> scheduleNotification({
    required String title,
    required String body,
    required DateTime scheduledDate,
    required int taskId,
    String? sound,
  }) async {
    if (scheduledDate.isBefore(DateTime.now())) return -1;

    final prefs = await SharedPreferences.getInstance();
    final chosenSound = sound ?? prefs.getString('notificationSound') ?? 'ding';
    final channelId = 'task_channel_$chosenSound';

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound(chosenSound),
    );

    final iosDetails = DarwinNotificationDetails(sound: '$chosenSound.mp3');

    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'task:$taskId',
    );

    return id;
  }

  // ✅ Cancel a scheduled notification
  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  // ✅ Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  // ✅ Preview sound immediately (for settings screen)
  Future<void> previewSound(String soundName) async {
    final androidDetails = AndroidNotificationDetails(
      'preview_channel_$soundName',
      'Preview Channel',
      channelDescription: 'Sound preview',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound(soundName),
    );

    final iosDetails = DarwinNotificationDetails(sound: '$soundName.mp3');

    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch % 10000,
      '🔔 Sound Preview',
      'Playing "$soundName"',
      NotificationDetails(android: androidDetails, iOS: iosDetails),
    );
  }
}
