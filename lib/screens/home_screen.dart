import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../widgets/summary_card.dart';
import '../widgets/transaction_list_item.dart';
import 'add_transaction_screen.dart';
import 'transaction_detail_screen.dart';
import 'statistics_screen.dart';
import 'settings_screen.dart';
import 'category_selection_screen.dart';
// import 'package:shared_preferences/shared_preferences.dart'; // 导入 SharedPreferences
// 导入 ExchangeRateService
import '../models/transaction.dart';
import '../utils/format_util.dart';
import 'search_screen.dart';
// import 'package:grouped_list/grouped_list.dart'; // No longer needed

enum DateFilterOption { none, oneWeek, oneMonth, sixMonths, oneYear, custom }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  // 默认货币符号
  final PageController _pageController = PageController();
  late ScrollController _scrollController;
  bool _isFabExtended = true;

  @override
  void initState() {
    super.initState();
    // 异步加载货币偏好
    _loadCurrencyPreference();
    // 初始化滚动控制器并添加监听器
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);

    // 使用 provider 初始化数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<TransactionProvider>(
          context,
          listen: false,
        ).loadTransactions();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.offset > 50 && _isFabExtended) {
      setState(() {
        _isFabExtended = false;
      });
    } else if (_scrollController.offset <= 50 && !_isFabExtended) {
      setState(() {
        _isFabExtended = true;
      });
    }
  }

  // 异步加载货币偏好
  Future<void> _loadCurrencyPreference() async {
    // final prefs = await SharedPreferences.getInstance(); // Unused
    if (mounted) {
      setState(() {});
      // 加载后更新交易
      if (!mounted) return; // Guard against async gaps
      await Provider.of<TransactionProvider>(
        context,
        listen: false,
      ).loadTransactions();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          children: <Widget>[
            _buildHomeContent(),
            const StatisticsScreen(),
            const SettingsScreen(),
          ],
        ),
      ),
      // 只在首页显示"记一笔"按钮，且修复跳转逻辑
      floatingActionButton: Consumer<TransactionProvider>(
        builder: (context, provider, child) {
          if (_selectedIndex == 0 && !provider.isLoading) {
            return _isFabExtended
                ? FloatingActionButton.extended(
                  onPressed: () => _navigateToAddTransaction(context),
                  label: const Text('记一笔'),
                  icon: const Icon(Icons.add),
                )
                : FloatingActionButton(
                  onPressed: () => _navigateToAddTransaction(context),
                  child: const Icon(Icons.add),
                );
          } else {
            return const SizedBox.shrink();
          }
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.ease,
          );
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '首页'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: '统计'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: '设置'),
        ],
      ),
    );
  }

  void _navigateToAddTransaction(BuildContext context) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const AddTransactionScreen()),
    );

    if (result == true) {
      // Data is updated by the provider, no manual reload needed here.
    }
  }

  Widget _buildHomeContent() {
    return Consumer<TransactionProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh:
              () =>
                  Provider.of<TransactionProvider>(
                    context,
                    listen: false,
                  ).loadTransactions(),
          child: ListView(
            controller: _scrollController,
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SearchScreen(),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).brightness == Brightness.light
                              ? Colors.grey[200]
                              : Colors.grey[800],
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Text('搜索交易', style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                  ),
                ),
              ),
              // 摘要卡片
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: SummaryCard(
                  income: provider.monthlyIncome,
                  expense: provider.monthlyExpense,
                  balance: provider.monthlyBalance,
                  currencySymbol: '',
                ),
              ),

              // 最近交易标题
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '最近交易',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AllTransactionsScreen(),
                          ),
                        );
                      },
                      child: const Text('查看全部'),
                    ),
                  ],
                ),
              ),

              // 分组交易列表
              if (provider.transactions.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text('暂无交易记录，点击下方 + 按钮添加'),
                  ),
                )
              else
                ..._buildGroupedTransactions(
                  context,
                  provider.convertedTransactions,
                ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildGroupedTransactions(
    BuildContext context,
    List<Transaction> transactions,
  ) {
    final grouped = <DateTime, List<Transaction>>{};

    // Sort transactions by date descending
    final sortedTransactions = List<Transaction>.from(transactions)
      ..sort((a, b) => b.date.compareTo(a.date));

    for (var transaction in sortedTransactions) {
      final dateKey = DateTime(
        transaction.date.year,
        transaction.date.month,
        transaction.date.day,
      );
      if (grouped[dateKey] == null) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(transaction);
    }

    final List<Widget> widgets = [];
    grouped.forEach((date, dailyTransactions) {
      widgets.add(_buildDateHeader(date, dailyTransactions));
      widgets.addAll(
        dailyTransactions.map((transaction) {
          return TransactionListItem(
            transaction: transaction,
            dateFormat: 'MM-dd',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) =>
                          TransactionDetailScreen(transaction: transaction),
                ),
              );
            },
            onDelete: () => _confirmDeleteTransaction(context, transaction.id),
          );
        }),
      );
    });

    return widgets;
  }

  Widget _buildDateHeader(DateTime date, List<Transaction> transactions) {
    final dailyExpense = transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);
    final dailyIncome = transactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);

    String summary = '';
    if (dailyExpense > 0) {
      summary += '支 ${FormatUtil.formatNumberSmart(dailyExpense)}';
    }
    if (dailyIncome > 0) {
      summary += ' 收 ${FormatUtil.formatNumberSmart(dailyIncome)}';
    }

    final headerTextStyle = TextStyle(color: Colors.grey[600], fontSize: 13);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              _buildRatioBar(dailyIncome, dailyExpense),
              const SizedBox(width: 8),
              Text(
                '${FormatUtil.formatDateForGroupHeader(date)} ${FormatUtil.getWeekdayName(date.weekday)} ${FormatUtil.getRelativeDayString(date)}',
                style: headerTextStyle,
              ),
            ],
          ),
          Text(summary.trim(), style: headerTextStyle),
        ],
      ),
    );
  }

  Widget _buildRatioBar(double income, double expense) {
    final total = income + expense;
    if (total == 0) {
      return const SizedBox(width: 4, height: 16);
    }

    final incomeRatio = income / total;
    final expenseRatio = expense / total;

    // 绿色代表支出, 红色代表收入
    const expenseColor = Colors.green;
    const incomeColor = Colors.red;

    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: SizedBox(
        width: 4,
        height: 16,
        child: Column(
          children: [
            if (expense > 0)
              Flexible(
                flex: (expenseRatio * 100).toInt(),
                child: Container(color: expenseColor),
              ),
            if (income > 0)
              Flexible(
                flex: (incomeRatio * 100).toInt(),
                child: Container(color: incomeColor),
              ),
          ],
        ),
      ),
    );
  }

  // 新增：确认删除交易的对话框
  Future<void> _confirmDeleteTransaction(
    BuildContext context,
    String id,
  ) async {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('确认删除'),
          content: const Text('您确定要删除此交易记录吗？此操作无法撤销。'),
          actions: <Widget>[
            TextButton(
              child: const Text('取消'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // 关闭对话框
              },
            ),
            TextButton(
              child: const Text('删除'),
              onPressed: () async {
                Navigator.of(dialogContext).pop(); // 关闭对话框
                // 调用 provider 中的方法删除交易
                if (!mounted) return;
                await Provider.of<TransactionProvider>(
                  context,
                  listen: false,
                ).deleteTransaction(id);
              },
            ),
          ],
        );
      },
    );
  }
}

