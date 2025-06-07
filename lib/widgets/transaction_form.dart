import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/transaction.dart';
import '../utils/format_util.dart';
import '../utils/theme_util.dart';
import '../services/exchange_rate_service.dart';

class TransactionForm extends StatefulWidget {
  final Function(Transaction) onSubmit;
  final Transaction? initialTransaction;
  final String currency; // 添加 currency 属性

  const TransactionForm({
    super.key,
    required this.onSubmit,
    this.initialTransaction,
    this.currency = '¥', // 设置默认值，对应CNY
  });

  @override
  State<TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends State<TransactionForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  late TransactionType _type;
  late Category _category;
  late DateTime _date;
  late String _selectedCurrency;

  @override
  void initState() {
    super.initState();
    // 如果是编辑模式，则填充表单
    if (widget.initialTransaction != null) {
      _titleController.text = widget.initialTransaction!.title;
      _amountController.text = widget.initialTransaction!.amount.toString();
      _noteController.text = widget.initialTransaction!.note ?? '';
      _type = widget.initialTransaction!.type;
      _category = widget.initialTransaction!.category;
      _date = widget.initialTransaction!.date;
      // 确保货币代码在支持的列表中
      _selectedCurrency =
          ExchangeRateService.supportedCurrencies.keys.contains(
                widget.initialTransaction!.currency, // 检查货币代码
              )
              ? widget.initialTransaction!.currency
              : ExchangeRateService.supportedCurrencies.keys.first; // 使用货币代码
    } else {
      // 默认值
      _type = TransactionType.expense;
      _category = Category.food;
      _date = DateTime.now();
      // 确保货币代码在支持的列表中，如果widget.currency不在列表中，使用默认的第一个
      _selectedCurrency =
          ExchangeRateService.supportedCurrencies.keys.contains(
                widget.currency, // 检查货币代码
              )
              ? widget.currency
              : ExchangeRateService.supportedCurrencies.keys.first; // 使用货币代码
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  // 选择日期
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _date) {
      setState(() {
        _date = picked;
      });
    }
  }

  // 提交表单
  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final transaction = Transaction(
        id: widget.initialTransaction?.id, // 如果是编辑模式，则保留原ID
        title: _noteController.text, // 备注即为title
        amount: double.parse(_amountController.text),
        date: _date,
        type: _type,
        category: _category,
        note: null, // 不再单独存note
        currency: _selectedCurrency, // 使用用户选择的货币代码
      );
      widget.onSubmit(transaction);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isExpense = _type == TransactionType.expense;
    final categories =
        isExpense
            ? [
              Category.food, // 餐饮
              Category.takeout, // 外卖
              Category.shopping, // 购物
              Category.daily, // 日用品
              Category.entertainment, // 娱乐
              Category.transportation, // 交通
              Category.utilities, // 水电煤
              Category.phone, // 话费
              Category.internet, // 网费
              Category.snacks, // 零食水果
              Category.drinks, // 饮料酒水
              Category.clothes, // 服饰
              Category.study, // 学习
              Category.campus, // 校园卡
              Category.health, // 医疗
              Category.beauty, // 护肤美妆
              Category.digital, // 数码
              Category.smoke, // 烟酒
              Category.sports, // 运动
              Category.travel, // 旅行
              Category.pets, // 宠物
              Category.gift, // 礼物
              Category.fastmail, // 快递
              Category.rent, // 房租
              Category.other, // 其他
            ]
            : [Category.salary, Category.gift, Category.other];

    // 保证切换类型时分类不会越界
    if (!categories.contains(_category)) {
      _category = categories.first;
    }

    final Color mainGreen = const Color(0xFF34C759); // 柔和绿色
    final Color mainGreenDark = const Color(0xFF30B158);
    final Color mainRed = const Color(0xFFFF3B30);

