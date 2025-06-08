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

  // 获取转换后的交易记录（用于UI显示，已统一为基准货币）
  List<Transaction> get convertedTransactions => _convertedTransactions;

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

  // 获取本月总收入
  double get monthlyIncome {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    return _convertedIncomeTransactions
        .where((t) => !t.date.isBefore(monthStart))
        .fold(0, (prev, t) => prev + t.amount);
  }

  // 获取本月总支出
  double get monthlyExpense {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    return _convertedExpenseTransactions
        .where((t) => !t.date.isBefore(monthStart))
        .fold(0, (prev, t) => prev + t.amount);
  }

  // 获取本月余额
  double get monthlyBalance => monthlyIncome - monthlyExpense;

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
    _setLoading(true);

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
      _setLoading(false);
    }
  }

  // 添加交易记录
  Future<void> addTransaction(Transaction transaction) async {
    try {
      // 核心操作：立即更新UI和数据库
      await _databaseService.insertTransaction(transaction);
      _transactions.insert(0, transaction); // 插入到列表开头
      _transactions.sort((a, b) => b.date.compareTo(a.date));
      await _convertTransactionsToBased(); // 重新计算转换后的列表
      notifyListeners(); // 立即通知UI更新

      // 非核心操作：在后台执行，不阻塞UI
      _performPostTransactionTasks(transaction);
    } catch (e) {
      // print('添加交易记录时出错: $e');
      rethrow;
    }
  }

  // 后台执行的额外任务
  Future<void> _performPostTransactionTasks(Transaction transaction) async {
    final notificationManager = NotificationManager();

    // 1. 发送交易成功通知
    await notificationManager.sendTransactionSuccessNotification(transaction);

    // 2. 检查大额支出提醒
    await notificationManager.sendLargeExpenseAlert(transaction);

    // 3. 检查预算警告
    if (transaction.type == TransactionType.expense) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final budgetKey = 'budget_${transaction.category.name}';
        final budgetLimit = prefs.getDouble(budgetKey);

        if (budgetLimit != null && budgetLimit > 0) {
          // 统计本月该类别的总支出
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
      } catch (e) {
        // print('检查预算时出错: $e');
      }
    }
  }

  // 更新交易记录
  Future<void> updateTransaction(Transaction transaction) async {
    try {
      await _databaseService.updateTransaction(transaction);
      final index = _transactions.indexWhere((t) => t.id == transaction.id);
      if (index != -1) {
        _transactions[index] = transaction;
        _transactions.sort((a, b) => b.date.compareTo(a.date));
        await _convertTransactionsToBased(); // 重新计算
        notifyListeners(); // 通知UI更新
      } else {
        await loadTransactions(); // 如果找不到，则重新加载
      }
    } catch (e) {
      // print('更新交易记录时出错: $e');
      rethrow;
    }
  }

  // 删除交易记录
  Future<void> deleteTransaction(String id) async {
    try {
      await _databaseService.deleteTransaction(id);
      _transactions.removeWhere((t) => t.id == id);
      await _convertTransactionsToBased(); // 重新计算
      notifyListeners(); // 通知UI更新
    } catch (e) {
      // print('删除交易记录时出错: $e');
      rethrow;
    }
  }

  // 按类别获取交易记录
  Future<void> loadTransactionsByCategory(Category category) async {
    _setLoading(true);

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
      _setLoading(false);
    }
  }

  // 按日期范围获取交易记录
  Future<void> loadTransactionsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    _setLoading(true);

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
      _setLoading(false);
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

  // 搜索交易记录
  Future<List<Transaction>> searchTransactions(String query) async {
    if (query.isEmpty) {
      return _convertedTransactions;
    }
    // Simple search in notes and category names for now
    final lowerCaseQuery = query.toLowerCase();
    return _convertedTransactions.where((t) {
      final noteMatch = t.note?.toLowerCase().contains(lowerCaseQuery) ?? false;
      final categoryMatch = t.category.name.toLowerCase().contains(
        lowerCaseQuery,
      );
      return noteMatch || categoryMatch;
    }).toList();
  }

  // 将所有交易记录转换为基准货币
  Future<void> _convertTransactionsToBased() async {
    final prefs = await SharedPreferences.getInstance();
    final baseCurrency = prefs.getString('currency') ?? 'CNY';

    final futures = _transactions.map((transaction) async {
      if (transaction.currency == baseCurrency) {
        return transaction;
      }
      final convertedAmount = await ExchangeRateService.convertAmount(
        transaction.amount,
        transaction.currency,
        baseCurrency,
      );
      return transaction.copyWith(
        amount: convertedAmount,
        currency: baseCurrency,
      );
    });

    _convertedTransactions = await Future.wait(futures);
    // Sort again, as conversion might affect order if dates are the same
    _convertedTransactions.sort((a, b) => b.date.compareTo(a.date));
  }

  // 刷新汇率并重新计算
  Future<void> refreshExchangeRates() async {
    if (_transactions.isNotEmpty) {
      _setLoading(true);
      try {
        // Re-converting will implicitly use cached or fetched rates
        await _convertTransactionsToBased();
      } catch (e) {
        // 刷新失败，保持当前状态
      } finally {
        _setLoading(false);
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

  // 删除所有数据
  Future<void> deleteAllData() async {
    _setLoading(true);
    try {
      final db = _databaseService;
      final allTransactions = await db.getTransactions();
      for (final t in allTransactions) {
        await db.deleteTransaction(t.id);
      }
      await loadTransactions();
    } catch (e) {
      // print('删除所有数据时出错: $e');
    } finally {
      _setLoading(false);
    }
  }

  // 安全地更新加载状态并通知监听器
  void _setLoading(bool loading) {
    Future.microtask(() {
      _isLoading = loading;
      notifyListeners();
    });
  }
}
