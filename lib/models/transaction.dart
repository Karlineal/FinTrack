import 'package:flutter/foundation.dart';

enum TransactionType { income, expense }

class Transaction {
  final String id;
  final DateTime date;
  final String description;
  final double amount;
  final TransactionType type;
  final String category;

  Transaction({
    required this.id,
    required this.date,
    required this.description,
    required this.amount,
    required this.type,
    required this.category,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      date: DateTime.parse(json['date']),
      description: json['description'],
      amount: (json['amount'] as num).toDouble(),
      type:
          (json['type'] as String).toLowerCase() == 'income'
              ? TransactionType.income
              : TransactionType.expense,
      category: json['category'],
    );
  }
}
