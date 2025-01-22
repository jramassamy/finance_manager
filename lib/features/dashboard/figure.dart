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
                              final categoryIndex = rodIndex;
                              
                              String categoryName;
                              List<BudgetItem> items;
                              Color trackColor;
                              Color budgetColor;
                              
                              switch(categoryIndex) {
                                case 0:
                                  categoryName = 'Income';
                                  items = BudgetData.incomeItems;
                                  trackColor = BudgetData.kGreen;
                                  budgetColor = const Color.fromARGB(255, 186, 238, 191);
                                  break;
                                case 1:
                                  categoryName = 'Expenses';
                                  items = BudgetData.expenseItems;
                                  trackColor = BudgetData.kPink;
                                  budgetColor = const Color.fromARGB(255, 240, 169, 219);
                                  break;
                                case 2:
                                  categoryName = 'Savings';
                                  items = BudgetData.savingsItems;
                                  trackColor = BudgetData.kBlue;
                                  budgetColor = const Color.fromARGB(255, 121, 205, 241);
                                  break;
                                default:
                                  return null;
                              }

                              final tracked = items.fold(0.0, (sum, item) => sum + item.monthly[monthIndex]);
                              final budget = items.fold(0.0, (sum, item) => sum + item.budget[monthIndex]);

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
                          touchCallback: (FlTouchEvent event, barTouchResponse) {
                            setState(() {
                              if (!event.isInterestedForInteractions ||
                                  barTouchResponse == null ||
                                  barTouchResponse.spot == null) {
                                touchedIndex = -1;
                                return;
                              }
                              touchedIndex = barTouchResponse.spot!.touchedBarGroupIndex;
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
                                const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                                return SideTitleWidget(
                                  meta: meta,
                                  child: Text(months[value.toInt()], style: const TextStyle(fontSize: 10)),
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
                        barGroups: List.generate(12, (monthIndex) {
                          return BarChartGroupData(
                            x: monthIndex,
                            barsSpace: 2,
                            barRods: [
                              // Income bar
                              BarChartRodData(
                                toY: BudgetData.incomeItems.fold(0.0, (sum, item) => sum + item.budget[monthIndex]),
                                rodStackItems: [
                                  BarChartRodStackItem(
                                    0,
                                    BudgetData.incomeItems.fold(0.0, (sum, item) => sum + item.monthly[monthIndex]),
                                    BudgetData.kGreen,
                                  ),
                                  BarChartRodStackItem(
                                    BudgetData.incomeItems.fold(0.0, (sum, item) => sum + item.monthly[monthIndex]),
                                    BudgetData.incomeItems.fold(0.0, (sum, item) => sum + item.budget[monthIndex]),
                                    const Color.fromARGB(255, 186, 238, 191),
                                  ),
                                ],
                                borderRadius: BorderRadius.zero,
                                width: barsWidth,
                              ),
                              // Expenses bar
                              BarChartRodData(
                                toY: BudgetData.expenseItems.fold(0.0, (sum, item) => sum + item.budget[monthIndex]),
                                rodStackItems: [
                                  BarChartRodStackItem(
                                    0,
                                    BudgetData.expenseItems.fold(0.0, (sum, item) => sum + item.monthly[monthIndex]),
                                    BudgetData.kPink,
                                  ),
                                  BarChartRodStackItem(
                                    BudgetData.expenseItems.fold(0.0, (sum, item) => sum + item.monthly[monthIndex]),
                                    BudgetData.expenseItems.fold(0.0, (sum, item) => sum + item.budget[monthIndex]),
                                    const Color.fromARGB(255, 240, 169, 219),
                                  ),
                                ],
                                borderRadius: BorderRadius.zero,
                                width: barsWidth,
                              ),
                              // Savings bar
                              BarChartRodData(
                                toY: BudgetData.savingsItems.fold(0.0, (sum, item) => sum + item.budget[monthIndex]),
                                rodStackItems: [
                                  BarChartRodStackItem(
                                    0,
                                    BudgetData.savingsItems.fold(0.0, (sum, item) => sum + item.monthly[monthIndex]),
                                    BudgetData.kBlue,
                                  ),
                                  BarChartRodStackItem(
                                    BudgetData.savingsItems.fold(0.0, (sum, item) => sum + item.monthly[monthIndex]),
                                    BudgetData.savingsItems.fold(0.0, (sum, item) => sum + item.budget[monthIndex]),
                                    const Color.fromARGB(255, 121, 205, 241),
                                  ),
                                ],
                                borderRadius: BorderRadius.zero,
                                width: barsWidth,
                              ),
                            ],
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