// 新增：全部交易页面
class AllTransactionsScreen extends StatefulWidget {
  const AllTransactionsScreen({super.key});

  @override
  State<AllTransactionsScreen> createState() => _AllTransactionsScreenState();
}

class _AllTransactionsScreenState extends State<AllTransactionsScreen> {
  // 筛选条件
  DateTimeRange? _dateRange;
  DateFilterOption _selectedDateOption = DateFilterOption.none;
  Set<Category> _selectedCategories = {};
  Set<TransactionType> _selectedTypes = {
    TransactionType.expense,
    TransactionType.income,
  };

  // 日期筛选弹窗
  Future<void> _pickDateRange() async {
    await showDialog(
      context: context,
      builder: (dialogContext) {
        final options = {
          '不限日期': DateFilterOption.none,
          '一周以内': DateFilterOption.oneWeek,
          '一个月以内': DateFilterOption.oneMonth,
          '半年以内': DateFilterOption.sixMonths,
          '一年以内': DateFilterOption.oneYear,
        };
        return SimpleDialog(
          title: const Text('选择日期'),
          children: [
            ...options.entries.map((entry) {
              final text = entry.key;
              final option = entry.value;
              final isSelected = _selectedDateOption == option;
              return ListTile(
                title: Text(
                  text,
                  style: TextStyle(
                    color: isSelected ? Theme.of(context).primaryColor : null,
                  ),
                ),
                trailing:
                    isSelected
                        ? Icon(
                          Icons.check,
                          color: Theme.of(context).primaryColor,
                        )
                        : null,
                onTap: () {
                  _setDateRangeFromOption(option);
                  Navigator.pop(dialogContext);
                },
              );
            }).toList(),
            const Divider(height: 1),
            ListTile(
              title: const Text('自定义范围'),
              onTap: () async {
                Navigator.pop(dialogContext);
                await _showCustomDateRangePicker();
              },
            ),
          ],
        );
      },
    );
  }

