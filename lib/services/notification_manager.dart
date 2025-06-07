import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction.dart';
import '../services/notification_service.dart';

class NotificationManager {
  static final NotificationManager _instance = NotificationManager._internal();
  factory NotificationManager() => _instance;
  NotificationManager._internal();

  final NotificationService _notificationService = NotificationService();

  /// 初始化通知管理器
  Future<void> initialize() async {
    await _notificationService.initialize();
  }



  /// 发送预算警告通知
  Future<void> sendBudgetWarning({
    required String category,
    required double currentAmount,
    required double budgetLimit,
    required double percentage,
  }) async {
    String title;
    String body;

    if (percentage >= 100) {
      title = '预算超支警告！';
      body =
          '$category 类别已超支 ¥${(currentAmount - budgetLimit).toStringAsFixed(2)}';
    } else if (percentage >= 80) {
      title = '预算即将超支';
      body = '$category 类别已使用 ${percentage.toStringAsFixed(1)}% 的预算';
    } else {
      return; // 不需要发送通知
    }

    await _notificationService.showNotification(
      id: NotificationService.budgetWarningNotificationId,
      title: title,
      body: body,
      payload: 'budget_warning:$category',
    );

    if (kDebugMode) {
      debugPrint('Budget warning sent for $category: $percentage%');
    }
  }

  /// 发送交易成功通知
  Future<void> sendTransactionSuccessNotification(
    Transaction transaction,
  ) async {
    final isTransactionNotificationEnabled =
        await _isTransactionNotificationEnabled();

    if (!isTransactionNotificationEnabled) return;

    final String type =
        transaction.type == TransactionType.income ? '收入' : '支出';
    final String emoji =
        transaction.type == TransactionType.income ? '💰' : '💸';

    await _notificationService.showNotification(
      id: NotificationService.transactionReminderNotificationId,
      title: '$type记录成功 $emoji',
      body: '${transaction.category} ¥${transaction.amount.toStringAsFixed(2)}',
      payload: 'transaction_success:${transaction.id}',
    );

    if (kDebugMode) {
      debugPrint('Transaction success notification sent: ${transaction.id}');
    }
  }

  /// 发送月度总结通知
  Future<void> sendMonthlySummaryNotification({
    required double totalIncome,
    required double totalExpense,
    required int transactionCount,
  }) async {
    final balance = totalIncome - totalExpense;
    final String balanceText =
        balance >= 0
            ? '结余 ¥${balance.toStringAsFixed(2)}'
            : '超支 ¥${(-balance).toStringAsFixed(2)}';

    await _notificationService.showNotification(
      id: 100, // 使用特殊ID避免冲突
      title: '月度财务总结 📊',
      body: '本月共 $transactionCount 笔交易，$balanceText',
      payload: 'monthly_summary',
    );

    if (kDebugMode) {
      debugPrint('Monthly summary notification sent');
    }
  }

  /// 发送大额支出提醒
  Future<void> sendLargeExpenseAlert(Transaction transaction) async {
    final prefs = await SharedPreferences.getInstance();
    final largeExpenseThreshold =
        prefs.getDouble('large_expense_threshold') ?? 1000.0;
    final isLargeExpenseAlertEnabled =
        prefs.getBool('large_expense_alert_enabled') ?? true;

    if (!isLargeExpenseAlertEnabled ||
        transaction.type != TransactionType.expense ||
        transaction.amount < largeExpenseThreshold) {
      return;
    }

    await _notificationService.showNotification(
      id: 101, // 使用特殊ID避免冲突
      title: '大额支出提醒 ⚠️',
      body:
          '${transaction.category} 支出 ¥${transaction.amount.toStringAsFixed(2)}',
      payload: 'large_expense:${transaction.id}',
    );

    if (kDebugMode) {
      debugPrint('Large expense alert sent: ¥${transaction.amount}');
    }
  }





  /// 设置大额支出阈值
  Future<void> setLargeExpenseThreshold(double threshold) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('large_expense_threshold', threshold);

    if (kDebugMode) {
      debugPrint('Large expense threshold set to ¥$threshold');
    }
  }

  /// 启用/禁用大额支出提醒
  Future<void> setLargeExpenseAlertEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('large_expense_alert_enabled', enabled);

    if (kDebugMode) {
      debugPrint('Large expense alert ${enabled ? "enabled" : "disabled"}');
    }
  }

  /// 启用/禁用交易成功通知
  Future<void> setTransactionNotificationEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('transaction_notification_enabled', enabled);

    if (kDebugMode) {
      debugPrint(
        'Transaction notification ${enabled ? "enabled" : "disabled"}',
      );
    }
  }

  /// 检查交易成功通知是否启用
  Future<bool> _isTransactionNotificationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('transaction_notification_enabled') ?? false;
  }



  /// 获取大额支出设置
  Future<Map<String, dynamic>> getLargeExpenseSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'enabled': prefs.getBool('large_expense_alert_enabled') ?? true,
      'threshold': prefs.getDouble('large_expense_threshold') ?? 1000.0,
    };
  }

  /// 获取交易通知设置
  Future<bool> getTransactionNotificationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('transaction_notification_enabled') ?? false;
  }

  /// 清除所有通知
  Future<void> clearAllNotifications() async {
    await _notificationService.cancelAllNotifications();

    if (kDebugMode) {
      debugPrint('All notifications cleared');
    }
  }
}
