import 'package:flutter/foundation.dart' hide Category;
import 'package:fintrack/services/data_service.dart';
import '../models/transaction.dart';
// import '../services/exchange_rate_service.dart'; // 暂时不使用
// import '../services/notification_manager.dart'; // 暂时不使用

class TransactionProvider with ChangeNotifier {
  final DataService _dataService = DataService();
  List<Transaction> _transactions = [];
  bool _isLoading = false;

  List<Transaction> get transactions => _transactions;

  List<Transaction> get incomeTransactions =>
      _transactions
          .where((transaction) => transaction.type == TransactionType.income)
          .toList();

  List<Transaction> get expenseTransactions =>
      _transactions
          .where((transaction) => transaction.type == TransactionType.expense)
          .toList();

  double get totalIncome => incomeTransactions.fold(
    0,
    (previousValue, transaction) => previousValue + transaction.amount,
  );

  double get totalExpense => expenseTransactions.fold(
    0,
    (previousValue, transaction) => previousValue + transaction.amount,
  );

  double get balance => totalIncome - totalExpense;

  bool get isLoading => _isLoading;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  Future<void> loadTransactions() async {
    _setLoading(true);
    try {
      _transactions = await _dataService.fetchTransactions();
      _transactions.sort((a, b) => b.date.compareTo(a.date));
    } catch (e) {
      if (kDebugMode) {
        print('Error loading transactions: $e');
      }
      _transactions = []; // On error, clear transactions
    } finally {
      _setLoading(false);
    }
  }

  List<Transaction> getTransactionsByCategory(String category) {
    if (category.toLowerCase() == 'all') {
      return _transactions;
    }
    return _transactions.where((t) => t.category == category).toList();
  }

  List<Transaction> getTransactionsInDateRange(
    DateTime startDate,
    DateTime endDate,
  ) {
    return _transactions
        .where((t) => !t.date.isBefore(startDate) && !t.date.isBefore(endDate))
        .toList();
  }
}
