import 'package:flutter/material.dart';
import 'package:finance_manager/features/budget/data.dart';
import 'package:finance_manager/features/dashboard/categorycard.dart';
import 'package:finance_manager/features/dashboard/figure.dart';
import 'package:finance_manager/features/dashboard/monthlycard.dart';


const double spaceXBetweenSummary = 32.0;
const double spaceYBetweenSummary = 0.0;
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
        body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Monthly card on left
                    const Expanded(
                      flex: 2,
                      child: MonthlyCard(),
                    ),

                    const SizedBox(width: 24),

                    // Four items arranged in two rows on right
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 4),
                          Container(
                          padding: EdgeInsets.symmetric(vertical: 6, horizontal: kPadding),
                            color: const Color(0xFF1E2B4C), // dark navy
                            child: Row(
                              children: [
                                const Text(
                                  'Summary 2025',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14),
                                )
                              ],
                            ),
                          ),
                          // const SizedBox(height: 42),
                          Row(
                            children: [
                              Expanded(
                                child: CategoryCard(
                                  title: 'Income',
                                  items: BudgetData.incomeItems,
                                  baseColor: BudgetData.kGreen,
                                ),
                              ),
                              SizedBox(width: spaceXBetweenSummary),
                              Expanded(
                                child: FigureCard(),
                              ),
                            ],
                          ),
                          const SizedBox(height: spaceYBetweenSummary),
                          Row(
                            children: [
                              Expanded(
                                child: CategoryCard(
                                  title: 'Expenses',
                                  items: BudgetData.expenseItems,
                                  baseColor: BudgetData.kPink,
                                ),
                              ),
                              SizedBox(width: spaceXBetweenSummary),
                              Expanded(
                                child: CategoryCard(
                                  title: 'Savings',
                                  items: BudgetData.savingsItems,
                                  baseColor: BudgetData.kBlue,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ));
  }

  // Example row for months + "Total"
  Widget buildMonthHeaderRow() {
    final List<String> monthsHeader = [
      '',
      'Jan ✓',
      'Feb ✓',
      'Mar ✓',
      'Apr ✓',
      'May ✓',
      'Jun ✓',
      'Jul ✓',
      'Aug ✓',
      'Sep ✓',
      'Oct ✓',
      'Nov ✓',
      'Dec ✓',
      'Total ✓'
    ];

    return Row(
      children: monthsHeader.map((month) {
        return Expanded(
          flex: month.isEmpty ? 3 : 2,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              month,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        );
      }).toList(),
    );
  }
}
