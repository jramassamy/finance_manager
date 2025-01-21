import 'package:flutter/material.dart';
import 'package:finance_manager/features/budget/data.dart';
import 'package:finance_manager/features/budget/budget-table.dart';

// Example color approximations – feel free to adjust to match the image
const Color kDarkNavy = Color(0xFF1E2B4C);
const Color kGreen = Color(0xFF26A86D);
const Color kPink = Color(0xFFFE1684);
const Color kBlue = Color(0xFF3285F3);

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
                          backgroundColor: kGreen,
                          items: BudgetData.incomeItems,
                          isExpanded: true,
                        ),

                        const SizedBox(height: 32),

                        // SAVINGS SECTION
                        BudgetTableSection(
                          title: 'Savings',
                          backgroundColor: kBlue,
                          items: BudgetData.savingsItems,
                          isExpanded: true,
                        ),

                        const SizedBox(height: 32),

                        // EXPENSES SECTION
                        BudgetTableSection(
                          title: 'Expenses',
                          backgroundColor: kPink,
                          items: BudgetData.expenseItems,
                          isExpanded: false,
                        ),

                        const SizedBox(height: 32),

                        // REMAINING SECTION
                        BudgetTableSection(
                          title: 'Remaining to Invest',
                          backgroundColor: kDarkNavy,
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
