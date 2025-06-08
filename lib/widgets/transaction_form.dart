import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../utils/format_util.dart';

class TransactionForm extends StatefulWidget {
  final Function(Transaction) onSubmit;
  final Function(Transaction)? onSubmitAndContinue;
  final Transaction? initialTransaction;

  const TransactionForm({
    super.key,
    required this.onSubmit,
    this.onSubmitAndContinue,
    this.initialTransaction,
  });

  @override
  State<TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends State<TransactionForm> {
  String _amountString = '0.0';
  final _noteController = TextEditingController();

  late TransactionType _type;
  late Category _category;
  late DateTime _date;
  late String _currency;

  @override
  void initState() {
    super.initState();
    if (widget.initialTransaction != null) {
      final transaction = widget.initialTransaction!;
      _amountString = transaction.amount
          .toStringAsFixed(2)
          .replaceAll('.00', '');
      _noteController.text = transaction.note ?? '';
      _type = transaction.type;
      _category = transaction.category;
      _date = transaction.date;
      _currency = transaction.currency;
    } else {
      _type = TransactionType.expense;
      _category = Category.food;
      _date = DateTime.now();
      _currency = 'CNY';
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _handleKeyPress(String key) {
    setState(() {
      if (key == 'BACKSPACE') {
        if (_amountString.length > 1) {
          _amountString = _amountString.substring(0, _amountString.length - 1);
          if (_amountString.endsWith('.')) {
            _amountString = _amountString.substring(
              0,
              _amountString.length - 1,
            );
          }
        } else {
          _amountString = '0.0';
        }
      } else if (key == '.') {
        if (!_amountString.contains('.')) {
          _amountString += '.';
        }
      } else {
        if (_amountString == '0.0') {
          _amountString = key;
        } else if (_amountString == '0') {
          _amountString = key;
        } else if (_amountString.contains('.') &&
            _amountString.split('.')[1].length < 2) {
          _amountString += key;
        } else if (!_amountString.contains('.')) {
          _amountString += key;
        }
      }
      if (_amountString.isEmpty) {
        _amountString = '0.0';
      }
    });
  }

  void _submit(bool addAnother) {
    final amount = double.tryParse(_amountString);
    if (amount == null || amount == 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('金额不能为0')));
      return;
    }

    final transaction = Transaction(
      id: widget.initialTransaction?.id,
      title:
          _noteController.text.isNotEmpty
              ? _noteController.text
              : FormatUtil.getCategoryName(_category),
      amount: amount,
      date: _date,
      type: _type,
      category: _category,
      note: _noteController.text,
      currency: _currency,
    );

    if (addAnother && widget.onSubmitAndContinue != null) {
      widget.onSubmitAndContinue!(transaction);
      setState(() {
        _amountString = '0.0';
        _noteController.clear();
        _category = Category.food;
        _type = TransactionType.expense;
        _currency = 'CNY';
      });
    } else {
      widget.onSubmit(transaction);
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _date) setState(() => _date = picked);
  }

  Future<void> _selectCurrency() async {
    final selectedCurrency = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('选择货币'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children:
                  ['CNY', 'USD']
                      .map(
                        (currency) => ListTile(
                          title: Text(currency),
                          onTap: () => Navigator.of(context).pop(currency),
                        ),
                      )
                      .toList(),
            ),
          ),
    );

