import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nestflow/nestflow.dart';

class BusinessDashboardTab extends StatelessWidget {
  final BusinessLoaded loaded;
  const BusinessDashboardTab({super.key, required this.loaded});

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final currency = loaded.active?.currency ?? '';
    final fmt = NumberFormat.currency(symbol: currency, decimalDigits: 0);

    final todaySales = loaded.sales.where((s) => _isToday(s.saleDate));
    final todayExpenses = loaded.cashbookExpenses.where((e) => _isToday(e.expenseDate));
    final todayOthers = loaded.others.where((o) => _isToday(o.entryDate));

    final todaySalesTotal = todaySales.fold<double>(0, (s, x) => s + x.amount);
    final todayExpensesTotal = todayExpenses.fold<double>(0, (s, x) => s + x.amount);
    final todayOthersNet = todayOthers.fold<double>(0, (s, x) => s + (x.isInflow ? x.amount : -x.amount));
    final todayNet = todaySalesTotal - todayExpensesTotal + todayOthersNet;

    // ?? Weekly trend, reusing the same model/widget as the main dashboard ??
    final startOfWeek = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
    final weekDays = List.generate(7, (i) => DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day + i));

    final weeklyChartData = weekDays.map((day) {
      bool sameDay(DateTime d) => d.year == day.year && d.month == day.month && d.day == day.day;
      final daySales = loaded.sales.where((s) => sameDay(s.saleDate)).fold<double>(0, (s, x) => s + x.amount);
      final dayExpenses = loaded.cashbookExpenses.where((e) => sameDay(e.expenseDate)).fold<double>(0, (s, x) => s + x.amount);
      return WeeklyChartDataModel(
        day: DateFormat.E().format(day),
        income: daySales,
        expenses: dayExpenses,
      );
    }).toList();

    // ?? Branch breakdown for today ??
    final branches = loaded.branches;
    final Map<int?, double> branchNet = {};
    for (final s in todaySales) {
      branchNet[s.branchId] = (branchNet[s.branchId] ?? 0) + s.amount;
    }
    for (final e in todayExpenses) {
      branchNet[e.branchId] = (branchNet[e.branchId] ?? 0) - e.amount;
    }
    for (final o in todayOthers) {
      branchNet[o.branchId] = (branchNet[o.branchId] ?? 0) + (o.isInflow ? o.amount : -o.amount);
    }
    String branchName(int? id) {
      if (id == null) return 'Unassigned';
      final match = branches.where((b) => b.id == id);
      return match.isNotEmpty ? match.first.name : 'Unknown branch';
    }

    // ?? Recent activity (last 5, combined) ??
    final combined = <_ActivityEntry>[
      ...loaded.sales.map((s) => _ActivityEntry(date: s.saleDate, description: s.description, amount: s.amount, isInflow: true)),
      ...loaded.cashbookExpenses.map((e) => _ActivityEntry(date: e.expenseDate, description: '${e.description} (${e.category})', amount: e.amount, isInflow: false)),
      ...loaded.others.map((o) => _ActivityEntry(date: o.entryDate, description: o.description, amount: o.amount, isInflow: o.isInflow)),
    ]..sort((a, b) => b.date.compareTo(a.date));
    final recent = combined.take(5).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          loaded.active?.name ?? 'Business',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colors.textPrimary),
        ),
        Text(
          DateFormat.yMMMMd().format(DateTime.now()),
          style: TextStyle(fontSize: 13, color: colors.textSecondary),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _SummaryCard(label: "Today's Sales", value: fmt.format(todaySalesTotal), color: Colors.green)),
            const SizedBox(width: 10),
            Expanded(child: _SummaryCard(label: "Today's Expenses", value: fmt.format(todayExpensesTotal), color: Colors.red)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _SummaryCard(label: 'Total Sales (All Time)', value: fmt.format(loaded.totalCashbookSales), color: Colors.green)),
            const SizedBox(width: 10),
            Expanded(
              child: _SummaryCard(
                label: "Today's Net",
                value: fmt.format(todayNet),
                color: todayNet >= 0 ? colors.primary : Colors.red,
                bold: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text('This Week', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: colors.textPrimary)),
        const SizedBox(height: 8),
        _BusinessWeeklyChart(chartData: weeklyChartData),
        if (branches.length > 1) ...[
          const SizedBox(height: 20),
          Text('Branches Today', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: colors.textPrimary)),
          const SizedBox(height: 8),
          ...branchNet.entries.map((entry) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(10)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(branchName(entry.key), style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(fmt.format(entry.value),
                    style: TextStyle(color: entry.value >= 0 ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
              ],
            ),
          )),
        ],
        const SizedBox(height: 20),
        Text('Recent Activity', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: colors.textPrimary)),
        const SizedBox(height: 8),
        if (recent.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(child: Text('No activity yet', style: TextStyle(color: colors.textSecondary))),
          )
        else
          ...recent.map((entry) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(10)),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.description, style: const TextStyle(fontSize: 13)),
                      Text(DateFormat.yMMMd().format(entry.date), style: TextStyle(fontSize: 11, color: colors.textSecondary)),
                    ],
                  ),
                ),
                Text(
                  '${entry.isInflow ? '+' : '-'}${NumberFormat('#,##0').format(entry.amount)}',
                  style: TextStyle(color: entry.isInflow ? Colors.green : Colors.red, fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ],
            ),
          )),
      ],
    );
  }
}

