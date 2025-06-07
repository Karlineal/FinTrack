import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../widgets/expense_chart.dart';
import '../utils/format_util.dart';
import '../utils/theme_util.dart';
import '../widgets/trend_line_chart.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_handleTabSelection);
    // 初始化时，默认显示当月
    _updateDateRangeForIndex(0);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabSelection() {
    // 仅当动画结束且index确实改变时才更新
    if (!_tabController.indexIsChanging &&
        _periodIndex != _tabController.index) {
      _updateDateRangeForIndex(_tabController.index);
    }
  }

  // 新增：根据tab index更新日期范围和状态
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
          _startDate = now.subtract(Duration(days: now.weekday - 1));
          _endDate = _startDate.add(const Duration(days: 6));
          break;
        case 2: // 年
          _startDate = DateTime(now.year, 1, 1);
          _endDate = DateTime(now.year, 12, 31);
          break;
        case 3: // 自定义
          // 自定义模式下，默认显示最近30天，或保持用户上次选择的范围
          if (_startDate == null || _endDate == null) {
            _startDate = now.subtract(const Duration(days: 30));
            _endDate = now;
          }
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
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
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
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left, size: 20),
                      onPressed: () => _changePeriod(-1),
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
                    if (!_isCurrentPeriod() && _periodIndex != 3)
                      IconButton(
                        icon: const Icon(Icons.chevron_right, size: 20),
                        onPressed: () => _changePeriod(1),
                      )
                    else
                      // 使用占位符保持布局稳定
                      const SizedBox(width: 48),
                  ],
                ),
              ),
            ),
            // 主要内容区块全部放入SliverList，便于后续插入更多功能
            SliverList(
              delegate: SliverChildListDelegate([
                if (Provider.of<TransactionProvider>(context, listen: false)
                    .transactions
                    .where(
                      (t) =>
                          !t.date.isBefore(_startDate) &&
                          !t.date.isAfter(_endDate),
                    )
                    .isEmpty)
                  // 空状态
                  SizedBox(
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
                  )
                else ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    child: Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Consumer<TransactionProvider>(
                          builder: (context, provider, child) {
                            final totalIncome = provider.totalIncome;
                            final totalExpense = provider.totalExpense;
                            final balance = provider.balance;
                            final sum = totalIncome.abs() + totalExpense.abs();
                            final expenseRatio =
                                sum == 0 ? 0.5 : totalExpense.abs() / sum;
                            final incomeRatio =
                                sum == 0 ? 0.5 : totalIncome.abs() / sum;
                            return Column(
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
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        balance.toStringAsFixed(2),
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
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Stack(
                                        children: [
                                          Container(
                                            height: 6,
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade200,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                          ),
                                          FractionallySizedBox(
                                            widthFactor: expenseRatio,
                                            child: Container(
                                              height: 6,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF43A047),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      totalExpense.toStringAsFixed(2),
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
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Stack(
                                        children: [
                                          Container(
                                            height: 6,
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade200,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                          ),
                                          FractionallySizedBox(
                                            widthFactor: incomeRatio,
                                            child: Container(
                                              height: 6,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFD32F2F),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      totalIncome.toStringAsFixed(2),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFFD32F2F),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  // 趋势折线图模块
                  Consumer<TransactionProvider>(
                    builder: (context, provider, child) {
                      final List<Transaction> filtered =
                          provider.transactions
                              .where(
                                (t) =>
                                    !t.date.isBefore(_startDate) &&
                                    !t.date.isAfter(_endDate),
                              )
                              .toList();
                      List<String> xLabels;
                      List<double> yData;
                      List<int> labelIndexes;
                      if (_periodIndex == 2) {
                        // 年视图，固定为1-12月
                        xLabels = List.generate(12, (i) => '${i + 1}月');
                        yData = List.filled(12, 0);
                        for (final t in filtered) {
                          final idx = t.date.month - 1;
                          if (idx >= 0 && idx < 12) {
                            if (_trendIsExpense)
                              yData[idx] +=
                                  t.type == TransactionType.expense
                                      ? t.amount
                                      : 0;
                            else
                              yData[idx] +=
                                  t.type == TransactionType.income
                                      ? t.amount
                                      : 0;
                          }
                        }
                        labelIndexes = [0, 3, 6, 9, 11];
                      } else if (_periodIndex == 3) {
                        // 自定义视图，不显示横坐标标签
                        yData = List.filled(3, 0);
                        // 数据统计逻辑保持不变
                        final totalDays =
                            _endDate.difference(_startDate).inDays;
                        final midDays = (totalDays / 2).floor();
                        final midDate = _startDate.add(Duration(days: midDays));
                        for (final t in filtered) {
                          if (!t.date.isBefore(_startDate) &&
                              t.date.isBefore(midDate)) {
                            if (_trendIsExpense)
                              yData[0] +=
                                  t.type == TransactionType.expense
                                      ? t.amount
                                      : 0;
                            else
                              yData[0] +=
                                  t.type == TransactionType.income
                                      ? t.amount
                                      : 0;
                          } else if (!t.date.isBefore(midDate) &&
                              t.date.isBefore(_endDate)) {
                            if (_trendIsExpense)
                              yData[1] +=
                                  t.type == TransactionType.expense
                                      ? t.amount
                                      : 0;
                            else
                              yData[1] +=
                                  t.type == TransactionType.income
                                      ? t.amount
                                      : 0;
                          } else if (t.date.isAtSameMomentAs(_endDate)) {
                            if (_trendIsExpense)
                              yData[2] +=
                                  t.type == TransactionType.expense
                                      ? t.amount
                                      : 0;
                            else
                              yData[2] +=
                                  t.type == TransactionType.income
                                      ? t.amount
                                      : 0;
                          }
                        }
                        xLabels = List.filled(3, '');
                        labelIndexes = [];
                      } else if (_periodIndex == 1) {
                        // 周视图按7天（日）铺满
                        final days = _endDate.difference(_startDate).inDays + 1;
                        xLabels = List.generate(days, (i) {
                          final d = _startDate.add(Duration(days: i));
                          return '${d.month}/${d.day}';
                        });
                        labelIndexes = List.generate(days, (i) => i);
                        yData = List.filled(days, 0);
                        for (final t in filtered) {
                          final idx = t.date.difference(_startDate).inDays;
                          if (idx >= 0 && idx < days) {
                            if (_trendIsExpense)
                              yData[idx] +=
                                  t.type == TransactionType.expense
                                      ? t.amount
                                      : 0;
                            else
                              yData[idx] +=
                                  t.type == TransactionType.income
                                      ? t.amount
                                      : 0;
                          }
                        }
                      } else {
                        // 月视图，xLabels为每天，labelIndexes固定为1号、5号、10号、15号、20号、25号和最后一天
                        final days = _endDate.difference(_startDate).inDays + 1;
                        xLabels = List.generate(days, (i) {
                          final d = _startDate.add(Duration(days: i));
                          return '${d.month}/${d.day}';
                        });
                        // 固定显示1号、5号、10号、15号、20号、25号和最后一天，自动适配2月等特殊月份
                        List<int> wantedDays = [1, 5, 10, 15, 20, 25];
                        labelIndexes =
                            wantedDays
                                .map((d) => d - 1)
                                .where((i) => i >= 0 && i < days)
                                .toList();
                        if (!labelIndexes.contains(days - 1))
                          labelIndexes.add(days - 1);
                        yData = List.filled(days, 0);
                        for (final t in filtered) {
                          final idx = t.date.difference(_startDate).inDays;
                          if (idx >= 0 && idx < days) {
                            if (_trendIsExpense)
                              yData[idx] +=
                                  t.type == TransactionType.expense
                                      ? t.amount
                                      : 0;
                            else
                              yData[idx] +=
                                  t.type == TransactionType.income
                                      ? t.amount
                                      : 0;
                          }
                        }
                      }
                      return TrendLineChart(
                        data: yData,
                        xLabels: xLabels,
                        isExpense: _trendIsExpense,
                        onToggle: () {
                          setState(() {
                            _trendIsExpense = !_trendIsExpense;
                          });
                        },
                        labelIndexes: labelIndexes,
                      );
                    },
                  ),
                  // ...后续功能区块可直接在此添加
                ],
              ]),
            ),
          ],
        ),
      ),
    );
  }

  // 新增：自定义日期区间选择弹窗
  Future<void> _showCustomDatePicker(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('自定义日期范围'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final provider = Provider.of<TransactionProvider>(
                    context,
                    listen: false,
                  );
                  if (provider.transactions.isEmpty) return;
                  final sorted = List.of(provider.transactions)
                    ..sort((a, b) => a.date.compareTo(b.date));
                  final firstDate = DateTime(2020, 1, 1); // 允许任意早期日期
                  final lastDate = sorted.last.date;
                  // clamp initialDateRange
                  final initialStart =
                      _startDate.isBefore(firstDate)
                          ? firstDate
                          : _startDate.isAfter(lastDate)
                          ? lastDate
                          : _startDate;
                  final initialEnd =
                      _endDate.isAfter(lastDate)
                          ? lastDate
                          : _endDate.isBefore(firstDate)
                          ? firstDate
                          : _endDate;
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: firstDate,
                    lastDate: lastDate,
                    initialDateRange: DateTimeRange(
                      start: initialStart,
                      end: initialEnd,
                    ),
                  );
                  if (picked != null) {
                    setState(() {
                      _startDate = picked.start;
                      _endDate = picked.end;
                    });
                  }
                },
              ),
              ListTile(
                title: const Text('全部时间'),
                onTap: () {
                  Navigator.pop(ctx);
                  final provider = Provider.of<TransactionProvider>(
                    context,
                    listen: false,
                  );
                  if (provider.transactions.isNotEmpty) {
                    final sorted = List.of(provider.transactions)
                      ..sort((a, b) => a.date.compareTo(b.date));
                    setState(() {
                      _startDate = sorted.first.date;
                      _endDate = sorted.last.date;
                    });
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // 新增：周期切换逻辑
  void _changePeriod(int direction) {
    setState(() {
      final now = DateTime.now();
      if (_periodIndex == 0) {
        // 月
        _startDate = DateTime(_startDate.year, _startDate.month + direction, 1);
        _endDate = DateTime(_startDate.year, _startDate.month + 1, 0);
      } else if (_periodIndex == 1) {
        // 周
        _startDate = _startDate.add(Duration(days: 7 * direction));
        _endDate = _startDate.add(const Duration(days: 6));
      } else if (_periodIndex == 2) {
        // 年
        _startDate = DateTime(_startDate.year + direction, 1, 1);
        _endDate = DateTime(_startDate.year, 12, 31);
      }
      // 自定义模式下，此函数不被调用
    });
  }

  bool _isCurrentPeriod() {
    final now = DateTime.now();
    if (_periodIndex == 0) {
      return _endDate.year == now.year && _endDate.month == now.month;
    } else if (_periodIndex == 1) {
      final monday = now.subtract(Duration(days: now.weekday - 1));
      return _startDate.year == monday.year &&
          _startDate.month == monday.month &&
          _startDate.day == monday.day;
    } else if (_periodIndex == 2) {
      return _endDate.year == now.year;
    } else {
      return false;
    }
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
}
