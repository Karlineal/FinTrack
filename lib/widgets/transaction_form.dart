import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/transaction.dart';
import '../utils/format_util.dart';
import '../services/exchange_rate_service.dart';

class TransactionForm extends StatefulWidget {
  final Function(Transaction) onSubmit;
  final Transaction? initialTransaction;

  const TransactionForm({
    super.key,
    required this.onSubmit,
    this.initialTransaction,
  });

  @override
  State<TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends State<TransactionForm> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  late TransactionType _type;
  late Category _category;
  late DateTime _date;
  late String _selectedCurrency;

  @override
  void initState() {
    super.initState();
    if (widget.initialTransaction != null) {
      final transaction = widget.initialTransaction!;
      _amountController.text = transaction.amount.toString();
      _noteController.text = transaction.note ?? '';
      _type = transaction.type;
      _category = transaction.category;
      _date = transaction.date;
      _selectedCurrency = transaction.currency;
    } else {
      _type = TransactionType.expense;
      _category = Category.food;
      _date = DateTime.now();
      _selectedCurrency = 'CNY';
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary:
                  _type == TransactionType.expense ? Colors.red : Colors.green,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor:
                    _type == TransactionType.expense
                        ? Colors.red
                        : Colors.green,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _date) {
      setState(() {
        _date = picked;
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final transaction = Transaction(
        id: widget.initialTransaction?.id,
        title:
            _noteController.text.isNotEmpty
                ? _noteController.text
                : FormatUtil.getCategoryName(_category),
        amount: double.tryParse(_amountController.text) ?? 0.0,
        date: _date,
        type: _type,
        category: _category,
        note: _noteController.text,
        currency: _selectedCurrency,
      );
      widget.onSubmit(transaction);
    }
  }

  Future<void> _showNoteDialog() async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('添加备注'),
          content: TextField(
            controller: _noteController,
            autofocus: true,
            decoration: const InputDecoration(hintText: '写点什么...'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                setState(() {}); // To rebuild and show the note text
                Navigator.of(context).pop();
              },
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 24),
                      _buildCategoryGrid(),
                      const SizedBox(height: 24),
                      _buildCalculatorStyleInputs(),
                    ],
                  ),
                ),
              ),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.close, size: 28),
            onPressed: () => Navigator.of(context).pop(),
          ),
          _buildTypeSelector(),
          SizedBox(width: 48), // Balance the close button
        ],
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      child: ToggleButtons(
        borderRadius: BorderRadius.circular(20),
        isSelected: [
          _type == TransactionType.expense,
          _type == TransactionType.income,
        ],
        onPressed: (index) {
          setState(() {
            _type =
                index == 0 ? TransactionType.expense : TransactionType.income;
            if (_type == TransactionType.expense &&
                !Category.values
                    .where(
                      (c) =>
                          c != Category.salary &&
                          c != Category.gift &&
                          c != Category.other,
                    )
                    .contains(_category)) {
              _category = Category.food;
            } else if (_type == TransactionType.income &&
                ![
                  Category.salary,
                  Category.gift,
                  Category.other,
                ].contains(_category)) {
              _category = Category.salary;
            }
          });
        },
        selectedColor: Colors.white,
        fillColor: _type == TransactionType.expense ? Colors.red : Colors.green,
        color: Colors.black,
        constraints: const BoxConstraints(minWidth: 80, minHeight: 36),
        children: const [Text('支出'), Text('收入')],
      ),
    );
  }

  Widget _buildCategoryGrid() {
    final isExpense = _type == TransactionType.expense;
    final categories =
        isExpense
            ? Category.values
                .where(
                  (c) =>
                      c != Category.salary &&
                      c != Category.gift &&
                      c != Category.other,
                )
                .toList()
            : [Category.salary, Category.gift, Category.other];

    final Color selectedColor = isExpense ? Colors.red : Colors.green;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemCount: categories.length,
      itemBuilder: (context, idx) {
        final category = categories[idx];
        final selected = _category == category;
        return GestureDetector(
          onTap: () => setState(() => _category = category),
          child: Container(
            decoration: BoxDecoration(
              color: selected ? selectedColor : Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
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
                    color: selected ? Colors.white : Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCalculatorStyleInputs() {
    final Color selectedColor =
        _type == TransactionType.expense ? Colors.red : Colors.green;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildAmountInput(selectedColor),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          _buildInputActions(),
        ],
      ),
    );
  }

  Widget _buildAmountInput(Color selectedColor) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _amountController,
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: selectedColor,
            ),
            textAlign: TextAlign.start,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: '0.00',
              hintStyle: TextStyle(color: Colors.grey[300], fontSize: 36),
              border: InputBorder.none,
              focusedBorder: InputBorder.none,
              enabledBorder: InputBorder.none,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return '请输入金额';
              if (double.tryParse(value) == null) return '请输入有效数字';
              if (double.parse(value) <= 0) return '金额必须大于0';
              return null;
            },
          ),
        ),
        const SizedBox(width: 12),
        DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _selectedCurrency,
            items:
                ExchangeRateService.supportedCurrencies.keys.map((String key) {
                  return DropdownMenuItem<String>(
                    value: key,
                    child: Text(
                      key,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  );
                }).toList(),
            onChanged: (value) {
              if (value != null) setState(() => _selectedCurrency = value);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildInputActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildActionButton(
          icon: Icons.calendar_today_outlined,
          label: FormatUtil.formatDate(_date),
          onTap: _selectDate,
        ),
        _buildActionButton(
          icon: Icons.note_outlined,
          label: _noteController.text.isEmpty ? '备注' : _noteController.text,
          onTap: _showNoteDialog,
          isNote: true,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isNote = false,
  }) {
    return TextButton.icon(
      icon: Icon(icon, color: Colors.grey[600]),
      label: Flexible(
        child: Text(
          label,
          style: TextStyle(
            color: Colors.grey[800],
            fontWeight: FontWeight.normal,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      onPressed: onTap,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          onPressed: _submitForm,
          child: Text(
            widget.initialTransaction == null ? '添加' : '更新',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}
