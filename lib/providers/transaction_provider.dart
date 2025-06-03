import 'package:flutter/foundation.dart' hide Category;
import '../models/transaction.dart';
import '../services/database_service.dart';

class TransactionProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  List<Transaction> _transactions = [];
  bool _isLoading = false;

  // 获取所有交易记录
  List<Transaction> get transactions => _transactions;

  // 获取收入交易记录
  List<Transaction> get incomeTransactions =>
      _transactions
          .where((transaction) => transaction.type == TransactionType.income)
          .toList();

  // 获取支出交易记录
  List<Transaction> get expenseTransactions =>
      _transactions
          .where((transaction) => transaction.type == TransactionType.expense)
          .toList();

  // 获取总收入
  double get totalIncome => incomeTransactions.fold(
    0,
    (previousValue, transaction) => previousValue + transaction.amount,
  );

  // 获取总支出
  double get totalExpense => expenseTransactions.fold(
    0,
    (previousValue, transaction) => previousValue + transaction.amount,
  );

  // 获取余额
  double get balance => totalIncome - totalExpense;

  // 加载状态
  bool get isLoading => _isLoading;

  // 初始化：从数据库加载所有交易记录
  Future<void> loadTransactions() async {
    _isLoading = true;
    notifyListeners();

    try {
      _transactions =
          (await _databaseService.getTransactions()).cast<Transaction>();
      // 按日期排序（最新的在前）
      _transactions.sort((a, b) => b.date.compareTo(a.date));
    } catch (e) {
      // print('加载交易记录时出错: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 添加交易记录
  Future<void> addTransaction(Transaction transaction) async {
    try {
      await _databaseService.insertTransaction(transaction);
      await loadTransactions(); // 重新加载所有交易记录
    } catch (e) {
      // print('添加交易记录时出错: $e');
      rethrow;
    }
  }

  // 更新交易记录
  Future<void> updateTransaction(Transaction transaction) async {
    try {
      await _databaseService.updateTransaction(transaction);
      await loadTransactions(); // 重新加载所有交易记录
    } catch (e) {
      // print('更新交易记录时出错: $e');
      rethrow;
    }
  }

  // 删除交易记录
  Future<void> deleteTransaction(String id) async {
    try {
      await _databaseService.deleteTransaction(id);
      await loadTransactions(); // 重新加载所有交易记录
    } catch (e) {
      // print('删除交易记录时出错: $e');
      rethrow;
    }
  }

  // 按类别获取交易记录
  Future<void> loadTransactionsByCategory(Category category) async {
    _isLoading = true;
    notifyListeners();

    try {
      _transactions =
          (await _databaseService.getTransactionsByCategory(
            category,
          )).cast<Transaction>();
      // 按日期排序（最新的在前）
      _transactions.sort((a, b) => b.date.compareTo(a.date));
    } catch (e) {
      // print('按类别加载交易记录时出错: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 按日期范围获取交易记录
  Future<void> loadTransactionsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    _isLoading = true;
    notifyListeners();

    try {
      _transactions =
          (await _databaseService.getTransactionsByDateRange(
            startDate,
            endDate,
          )).cast<Transaction>();
      // 按日期排序（最新的在前）
      _transactions.sort((a, b) => b.date.compareTo(a.date));
    } catch (e) {
      // print('按日期范围加载交易记录时出错: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 按类型获取交易记录
  Future<void> loadTransactionsByType(TransactionType type) async {
    _isLoading = true;
    notifyListeners();

    try {
      _transactions =
          (await _databaseService.getTransactionsByType(
            type,
          )).cast<Transaction>();
      // 按日期排序（最新的在前）
      _transactions.sort((a, b) => b.date.compareTo(a.date));
    } catch (e) {
      // print('按类型加载交易记录时出错: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 获取按类别分组的支出统计
  Map<Category, double> getExpenseStatsByCategory() {
    final Map<Category, double> stats = {};
    for (var transaction in expenseTransactions) {
      stats[transaction.category] =
          (stats[transaction.category] ?? 0) + transaction.amount;
    }
    return stats;
  }

  // 获取按类别分组的收入统计
  Map<Category, double> getIncomeStatsByCategory() {
    final Map<Category, double> stats = {};
    for (var transaction in incomeTransactions) {
      stats[transaction.category] =
          (stats[transaction.category] ?? 0) + transaction.amount;
    }
    return stats;
  }
}
