import 'package:flutter/material.dart';
import '../utils/format_util.dart';
import '../utils/theme_util.dart';
import '../services/exchange_rate_service.dart';

class SummaryCard extends StatelessWidget {
  final double income;
  final double expense;
  final double balance;
  final String currencySymbol; // 添加 currencySymbol 属性

  const SummaryCard({
    super.key,
    required this.income,
    required this.expense,
    required this.balance,
    this.currencySymbol = '¥', // 设置默认值
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [ThemeUtil.primaryColor, Color(0xFF1B5E20)],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  '当前余额',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '基准货币',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              FormatUtil.formatCurrency(
                balance,
                currencyCode: _getCurrencyCodeFromSymbol(currencySymbol),
              ),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 收入
                _buildSummaryItem(
                  context,
                  '收入',
                  FormatUtil.formatCurrency(
                    income,
                    currencyCode: _getCurrencyCodeFromSymbol(currencySymbol),
                  ),
                  Icons.arrow_upward,
                  Colors.white,
                ),
                // 支出
                _buildSummaryItem(
                  context,
                  '支出',
                  FormatUtil.formatCurrency(
                    expense,
                    currencyCode: _getCurrencyCodeFromSymbol(currencySymbol),
                  ),
                  Icons.arrow_downward,
                  Colors.white70,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context,
    String title,
    String amount,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha((0.2 * 255).round()),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: color.withAlpha((0.8 * 255).round()),
                fontSize: 14,
              ),
            ),
            Text(
              amount,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 从货币符号获取货币代码
  String _getCurrencyCodeFromSymbol(String symbol) {
    // 遍历支持的货币映射，找到对应的货币代码
    for (final entry in ExchangeRateService.supportedCurrencies.entries) {
      if (entry.value == symbol) {
        return entry.key;
      }
    }
    // 如果找不到匹配的符号，默认返回CNY
    return 'CNY';
  }
}
