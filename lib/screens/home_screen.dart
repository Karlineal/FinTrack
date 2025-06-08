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
import 'package:shared_preferences/shared_preferences.dart'; // 导入 SharedPreferences
import '../services/exchange_rate_service.dart'; // 导入 ExchangeRateService
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../utils/format_util.dart';

enum DateFilterOption { none, oneWeek, oneMonth, sixMonths, oneYear, custom }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  late List<Widget> _screens;
  String _currencySymbol = '¥'; // 添加状态变量存储货币符号

  @override
  void initState() {
    super.initState();
    // 先初始化屏幕列表，确保_screens不为空
    _screens = [
      _buildHomeContent(),
      const StatisticsScreen(),
      const SettingsScreen(),
    ];
    _loadCurrencyPreference(); // 加载货币偏好

    // 加载交易数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TransactionProvider>(
        context,
        listen: false,
      ).loadTransactions();
      // 在数据加载后，再次确保货币符号是最新的
      // 这也处理了从设置页返回时可能需要更新符号的情况
      _loadCurrencyPreference();
    });
  }

  Future<void> _loadCurrencyPreference() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      // 检查 widget 是否仍然挂载
      setState(() {
        // 从defaultInputCurrency获取货币代码，然后转换为符号
        final currencyCode = prefs.getString('defaultInputCurrency') ?? 'CNY';
        _currencySymbol = ExchangeRateService.getCurrencySymbol(currencyCode);
        // 更新 _screens 列表中的 _buildHomeContent，以确保它使用最新的 _currencySymbol
        // 这是一个简化的处理，更健壮的方式可能是在 _buildHomeContent 中直接使用 _currencySymbol
        // 或者通过其他状态管理方式传递
        _screens.clear();
        _screens.addAll([
          _buildHomeContent(), // 重建 _buildHomeContent
          const StatisticsScreen(),
          const SettingsScreen(),
        ]);
      });
    }
  }

  // 当从设置页面返回时，也可能需要刷新货币符号
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 监听路由变化，如果从设置页返回，则重新加载货币偏好
    // 这是一个简化的示例，实际应用中可能有更优雅的跨页面状态同步方式
    final ModalRoute? route = ModalRoute.of(context);
    if (route is PageRoute && route.isCurrent) {
      // 尝试在每次页面变为当前时刷新，确保从设置返回时更新
      _loadCurrencyPreference();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 顶部搜索栏只在首页tab显示
            if (_selectedIndex == 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 12),
                      const Icon(Icons.search, color: Colors.grey, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '搜索账单/备注/分类',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            // 其余内容（摘要卡片、预算卡片、分组账单列表等）
            Expanded(child: _screens[_selectedIndex]),
          ],
        ),
      ),
      // 只在首页显示"记一笔"按钮，且修复跳转逻辑
      floatingActionButton:
          _selectedIndex == 0
              ? Stack(
                children: [
                  Positioned(
                    right: 4,
                    bottom: 80, // 保持上移，避免遮挡底部导航栏
                    child: Material(
                      color: Colors.transparent,
                      elevation: 12,
                      borderRadius: BorderRadius.circular(24),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => const AddTransactionScreen(),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFFEEF0FF), Color(0xFFD6D8F6)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(
                                  (0.1 * 255).round(),
                                ),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(
                                Icons.add,
                                color: Color(0xFF5B5BFF),
                                size: 24,
                              ),
                              SizedBox(width: 6),
                              Text(
                                '记一笔',
                                style: TextStyle(
                                  color: Color(0xFF5B5BFF),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              )
              : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '首页'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: '统计'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: '设置'),
        ],
      ),
    );
  }

  Widget _buildHomeContent() {
    return Consumer<TransactionProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            // 摘要卡片
            SummaryCard(
              income: provider.totalIncome,
              expense: provider.totalExpense,
              balance: provider.balance,
              currencySymbol: _currencySymbol, // 传递货币符号
            ),

            // 最近交易标题
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '最近交易',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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

            // 交易列表
            Expanded(
              child:
                  provider.transactions.isEmpty
                      ? const Center(child: Text('暂无交易记录，点击下方 + 按钮添加'))
                      : ListView.builder(
                        itemCount: provider.transactions.length,
                        itemBuilder: (context, index) {
                          final transaction = provider.transactions[index];
                          return TransactionListItem(
                            transaction: transaction,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => TransactionDetailScreen(
                                        transaction: transaction,
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
                                              () =>
                                                  Navigator.pop(context, false),
                                          child: const Text('取消'),
                                        ),
                                        TextButton(
                                          onPressed:
                                              () =>
                                                  Navigator.pop(context, true),
                                          child: const Text('删除'),
                                        ),
                                      ],
                                    ),
                              );
                              if (confirmed == true) {
                                await Provider.of<TransactionProvider>(
                                  context,
                                  listen: false,
                                ).deleteTransaction(transaction.id);
                              }
                            },
                          );
                        },
                      ),
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
    final Color mainColor = Colors.green;
    return Scaffold(
      appBar: AppBar(
        title: const Text('账单'),
        centerTitle: true,
        backgroundColor: mainColor,
        elevation: 0.5,
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, provider, child) {
          final filtered = _filterTransactions(provider.transactions);

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
                      mainColor: mainColor,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterButton(
                      '分类',
                      onTap: _pickCategories,
                      selected: _selectedCategories.isNotEmpty,
                      mainColor: mainColor,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterButton(
                      '类型',
                      onTap: _pickTypes,
                      selected:
                          _selectedTypes.length !=
                          TransactionType.values.length,
                      mainColor: mainColor,
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
    required Color mainColor,
  }) {
    return Expanded(
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor:
              selected
                  ? mainColor.withAlpha((0.08 * 255).toInt())
                  : Colors.white,
          side: BorderSide(color: selected ? mainColor : Colors.grey.shade300),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? mainColor : Colors.black87,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
