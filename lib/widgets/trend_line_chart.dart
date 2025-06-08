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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF7F7FA),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 14, top: 8),
              child: Row(
                children: [
                  const Text(
                    '趋势',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                      color: Color(0xFF23232B),
                    ),
                  ),
                  const Spacer(),
                  _buildTrendToggleButton(true),
                  const SizedBox(width: 10),
                  _buildTrendToggleButton(false),
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
                    style: TextStyle(color: Colors.grey.shade600),
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
                            color: Colors.grey.shade300,
                            strokeWidth: 1,
                            dashArray: [4, 4],
                          );
                        },
                        getDrawingVerticalLine: (value) {
                          return FlLine(
                            color: Colors.grey.shade200,
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
                            getTitlesWidget: bottomTitleWidgets,
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: leftTitleWidgets,
                            reservedSize: 42,
                            interval: _getHorizontalInterval(),
                          ),
                        ),
                      ),
                      borderData: FlBorderData(
                        show: false,
                        border: Border.all(color: const Color(0xff37434d)),
                      ),
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
                          color: const Color(0xFF373A53),
                          barWidth: 2.5,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF373A53).withOpacity(0.4),
                                const Color(0xFF373A53).withOpacity(0.0),
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

  Widget _buildTrendToggleButton(bool forExpense) {
    final bool selected = (forExpense == isExpense);
    return GestureDetector(
      onTap: selected ? null : onToggle,
      child: Container(
        width: 54,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF545F92) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border:
              selected
                  ? null
                  : Border.all(color: const Color(0xFF545F92), width: 1),
        ),
        child: Text(
          forExpense ? '支出' : '收入',
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF545F92),
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

  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      color: Color(0xff68737d),
      fontWeight: FontWeight.normal,
      fontSize: 12,
    );
    Widget text;
    int index = value.toInt();
    if (index >= 0 && index < xLabels.length) {
      text = Text(xLabels[index], style: style);
    } else {
      text = const Text('', style: style);
    }

    return SideTitleWidget(axisSide: meta.axisSide, child: text);
  }

  Widget leftTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      color: Color(0xff67727d),
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
