import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../utils/format_util.dart';
import '../widgets/transaction_form.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 导入 SharedPreferences

class TransactionDetailScreen extends StatefulWidget {
  final Transaction transaction;

  const TransactionDetailScreen({super.key, required this.transaction});

  @override
  State<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  bool _isEditing = false;
  String _globalCurrencySymbol = '¥'; // 添加状态变量存储全局货币符号

  @override
  void initState() {
    super.initState();
    _loadGlobalCurrencyPreference(); // 加载全局货币偏好
  }

  Future<void> _loadGlobalCurrencyPreference() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _globalCurrencySymbol = prefs.getString('currency') ?? '¥';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('交易详情'),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.close : Icons.edit),
            onPressed: () {
              setState(() {
                _isEditing = !_isEditing;
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child:
            _isEditing ? _buildEditForm() : _buildTransactionDetails(context),
      ),
    );
  }

  Widget _buildTransactionDetails(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final amountColor =
        widget.transaction.type == TransactionType.income
            ? Colors.green
            : Colors.red;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题和金额
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.transaction.title, style: textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(
                  FormatUtil.formatCurrency(
                    widget.transaction.amount,
                    currencySymbol: widget.transaction.currency,
                  ),
                  style: textTheme.headlineMedium?.copyWith(color: amountColor),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // 详细信息
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildDetailRow(
                  '类别',
                  FormatUtil.getCategoryName(widget.transaction.category),
                ),
                const Divider(),
                _buildDetailRow(
                  '日期',
                  FormatUtil.formatDate(widget.transaction.date),
                ),
                const Divider(),
                _buildDetailRow(
                  '类型',
                  FormatUtil.getTransactionTypeName(widget.transaction.type),
                ),
                if (widget.transaction.note != null &&
                    widget.transaction.note!.isNotEmpty) ...[
                  const Divider(),
                  _buildDetailRow('备注', widget.transaction.note!),
                ],
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // 删除按钮
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _confirmDelete(context),
            icon: const Icon(Icons.delete, color: Colors.white),
            label: const Text('删除交易'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildEditForm() {
    return TransactionForm(
      initialTransaction:
          widget.transaction, // Changed 'transaction' to 'initialTransaction'
      currency: _globalCurrencySymbol, // 传递全局货币符号
      onSubmit: (updatedTransaction) async {
        // Store the BuildContext before the async gap.
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        // final navigator = Navigator.of(context); // Removed unused navigator
        try {
          if (!mounted) return; // Added mounted check
          await Provider.of<TransactionProvider>(
            context,
            listen: false,
          ).updateTransaction(updatedTransaction);
          if (!mounted) return;
          scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text('交易记录已更新')),
          );
          setState(() {
            _isEditing = false;
          });
        } catch (e) {
          if (!mounted) return;
          scaffoldMessenger.showSnackBar(SnackBar(content: Text('更新失败: $e')));
        }
      },
    );
  }

  void _confirmDelete(BuildContext context) async {
    // Store the BuildContext and Navigator before the async gap.
    final navigator = Navigator.of(
      context,
    ); // This navigator is used later for pop()
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('确认删除'),
            content: const Text('确定要删除这条交易记录吗？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('删除'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        if (!mounted) return; // Guard access to context for Provider
        await Provider.of<TransactionProvider>(
          context,
          listen: false,
        ).deleteTransaction(widget.transaction.id);
        if (!mounted) return;
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('交易记录已删除')),
        );
        // The navigator.pop() call needs to be guarded as well if context might be invalid
        // The navigator variable itself captured the context from before the async gap.
        // However, the action of popping uses the current context state.
        if (!mounted) return;
        navigator.pop();
      } catch (e) {
        if (!mounted) return;
        scaffoldMessenger.showSnackBar(SnackBar(content: Text('删除失败: $e')));
      }
    }
  }

  // Removed extra closing brace
}
