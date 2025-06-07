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
        automaticallyImplyLeading: true, // 只保留返回按钮
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        // 不显示标题和右侧icon
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child:
            _isEditing ? _buildEditForm() : _buildTransactionDetails(context),
      ),
      bottomNavigationBar:
          !_isEditing
              ? Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _confirmDelete(context),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: Colors.grey.shade400,
                            width: 1.2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          '删除',
                          style: TextStyle(fontSize: 18, color: Colors.black54),
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _isEditing = true;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('修改', style: TextStyle(fontSize: 18)),
                      ),
                    ),
                  ],
                ),
              )
              : null,
    );
  }

  Widget _buildTransactionDetails(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final amountColor =
        widget.transaction.type == TransactionType.income
            ? Colors.green
            : Colors.red;
    final iconData = FormatUtil.getCategoryIcon(widget.transaction.category);
    final iconColor = Colors.pink.shade200;

    return Column(
      children: [
        // 顶部卡片：icon+分类名+金额
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(iconData, color: Colors.white, size: 32),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Text(
                    FormatUtil.getCategoryName(widget.transaction.category),
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  FormatUtil.formatCurrency(
                    widget.transaction.amount,
                    currencyCode: widget.transaction.currency,
                  ),
                  style: textTheme.headlineSmall?.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        // 下部卡片：详细信息
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              children: [
                _buildDetailRow(
                  '类型',
                  FormatUtil.getTransactionTypeName(widget.transaction.type),
                ),
                const SizedBox(height: 12),
                _buildDetailRow(
                  '日期',
                  FormatUtil.formatDate(widget.transaction.date),
                ),
                if (widget.transaction.note != null &&
                    widget.transaction.note!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildDetailRow('备注', widget.transaction.note!),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {String? rightLabel}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, color: Colors.black87),
        ),
        Flexible(
          child: Text(
            rightLabel ?? value,
            style: const TextStyle(fontSize: 16, color: Colors.black54),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildEditForm() {
    return TransactionForm(
      initialTransaction:
          widget.transaction, // Changed 'transaction' to 'initialTransaction'
      currency: _globalCurrencySymbol, // 传递全局货币符号
      onSubmit: (updatedTransaction) async {
        final provider = Provider.of<TransactionProvider>(
          context,
          listen: false,
        );
        try {
          await provider.updateTransaction(updatedTransaction);

          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('交易记录已更新')));
          setState(() {
            _isEditing = false;
          });
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('更新失败: $e')));
        }
      },
    );
  }

  void _confirmDelete(BuildContext context) async {
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
      // 在异步操作之后，但在使用 BuildContext 之前，检查 mounted
      if (!mounted) return;
      final navigator = Navigator.of(context);
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      final provider = Provider.of<TransactionProvider>(context, listen: false);

      try {
        await provider.deleteTransaction(widget.transaction.id);
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('交易记录已删除')),
        );
        navigator.pop();
      } catch (e) {
        scaffoldMessenger.showSnackBar(SnackBar(content: Text('删除失败: $e')));
      }
    }
  }

  // Removed extra closing brace
}
