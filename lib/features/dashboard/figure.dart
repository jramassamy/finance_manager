import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:finance_manager/features/budget/data.dart';

class FigureCard extends StatefulWidget {
  FigureCard({super.key});

  @override
  State<StatefulWidget> createState() => FigureCardState();
}

class FigureCardState extends State<FigureCard> {
  int selectedMonth = DateTime.now().month - 1;

  Widget _buildLegendItem(Color color, String label) {
    return Row(
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
          // Month selector
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: DropdownButton<int>(
              value: selectedMonth,
              items: List.generate(12, (index) {
                final months = ['Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin', 'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'];
                return DropdownMenuItem(
                  value: index,
                  child: Text(months[index]),
                );
              }),
              onChanged: (value) {
                setState(() {
                  selectedMonth = value!;
                });
                Future.delayed(Duration.zero, () {
                    FocusManager.instance.primaryFocus?.unfocus();
                });
              },
            ),
          ),
          // Legend row
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(BudgetData.kGreen, 'Income'),
                _buildLegendItem(BudgetData.kPink, 'Expenses'),
                _buildLegendItem(BudgetData.kBlue, 'Savings'),
              ],
            ),
          ),
          // Chart
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final barsWidth = 32.0;
                  return BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.center,
                      barTouchData: BarTouchData(
                        enabled: false,
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            getTitlesWidget: (double value, TitleMeta meta) {
                              const style = TextStyle(fontSize: 10);
                              String text = '';
                              switch(value.toInt()) {
                                case 0: text = 'Income'; break;
                                case 1: text = 'Expenses'; break;
                                case 2: text = 'Savings'; break;
                              }
                              return SideTitleWidget(
                                meta: meta,
                                child: Text(text, style: style),
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
                      barGroups: [
                        // Income bar
                        BarChartGroupData(
                          x: 0,
                          barRods: [
                            BarChartRodData(
                              toY: BudgetData.incomeItems.fold(0.0, (sum, item) => sum + item.budget[selectedMonth]),
                              rodStackItems: [
                                BarChartRodStackItem(
                                  0,
                                  BudgetData.incomeItems.fold(0.0, (sum, item) => sum + item.monthly[selectedMonth]),
                                  BudgetData.kGreen,
                                ),
                                BarChartRodStackItem(
                                  BudgetData.incomeItems.fold(0.0, (sum, item) => sum + item.monthly[selectedMonth]),
                                  BudgetData.incomeItems.fold(0.0, (sum, item) => sum + item.budget[selectedMonth]),
                                  const Color.fromARGB(255, 186, 238, 191),
                                ),
                              ],
                              borderRadius: BorderRadius.zero,
                              width: barsWidth,
                            ),
                          ],
                        ),
                        // Expenses bar
                        BarChartGroupData(
                          x: 1,
                          barRods: [
                            BarChartRodData(
                              toY: BudgetData.expenseItems.fold(0.0, (sum, item) => sum + item.budget[selectedMonth]),
                              rodStackItems: [
                                BarChartRodStackItem(
                                  0,
                                  BudgetData.expenseItems.fold(0.0, (sum, item) => sum + item.monthly[selectedMonth]),
                                  BudgetData.kPink,
                                ),
                                BarChartRodStackItem(
                                  BudgetData.expenseItems.fold(0.0, (sum, item) => sum + item.monthly[selectedMonth]),
                                  BudgetData.expenseItems.fold(0.0, (sum, item) => sum + item.budget[selectedMonth]),
                                  const Color.fromARGB(255, 240, 169, 219),
                                ),
                              ],
                              borderRadius: BorderRadius.zero,
                              width: barsWidth,
                            ),
                          ],
                        ),
                        // Savings bar
                        BarChartGroupData(
                          x: 2,
                          barRods: [
                            BarChartRodData(
                              toY: BudgetData.savingsItems.fold(0.0, (sum, item) => sum + item.budget[selectedMonth]),
                              rodStackItems: [
                                BarChartRodStackItem(
                                  0,
                                  BudgetData.savingsItems.fold(0.0, (sum, item) => sum + item.monthly[selectedMonth]),
                                  BudgetData.kBlue,
                                ),
                                BarChartRodStackItem(
                                  BudgetData.savingsItems.fold(0.0, (sum, item) => sum + item.monthly[selectedMonth]),
                                  BudgetData.savingsItems.fold(0.0, (sum, item) => sum + item.budget[selectedMonth]),
                                  const Color.fromARGB(255, 121, 205, 241),
                                ),
                              ],
                              borderRadius: BorderRadius.zero,
                              width: barsWidth,
                            ),
                          ],
                        ),
                      ],
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