import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:nestflow/nestflow.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    await _plugin.initialize(settings: settings);

    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.requestNotificationsPermission();

    _initialized = true;
  }

  // ---------------------------------------------------------------------
  // Todo reminders
  // ---------------------------------------------------------------------
  static const _todoChannel = AndroidNotificationDetails(
    'todo_reminders',
    'Task Reminders',
    channelDescription: 'Reminders for upcoming and overdue tasks',
    importance: Importance.high,
    priority: Priority.high,
    playSound: true,
    enableVibration: true,
  );

  int _upcomingId(int todoId) => todoId * 10 + 1;
  int _overdueId(int todoId) => todoId * 10 + 2;

  Future<void> scheduleTodoReminders(TodoModel todo) async {
    await cancelTodoReminders(todo.id);
    if (todo.dueDate == null || todo.isCompleted) return;

    final now = DateTime.now();
    final due = todo.dueDate!;

    final upcomingTime = due.subtract(const Duration(hours: 3));
    if (upcomingTime.isAfter(now)) {
      await _plugin.zonedSchedule(
        id: _upcomingId(todo.id),
        title: 'Task due soon',
        body: '"${todo.title}" is due soon.',
        scheduledDate: tz.TZDateTime.from(upcomingTime, tz.local),
        notificationDetails: const NotificationDetails(android: _todoChannel, iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true)),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }

    if (due.isAfter(now)) {
      await _plugin.zonedSchedule(
        id: _overdueId(todo.id),
        title: 'Task overdue',
        body: '"${todo.title}" is now overdue.',
        scheduledDate: tz.TZDateTime.from(due, tz.local),
        notificationDetails: const NotificationDetails(android: _todoChannel, iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true)),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } else {
      await _plugin.show(
        id: _overdueId(todo.id),
        title: 'Task overdue',
        body: '"${todo.title}" is overdue.',
        notificationDetails: const NotificationDetails(android: _todoChannel, iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true)),
      );
    }
  }

  Future<void> cancelTodoReminders(int todoId) async {
    await _plugin.cancel(id: _upcomingId(todoId));
    await _plugin.cancel(id: _overdueId(todoId));
  }

  // ---------------------------------------------------------------------
  // Daily transaction report
  // ---------------------------------------------------------------------
  static const _reportChannel = AndroidNotificationDetails(
    'transaction_reports',
    'Transaction Reports',
    channelDescription: 'Daily summaries of your transactions',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
    playSound: true,
    enableVibration: true,
  );

  static const _reportId = 9999;

  Future<void> showTransactionReport(String title, String body) async {
    await _plugin.show(
      id: _reportId,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(android: _reportChannel, iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true)),
    );
  }

  Future<void> refreshDailyTransactionReport({int hour = 20, int minute = 0}) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final totals = await TransactionService().getTotals(
      dateRange: DateTimeRange(start: startOfDay, end: endOfDay),
    );

    const title = "Today's transaction report";
    final body =
        'Income: ${totals.income.amount.toStringAsFixed(2)}   |   Expenses: ${totals.expenses.amount.toStringAsFixed(2)}';

    await _plugin.cancel(id: _reportId);
    var fireTime = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    final nowTz = tz.TZDateTime.now(tz.local);
    if (fireTime.isBefore(nowTz)) fireTime = fireTime.add(const Duration(days: 1));

    await _plugin.zonedSchedule(
      id: _reportId,
      title: title,
      body: body,
      scheduledDate: fireTime,
      notificationDetails: const NotificationDetails(android: _reportChannel, iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true)),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  // ---------------------------------------------------------------------
  // Follow-up notification 10 minutes after any transaction
  // ---------------------------------------------------------------------
  static const _transactionChannel = AndroidNotificationDetails(
    'transaction_followup',
    'Transaction Alerts',
    channelDescription: 'A quick recap shortly after you record a transaction',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
    playSound: true,
    enableVibration: true,
  );

  int _followUpId(DateTime now) => 3000000 + (now.millisecondsSinceEpoch % 900000);

  Future<void> scheduleTransactionFollowUp(TransactionModel transaction) async {
    final now = DateTime.now();
    final sign = transaction.type == TransactionType.income
        ? '+'
        : transaction.type == TransactionType.expenses
            ? '-'
            : '';
    final label = transaction.note?.trim().isNotEmpty == true
        ? transaction.note!.trim()
        : 'your transaction';

    final title = 'Transaction recorded';
    final body = '$sign${transaction.amount.toStringAsFixed(2)} on $label';

    await _plugin.zonedSchedule(
      id: _followUpId(now),
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(now.add(const Duration(minutes: 10)), tz.local),
      notificationDetails: const NotificationDetails(android: _transactionChannel, iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true)),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  // ---------------------------------------------------------------------
  // Daily budget tracking
  // ---------------------------------------------------------------------
  static const _budgetChannel = AndroidNotificationDetails(
    'budget_alerts',
    'Budget Alerts',
    channelDescription: 'Alerts when a budget is close to or over its limit',
    importance: Importance.high,
    priority: Priority.high,
    playSound: true,
    enableVibration: true,
  );

  static const _budgetReportId = 9998;
  static const double _budgetWarningThreshold = 0.8;

  Future<void> refreshDailyBudgetReport({int hour = 21, int minute = 0}) async {
    final now = DateTime.now();

    final budgets = await BudgetService().fetchAll(relations: ['category']);
    final activeAtRisk = budgets.where((b) {
      final isActive = !now.isBefore(b.startDate) && !now.isAfter(b.endDate);
      return isActive && b.amount > 0 && b.progressValue >= _budgetWarningThreshold;
    }).toList();

    await _plugin.cancel(id: _budgetReportId);

    if (activeAtRisk.isEmpty) return;

    final title = activeAtRisk.any((b) => b.progressValue >= 1.0)
        ? 'Budget limit reached'
        : 'Budget getting close';

    final body = activeAtRisk
        .map((b) => '${b.name}: ${(b.progressValue * 100).toStringAsFixed(0)}%')
        .join('   •   ');

    var fireTime = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    final nowTz = tz.TZDateTime.now(tz.local);
    if (fireTime.isBefore(nowTz)) fireTime = fireTime.add(const Duration(days: 1));

    await _plugin.zonedSchedule(
      id: _budgetReportId,
      title: title,
      body: body,
      scheduledDate: fireTime,
      notificationDetails: const NotificationDetails(android: _budgetChannel, iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true)),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }
}
