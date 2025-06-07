import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class TrendLineChart extends StatelessWidget {
  final List<double> data;
  final List<String> xLabels;
  final bool isExpense;
  final VoidCallback? onToggle;
  final List<int>? labelIndexes;

  const TrendLineChart({
    super.key,
    required this.data,
    required this.xLabels,
    this.isExpense = true,
    this.onToggle,
    this.labelIndexes,
  });

  @override
  Widget build(BuildContext context) {
    final Color mainColor =
        isExpense ? const Color(0xFF545F92) : const Color(0xFF6B7BB6);
    // 1. 计算最大值，Y轴4等分
    double maxY = 1.0;
    if (data.isNotEmpty) {
      maxY = data.reduce((a, b) => a > b ? a : b);
      if (maxY < 1) maxY = 1.0;
      // 上取整到最近的100/50/10等
      double step = 1;
      if (maxY > 1000)
        step = 500;
      else if (maxY > 500)
        step = 200;
      else if (maxY > 200)
        step = 100;
      else if (maxY > 100)
        step = 50;
      else if (maxY > 50)
        step = 20;
      else if (maxY > 20)
        step = 10;
      else if (maxY > 10)
        step = 5;
      else if (maxY > 5)
        step = 2;
      maxY = (maxY / step).ceil() * step;
    }
    // 只显示4个刻度（3等分，含0）
    List<double> yTicks = List.generate(4, (i) => (maxY / 3 * i));
    String formatYLabel(double value) {
      if (maxY >= 1000) {
        return (value / 1000).toStringAsFixed(1) + 'k';
      } else {
        return value.toStringAsFixed(0);
      }
    }

    // 横坐标标签恢复为原有customXLabels逻辑
    List<String> customXLabels;
    // 年视图下直接全部显示月份
    if (xLabels.length == 12 &&
        xLabels[0].endsWith('月') &&
        xLabels[11] == '12月') {
      customXLabels = xLabels;
    } else {
      List<int> labelDays;
      if (xLabels.length == 30) {
        labelDays = [1, 5, 10, 15, 20, 25, 30];
      } else {
        // Handles 31, 29, 28 day months to have 6 intervals
        labelDays = [1, 5, 10, 15, 20, 25];
      }
      customXLabels = List.generate(xLabels.length, (i) {
        final label = xLabels[i];
        for (final d in labelDays) {
          if (label.endsWith('/$d')) return label;
        }
        if (i == xLabels.length - 1) return xLabels[i];
        return '';
      });
    }
    // 判断是否有数据
    final bool hasData = data.any((v) => v > 0.0001);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7FA),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: 14,
              right: 14,
              top: 8,
              bottom: 0,
            ),
            child: Row(
              children: [
                const Text(
                  '趋势',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF23232B),
                  ),
                ),
                Spacer(),
                _buildToggleButton(context, true, isExpense),
                const SizedBox(width: 10),
                _buildToggleButton(context, false, isExpense),
              ],
            ),
          ),
          const SizedBox(height: 20), // 增加趋势与图表间距
          SizedBox(
            height: 170,
            child:
                hasData
                    ? Padding(
                      padding: const EdgeInsets.only(
                        left: 8,
                        right: 8,
                        top: 0,
                        bottom: 0,
                      ),
                      child: LineChart(
                        LineChartData(
                          minX: 0,
                          maxX: data.length.toDouble(),
                          minY: 0,
                          maxY: maxY,
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval:
                                yTicks.length > 1 ? yTicks[1] - yTicks[0] : 1.0,
                            getDrawingHorizontalLine:
                                (value) => FlLine(
                                  color: const Color(0xFFE5E5EF),
                                  strokeWidth: 1,
                                  dashArray: [6, 4],
                                ),
                          ),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 28,
                                getTitlesWidget: (value, meta) {
                                  if (!yTicks.contains(value))
                                    return const SizedBox.shrink();
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 2),
                                    child: Text(
                                      formatYLabel(value),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Color(0xFFB0B0C0),
                                        fontWeight: FontWeight.normal,
                                      ),
                                    ),
                                  );
                                },
                                interval:
                                    yTicks.length > 1
                                        ? yTicks[1] - yTicks[0]
                                        : 1.0,
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 18,
                                getTitlesWidget: (value, meta) {
                                  final idx = value.toInt();
                                  if (idx < 0 || idx >= customXLabels.length)
                                    return const SizedBox.shrink();
                                  final label = customXLabels[idx];
                                  if (label.isEmpty)
                                    return const SizedBox.shrink();
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      label,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Color(0xFFB0B0C0),
                                        fontWeight: FontWeight.normal,
                                      ),
                                    ),
                                  );
                                },
                                interval: 1,
                              ),
                            ),
                            rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              spots: [
                                for (int i = 0; i < data.length; i++)
                                  FlSpot(
                                    i.toDouble(),
                                    data[i] < 0 ? 0 : data[i],
                                  ),
                              ],
                              isCurved: false,
                              color: mainColor,
                              barWidth: 2,
                              isStrokeCapRound: true,
                              dotData: FlDotData(show: false),
                              belowBarData: BarAreaData(
                                show: true,
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    mainColor.withOpacity(0.18),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                              shadow: const Shadow(
                                color: Color(0x33545F92),
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.insert_drive_file_rounded,
                            size: 48,
                            color: Color(0xFFFBC02D),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '暂无数据',
                            style: TextStyle(
                              fontSize: 15,
                              color: Color(0xFFB0B0C0),
                            ),
                          ),
                        ],
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(
    BuildContext context,
    bool expense,
    bool selectedExpense,
  ) {
    final bool selected = (expense == selectedExpense);
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
          expense ? '支出' : '收入',
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF545F92),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
