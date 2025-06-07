import 'package:uuid/uuid.dart';
import '../services/exchange_rate_service.dart';

enum TransactionType { income, expense }

enum Category {
  food,
  transportation,
  entertainment,
  shopping,
  utilities,
  health,
  education,
  salary,
  gift,
  other,
}

class Transaction {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final TransactionType type;
  final Category category;
  final String? note;
  final String currency; // 添加 currency 字段

  Transaction({
    String? id,
    required this.title,
    required this.amount,
    required this.date,
    required this.type,
    required this.category,
    this.note,
    required this.currency, // 将currency设为required，确保传入有效的货币符号
  }) : id = id ?? const Uuid().v4();

  // 从Map创建Transaction对象（用于数据库操作）
  factory Transaction.fromMap(Map<String, dynamic> map) {
    // 获取货币代码，确保是有效的
    String currencyCode = map['currency'] ?? 'CNY'; // 默认使用CNY代码
    // 如果货币代码不在支持的列表中，使用默认的第一个
    if (!ExchangeRateService.supportedCurrencies.keys.contains(currencyCode)) {
      currencyCode = ExchangeRateService.supportedCurrencies.keys.first;
    }

    return Transaction(
      id: map['id'],
      title: map['title'],
      amount: map['amount'],
      date: DateTime.parse(map['date']),
      type: TransactionType.values.byName(map['type']),
      category: Category.values.byName(map['category']),
      note: map['note'],
      currency: currencyCode, // 使用有效的货币代码
    );
  }

  // 将Transaction对象转换为Map（用于数据库操作）
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'date': date.toIso8601String(),
      'type': type.name,
      'category': category.name,
      'note': note,
      'currency': currency, // 将 currency 添加到 map
    };
  }

  // 创建Transaction的副本
  Transaction copyWith({
    String? id,
    String? title,
    double? amount,
    DateTime? date,
    TransactionType? type,
    Category? category,
    String? note,
    String? currency, // 添加 currency 参数
  }) {
    return Transaction(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      type: type ?? this.type,
      category: category ?? this.category,
      note: note ?? this.note,
      currency: currency ?? this.currency, // 更新 currency
    );
  }
}
