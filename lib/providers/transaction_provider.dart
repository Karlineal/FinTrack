import 'package:flutter/foundation.dart' hide Category;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction.dart';
import '../services/database_service.dart';
import '../services/exchange_rate_service.dart';

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

  // 获取总收入（转换为基准货币）
  double get totalIncome => _convertedIncomeTransactions.fold(
    0,
    (previousValue, transaction) => previousValue + transaction.amount,
  );

  // 获取总支出（转换为基准货币）
  double get totalExpense => _convertedExpenseTransactions.fold(
    0,
    (previousValue, transaction) => previousValue + transaction.amount,
  );

  // 获取余额
  double get balance => totalIncome - totalExpense;

  // 获取转换后的收入交易记录
  List<Transaction> get _convertedIncomeTransactions =>
      _convertedTransactions
          .where((transaction) => transaction.type == TransactionType.income)
          .toList();

  // 获取转换后的支出交易记录
  List<Transaction> get _convertedExpenseTransactions =>
      _convertedTransactions
          .where((transaction) => transaction.type == TransactionType.expense)
          .toList();

  // 转换后的交易记录（用于计算总额）
  List<Transaction> _convertedTransactions = [];

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

      // 转换交易记录到基准货币
      await _convertTransactionsToBased();
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

      // 转换交易记录到基准货币
      await _convertTransactionsToBased();
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

      // 转换交易记录到基准货币
      await _convertTransactionsToBased();
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

      // 转换交易记录到基准货币
      await _convertTransactionsToBased();
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

  // 转换所有交易记录到基准货币
  Future<void> _convertTransactionsToBased() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final baseCurrency = _getCurrencyCodeFromSymbol(
        prefs.getString('currency') ?? '¥',
      );

      _convertedTransactions = [];

      for (final transaction in _transactions) {
        final transactionCurrency = _getCurrencyCodeFromSymbol(
          transaction.currency,
        );

        if (transactionCurrency == baseCurrency) {
          // 相同货币，直接添加
          _convertedTransactions.add(transaction);
        } else {
          // 不同货币，需要转换
          final convertedAmount = await ExchangeRateService.convertAmount(
            transaction.amount,
            transactionCurrency,
            baseCurrency,
          );

          // 创建转换后的交易记录副本
          final convertedTransaction = transaction.copyWith(
            amount: convertedAmount,
            currency: _getCurrencySymbolFromCode(baseCurrency),
          );

          _convertedTransactions.add(convertedTransaction);
        }
      }
    } catch (e) {
      // 转换失败时，使用原始交易记录
      _convertedTransactions = List.from(_transactions);
    }
  }

  // 从货币符号获取货币代码
  String _getCurrencyCodeFromSymbol(String symbol) {
    for (final entry in ExchangeRateService.supportedCurrencies.entries) {
      if (entry.value == symbol) {
        return entry.key;
      }
    }
    return 'CNY'; // 默认返回CNY
  }

  // 从货币代码获取货币符号
  String _getCurrencySymbolFromCode(String code) {
    return ExchangeRateService.getCurrencySymbol(code);
  }

  // 刷新汇率并重新计算
  Future<void> refreshExchangeRates() async {
    if (_transactions.isNotEmpty) {
      _isLoading = true;
      notifyListeners();

      try {
        await _convertTransactionsToBased();
      } catch (e) {
        // 刷新失败，保持当前状态
      } finally {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  // 获取指定货币的总额（不转换）
  double getTotalIncomeByCurrency(String currency) {
    return _transactions
        .where(
          (t) => t.type == TransactionType.income && t.currency == currency,
        )
        .fold(0, (sum, t) => sum + t.amount);
  }

  double getTotalExpenseByCurrency(String currency) {
    return _transactions
        .where(
          (t) => t.type == TransactionType.expense && t.currency == currency,
        )
        .fold(0, (sum, t) => sum + t.amount);
  }

  // 获取所有使用的货币列表
  Set<String> getUsedCurrencies() {
    return _transactions.map((t) => t.currency).toSet();
  }
}
