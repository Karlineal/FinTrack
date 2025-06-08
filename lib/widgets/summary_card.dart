import 'package:flutter/material.dart';
import 'package:fintrack/utils/theme_util.dart';

class SummaryCard extends StatelessWidget {
  final double income;
  final double expense;
  final double balance;
  final String currencySymbol;
  final String periodLabel;

  const SummaryCard({
    super.key,
    required this.income,
    required this.expense,
    required this.balance,
    required this.currencySymbol,
    this.periodLabel = '本月',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final cardColor = isDarkMode ? Colors.grey[850] : Colors.white;
    final textColor = isDarkMode ? Colors.white70 : Colors.black54;

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '结余',
                style: theme.textTheme.titleMedium?.copyWith(color: textColor),
              ),
              Text(
                periodLabel,
                style: theme.textTheme.bodyMedium?.copyWith(color: textColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$currencySymbol${balance.toStringAsFixed(2)}',
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildIncomeExpenseItem(
                context,
                '支出',
                expense,
                ThemeUtil.expenseColor,
              ),
              const SizedBox(width: 24),
              _buildIncomeExpenseItem(
                context,
                '收入',
                income,
                ThemeUtil.incomeColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeExpenseItem(
    BuildContext context,
    String title,
    double value,
    Color indicatorColor,
  ) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white70 : Colors.black54;

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(color: textColor),
          ),
          const SizedBox(height: 4),
          Text(
            '$currencySymbol${value.toStringAsFixed(2)}',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: indicatorColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}
