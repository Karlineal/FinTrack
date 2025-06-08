import 'package:flutter/foundation.dart' hide Category;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction.dart';
import '../services/database_service.dart';
import '../services/exchange_rate_service.dart';
import '../services/notification_manager.dart';

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

      // 发送通知
      final notificationManager = NotificationManager();

      // 发送交易成功通知
      await notificationManager.sendTransactionSuccessNotification(transaction);

      // 检查大额支出提醒
      await notificationManager.sendLargeExpenseAlert(transaction);

      // 检查预算警告（需要实现预算功能后添加）
      // 仅对支出类型交易进行预算检查
      if (transaction.type == TransactionType.expense) {
        final prefs = await SharedPreferences.getInstance();
        final baseCurrency = prefs.getString('defaultInputCurrency') ?? 'CNY';
        // 获取该类别的预算（单位为基准货币）
        final budgetKey = 'budget_${transaction.category.name}';
        final budgetLimit = prefs.getDouble(budgetKey);
        if (budgetLimit != null && budgetLimit > 0) {
          // 统计本月该类别的总支出（已转换为基准货币）
          final now = DateTime.now();
          final monthStart = DateTime(now.year, now.month, 1);
          double categoryExpense = 0;
          for (final t in _convertedExpenseTransactions) {
            if (t.category == transaction.category &&
                t.date.isAfter(monthStart.subtract(const Duration(days: 1))) &&
                t.date.isBefore(now.add(const Duration(days: 1)))) {
              categoryExpense += t.amount;
            }
          }
          final percentage = categoryExpense / budgetLimit * 100;
          // 发送预算警告通知
          await notificationManager.sendBudgetWarning(
            category: transaction.category.name,
            currentAmount: categoryExpense,
            budgetLimit: budgetLimit,
            percentage: percentage,
          );
        }
      }
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

  // 从现有列表中按日期范围筛选交易记录 (同步)
  List<Transaction> getTransactionsInDateRange(
    DateTime startDate,
    DateTime endDate,
  ) {
    return _transactions
        .where(
          (t) =>
              !t.date.isBefore(startDate) &&
              !t.date.isAfter(endDate.add(const Duration(days: 1))),
        )
        .toList();
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
      // 直接从 SharedPreferences 获取基准货币代码
      final baseCurrency = prefs.getString('defaultInputCurrency') ?? 'CNY';

      _convertedTransactions = [];

      for (final transaction in _transactions) {
        final transactionCurrency =
            transaction.currency; // transaction.currency 已经是货币代码

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

          // 创建转换后的交易记录副本，currency 字段保持为基准货币代码
          final convertedTransaction = transaction.copyWith(
            amount: convertedAmount,
            currency: baseCurrency, // 存储基准货币代码
          );

          _convertedTransactions.add(convertedTransaction);
        }
      }
    } catch (e) {
      // 转换失败时，使用原始交易记录
      _convertedTransactions = List.from(_transactions);
    }
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

  // 批量插入交易记录（用于导入）
  Future<void> batchInsertTransactions(List<Transaction> transactions) async {
    for (final t in transactions) {
      await _databaseService.insertTransaction(t);
    }
    await loadTransactions();
  }
}