    return SingleChildScrollView(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF8FFF6), Color(0xFFE6F9ED)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 顶部自定义Tab+关闭按钮
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, size: 28),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Spacer(),
                    ToggleButtons(
                      borderRadius: BorderRadius.circular(20),
                      isSelected: [
                        _type == TransactionType.expense,
                        _type == TransactionType.income,
                      ],
                      onPressed: (index) {
                        setState(() {
                          _type =
                              index == 0
                                  ? TransactionType.expense
                                  : TransactionType.income;
                        });
                      },
                      selectedColor: Colors.white,
                      fillColor:
                          _type == TransactionType.expense
                              ? mainRed
                              : mainGreen,
                      color: Colors.grey[600],
                      constraints: const BoxConstraints(
                        minWidth: 80,
                        minHeight: 36,
                      ),
                      children: const [
                        Text(
                          '支出',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '收入',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(flex: 2),
                  ],
                ),
                const SizedBox(height: 16),
                // 类别选择区（支出/收入类别分开，支出更丰富，支持滑动）
                SizedBox(
                  height: isExpense ? 320 : 100,
                  child: GridView.builder(
                    physics: const BouncingScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 1.1,
                    ),
                    itemCount: categories.length,
                    itemBuilder: (context, idx) {
                      final category = categories[idx];
                      final selected = _category == category;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _category = category;
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color:
                                selected
                                    ? (_type == TransactionType.income
                                        ? mainGreen
                                        : mainRed.withOpacity(0.85))
                                    : Colors.grey[100],
                            borderRadius: BorderRadius.circular(22),
                            boxShadow:
                                selected
                                    ? [
                                      BoxShadow(
                                        color: (_type == TransactionType.income
                                                ? mainGreen
                                                : mainRed)
                                            .withAlpha(30),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                    : [],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                FormatUtil.getCategoryIcon(category),
                                size: 24,
                                color: selected ? Colors.white : Colors.black87,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                FormatUtil.getCategoryName(category),
                                style: TextStyle(
                                  fontSize: 13,
                                  color:
                                      selected ? Colors.white : Colors.black87,
                                  fontWeight:
                                      selected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                // 金额与货币类型并列
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: SizedBox(
                        height: 56,
                        child: TextFormField(
                          controller: _amountController,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: const BorderRadius.all(
                                Radius.circular(16),
                              ),
                              borderSide: BorderSide(
                                color: mainGreen,
                                width: 1.2,
                              ),
                            ),
                            hintText: '0.0',
                            prefixIcon: Padding(
                              padding: const EdgeInsets.only(
                                left: 16,
                                right: 8,
                              ),
                              child: Text(
                                ExchangeRateService.getCurrencySymbol(
                                  _selectedCurrency,
                                ),
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            prefixIconConstraints: const BoxConstraints(
                              minWidth: 0,
                              minHeight: 0,
                            ),
                            hintStyle: const TextStyle(
                              fontSize: 20,
                              color: Colors.grey,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 14,
                            ),
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[\d\.]'),
                            ),
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '请输入金额';
                            }
                            try {
                              final amount = double.parse(value);
                              if (amount <= 0) {
                                return '金额必须大于0';
                              }
                            } catch (e) {
                              return '请输入有效的金额';
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: SizedBox(
                        height: 56,
                        child: DropdownButtonFormField<String>(
                          value: _selectedCurrency,
                          isExpanded: true,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: const BorderRadius.all(
                                Radius.circular(16),
                              ),
                              borderSide: BorderSide(
                                color: mainGreen,
                                width: 1.2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 14,
                            ),
                          ),
                          items:
                              [
                                    MapEntry(
                                      'CNY',
                                      ExchangeRateService
                                              .supportedCurrencies['CNY'] ??
                                          '¥',
                                    ),
                                    MapEntry(
                                      'USD',
                                      ExchangeRateService
                                              .supportedCurrencies['USD'] ??
                                          ' 24',
                                    ),
                                  ]
                                  .map(
                                    (entry) => DropdownMenuItem<String>(
                                      value: entry.key,
                                      child: Text(
                                        entry.key,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedCurrency = value;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // 日期选择
                InkWell(
                  onTap: _selectDate,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: '日期',
                      prefixIcon: const Icon(Icons.calendar_today),
                      border: OutlineInputBorder(
                        borderRadius: const BorderRadius.all(
                          Radius.circular(16),
                        ),
                        borderSide: BorderSide(color: mainGreen, width: 1.2),
                      ),
                    ),
                    child: Text(
                      FormatUtil.formatDate(_date),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // 备注（单行）
                TextFormField(
                  controller: _noteController,
                  decoration: InputDecoration(
                    labelText: '备注',
                    prefixIcon: const Icon(Icons.note),
                    border: OutlineInputBorder(
                      borderRadius: const BorderRadius.all(Radius.circular(16)),
                      borderSide: BorderSide(color: mainGreen, width: 1.2),
                    ),
                  ),
                  maxLines: 1,
                ),
                const SizedBox(height: 24),
                // 提交按钮
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      elevation: 2,
                      backgroundColor: mainGreen,
                    ),
                    onPressed: _submitForm,
                    child: Text(
                      widget.initialTransaction == null ? '添加' : '更新',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
