import 'package:flutter/material.dart';
import 'package:fintrack/screens/add_transaction_screen.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../utils/format_util.dart';

class TransactionDetailScreen extends StatelessWidget {
  final Transaction transaction;

  const TransactionDetailScreen({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (context, provider, child) {
        // 从provider中查找最新的【转换后】的交易数据
        final liveTransaction = provider.convertedTransactions.firstWhere(
          (t) => t.id == transaction.id,
          orElse: () => transaction, // 如果找不到，返回旧数据
        );

        return Scaffold(
          appBar: AppBar(
            title: const Text('账单详情'),
            elevation: 0,
            foregroundColor: Theme.of(context).colorScheme.onSurface,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildHeaderCard(context, liveTransaction),
                const SizedBox(height: 16),
                _buildDetailsCard(context, liveTransaction),
              ],
            ),
          ),
          bottomNavigationBar: _buildBottomButtons(context, liveTransaction),
        );
      },
    );
  }

  Widget _buildHeaderCard(BuildContext context, Transaction transaction) {
    final theme = Theme.of(context);
    final isIncome = transaction.type == TransactionType.income;
    final color = isIncome ? Colors.green : Colors.red;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: theme.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                FormatUtil.getCategoryIcon(transaction.category),
                color: color,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                FormatUtil.getCategoryName(transaction.category),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            Text(
              '${isIncome ? '+' : '-'}${FormatUtil.formatCurrency(transaction.amount, currencyCode: transaction.currency)}',
              style: theme.textTheme.titleLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard(BuildContext context, Transaction transaction) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: theme.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _buildDetailRow(
              context,
              icon: Icons.wallet_outlined,
              label: '账户',
              value: '日常', // 示例，后续可替换为真实账户
            ),
            const Divider(height: 24),
            _buildDetailRow(
              context,
              icon: Icons.sell_outlined,
              label: '类型',
              value: FormatUtil.getTransactionTypeName(transaction.type),
            ),
            const Divider(height: 24),
            _buildDetailRow(
              context,
              icon: Icons.calendar_today_outlined,
              label: '日期',
              value: FormatUtil.formatDateTime(transaction.date),
            ),
            if (transaction.note != null && transaction.note!.isNotEmpty) ...[
              const Divider(height: 24),
              _buildDetailRow(
                context,
                icon: Icons.notes_outlined,
                label: '备注',
                value: transaction.note!,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.onSurface;
    final secondaryColor = theme.colorScheme.onSurfaceVariant;

    return Row(
      children: [
        Icon(icon, size: 22, color: secondaryColor),
        const SizedBox(width: 16),
        Text(
          label,
          style: theme.textTheme.titleMedium?.copyWith(color: primaryColor),
        ),
        const Spacer(),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(color: secondaryColor),
        ),
      ],
    );
  }

  Widget _buildBottomButtons(BuildContext context, Transaction transaction) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.delete_outline),
              label: const Text('删除'),
              onPressed: () => _confirmDelete(context, transaction),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: BorderSide(color: Colors.grey.shade300),
                foregroundColor: Colors.red,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.edit_outlined),
              label: const Text('修改'),
              onPressed: () => _navigateToEdit(context, transaction),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToEdit(BuildContext context, Transaction transaction) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => AddTransactionScreen(transactionToEdit: transaction),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Transaction transaction) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('确认删除'),
            content: const Text('您确定要删除此交易记录吗？此操作无法撤销。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(dialogContext, true);
                },
                child: const Text('删除', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        await Provider.of<TransactionProvider>(
          context,
          listen: false,
        ).deleteTransaction(transaction.id);
        if (context.mounted) {
          Navigator.pop(context, true); // 删除成功后，需要返回并通知刷新
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('删除失败: $e')));
        }
      }
    }
  }
}
