import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../budget/data.dart'; // <-- Your data.dart

class FigureWidget extends StatefulWidget {
  const FigureWidget({Key? key}) : super(key: key);

  @override
  State<FigureWidget> createState() => _FigureWidgetState();
}

class _FigureWidgetState extends State<FigureWidget> {
  bool _initialized = false;

  // Toggles for the three categories:
  bool showIncome = true;
  bool showExpenses = true;
  bool showSavings = true;

  @override
  void initState() {
    super.initState();
    BudgetData.initialize().then((_) {
      setState(() => _initialized = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      // While data is loading, show a placeholder
      return const SizedBox(
        width: 600,
        height: 600,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return SizedBox(
      width: 600,
      height: 600,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(title: const Text('Tracked (vs. Budget)')),
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 16),
              // Title
              const Text(
                'Tracked (vs. Budget)',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Checkboxes row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendCheckbox(
                    label: 'Income',
                    color: Colors.green,
                    value: showIncome,
                    onChanged: (val) => setState(() => showIncome = val),
                  ),
                  _buildLegendCheckbox(
                    label: 'Expenses',
                    color: Colors.pink,
                    value: showExpenses,
                    onChanged: (val) => setState(() => showExpenses = val),
                  ),
                  _buildLegendCheckbox(
                    label: 'Savings',
                    color: Colors.blue,
                    value: showSavings,
                    onChanged: (val) => setState(() => showSavings = val),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // The bar chart
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: BarChart(
                    BarChartData(
                      // Add some headroom above the highest bar
                      maxY: _computeMaxY() * 1.1,
                      gridData: FlGridData(show: true),
                      borderData: FlBorderData(show: false),
                      // Show only month labels on the bottom, hide other axes
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index < 0 || index >= months.length) {
                                return const SizedBox.shrink();
                              }
                              return Text(
                                months[index],
                                style: const TextStyle(fontSize: 10),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      // Spacing between months
                      groupsSpace: 30,
                      barGroups: _buildBarGroups(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  ///
  /// For each of the 12 months, builds one BarChartGroupData with up to 3 rods:
  ///  (Income, Expenses, Savings).
  /// barsSpace=0 => the bars for that month touch each other horizontally.
  ///
  List<BarChartGroupData> _buildBarGroups() {
    final groups = <BarChartGroupData>[];

    for (int i = 0; i < months.length; i++) {
      // Sums for each category, at month i
      final incBudget  = _sumMonth(BudgetData.incomeItems, i, budget: true);
      final incActual  = _sumMonth(BudgetData.incomeItems, i);

      final expBudget  = _sumMonth(BudgetData.expenseItems, i, budget: true);
      final expActual  = _sumMonth(BudgetData.expenseItems, i);

      final savBudget  = _sumMonth(BudgetData.savingsItems, i, budget: true);
      final savActual  = _sumMonth(BudgetData.savingsItems, i);

      final rods = <BarChartRodData>[];

      // Income bar
      if (showIncome) {
        rods.add(_buildBudgetActualRod(
          budget: incBudget,
          actual: incActual,
          color: Colors.green,
        ));
      }

      // Expenses bar
      if (showExpenses) {
        rods.add(_buildBudgetActualRod(
          budget: expBudget,
          actual: expActual,
          color: Colors.pink,
        ));
      }

      // Savings bar
      if (showSavings) {
        rods.add(_buildBudgetActualRod(
          budget: savBudget,
          actual: savActual,
          color: Colors.blue,
        ));
      }

      groups.add(BarChartGroupData(
        x: i,
        barsSpace: 0,  // No space between the 3 bars for this month
        barRods: rods,
      ));
    }

    return groups;
  }

  ///
  /// Returns one BarChartRodData that visually overlays the “budget” portion
  /// in semi‐transparent color, plus the “actual” portion in full color.
  ///
  BarChartRodData _buildBudgetActualRod({
    required double budget,
    required double actual,
    required Color color,
  }) {
    // The bar extends up to whichever is bigger.
    final double barTop = math.max(budget, actual);

    // We'll always draw the "budget" segment from 0..budget in 0.3 opacity,
    // then we overlay the "actual" portion in full color from 0..actual
    // if actual < budget, or from budget..actual if actual > budget.
    return BarChartRodData(
      toY: barTop,
      color: Colors.transparent,
      width: 16,
      rodStackItems: [
        // 1) Budget portion: 0..budget with 0.3 opacity
        BarChartRodStackItem(
          0,
          budget,
          color.withOpacity(0.3),
        ),
        // 2) Actual portion (overlay)
        if (actual <= budget)
          // Actual is smaller => overlay from 0..actual with full color
          BarChartRodStackItem(0, actual, color)
        else
          // Actual is larger => overlay from budget..actual with full color
          BarChartRodStackItem(budget, actual, color),
      ],
    );
  }

  // Returns the largest of any budget/actual across all categories & months
  double _computeMaxY() {
    double maxVal = 0;
    for (int i = 0; i < months.length; i++) {
      final incB = _sumMonth(BudgetData.incomeItems, i, budget: true);
      final incA = _sumMonth(BudgetData.incomeItems, i);

      final expB = _sumMonth(BudgetData.expenseItems, i, budget: true);
      final expA = _sumMonth(BudgetData.expenseItems, i);

      final savB = _sumMonth(BudgetData.savingsItems, i, budget: true);
      final savA = _sumMonth(BudgetData.savingsItems, i);

      maxVal = math.max(maxVal, math.max(incB, incA));
      maxVal = math.max(maxVal, math.max(expB, expA));
      maxVal = math.max(maxVal, math.max(savB, savA));
    }
    return maxVal;
  }

  // Helper to sum either the budget or actual values for a list of items for monthIndex
  double _sumMonth(List<BudgetItem> items, int monthIndex, {bool budget = false}) {
    double sum = 0;
    for (final item in items) {
      sum += budget
          ? item.budget[monthIndex].toDouble()
          : item.monthly[monthIndex].toDouble();
    }
    return sum;
  }

  // Simple row with a checkbox + label
  Widget _buildLegendCheckbox({
    required String label,
    required Color color,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(
          value: value,
          onChanged: (checked) => onChanged(checked ?? false),
          activeColor: color,
        ),
        Text(label),
        const SizedBox(width: 16),
      ],
    );
  }
}
