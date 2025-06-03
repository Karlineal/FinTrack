import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../utils/format_util.dart';
import '../utils/theme_util.dart';

class ExpenseChart extends StatelessWidget {
  final Map<Category, double> categoryData;
  final double total;
  final bool isExpense;

  const ExpenseChart({
    super.key,
    required this.categoryData,
    required this.total,
    this.isExpense = true,
  });

  @override
  Widget build(BuildContext context) {
    if (categoryData.isEmpty) {
      return const Center(child: Text('暂无数据'));
    }

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sections: _createSections(),
              centerSpaceRadius: 40,
              sectionsSpace: 2,
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: _createLegends(),
        ),
      ],
    );
  }

  List<PieChartSectionData> _createSections() {
    final List<PieChartSectionData> sections = [];
    int colorIndex = 0;

    categoryData.forEach((category, amount) {
      final percentage = (amount / total) * 100;
      final color =
          ThemeUtil.chartColors[colorIndex % ThemeUtil.chartColors.length];

      sections.add(
        PieChartSectionData(
          value: amount,
          title: '${percentage.toStringAsFixed(1)}%',
          color: color,
          radius: 80,
          titleStyle: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      );

      colorIndex++;
    });

    return sections;
  }

  List<Widget> _createLegends() {
    final List<Widget> legends = [];
    int colorIndex = 0;

    categoryData.forEach((category, amount) {
      final color =
          ThemeUtil.chartColors[colorIndex % ThemeUtil.chartColors.length];
      final percentage = (amount / total) * 100;

      legends.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
            Text(
              '${FormatUtil.getCategoryName(category)} (${percentage.toStringAsFixed(1)}%)',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );

      colorIndex++;
    });

    return legends;
  }
}
