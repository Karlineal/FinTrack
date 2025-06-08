import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../widgets/expense_chart.dart';
import '../utils/format_util.dart';
import '../utils/theme_util.dart';
import '../widgets/ratio_details.dart';
import '../widgets/trend_line_chart.dart' as trend;

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late DateTime _startDate;
  late DateTime _endDate;
  int _periodIndex = 0; // 0:月 1:周 2:年 3:自定义
  bool _trendIsExpense = true;
  bool _ratioIsExpense = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _updateDateRangeForIndex(0);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabSelection() {
    if (!_tabController.indexIsChanging &&
        _periodIndex != _tabController.index) {
      _updateDateRangeForIndex(_tabController.index);
    }
  }

  void _updateDateRangeForIndex(int index) {
    setState(() {
      _periodIndex = index;
      final now = DateTime.now();
      switch (index) {
        case 0: // 月
          _startDate = DateTime(now.year, now.month, 1);
          _endDate = DateTime(now.year, now.month + 1, 0);
          break;
        case 1: // 周
          final weekRange = _getWeekDateRange(now);
          _startDate = weekRange.start;
          _endDate = weekRange.end;
          break;
        case 2: // 年
          _startDate = DateTime(now.year, 1, 1);
          _endDate = DateTime(now.year, 12, 31);
          break;
        case 3: // 自定义
          _startDate = _startDate;
          _endDate = _endDate;
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 8, left: 8, right: 8),
                child: Row(
                  children: [
                    Text(
                      '图表',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _DatePickerHeaderDelegate(
                height: 48.0, // kTextTabBarHeight
                child: Container(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: TabBar(
                    controller: _tabController,
                    labelColor: Theme.of(context).primaryColor,
                    unselectedLabelColor: Colors.black54,
                    indicator: UnderlineTabIndicator(
                      borderSide: BorderSide(
                        width: 3,
                        color: Theme.of(context).primaryColor,
                      ),
                      insets: const EdgeInsets.symmetric(horizontal: 24),
                    ),
                    tabs: const [
                      Tab(text: '月'),
                      Tab(text: '周'),
                      Tab(text: '年'),
                      Tab(text: '自定义'),
                    ],
                  ),
                ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _DatePickerHeaderDelegate(
                height: 56.0,
                child: Container(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Visibility(
                          visible: _periodIndex != 3,
                          maintainSize: true,
                          maintainAnimation: true,
                          maintainState: true,
                          child: IconButton(
                            icon: const Icon(Icons.chevron_left, size: 20),
                            onPressed: () => _changePeriod(-1),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap:
                                _periodIndex == 3
                                    ? () => _showCustomDatePicker(context)
                                    : null,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: Text(
                                    _getPeriodLabel(),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                if (_periodIndex == 3)
                                  const Padding(
                                    padding: EdgeInsets.only(left: 4),
                                    child: Icon(
                                      Icons.edit,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                if (_isCurrentPeriod())
                                  Container(
                                    margin: const EdgeInsets.only(left: 6),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      _periodIndex == 0
                                          ? '本月'
                                          : _periodIndex == 1
                                          ? '本周'
                                          : _periodIndex == 2
                                          ? '今年'
                                          : '',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        Visibility(
                          visible: _periodIndex != 3,
                          maintainSize: true,
                          maintainAnimation: true,
                          maintainState: true,
                          child: IconButton(
                            icon: const Icon(Icons.chevron_right, size: 20),
                            onPressed: () => _changePeriod(1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Consumer<TransactionProvider>(
              builder: (context, provider, child) {
                final transactions = provider.getTransactionsInDateRange(
                  _startDate,
                  _endDate,
                );
                if (transactions.isEmpty) {
                  return SliverToBoxAdapter(
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.5,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.insert_drive_file_rounded,
                              size: 90,
                              color: Color(0xFFFBC02D),
                            ),
                            const SizedBox(height: 18),
                            const Text(
                              '您添加的账单统计分析将会显示在此处',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFFB0B0C0),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                return SliverList(
                  delegate: SliverChildListDelegate([
                    _buildSummaryCard(transactions),
                    _buildTrendChart(transactions),
                    _buildRatioSection(transactions),
                  ]),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(List<Transaction> transactions) {
    double totalIncome = 0;
    double totalExpense = 0;
    for (var t in transactions) {
      if (t.type == TransactionType.expense) {
        totalExpense += t.amount;
      } else {
        totalIncome += t.amount;
      }
    }
    final balance = totalIncome - totalExpense;
    final sum = totalIncome.abs() + totalExpense.abs();
    final expenseRatio = sum == 0 ? 0.0 : totalExpense.abs() / sum;
    final incomeRatio = sum == 0 ? 0.0 : totalIncome.abs() / sum;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFBC02D),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    '结余',
                    style: TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      FormatUtil.formatCurrency(balance),
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF43A047),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    '支出',
                    style: TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Stack(
                      children: [
                        Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: expenseRatio,
                          child: Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: const Color(0xFF43A047),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    FormatUtil.formatCurrency(totalExpense),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF43A047),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFD32F2F),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    '收入',
                    style: TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Stack(
                      children: [
                        Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: incomeRatio,
                          child: Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: const Color(0xFFD32F2F),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    FormatUtil.formatCurrency(totalIncome),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFD32F2F),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRatioSection(List<Transaction> transactions) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF7F7FA),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 14, top: 8),
              child: Row(
                children: [
                  const Text(
                    '占比',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                      color: Color(0xFF23232B),
                    ),
                  ),
                  const Spacer(),
                  _buildRatioToggleButton(true),
                  const SizedBox(width: 10),
                  _buildRatioToggleButton(false),
                ],
              ),
            ),
            RatioDetails(
              transactions: transactions,
              isExpense: _ratioIsExpense,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatioToggleButton(bool isExpense) {
    final bool selected = (isExpense == _ratioIsExpense);
    return GestureDetector(
      onTap:
          selected
              ? null
              : () {
                setState(() {
                  _ratioIsExpense = isExpense;
                });
              },
      child: Container(
        width: 54,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF545F92) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border:
              selected
                  ? null
                  : Border.all(color: const Color(0xFF545F92), width: 1),
        ),
        child: Text(
          isExpense ? '支出' : '收入',
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF545F92),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildTrendChart(List<Transaction> transactions) {
    List<double> trendData = [];
    List<String> xLabels = [];

    if (_periodIndex == 2) {
      // 年视图
      trendData = List.filled(12, 0.0);
      xLabels = List.generate(12, (index) => '${index + 1}月');
      final monthlyData = _groupTransactionsByMonth(
        transactions,
        _trendIsExpense,
      );
      monthlyData.forEach((month, amount) {
        if (month >= 1 && month <= 12) {
          trendData[month - 1] = amount;
        }
      });
    } else if (_periodIndex == 1) {
      // 周视图
      trendData = List.filled(7, 0.0);
      xLabels = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
      final dailyData = _groupTransactionsByDayOfWeek(
        transactions,
        _trendIsExpense,
      );
      dailyData.forEach((weekday, amount) {
        if (weekday >= 1 && weekday <= 7) {
          trendData[weekday - 1] = amount;
        }
      });
    } else {
      // 月视图和自定义视图
      final daysInRange = _endDate.difference(_startDate).inDays + 1;

      if (_periodIndex == 3 && daysInRange > 35) {
        // 大于35天的自定义范围，按月聚合
        final Map<String, double> monthlyData = {};
        DateTime tempDate = DateTime(_startDate.year, _startDate.month, 1);
        while (tempDate.isBefore(_endDate.add(const Duration(days: 1)))) {
          final key = DateFormat('yy/MM').format(tempDate);
          monthlyData[key] = 0.0;
          tempDate = DateTime(tempDate.year, tempDate.month + 1, 1);
        }

        final relevantTransactions = transactions.where(
          (t) => (t.type == TransactionType.expense) == _trendIsExpense,
        );

        for (final transaction in relevantTransactions) {
          final key = DateFormat('yy/MM').format(transaction.date);
          if (monthlyData.containsKey(key)) {
            monthlyData.update(key, (value) => value + transaction.amount);
          }
        }
        trendData = monthlyData.values.toList();
        xLabels = monthlyData.keys.toList();
      } else {
        // 月视图和短期自定义范围，按天聚合
        if (daysInRange <= 0) {
          trendData = [];
          xLabels = [];
        } else {
          trendData = List.filled(daysInRange, 0.0);

          final relevantTransactions = transactions.where(
            (t) => (t.type == TransactionType.expense) == _trendIsExpense,
          );

          for (final transaction in relevantTransactions) {
            final index = transaction.date.difference(_startDate).inDays;
            if (index >= 0 && index < daysInRange) {
              trendData[index] += transaction.amount;
            }
          }

          if (_periodIndex == 0) {
            // 月视图标签
            final daysInMonth = _endDate.day;
            final labelDays = <int>{1, daysInMonth};
            for (int i = 5; i < daysInMonth; i += 5) {
              labelDays.add(i);
            }
            xLabels = List.generate(daysInMonth, (i) {
              final day = i + 1;
              if (labelDays.contains(day)) {
                return '${_startDate.month}/$day';
              }
              return '';
            });
          } else {
            // 短期自定义视图标签
            xLabels = List.generate(daysInRange, (i) {
              final date = _startDate.add(Duration(days: i));
              if (daysInRange <= 7) {
                return DateFormat('M/d').format(date);
              }
              if (i == 0 || i == daysInRange - 1) {
                return DateFormat('M/d').format(date);
              }
              final interval = (daysInRange / 5).ceil();
              if (i % interval == 0) {
                return DateFormat('M/d').format(date);
              }
              return '';
            });
          }
        }
      }
    }

    return trend.TrendLineChart(
      data: trendData,
      xLabels: xLabels,
      isExpense: _trendIsExpense,
      onToggle: () {
        setState(() {
          _trendIsExpense = !_trendIsExpense;
        });
      },
    );
  }

  String _getPeriodLabel() {
    if (_periodIndex == 0) {
      return '${_endDate.year}年${_endDate.month.toString().padLeft(2, '0')}月';
    } else if (_periodIndex == 1) {
      final formatter = DateFormat('yyyy/MM/dd');
      return '${formatter.format(_startDate)}-${formatter.format(_endDate)}';
    } else if (_periodIndex == 2) {
      return '${_endDate.year}年';
    } else {
      final formatter = DateFormat('yyyy-MM-dd');
      return '${formatter.format(_startDate)} ~ ${formatter.format(_endDate)}';
    }
  }

  bool _isCurrentPeriod() {
    final now = DateTime.now();
    if (_periodIndex == 0) {
      return _startDate.year == now.year && _startDate.month == now.month;
    } else if (_periodIndex == 1) {
      final beginningOfWeek = now.subtract(Duration(days: now.weekday - 1));
      return _startDate.year == beginningOfWeek.year &&
          _startDate.month == beginningOfWeek.month &&
          _startDate.day == beginningOfWeek.day;
    } else if (_periodIndex == 2) {
      return _startDate.year == now.year;
    }
    return false;
  }

  void _changePeriod(int direction) {
    setState(() {
      if (_periodIndex == 0) {
        // 月
        _startDate = DateTime(_startDate.year, _startDate.month + direction, 1);
        _endDate = DateTime(_startDate.year, _startDate.month + 1, 0);
      } else if (_periodIndex == 1) {
        // 周
        final newDate = _startDate.add(Duration(days: 7 * direction));
        final weekRange = _getWeekDateRange(newDate);
        _startDate = weekRange.start;
        _endDate = weekRange.end;
      } else if (_periodIndex == 2) {
        // 年
        _startDate = DateTime(_startDate.year + direction, 1, 1);
        _endDate = DateTime(_startDate.year + direction, 12, 31);
      }
    });
  }

  Future<void> _showCustomDatePicker(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).primaryColor,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  DateTimeRange _getWeekDateRange(DateTime date) {
    // weekday is 1 for Monday and 7 for Sunday.
    final startOfWeek = date.subtract(Duration(days: date.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    return DateTimeRange(start: startOfWeek, end: endOfWeek);
  }

  Map<int, double> _groupTransactionsByMonth(
    List<Transaction> transactions,
    bool isExpense,
  ) {
    final data = <int, double>{};
    for (final t in transactions) {
      if ((t.type == TransactionType.expense) == isExpense) {
        final month = t.date.month;
        data.update(
          month,
          (value) => value + t.amount,
          ifAbsent: () => t.amount,
        );
      }
    }
    return data;
  }

  Map<int, double> _groupTransactionsByDayOfWeek(
    List<Transaction> transactions,
    bool isExpense,
  ) {
    final data = <int, double>{};
    for (final t in transactions) {
      if ((t.type == TransactionType.expense) == isExpense) {
        final weekday = t.date.weekday;
        data.update(
          weekday,
          (value) => value + t.amount,
          ifAbsent: () => t.amount,
        );
      }
    }
    return data;
  }

  Map<int, double> _groupTransactionsByDayOfMonth(
    List<Transaction> transactions,
    bool isExpense,
  ) {
    final data = <int, double>{};
    for (final t in transactions) {
      if ((t.type == TransactionType.expense) == isExpense) {
        final day = t.date.day;
        data.update(day, (value) => value + t.amount, ifAbsent: () => t.amount);
      }
    }
    return data;
  }
}

class _DatePickerHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double height;
  final Widget child;

  _DatePickerHeaderDelegate({required this.height, required this.child});

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(SliverPersistentHeaderDelegate oldDelegate) {
    return true;
  }
}
