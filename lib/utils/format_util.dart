import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';

class FormatUtil {
  // 格式化货币
  static String formatCurrency(double amount, {String currencySymbol = '¥'}) {
    // 根据提供的 currencySymbol 调整 locale 可能更健壮，但这里为了简单起见，仅替换 symbol
    // 对于更复杂的国际化需求，可能需要更完善的 locale 管理
    final formatter = NumberFormat.currency(
      locale: 'zh_CN',
      symbol: currencySymbol,
    );
    return formatter.format(amount);
  }

  // 格式化日期
  static String formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  // 格式化日期和时间
  static String formatDateTime(DateTime date) {
    return DateFormat('yyyy-MM-dd HH:mm').format(date);
  }

  // 获取类别图标
  static IconData getCategoryIcon(Category category) {
    switch (category) {
      case Category.food:
        return Icons.fastfood;
      case Category.transportation:
        return Icons.directions_car;
      case Category.entertainment:
        return Icons.movie;
      case Category.shopping:
        return Icons.shopping_bag;
      case Category.utilities:
        return Icons.lightbulb;
      case Category.health:
        return Icons.health_and_safety;
      case Category.education:
        return Icons.school;
      case Category.salary:
        return Icons.attach_money;
      case Category.gift:
        return Icons.card_giftcard;
      case Category.other:
        return Icons.category;
    }
  }

  // 获取类别名称
  static String getCategoryName(Category category) {
    switch (category) {
      case Category.food:
        return '餐饮';
      case Category.transportation:
        return '交通';
      case Category.entertainment:
        return '娱乐';
      case Category.shopping:
        return '购物';
      case Category.utilities:
        return '水电';
      case Category.health:
        return '医疗';
      case Category.education:
        return '教育';
      case Category.salary:
        return '工资';
      case Category.gift:
        return '礼物';
      case Category.other:
        return '其他';
    }
  }

  // 获取交易类型名称
  static String getTransactionTypeName(TransactionType type) {
    switch (type) {
      case TransactionType.income:
        return '收入';
      case TransactionType.expense:
        return '支出';
    }
  }

  // 获取月份名称
  static String getMonthName(int month) {
    final months = [
      '一月',
      '二月',
      '三月',
      '四月',
      '五月',
      '六月',
      '七月',
      '八月',
      '九月',
      '十月',
      '十一月',
      '十二月',
    ];
    return months[month - 1];
  }

  // 获取星期名称
  static String getWeekdayName(int weekday) {
    final weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return weekdays[weekday - 1];
  }
}
