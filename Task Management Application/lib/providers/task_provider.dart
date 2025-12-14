import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../db/db_helper.dart';
import '../models/task_model.dart';
import '../services/notification_service.dart';

class TaskProvider extends ChangeNotifier {
  List<TaskModel> _tasks = [];
  bool isDark = false;
  String notificationSound = 'default';
  final _db = DBHelper.instance;
  final _notif = NotificationService();

  List<TaskModel> get tasks => _tasks;

  TaskProvider() {
    _init();
  }

  Future<void> _init() async {
    await _loadSettings();
    await _notif.init();
    await loadTasks();
  }

  Future<void> _loadSettings() async {
    final sp = await SharedPreferences.getInstance();
    isDark = sp.getBool('isDark') ?? false;
    notificationSound = sp.getString('notifSound') ?? 'default';
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    isDark = !isDark;
    final sp = await SharedPreferences.getInstance();
    await sp.setBool('isDark', isDark);
    notifyListeners();
  }

  Future<void> setNotificationSound(String id) async {
    notificationSound = id;
    final sp = await SharedPreferences.getInstance();
    await sp.setString('notifSound', id);
    notifyListeners();
  }

  Future<void> loadTasks() async {
    _tasks = await _db.getAllTasks();
    notifyListeners();
  }

  Future<void> addTask(TaskModel t, {bool scheduleNotification = true}) async {
    if (scheduleNotification && t.dueDate.isAfter(DateTime.now())) {
      final nid = await _notif.scheduleNotification(
        title: t.title,
        body: t.description.isEmpty ? 'Task due' : t.description,
        scheduledDate: t.dueDate,
      );
      t.notificationId = nid.toString();
    }

    await _db.insertTask(t);
    await loadTasks();
  }

  Future<void> updateTask(TaskModel t, {bool scheduleNotification = true}) async {
    // Cancel old notification
    try {
      if (t.notificationId.isNotEmpty) {
        final oldId = int.tryParse(t.notificationId) ?? -1;
        if (oldId != -1) await _notif.cancelNotification(oldId);
      }
    } catch (_) {}

    // Schedule new notification
    if (scheduleNotification && t.dueDate.isAfter(DateTime.now()) && !t.isCompleted) {
      final nid = await _notif.scheduleNotification(
        title: t.title,
        body: t.description.isEmpty ? 'Task due' : t.description,
        scheduledDate: t.dueDate,
      );
      t.notificationId = nid.toString();
    } else {
      t.notificationId = '';
    }

    await _db.updateTask(t);
    await loadTasks();
  }

  Future<void> deleteTask(TaskModel t) async {
    try {
      if (t.notificationId.isNotEmpty) {
        final nid = int.tryParse(t.notificationId) ?? -1;
        if (nid != -1) await _notif.cancelNotification(nid);
      }
    } catch (_) {}

    if (t.id != null) await _db.deleteTask(t.id!);
    await loadTasks();
  }

  Future<void> toggleTaskCompletion(TaskModel t) async {
    t.isCompleted = !t.isCompleted;
    t.progress = t.isCompleted ? 1.0 : 0.0;

    try {
      if (t.notificationId.isNotEmpty) {
        final nid = int.tryParse(t.notificationId) ?? -1;
        if (nid != -1) await _notif.cancelNotification(nid);
      }
    } catch (_) {}

    await _db.updateTask(t);
    await loadTasks();
  }

  double computeProgress(TaskModel t) {
    if (t.subtasks.isEmpty) return t.progress;
    final done = t.subtasks.where((s) => s.done).length;
    return done / t.subtasks.length;
  }

  Future<void> updateProgressFromSubtasks(TaskModel t) async {
    t.progress = computeProgress(t);
    await _db.updateTask(t);
    await loadTasks();
  }

  Future<void> completeTask(TaskModel task) async {
    task.isCompleted = true;
    await _db.updateTask(task);

    if (task.repeatType != 'none') {
      await _createNextRepeatTask(task);
    }

    await loadTasks();
  }

  Future<void> _createNextRepeatTask(TaskModel task) async {
    DateTime nextDate = task.dueDate;

    switch (task.repeatType) {
      case 'daily':
        nextDate = nextDate.add(const Duration(days: 1));
        break;
      case 'weekly':
        nextDate = nextDate.add(const Duration(days: 7));
        break;
      case 'custom':
      // Convert repeatDays (String) -> weekday int
        List<int> repeatWeekdays = task.repeatDays.map((d) => _stringToWeekday(d)).toList();

        if (repeatWeekdays.isNotEmpty) {
          int addDays = 1;
          while (addDays <= 7) {
            final checkDate = nextDate.add(Duration(days: addDays));
            if (repeatWeekdays.contains(checkDate.weekday)) {
              nextDate = checkDate;
              break;
            }
            addDays++;
          }
        }
        break;
    }

    TaskModel newTask = TaskModel(
      title: task.title,
      description: task.description,
      dueDate: nextDate,
      repeatType: task.repeatType,
      repeatDays: task.repeatDays,
      subtasks: task.subtasks.map((s) => s.copy()).toList(), // deep copy subtasks
      progress: 0.0,
    );

    await addTask(newTask);
  }

  int _stringToWeekday(String day) {
    switch (day) {
      case 'Mon':
        return DateTime.monday;
      case 'Tue':
        return DateTime.tuesday;
      case 'Wed':
        return DateTime.wednesday;
      case 'Thu':
        return DateTime.thursday;
      case 'Fri':
        return DateTime.friday;
      case 'Sat':
        return DateTime.saturday;
      case 'Sun':
        return DateTime.sunday;
      default:
        return DateTime.monday;
    }
  }

  String _weekdayToString(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Mon';
      case DateTime.tuesday:
        return 'Tue';
      case DateTime.wednesday:
        return 'Wed';
      case DateTime.thursday:
        return 'Thu';
      case DateTime.friday:
        return 'Fri';
      case DateTime.saturday:
        return 'Sat';
      case DateTime.sunday:
        return 'Sun';
      default:
        return '';
    }
  }
}
