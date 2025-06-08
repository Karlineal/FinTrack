import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class TrendLineChart extends StatelessWidget {
  final List<double> data;
  final List<String> xLabels;
  final bool isExpense;
  final VoidCallback onToggle;

  const TrendLineChart({
    super.key,
    required this.data,
    required this.xLabels,
    required this.isExpense,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 14, top: 8),
              child: Row(
                children: [
                  Text(
                    '趋势',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  _buildTrendToggleButton(context, true),
                  const SizedBox(width: 10),
                  _buildTrendToggleButton(context, false),
                ],
              ),
            ),
            const SizedBox(height: 10),
            if (data.every((d) => d == 0.0))
              SizedBox(
                height: 200,
                child: Center(
                  child: Text(
                    '暂无数据',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                ),
              )
            else
              SizedBox(
                height: 200,
                child: Padding(
                  padding: const EdgeInsets.only(right: 20, top: 10),
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: true,
                        horizontalInterval: _getHorizontalInterval(),
                        verticalInterval: 1,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: colorScheme.onSurface.withOpacity(0.1),
                            strokeWidth: 1,
                            dashArray: [4, 4],
                          );
                        },
                        getDrawingVerticalLine: (value) {
                          return FlLine(
                            color: colorScheme.onSurface.withOpacity(0.1),
                            strokeWidth: 1,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            interval: _getBottomTitleInterval(),
                            getTitlesWidget:
                                (value, meta) =>
                                    bottomTitleWidgets(value, meta, context),
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget:
                                (value, meta) =>
                                    leftTitleWidgets(value, meta, context),
                            reservedSize: 42,
                            interval: _getHorizontalInterval(),
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      minX: 0,
                      maxX: (data.length - 1).toDouble(),
                      minY: 0,
                      maxY: _getMaxY(),
                      lineBarsData: [
                        LineChartBarData(
                          spots: List.generate(data.length, (index) {
                            return FlSpot(index.toDouble(), data[index]);
                          }),
                          isCurved: false,
                          color: colorScheme.primary,
                          barWidth: 2.5,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                colorScheme.primary.withOpacity(0.4),
                                colorScheme.primary.withOpacity(0.0),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendToggleButton(BuildContext context, bool forExpense) {
    final bool selected = (forExpense == isExpense);
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: selected ? null : onToggle,
      child: Container(
        width: 54,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border:
              selected
                  ? null
                  : Border.all(color: colorScheme.primary, width: 1),
        ),
        child: Text(
          forExpense ? '支出' : '收入',
          style: TextStyle(
            color: selected ? colorScheme.onPrimary : colorScheme.primary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  double _getHorizontalInterval() {
    if (data.isEmpty) return 1;
    final maxVal = _getMaxY();
    if (maxVal == 0) return 1;
    return maxVal / 4;
  }

  double _getMaxY() {
    if (data.isEmpty) return 100.0;
    double maxVal = data.reduce((a, b) => a > b ? a : b);
    if (maxVal == 0) return 100.0;
    return maxVal;
  }

  double _getBottomTitleInterval() {
    // The logic to show/hide labels is now handled in statistics_screen by populating
    return 1;
  }

  Widget bottomTitleWidgets(
    double value,
    TitleMeta meta,
    BuildContext context,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final style = TextStyle(
      color: colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.normal,
      fontSize: 12,
    );
    Widget text;
    int index = value.toInt();
    if (index >= 0 && index < xLabels.length) {
      text = Text(xLabels[index], style: style);
    } else {
      text = Text('', style: style);
    }

    return SideTitleWidget(axisSide: meta.axisSide, child: text);
  }

  Widget leftTitleWidgets(double value, TitleMeta meta, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final style = TextStyle(
      color: colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.normal,
      fontSize: 12,
    );
    return Text(
      value.toStringAsFixed(1),
      style: style,
      textAlign: TextAlign.left,
    );
  }
}
