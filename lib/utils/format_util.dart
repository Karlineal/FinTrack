import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../services/exchange_rate_service.dart'; // 导入 ExchangeRateService

class FormatUtil {
  // 格式化货币
  static String formatCurrency(double amount, {String currencyCode = 'CNY'}) {
    // 获取货币符号
    final String symbol =
        currencyCode == 'CNY'
            ? ''
            : ExchangeRateService.getCurrencySymbol(currencyCode);
    String formattedAmount;
    if (amount.truncateToDouble() == amount) {
      formattedAmount = amount.toInt().toString();
    } else {
      formattedAmount = amount
          .toStringAsFixed(2)
          .replaceAll(RegExp(r'0+$'), '')
          .replaceAll(RegExp(r'\.$'), '');
    }
    return symbol + formattedAmount;
  }

  // 格式化日期
  static String formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  // 格式化日期和时间
  static String formatDateTime(DateTime date) {
    return DateFormat('yyyy-MM-dd HH:mm').format(date);
  }

  // 格式化日期为 MM/dd
  static String formatDateForGroupHeader(DateTime date) {
    return DateFormat('MM/dd').format(date);
  }

  // 获取相对日期字符串（今天/昨天）
  static String getRelativeDayString(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final checkDate = DateTime(date.year, date.month, date.day);

    if (checkDate == today) {
      return '今天';
    } else if (checkDate == yesterday) {
      return '昨天';
    }
    return '';
  }

  // 格式化时间
  static String formatTime(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }

  // 智能格式化数字（整数不带小数，小数最多两位）
  static String formatNumberSmart(double value) {
    if (value.truncateToDouble() == value) {
      return value.toInt().toString();
    } else {
      return value
          .toStringAsFixed(2)
          .replaceAll(RegExp(r'0+$'), '')
          .replaceAll(RegExp(r'\.$'), '');
    }
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
      case Category.takeout:
        return Icons.delivery_dining;
      case Category.daily:
        return Icons.home;
      case Category.pets:
        return Icons.pets;
      case Category.campus:
        return Icons.account_balance;
      case Category.phone:
        return Icons.phone_android;
      case Category.drinks:
        return Icons.local_drink;
      case Category.study:
        return Icons.menu_book;
      case Category.clothes:
        return Icons.checkroom;
      case Category.internet:
        return Icons.wifi;
      case Category.snacks:
        return Icons.icecream;
      case Category.digital:
        return Icons.devices;
      case Category.beauty:
        return Icons.brush;
      case Category.smoke:
        return Icons.smoking_rooms;
      case Category.sports:
        return Icons.sports_soccer;
      case Category.travel:
        return Icons.flight;
      case Category.water:
        return Icons.water;
      case Category.fastmail:
        return Icons.local_shipping;
      case Category.rent:
        return Icons.house;
      case Category.otherExpense:
        return Icons.money_off;
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
      case Category.takeout:
        return '外卖';
      case Category.daily:
        return '日用品';
      case Category.pets:
        return '宠物';
      case Category.campus:
        return '校园卡';
      case Category.phone:
        return '话费';
      case Category.drinks:
        return '饮料酒水';
      case Category.study:
        return '学习';
      case Category.clothes:
        return '服饰';
      case Category.internet:
        return '网费';
      case Category.snacks:
        return '零食水果';
      case Category.digital:
        return '数码';
      case Category.beauty:
        return '护肤美妆';
      case Category.smoke:
        return '烟酒';
      case Category.sports:
        return '运动';
      case Category.travel:
        return '旅行';
      case Category.water:
        return '水费';
      case Category.fastmail:
        return '快递';
      case Category.rent:
        return '房租';
      case Category.otherExpense:
        return '其他支出';
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
