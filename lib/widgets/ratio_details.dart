import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../utils/format_util.dart';

List<Color> _generateColors(BuildContext context) {
  final brightness = Theme.of(context).brightness;
  if (brightness == Brightness.dark) {
    // Dark mode color palette - vibrant but not overly bright
    return [
      Colors.teal.shade300,
      Colors.lightBlue.shade300,
      Colors.purple.shade300,
      Colors.pink.shade300,
      Colors.orange.shade400,
      Colors.green.shade400,
      Colors.amber.shade400,
      Colors.cyan.shade300,
      Colors.indigo.shade300,
      Colors.red.shade300,
    ];
  } else {
    // Light mode color palette - soft and pleasant
    return [
      Colors.blue.shade400,
      Colors.green.shade500,
      Colors.orange.shade500,
      Colors.purple.shade400,
      Colors.red.shade400,
      Colors.teal.shade400,
      Colors.pink.shade400,
      Colors.amber.shade600,
      Colors.cyan.shade500,
      Colors.indigo.shade400,
    ];
  }
}

Map<Category, Color> _getCategoryColors(
  BuildContext context,
  List<Category> categories,
) {
  final colors = _generateColors(context);
  final colorMap = <Category, Color>{};
  for (int i = 0; i < categories.length; i++) {
    colorMap[categories[i]] = colors[i % colors.length];
  }
  return colorMap;
}

class RatioDetails extends StatefulWidget {
  final List<Transaction> transactions;
  final bool isExpense;

  const RatioDetails({
    super.key,
    required this.transactions,
    required this.isExpense,
  });

  @override
  State<RatioDetails> createState() => _RatioDetailsState();
}

class _RatioDetailsState extends State<RatioDetails> {
  int? touchedIndex;

  @override
  Widget build(BuildContext context) {
    final filtered =
        widget.transactions
            .where(
              (t) => (t.type == TransactionType.expense) == widget.isExpense,
            )
            .toList();

    if (filtered.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: Text(
          '当前范围无相关数据',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    Map<Category, double> categoryData = {};
    double total = 0;
    for (var t in filtered) {
      categoryData.update(
        t.category,
        (value) => value + t.amount,
        ifAbsent: () => t.amount,
      );
      total += t.amount;
    }

    final sortedCategories =
        categoryData.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    final categoryColorMap = _getCategoryColors(
      context,
      sortedCategories.map((e) => e.key).toList(),
    );

    Color getColorForCategory(Category category) {
      return categoryColorMap[category] ?? Colors.grey;
    }

    return Column(
      children: [
        Container(
          height: 180,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              pieTouchResponse == null ||
                              pieTouchResponse.touchedSection == null) {
                            touchedIndex = -1;
                            return;
                          }
                          touchedIndex =
                              pieTouchResponse
                                  .touchedSection!
                                  .touchedSectionIndex;
                        });
                      },
                    ),
                    borderData: FlBorderData(show: false),
                    sectionsSpace: 2,
                    centerSpaceRadius: 50,
                    sections: List.generate(sortedCategories.length, (i) {
                      final isTouched = i == touchedIndex;
                      final radius = isTouched ? 35.0 : 25.0;
                      final entry = sortedCategories[i];

                      return PieChartSectionData(
                        color: getColorForCategory(entry.key),
                        value: entry.value,
                        title: '',
                        radius: radius,
                      );
                    }),
                  ),
                ),
              ),
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: ListView.builder(
                    itemCount: sortedCategories.length,
                    itemBuilder: (context, index) {
                      final entry = sortedCategories[index];
                      final percentage =
                          total > 0 ? (entry.value / total) * 100 : 0.0;
                      return _buildLegendItem(
                        category: entry.key,
                        percentage: percentage,
                        isTouched: index == touchedIndex,
                        color: getColorForCategory(entry.key),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sortedCategories.length,
          itemBuilder: (context, index) {
            final entry = sortedCategories[index];
            final percentage = total > 0 ? (entry.value / total) * 100 : 0.0;
            return _buildCategoryListItem(
              context: context,
              category: entry.key,
              amount: entry.value,
              percentage: percentage,
              color: getColorForCategory(entry.key),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLegendItem({
    required Category category,
    required double percentage,
    required bool isTouched,
    required Color color,
  }) {
    final double size = isTouched ? 14 : 10;
    final double verticalPadding = isTouched ? 3 : 5;

    return InkWell(
      onTap: () {
        // can add navigation or other interaction here
      },
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: verticalPadding, horizontal: 8),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: size,
              height: size,
              color: color,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                FormatUtil.getCategoryName(category),
                style: Theme.of(context).textTheme.bodyMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryListItem({
    required BuildContext context,
    required Category category,
    required double amount,
    required double percentage,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      color: color.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    FormatUtil.getCategoryIcon(category),
                    color: color,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        FormatUtil.getCategoryName(category),
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${percentage.toStringAsFixed(2)}%',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  FormatUtil.formatCurrency(amount),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percentage / 100,
                backgroundColor: color.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
