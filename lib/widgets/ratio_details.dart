import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../utils/format_util.dart';

// 为不同类别定义一组固定的颜色以获得更好的视觉效果
Map<Category, Color> _getCategoryColors() {
  return {
    Category.food: Colors.orange.shade400,
    Category.takeout: Colors.orange.shade600,
    Category.snacks: Colors.amber.shade400,
    Category.drinks: Colors.amber.shade600,
    Category.shopping: Colors.pink.shade300,
    Category.clothes: Colors.pink.shade400,
    Category.digital: Colors.red.shade400,
    Category.transportation: Colors.blue.shade400,
    Category.entertainment: Colors.purple.shade300,
    Category.utilities: Colors.lightGreen.shade400,
    Category.rent: Colors.green.shade600,
    Category.internet: Colors.teal.shade300,
    Category.phone: Colors.cyan.shade400,
    Category.health: Colors.red.shade300,
    Category.education: Colors.indigo.shade300,
    Category.study: Colors.indigo.shade400,
    Category.sports: Colors.lightBlue.shade300,
    Category.travel: Colors.teal.shade400,
    Category.pets: Colors.brown.shade400,
    Category.beauty: Colors.pink.shade200,
    Category.smoke: Colors.grey.shade500,
    Category.daily: Colors.lime.shade600,
    Category.fastmail: Colors.deepOrange.shade300,
    Category.otherExpense: Colors.grey.shade400,
    Category.salary: Colors.green.shade500,
    Category.gift: Colors.red.shade500,
    Category.other: Colors.blueGrey.shade400,
    Category.campus: Colors.lightGreen.shade600,
    Category.water: Colors.blue.shade200,
  };
}

Color _getColorForCategory(Category category) {
  return _getCategoryColors()[category] ?? Colors.grey;
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
        child: const Text('当前范围无相关数据'),
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
                        color: _getColorForCategory(entry.key),
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
                      final percentage = (entry.value / total) * 100;
                      final isTouched = index == touchedIndex;
                      return _buildLegendItem(
                        entry.key,
                        percentage,
                        isTouched,
                        context,
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
            return _buildCategoryListItem(
              context: context,
              category: entry.key,
              amount: entry.value,
            );
          },
        ),
      ],
    );
  }

  Widget _buildLegendItem(
    Category category,
    double percentage,
    bool isTouched,
    BuildContext context,
  ) {
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
              color: _getColorForCategory(category),
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
  }) {
    return Card(
      elevation: 0.5,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getColorForCategory(category).withOpacity(0.15),
          child: Icon(
            FormatUtil.getCategoryIcon(category),
            color: _getColorForCategory(category),
            size: 20,
          ),
        ),
        title: Text(
          FormatUtil.getCategoryName(category),
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        trailing: Text(
          FormatUtil.formatCurrency(amount),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color:
                widget.isExpense ? Colors.red.shade400 : Colors.green.shade600,
          ),
        ),
      ),
    );
  }
}
