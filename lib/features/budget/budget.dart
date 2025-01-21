import 'package:flutter/material.dart';
import 'package:finance_manager/features/budget/data.dart';
import 'package:finance_manager/features/budget/budget-table.dart';

class BudgetPage extends StatelessWidget {
  const BudgetPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.95,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        // INCOME SECTION
                        BudgetTableSection(
                          title: 'Income',
                          backgroundColor: BudgetData.kGreen,
                          items: BudgetData.incomeItems,
                          isExpanded: true,
                        ),

                        const SizedBox(height: 32),

                        // SAVINGS SECTION
                        BudgetTableSection(
                          title: 'Savings',
                          backgroundColor: BudgetData.kBlue,
                          items: BudgetData.savingsItems,
                          isExpanded: true,
                        ),

                        const SizedBox(height: 32),

                        // EXPENSES SECTION
                        BudgetTableSection(
                          title: 'Expenses',
                          backgroundColor: BudgetData.kPink,
                          items: BudgetData.expenseItems,
                          isExpanded: false,
                        ),

                        const SizedBox(height: 32),

                        // REMAINING SECTION
                        BudgetTableSection(
                          title: '€ to Invest',
                          backgroundColor: BudgetData.kDarkNavy,
                          items: BudgetData.remainingItems,
                          isExpanded: false,
                        ),
                        const SizedBox(height: 32),

                        // PATRIMOINE SECTION
                        BudgetTableSection(
                          title: 'Patrimoine',
                          backgroundColor: const Color.fromARGB(255, 12, 122, 108),
                          items: BudgetData.patrimoineItems,
                          isExpanded: false,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
