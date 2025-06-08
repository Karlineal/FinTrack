import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../widgets/transaction_list_item.dart';
import 'transaction_detail_screen.dart';
import '../utils/format_util.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  // Use a dialog controller for search term
  final _searchDialogController = TextEditingController();
  // Controllers for the amount dialog
  final _minAmountDialogController = TextEditingController();
  final _maxAmountDialogController = TextEditingController();

  String _searchTerm = '';
  final List<TransactionType> _selectedTypes = [
    TransactionType.expense,
    TransactionType.income,
  ];
  double? _minAmount;
  double? _maxAmount;

  @override
  void initState() {
    super.initState();
    // Initialize dialog controllers
    _searchDialogController.text = _searchTerm;
    _minAmountDialogController.text = _minAmount?.toString() ?? '';
    _maxAmountDialogController.text = _maxAmount?.toString() ?? '';
  }

  @override
  void dispose() {
    _searchDialogController.dispose();
    _minAmountDialogController.dispose();
    _maxAmountDialogController.dispose();
    super.dispose();
  }

  void _toggleType(TransactionType type) {
    setState(() {
      if (_selectedTypes.contains(type)) {
        _selectedTypes.remove(type);
      } else {
        _selectedTypes.add(type);
      }
    });
  }

  List<Transaction> _getFilteredTransactions(
    List<Transaction> allTransactions,
  ) {
    return allTransactions.where((t) {
      final categoryName = FormatUtil.getCategoryName(t.category);
      final note = t.note ?? '';
      final title = t.title;

      final matchesSearchTerm =
          _searchTerm.isEmpty ||
          note.toLowerCase().contains(_searchTerm.toLowerCase()) ||
          categoryName.toLowerCase().contains(_searchTerm.toLowerCase()) ||
          title.toLowerCase().contains(_searchTerm.toLowerCase());

      final matchesType =
          _selectedTypes.isEmpty || _selectedTypes.contains(t.type);

      final min = _minAmount;
      final max = _maxAmount;
      final matchesAmount =
          (min == null || t.amount >= min) && (max == null || t.amount <= max);

      return matchesSearchTerm && matchesType && matchesAmount;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransactionProvider>(context, listen: false);
    final allTransactions = provider.convertedTransactions;
    final filteredTransactions = _getFilteredTransactions(allTransactions);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '搜索账单',
          style: TextStyle(
            color:
                Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
          ),
        ),
        leading: BackButton(
          color:
              Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black,
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        actions: <Widget>[
          IconButton(
            icon: Icon(
              Icons.close,
              color:
                  Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          const Divider(height: 1, thickness: 1),
          Expanded(
            child:
                filteredTransactions.isEmpty
                    ? Center(
                      child: Text(
                        '没有找到匹配的交易',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                        ),
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.only(top: 8),
                      itemCount: filteredTransactions.length,
                      itemBuilder: (context, index) {
                        final transaction = filteredTransactions[index];
                        return TransactionListItem(
                          transaction: transaction,
                          dateFormat: 'yyyy-MM-dd',
                          onTap: () {
                            // Hide keyboard when navigating away
                            FocusScope.of(context).unfocus();
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
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Wrap(
        spacing: 8.0,
        runSpacing: 4.0,
        alignment: WrapAlignment.start,
        children: [
          _buildKeywordFilterChip(),
          _buildAmountFilterChip(),
          _buildTypeFilterChip(TransactionType.income, '收入'),
          _buildTypeFilterChip(TransactionType.expense, '支出'),
        ],
      ),
    );
  }

  Widget _buildKeywordFilterChip() {
    final bool isActive = _searchTerm.isNotEmpty;
    String label = isActive ? _searchTerm : '关键字';
    if (label.length > 10) {
      label = '${label.substring(0, 8)}...';
    }

    return FilterChip(
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      selected: isActive,
      onSelected: (_) => _showKeywordDialog(),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color:
              isActive ? Theme.of(context).primaryColor : Colors.grey.shade400,
          width: 1,
        ),
      ),
      backgroundColor:
          isActive
              ? Theme.of(context).primaryColor.withAlpha((0.1 * 255).round())
              : Colors.transparent,
      selectedColor: Theme.of(
        context,
      ).primaryColor.withAlpha((0.1 * 255).round()),
      showCheckmark: false,
    );
  }

  Widget _buildAmountFilterChip() {
    final bool isActive = _minAmount != null || _maxAmount != null;
    String label = '金额';
    if (isActive) {
      if (_minAmount != null && _maxAmount != null) {
        label =
            '${FormatUtil.formatNumberSmart(_minAmount!)} - ${FormatUtil.formatNumberSmart(_maxAmount!)}';
      } else if (_minAmount != null) {
        label = '> ${FormatUtil.formatNumberSmart(_minAmount!)}';
      } else if (_maxAmount != null) {
        label = '< ${FormatUtil.formatNumberSmart(_maxAmount!)}';
      }
    }

    return FilterChip(
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      selected: isActive,
      onSelected: (_) => _showAmountRangeDialog(),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color:
              isActive ? Theme.of(context).primaryColor : Colors.grey.shade400,
          width: 1,
        ),
      ),
      backgroundColor:
          isActive
              ? Theme.of(context).primaryColor.withAlpha((0.1 * 255).round())
              : Colors.transparent,
      selectedColor: Theme.of(
        context,
      ).primaryColor.withAlpha((0.1 * 255).round()),
      showCheckmark: false,
    );
  }

  Widget _buildTypeFilterChip(TransactionType type, String label) {
    final isSelected = _selectedTypes.contains(type);
    return FilterChip(
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      selected: isSelected,
      onSelected: (bool selected) {
        _toggleType(type);
      },
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color:
              isSelected
                  ? Theme.of(
                    context,
                  ).primaryColor.withAlpha((0.1 * 255).round())
                  : Colors.grey.shade400,
          width: 1,
        ),
      ),
      backgroundColor:
          isSelected
              ? Theme.of(context).primaryColor.withAlpha((0.1 * 255).round())
              : Colors.transparent,
      selectedColor: Theme.of(
        context,
      ).primaryColor.withAlpha((0.1 * 255).round()),
      showCheckmark: false,
    );
  }

  Future<void> _showKeywordDialog() async {
    _searchDialogController.text = _searchTerm;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('输入搜索关键字'),
          content: TextField(
            controller: _searchDialogController,
            autofocus: true,
            decoration: const InputDecoration(hintText: '备注、分类...'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _searchDialogController.clear();
              },
              child: const Text('清除'),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('确定'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      setState(() {
        _searchTerm = _searchDialogController.text;
      });
    }
  }

  Future<void> _showAmountRangeDialog() async {
    _minAmountDialogController.text = _minAmount?.toString() ?? '';
    _maxAmountDialogController.text = _maxAmount?.toString() ?? '';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('筛选金额范围'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _minAmountDialogController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: '最小金额'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _maxAmountDialogController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: '最大金额'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                _minAmountDialogController.clear();
                _maxAmountDialogController.clear();
              },
              child: const Text('清除'),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('确定'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      setState(() {
        _minAmount = double.tryParse(_minAmountDialogController.text);
        _maxAmount = double.tryParse(_maxAmountDialogController.text);
      });
    }
  }
}
