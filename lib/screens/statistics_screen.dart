import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../widgets/expense_chart.dart';
import '../utils/format_util.dart';
import '../utils/theme_util.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  TransactionType _selectedType = TransactionType.expense;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _selectedType =
              _tabController.index == 0
                  ? TransactionType.expense
                  : TransactionType.income;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // 日期选择器
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _selectDate(context, true),
                    child: Text(
                      '从: ${DateFormat('yyyy-MM-dd').format(_startDate)}',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _selectDate(context, false),
                    child: Text(
                      '至: ${DateFormat('yyyy-MM-dd').format(_endDate)}',
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 收入/支出选项卡
          TabBar(
            controller: _tabController,
            tabs: const [Tab(text: '支出'), Tab(text: '收入')],
          ),

          // 图表和统计内容
          Expanded(
            child: Consumer<TransactionProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                // 根据选择的日期范围和类型筛选交易
                // 根据选择的日期范围和类型筛选交易
                // 先加载数据
                provider.loadTransactionsByDateRange(_startDate, _endDate);
                final filteredTransactions =
                    provider.transactions
                        .where((t) => t.type == _selectedType)
                        .toList();

                // 按类别分组
                final categoryData =
                    _selectedType == TransactionType.expense
                        ? provider.getExpenseStatsByCategory()
                        : provider.getIncomeStatsByCategory();

                if (filteredTransactions.isEmpty) {
                  return Center(
                    child: Text(
                      '所选时间段内没有${_selectedType == TransactionType.expense ? "支出" : "收入"}记录',
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // 总金额
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '总${_selectedType == TransactionType.expense ? "支出" : "收入"}: ',
                                style: const TextStyle(fontSize: 18),
                              ),
                              Text(
                                FormatUtil.formatCurrency(
                                  categoryData.values.fold(
                                    0,
                                    (sum, amount) => sum + amount,
                                  ),
                                ),
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      _selectedType == TransactionType.expense
                                          ? ThemeUtil.expenseColor
                                          : ThemeUtil.incomeColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // 饼图
                      Expanded(
                        flex: 3,
                        child: ExpenseChart(
                          categoryData: categoryData,
                          total: categoryData.values.fold(
                            0,
                            (sum, val) => sum + val,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // 类别列表
                      Expanded(
                        flex: 2,
                        child: Card(
                          elevation: 2,
                          child: ListView(
                            children:
                                categoryData.entries.map((entry) {
                                  final category = entry.key;
                                  final amount = entry.value;
                                  final percentage =
                                      amount /
                                      categoryData.values.fold(
                                        0,
                                        (sum, val) => sum + val,
                                      ) *
                                      100;

                                  return ListTile(
                                    leading: Icon(
                                      FormatUtil.getCategoryIcon(category),
                                      color: ThemeUtil.getCategoryColor(
                                        category,
                                      ),
                                    ),
                                    title: Text(
                                      FormatUtil.getCategoryName(category),
                                    ),
                                    trailing: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          FormatUtil.formatCurrency(amount),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          '${percentage.toStringAsFixed(1)}%',
                                          style: const TextStyle(
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          // 确保开始日期不晚于结束日期
          if (_startDate.isAfter(_endDate)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = picked;
          // 确保结束日期不早于开始日期
          if (_endDate.isBefore(_startDate)) {
            _startDate = _endDate;
          }
        }
      });
    }
  }
}
