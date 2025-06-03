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
      // 确保货币符号在支持的列表中
      _selectedCurrency =
          ExchangeRateService.supportedCurrencies.values.contains(
                widget.initialTransaction!.currency,
              )
              ? widget.initialTransaction!.currency
              : ExchangeRateService.supportedCurrencies.values.first;
    } else {
      // 默认值
      _type = TransactionType.expense;
      _category = Category.food;
      _date = DateTime.now();
      // 确保货币符号在支持的列表中，如果widget.currency不在列表中，使用默认的第一个
      _selectedCurrency =
          ExchangeRateService.supportedCurrencies.values.contains(
                widget.currency,
              )
              ? widget.currency
              : ExchangeRateService.supportedCurrencies.values.first;
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
        title: _titleController.text,
        amount: double.parse(_amountController.text),
        date: _date,
        type: _type,
        category: _category,
        note: _noteController.text.isEmpty ? null : _noteController.text,
        currency: _selectedCurrency, // 使用用户选择的货币
      );

      widget.onSubmit(transaction);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 交易类型选择
          _buildTypeSelector(),
          const SizedBox(height: 16),

          // 标题
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: '标题',
              prefixIcon: Icon(Icons.title),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '请输入标题';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // 金额和货币选择
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: _amountController,
                  decoration: InputDecoration(
                    labelText: '金额',
                    prefixIcon: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(
                        _selectedCurrency,
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d\.]')),
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
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  value: _selectedCurrency,
                  decoration: const InputDecoration(
                    labelText: '货币',
                    prefixIcon: Icon(Icons.monetization_on),
                  ),
                  items:
                      ExchangeRateService.supportedCurrencies.entries
                          .map(
                            (entry) => DropdownMenuItem<String>(
                              value: entry.value, // 货币符号作为值
                              child: Text('${entry.value} (${entry.key})'),
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
            ],
          ),
          const SizedBox(height: 16),

          // 日期选择
          InkWell(
            onTap: _selectDate,
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: '日期',
                prefixIcon: Icon(Icons.calendar_today),
              ),
              child: Text(
                FormatUtil.formatDate(_date),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 类别选择
          _buildCategorySelector(),
          const SizedBox(height: 16),

          // 备注
          TextFormField(
            controller: _noteController,
            decoration: const InputDecoration(
              labelText: '备注（可选）',
              prefixIcon: Icon(Icons.note),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 24),

          // 提交按钮
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitForm,
              child: Text(
                widget.initialTransaction == null ? '添加' : '更新',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 交易类型选择器
  Widget _buildTypeSelector() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _type = TransactionType.expense;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color:
                    _type == TransactionType.expense
                        ? ThemeUtil.expenseColor
                        : ThemeUtil.expenseColor.withAlpha((0.1 * 255).round()),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  bottomLeft: Radius.circular(8),
                ),
              ),
              child: Text(
                '支出',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color:
                      _type == TransactionType.expense
                          ? Colors.white
                          : ThemeUtil.expenseColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _type = TransactionType.income;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color:
                    _type == TransactionType.income
                        ? ThemeUtil.incomeColor
                        : ThemeUtil.incomeColor.withAlpha((0.1 * 255).round()),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: Text(
                '收入',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color:
                      _type == TransactionType.income
                          ? Colors.white
                          : ThemeUtil.incomeColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 类别选择器
  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '类别',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              Category.values.map((category) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _category = category;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color:
                          _category == category
                              ? (_type == TransactionType.income
                                  ? ThemeUtil.incomeColor
                                  : ThemeUtil.expenseColor)
                              : Colors.grey.withAlpha((0.1 * 255).round()),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(FormatUtil.getCategoryIcon(category), size: 16),
                        const SizedBox(width: 4),
                        Text(
                          FormatUtil.getCategoryName(category),
                          style: TextStyle(
                            color:
                                _category == category
                                    ? Colors.white
                                    : Theme.of(context).colorScheme.onSurface,
                            fontWeight:
                                _category == category
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }
}