  void _setDateRangeFromOption(DateFilterOption option) {
    final now = DateTime.now();
    DateTimeRange? newRange;

    switch (option) {
      case DateFilterOption.none:
        newRange = null;
        break;
      case DateFilterOption.oneWeek:
        newRange = DateTimeRange(
          start: now.subtract(const Duration(days: 7)),
          end: now,
        );
        break;
      case DateFilterOption.oneMonth:
        newRange = DateTimeRange(
          start: now.subtract(const Duration(days: 30)),
          end: now,
        );
        break;
      case DateFilterOption.sixMonths:
        newRange = DateTimeRange(
          start: now.subtract(const Duration(days: 180)),
          end: now,
        );
        break;
      case DateFilterOption.oneYear:
        newRange = DateTimeRange(
          start: now.subtract(const Duration(days: 365)),
          end: now,
        );
        break;
      case DateFilterOption.custom:
        return; // Custom is handled by _showCustomDateRangePicker
    }

    setState(() {
      _dateRange = newRange;
      _selectedDateOption = option;
    });
  }

  Future<void> _showCustomDateRangePicker() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
    );
    if (picked != null) {
      setState(() {
        _dateRange = picked;
        _selectedDateOption = DateFilterOption.custom;
      });
    }
  }

  // 类型多选弹窗
  Future<void> _pickTypes() async {
    final selected = Set<TransactionType>.from(_selectedTypes);
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('选择类型'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children:
                    TransactionType.values.map((type) {
                      return CheckboxListTile(
                        value: selected.contains(type),
                        title: Text(
                          type == TransactionType.expense ? '支出' : '收入',
                        ),
                        onChanged: (checked) {
                          setState(() {
                            if (checked == true) {
                              selected.add(type);
                            } else {
                              selected.remove(type);
                            }
                          });
                          // 立即生效并关闭弹窗
                          this.setState(() {
                            _selectedTypes = Set<TransactionType>.from(
                              selected,
                            );
                          });
                          Navigator.pop(context);
                        },
                      );
                    }).toList(),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // 分类多选弹窗
  Future<void> _pickCategories() async {
    final result = await Navigator.push<Set<Category>>(
      context,
      MaterialPageRoute(
        builder:
            (context) => CategorySelectionScreen(
              initialSelectedCategories: _selectedCategories,
            ),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedCategories = result;
      });
    }
  }

  // 过滤账单
  List<Transaction> _filterTransactions(List<Transaction> all) {
    return all.where((t) {
      if (_dateRange != null) {
        if (t.date.isBefore(_dateRange!.start) ||
            t.date.isAfter(_dateRange!.end)) {
          return false;
        }
      }
      if (_selectedCategories.isNotEmpty &&
          !_selectedCategories.contains(t.category)) {
        return false;
      }
      if (_selectedTypes.isNotEmpty && !_selectedTypes.contains(t.type)) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('账单'),
        centerTitle: true,
        backgroundColor: colorScheme.primary,
        elevation: 0.5,
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, provider, child) {
          final filtered = _filterTransactions(provider.convertedTransactions);

          return Column(
            children: [
              // 筛选栏
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    _buildFilterButton(
                      '日期',
                      onTap: _pickDateRange,
                      selected: _dateRange != null,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterButton(
                      '分类',
                      onTap: _pickCategories,
                      selected: _selectedCategories.isNotEmpty,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterButton(
                      '类型',
                      onTap: _pickTypes,
                      selected:
                          _selectedTypes.length !=
                          TransactionType.values.length,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // 账单列表
              Expanded(
                child:
                    filtered.isEmpty
                        ? const Center(child: Text('暂无符合条件的账单'))
                        : ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (context, idx) {
                            final t = filtered[idx];
                            return TransactionListItem(
                              transaction: t,
                              dateFormat: 'MM-dd',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => TransactionDetailScreen(
                                          transaction: t,
                                        ),
                                  ),
                                );
                              },
                              onDelete: () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder:
                                      (context) => AlertDialog(
                                        title: const Text('确认删除'),
                                        content: const Text('确定要删除这条交易记录吗？'),
                                        actions: [
                                          TextButton(
                                            onPressed:
                                                () => Navigator.pop(
                                                  context,
                                                  false,
                                                ),
                                            child: const Text('取消'),
                                          ),
                                          TextButton(
                                            onPressed:
                                                () => Navigator.pop(
                                                  context,
                                                  true,
                                                ),
                                            child: const Text('删除'),
                                          ),
                                        ],
                                      ),
                                );
                                if (confirmed == true) {
                                  if (!mounted) return;
                                  await Provider.of<TransactionProvider>(
                                    context,
                                    listen: false,
                                  ).deleteTransaction(t.id);
                                }
                              },
                            );
                          },
                        ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterButton(
    String label, {
    required VoidCallback onTap,
    bool selected = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Expanded(
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor:
              selected
                  ? colorScheme.primary.withAlpha(30) // withOpacity(0.12)
                  : colorScheme.surface,
          side: BorderSide(
            color: selected ? colorScheme.primary : theme.dividerColor,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? colorScheme.primary : colorScheme.onSurface,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
