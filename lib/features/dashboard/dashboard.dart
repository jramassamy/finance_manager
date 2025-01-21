import 'package:flutter/material.dart';
import 'package:finance_manager/features/budget/data.dart';
import 'package:finance_manager/features/dashboard/categorycard.dart';
import 'package:finance_manager/features/dashboard/figure.dart';
import 'package:finance_manager/features/dashboard/monthlycard.dart';

// Example color approximations – feel free to adjust
const Color kDarkNavy = Color(0xFF1E2B4C);
const Color kGreen = Color(0xFF26A86D);
const Color kPink = Color(0xFFFE1684);
const Color kBlue = Color(0xFF3285F3);
const double spaceXBetweenSummary = 32.0;
const double spaceYBetweenSummary = 16.0;
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
                            padding: EdgeInsets.symmetric(
                                vertical: 14, horizontal: 8),
                            color: const Color(0xFF1E2B4C), // dark navy
                            child: Row(
                              children: [
                                const Text(
                                  'Summary - 2025',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                )
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: CategoryCard(
                                  title: 'Income',
                                  items: BudgetData.incomeItems,
                                  baseColor: kGreen,
                                ),
                              ),
                              SizedBox(width: spaceXBetweenSummary),
                              Expanded(
                                child: Container(
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Center(
                                    child: Text('Placeholder Item'),
                                  ),
                                ),
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
                                  baseColor: kPink,
                                ),
                              ),
                              SizedBox(width: spaceXBetweenSummary),
                              Expanded(
                                child: CategoryCard(
                                  title: 'Savings',
                                  items: BudgetData.savingsItems,
                                  baseColor: kBlue,
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