    if (selectedCurrency != null) {
      setState(() {
        _currency = selectedCurrency;
      });
    }
  }

  void _showNoteEntryModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: _NoteInputSheet(noteController: _noteController),
        );
      },
    ).then((_) {
      // Refresh the state to show the updated note label on the button
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        Expanded(child: _buildCategoryGrid()),
        _buildDisplayAndActions(),
        _buildCalculatorKeyboard(),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Center(child: _buildTypeSelector()),
    );
  }

  Widget _buildTypeSelector() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: ToggleButtons(
        borderRadius: BorderRadius.circular(20),
        isSelected: [
          _type == TransactionType.expense,
          _type == TransactionType.income,
        ],
        onPressed:
            (index) => setState(() {
              _type =
                  index == 0 ? TransactionType.expense : TransactionType.income;
              if (_type == TransactionType.expense &&
                  !Category.values
                      .where((c) => c.isExpense)
                      .contains(_category)) {
                _category = Category.food;
              } else if (_type == TransactionType.income &&
                  !Category.values
                      .where((c) => c.isIncome)
                      .contains(_category)) {
                _category = Category.salary;
              }
            }),
        selectedColor: colorScheme.onPrimary,
        fillColor:
            _type == TransactionType.expense
                ? colorScheme.error
                : colorScheme.primary,
        color: colorScheme.onSurface,
        constraints: const BoxConstraints(minWidth: 80, minHeight: 36),
        children: const [Text('支出'), Text('收入')],
      ),
    );
  }

  Widget _buildCategoryGrid() {
    final colorScheme = Theme.of(context).colorScheme;
    final isExpense = _type == TransactionType.expense;
    final categories =
        isExpense
            ? Category.values.where((c) => c.isExpense).toList()
            : Category.values.where((c) => c.isIncome).toList();
    final Color selectedColor =
        isExpense ? colorScheme.error : colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          mainAxisSpacing: 8,
          crossAxisSpacing: 12,
          childAspectRatio: 0.9,
        ),
        itemCount: categories.length,
        itemBuilder: (context, idx) {
          final category = categories[idx];
          final selected = _category == category;
          return GestureDetector(
            onTap:
                () => setState(() {
                  _category = category;
                }),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color:
                        selected ? selectedColor : colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    FormatUtil.getCategoryIcon(category),
                    size: 22,
                    color:
                        selected
                            ? colorScheme.onPrimary
                            : colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  FormatUtil.getCategoryName(category),
                  style: TextStyle(fontSize: 11, color: colorScheme.onSurface),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDisplayAndActions() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _currency == 'CNY' ? '¥' : '\$',
                style: TextStyle(
                  fontSize: 28,
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _amountString,
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontSize: 40,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.start,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildActionButton(
                icon: Icons.calendar_today_outlined,
                label: DateFormat('M月d日').format(_date),
                onTap: _selectDate,
              ),
              const SizedBox(width: 12),
              Flexible(child: _buildNoteButton()),
              const SizedBox(width: 12),
              _buildActionButton(
                icon: Icons.monetization_on_outlined,
                label: _currency,
                onTap: _selectCurrency,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoteButton() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final noteText = _noteController.text;
    final noteLabel = noteText.isEmpty ? '备注' : noteText;

    return InkWell(
      onTap: _showNoteEntryModal,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              Icons.notes_rounded,
              size: 16,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                noteLabel,
                style: TextStyle(fontSize: 14, color: colorScheme.onSurface),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(fontSize: 14, color: colorScheme.onSurface),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalculatorKeyboard() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final keys = [
      '1',
      '2',
      '3',
      'BACKSPACE',
      '4',
      '5',
      '6',
      '再记',
      '7',
      '8',
      '9',
      '确定',
      '.',
      '0',
      '+',
      '-',
    ];

    return Container(
      key: const ValueKey('calculator-keyboard'),
      padding: const EdgeInsets.all(8.0),
      color: colorScheme.surface,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 1.4,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
        ),
        itemCount: keys.length,
        itemBuilder: (context, index) {
          final key = keys[index];

          // Style for special buttons
          if (key == '确定') {
            return _buildKey(
              key,
              onTap: () => _submit(false),
              backgroundColor: colorScheme.primary,
              textColor: colorScheme.onPrimary,
            );
          }
          if (key == '再记') {
            return _buildKey(
              key,
              onTap: () => _submit(true),
              backgroundColor: colorScheme.surface,
              textColor: colorScheme.onSurface,
            );
          }
          if (key == 'BACKSPACE') {
            return _buildKey(
              key,
              onTap: () => _handleKeyPress('BACKSPACE'),
              backgroundColor: colorScheme.surface,
              textColor: colorScheme.onSurface,
            );
          }
          if (key == '+' || key == '-') {
            // Disabled for now
            return _buildKey(
              key,
              backgroundColor: colorScheme.surface,
              textColor: colorScheme.onSurface.withOpacity(0.5),
            );
          }

          return _buildKey(
            key,
            onTap: () => _handleKeyPress(key),
            backgroundColor: Colors.transparent,
            textColor: colorScheme.onSurface,
          );
        },
      ),
    );
  }

  Widget _buildKey(
    String key, {
    VoidCallback? onTap,
    Color? backgroundColor,
    Color? textColor,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor ?? colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child:
              key == 'BACKSPACE'
                  ? Icon(Icons.backspace_outlined, color: textColor)
                  : Text(
                    key,
                    style: TextStyle(
                      fontSize: key == '再记' || key == '确定' ? 16 : 22,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
        ),
      ),
    );
  }
}

class _NoteInputSheet extends StatefulWidget {
  final TextEditingController noteController;

  const _NoteInputSheet({required this.noteController});

  @override
  State<_NoteInputSheet> createState() => _NoteInputSheetState();
}

class _NoteInputSheetState extends State<_NoteInputSheet> {
  bool _keyboardVisibleOnce = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    if (bottomInset > 0) {
      _keyboardVisibleOnce = true;
    }
    if (_keyboardVisibleOnce && bottomInset == 0 && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pop();
        }
      });
    }

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 12, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: TextField(
              controller: widget.noteController,
              autofocus: true,
              textAlignVertical: TextAlignVertical.center,
              decoration: InputDecoration(
                hintText: '点击输入备注',
                filled: true,
                fillColor: colorScheme.surfaceVariant.withOpacity(0.6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down),
            iconSize: 28,
            onPressed: () => Navigator.of(context).pop(),
            color: colorScheme.onSurface.withOpacity(0.6),
          ),
        ],
      ),
    );
  }
}
