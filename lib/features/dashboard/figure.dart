import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:finance_manager/features/budget/data.dart';

class FigureCard extends StatefulWidget {
  const FigureCard({super.key});

  @override
  State<StatefulWidget> createState() => FigureCardState();
}

class FigureCardState extends State<FigureCard> {
  int? touchedIndex;
  int selectedLastMonth = DateTime.now().month - 1; // Current month
  final dropdown = FocusNode();

  // Track visibility of each category
  bool showIncome = true;
  bool showExpenses = true;
  bool showSavings = true;
  bool showPatrimoine = false;
  bool showToInvest = false;

  @override
  void initState() {
    super.initState();
    BudgetData.onDataChanged.listen((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  Widget _buildLegendItem(
      Color color, String label, bool isVisible, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: isVisible ? 1.0 : 0.5,
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1.0,
        ),
      ),
      height: 260,
      padding: const EdgeInsets.all(0),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: AspectRatio(
        aspectRatio: 2,
        child: Column(
          children: [
            // Month selector and Legend row
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  // Month selector dropdown
                  Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: DropdownButton<int>(
                      focusNode: dropdown,
                      value: selectedLastMonth,
                      items: List.generate(
                        12,
                        (index) => DropdownMenuItem(
                          value: index,
                          child: Text(months[index]),
                        ),
                      ),
                      onChanged: (int? newValue) {
                        if (newValue != null) {
                          setState(() {
                            selectedLastMonth = newValue;
                          });
                          dropdown.unfocus();
                        }
                      },
                    ),
                  ),
                  const Spacer(),
                  // Legend items
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _buildLegendItem(
                        BudgetData.kGreen,
                        'Income',
                        showIncome,
                        () => setState(() => showIncome = !showIncome),
                      ),
                      _buildLegendItem(
                        BudgetData.kPink,
                        'Expenses',
                        showExpenses,
                        () => setState(() => showExpenses = !showExpenses),
                      ),
                      _buildLegendItem(
                        BudgetData.kBlue,
                        'Savings',
                        showSavings,
                        () => setState(() => showSavings = !showSavings),
                      ),
                      _buildLegendItem(
                        const Color.fromARGB(255, 12, 122, 108),
                        'Patrimoine',
                        showPatrimoine,
                        () => setState(() => showPatrimoine = !showPatrimoine),
                      ),
                      _buildLegendItem(
                        BudgetData.kDarkNavy,
                        '€ to invest',
                        showToInvest,
                        () => setState(() => showToInvest = !showToInvest),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                ],
              ),
            ),
            // Chart
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 16),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final barsWidth = 16.0;
                    final groupSpaceWidth = 50.0;
                    return BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.center,
                        groupsSpace: groupSpaceWidth,
                        barTouchData: BarTouchData(
                          enabled: true,
                          touchTooltipData: BarTouchTooltipData(
                            tooltipPadding: const EdgeInsets.all(8),
                            tooltipMargin: 8,
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              final monthIndex = groupIndex;

                              // Create a list of visible categories
                              final visibleCategories = [
                                if (showIncome)
                                  (
                                    'Income',
                                    BudgetData.incomeItems,
                                    BudgetData.kGreen,
                                    const Color.fromARGB(255, 186, 238, 191)
                                  ),
                                if (showExpenses)
                                  (
                                    'Expenses',
                                    BudgetData.expenseItems,
                                    BudgetData.kPink,
                                    const Color.fromARGB(255, 240, 169, 219)
                                  ),
                                if (showSavings)
                                  (
                                    'Savings',
                                    BudgetData.savingsItems,
                                    BudgetData.kBlue,
                                    const Color.fromARGB(255, 121, 205, 241)
                                  ),
                                if (showPatrimoine)
                                  (
                                    'Patrimoine',
                                    BudgetData.patrimoineItems,
                                    const Color.fromARGB(255, 12, 122, 108),
                                    const Color.fromARGB(255, 144, 199, 192)
                                  ),
                                if (showToInvest)
                                  (
                                    '€ to invest',
                                    BudgetData.remainingItems,
                                    BudgetData.kDarkNavy,
                                    const Color.fromARGB(255, 108, 124, 156)
                                  ),
                              ];

                              // Check if rodIndex is valid for visible categories
                              if (rodIndex >= visibleCategories.length)
                                return null;

                              final (
                                categoryName,
                                items,
                                trackColor,
                                budgetColor
                              ) = visibleCategories[rodIndex];

                              final tracked = items[0].monthly[monthIndex];
                              final budget = (categoryName == '€ to invest' ||
                                      categoryName == 'Patrimoine')
                                  ? items[0].monthly[monthIndex]
                                  : items[0].budget[monthIndex];

                              return BarTooltipItem(
                                '$categoryName\n',
                                const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.left,
                                children: [
                                  TextSpan(
                                    text: 'Tracked: ',
                                    style: TextStyle(
                                      color: trackColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextSpan(
                                    text: '${tracked.toStringAsFixed(1)}\n',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'Budget:  ',
                                    style: TextStyle(
                                      color: budgetColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextSpan(
                                    text: budget.toStringAsFixed(1),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          touchCallback:
                              (FlTouchEvent event, barTouchResponse) {
                            setState(() {
                              if (!event.isInterestedForInteractions ||
                                  barTouchResponse == null ||
                                  barTouchResponse.spot == null) {
                                touchedIndex = -1;
                                return;
                              }
                              touchedIndex =
                                  barTouchResponse.spot!.touchedBarGroupIndex;
                            });
                          },
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 28,
                              getTitlesWidget: (double value, TitleMeta meta) {
                                const months = [
                                  'Jan',
                                  'Fév',
                                  'Mar',
                                  'Avr',
                                  'Mai',
                                  'Juin',
                                  'Juil',
                                  'Août',
                                  'Sep',
                                  'Oct',
                                  'Nov',
                                  'Déc'
                                ];
                                return SideTitleWidget(
                                  meta: meta,
                                  child: Text(months[value.toInt()],
                                      style: const TextStyle(fontSize: 10)),
                                );
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (double value, TitleMeta meta) {
                                if (value == meta.max) {
                                  return Container();
                                }
                                return SideTitleWidget(
                                  meta: meta,
                                  child: Text(
                                    meta.formattedValue,
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                );
                              },
                            ),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        gridData: FlGridData(
                          show: true,
                          checkToShowHorizontalLine: (value) => value % 10 == 0,
                          getDrawingHorizontalLine: (value) => FlLine(
                            color: Colors.grey.withOpacity(0.1),
                            strokeWidth: 1,
                          ),
                          drawVerticalLine: false,
                        ),
                        borderData: FlBorderData(
                          show: false,
                        ),
                        barGroups:
                            List.generate(selectedLastMonth + 1, (monthIndex) {
                          return BarChartGroupData(
                            x: monthIndex,
                            barsSpace: 2,
                            barRods: [
                              // Income bar
                              if (showIncome)
                                BarChartRodData(
                                  toY: BudgetData.incomeItems.fold(
                                      0.0,
                                      (sum, item) =>
                                          sum + item.budget[monthIndex]),
                                  rodStackItems: [
                                    BarChartRodStackItem(
                                      0,
                                      BudgetData.incomeItems.fold(
                                          0.0,
                                          (sum, item) =>
                                              sum + item.monthly[monthIndex]),
                                      BudgetData.kGreen,
                                    ),
                                    BarChartRodStackItem(
                                      BudgetData.incomeItems.fold(
                                          0.0,
                                          (sum, item) =>
                                              sum + item.monthly[monthIndex]),
                                      BudgetData.incomeItems.fold(
                                          0.0,
                                          (sum, item) =>
                                              sum + item.budget[monthIndex]),
                                      const Color.fromARGB(255, 186, 238, 191),
                                    ),
                                  ],
                                  borderRadius: BorderRadius.zero,
                                  width: barsWidth,
                                ),
                              // Expenses bar
                              if (showExpenses)
                                BarChartRodData(
                                  toY: BudgetData.expenseItems.fold(
                                      0.0,
                                      (sum, item) =>
                                          sum + item.budget[monthIndex]),
                                  rodStackItems: [
                                    BarChartRodStackItem(
                                      0,
                                      BudgetData.expenseItems.fold(
                                          0.0,
                                          (sum, item) =>
                                              sum + item.monthly[monthIndex]),
                                      BudgetData.kPink,
                                    ),
                                    BarChartRodStackItem(
                                      BudgetData.expenseItems.fold(
                                          0.0,
                                          (sum, item) =>
                                              sum + item.monthly[monthIndex]),
                                      BudgetData.expenseItems.fold(
                                          0.0,
                                          (sum, item) =>
                                              sum + item.budget[monthIndex]),
                                      const Color.fromARGB(255, 240, 169, 219),
                                    ),
                                  ],
                                  borderRadius: BorderRadius.zero,
                                  width: barsWidth,
                                ),
                              // Savings bar
                              if (showSavings)
                                BarChartRodData(
                                  toY: BudgetData.savingsItems.fold(
                                      0.0,
                                      (sum, item) =>
                                          sum + item.budget[monthIndex]),
                                  rodStackItems: [
                                    BarChartRodStackItem(
                                      0,
                                      BudgetData.savingsItems.fold(
                                          0.0,
                                          (sum, item) =>
                                              sum + item.monthly[monthIndex]),
                                      BudgetData.kBlue,
                                    ),
                                    BarChartRodStackItem(
                                      BudgetData.savingsItems.fold(
                                          0.0,
                                          (sum, item) =>
                                              sum + item.monthly[monthIndex]),
                                      BudgetData.savingsItems.fold(
                                          0.0,
                                          (sum, item) =>
                                              sum + item.budget[monthIndex]),
                                      const Color.fromARGB(255, 121, 205, 241),
                                    ),
                                  ],
                                  borderRadius: BorderRadius.zero,
                                  width: barsWidth,
                                ),
                              // Patrimoine bar
                              if (showPatrimoine)
                                BarChartRodData(
                                  toY: BudgetData
                                      .patrimoineItems[0].budget[monthIndex]
                                      .toDouble(),
                                  rodStackItems: [
                                    BarChartRodStackItem(
                                      0,
                                      BudgetData.patrimoineItems[0]
                                          .monthly[monthIndex]
                                          .toDouble(),
                                      const Color.fromARGB(255, 12, 122, 108),
                                    ),
                                    BarChartRodStackItem(
                                      BudgetData.patrimoineItems[0]
                                          .monthly[monthIndex]
                                          .toDouble(),
                                      BudgetData
                                          .patrimoineItems[0].budget[monthIndex]
                                          .toDouble(),
                                      const Color.fromARGB(255, 144, 199, 192),
                                    ),
                                  ],
                                  borderRadius: BorderRadius.zero,
                                  width: barsWidth,
                                ),
                              // € to invest bar
                              if (showToInvest)
                                BarChartRodData(
                                  toY: BudgetData
                                      .remainingItems[0].budget[monthIndex]
                                      .toDouble(),
                                  rodStackItems: [
                                    BarChartRodStackItem(
                                      0,
                                      BudgetData
                                          .remainingItems[0].monthly[monthIndex]
                                          .toDouble(),
                                      BudgetData.kDarkNavy,
                                    ),
                                    BarChartRodStackItem(
                                      BudgetData
                                          .remainingItems[0].monthly[monthIndex]
                                          .toDouble(),
                                      BudgetData
                                          .remainingItems[0].budget[monthIndex]
                                          .toDouble(),
                                      const Color.fromARGB(255, 108, 124, 156),
                                    ),
                                  ],
                                  borderRadius: BorderRadius.zero,
                                  width: barsWidth,
                                ),
                            ].where((rod) => rod != null).toList(),
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