class _BusinessWeeklyChart extends StatelessWidget {
  final List<WeeklyChartDataModel> chartData;
  const _BusinessWeeklyChart({required this.chartData});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    if (chartData.isEmpty) {
      return Container(
        height: 150,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(20)),
        child: Text('No data yet', style: TextStyle(color: colors.textSecondary)),
      );
    }

    final netValues = chartData.map((d) => d.income - d.expenses).toList();
    final barMax = chartData.map((d) => d.income > d.expenses ? d.income : d.expenses).reduce(max);
    final lineMax = netValues.map((v) => v.abs()).reduce(max);
    final maxY = (barMax > lineMax ? barMax : lineMax) * 1.2 + 10;
    final minY = netValues.any((v) => v < 0) ? -(lineMax * 1.2 + 10) : 0.0;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _LegendDot(color: Colors.green, label: 'Sales'),
              const SizedBox(width: 14),
              _LegendDot(color: Colors.red, label: 'Expenses'),
              const SizedBox(width: 14),
              _LegendDot(color: colors.primary, label: 'Net', isLine: true),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: Stack(
              children: [
                BarChart(
                  BarChartData(
                    maxY: maxY,
                    minY: minY,
                    alignment: BarChartAlignment.spaceAround,
                    borderData: FlBorderData(show: false),
                    gridData: const FlGridData(show: false),
                    barTouchData: BarTouchData(enabled: false),
                    barGroups: List.generate(chartData.length, (index) {
                      final day = chartData[index];
                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(toY: day.income, color: Colors.green, width: 10, borderRadius: BorderRadius.circular(3)),
                          BarChartRodData(toY: day.expenses, color: Colors.red, width: 10, borderRadius: BorderRadius.circular(3)),
                        ],
                      );
                    }),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) => SideTitleWidget(
                            meta: meta,
                            child: Text(meta.formattedValue, style: TextStyle(color: colors.textSecondary, fontSize: 10)),
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, _) => Text(
                            chartData[value.toInt()].day,
                            style: TextStyle(color: colors.textSecondary, fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                IgnorePointer(
                  child: LineChart(
                    LineChartData(
                      maxY: maxY,
                      minY: minY,
                      minX: -0.5,
                      maxX: chartData.length - 0.5,
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      titlesData: const FlTitlesData(show: false),
                      lineTouchData: const LineTouchData(enabled: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: List.generate(netValues.length, (i) => FlSpot(i.toDouble(), netValues[i])),
                          isCurved: true,
                          color: colors.primary,
                          barWidth: 2.5,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, bar, index) =>
                                FlDotCirclePainter(radius: 3, color: colors.primary, strokeWidth: 0),
                          ),
                          belowBarData: BarAreaData(show: false),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  final bool isLine;
  const _LegendDot({required this.color, required this.label, this.isLine = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        isLine
            ? Container(width: 10, height: 2, color: color)
            : Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: context.colors.textSecondary)),
      ],
    );
  }
}

class _ActivityEntry {
  final DateTime date;
  final String description;
  final double amount;
  final bool isInflow;
  _ActivityEntry({required this.date, required this.description, required this.amount, required this.isInflow});
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool bold;
  const _SummaryCard({required this.label, required this.value, required this.color, this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: bold ? Border.all(color: color, width: 1.5) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: context.colors.textSecondary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: bold ? 20 : 17)),
        ],
      ),
    );
  }
}
