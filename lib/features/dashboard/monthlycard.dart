import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../budget/data.dart';

// Configurable parameters
const double kTextSize = 12.0;
const double kMargin = 4.0;
const double kPadding = 8.0;

/// A card that shows the full "Breakdown" for the selected month/year
class MonthlyCard extends StatefulWidget {
  const MonthlyCard({super.key});

  @override
  State<MonthlyCard> createState() => _MonthlyCardState();
}

class _MonthlyCardState extends State<MonthlyCard> {
  // The currently displayed month index (0..11). Example: 7 -> "août" (August)
  int _monthIndex = DateTime.now().month - 1; // 0-based index for current month
  final FocusNode _focusNode = FocusNode();

  // Editing state
  bool _isEditing = false;
  BudgetItem? _editingItem;
  int? _editingRowIndex;
  String? _editingCategory;
  String? _originalValue;
  final TextEditingController _editingController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  /// Begin editing a particular (item, rowIndex, category).
  /// If already editing another cell, commit that first.
  void _startEditing(
      BudgetItem item, int rowIndex, String category, double value) {
    if (_isEditing &&
        (_editingItem != item ||
            _editingRowIndex != rowIndex ||
            _editingCategory != category)) {
      _commitEditing(); // commit/cancel the previous editing
    }

    setState(() {
      _isEditing = true;
      _editingItem = item;
      _editingRowIndex = rowIndex;
      _editingCategory = category;
      _originalValue = value.toString();
      _editingController.text = '';
      // _editingController.text = _originalValue!;
    });
  }

  /// Commit the value from [_editingController] to the relevant budget list.
  void _commitEditing() {
    if (!_isEditing || _editingItem == null || _editingRowIndex == null) {
      return;
    }

    if (_editingController.text.trim().isEmpty) {
      _editingController.text = _originalValue!;
    }

    final newValue = double.tryParse(_editingController.text.trim()) ?? 0.0;

    setState(() {
      if (_editingCategory == 'Income') {
        BudgetData.incomeItems[_editingRowIndex!].budget[_monthIndex] =
            newValue;
      } else if (_editingCategory == 'Expenses') {
        BudgetData.expenseItems[_editingRowIndex!].budget[_monthIndex] =
            newValue;
      } else if (_editingCategory == 'Savings') {
        BudgetData.savingsItems[_editingRowIndex!].budget[_monthIndex] =
            newValue;
      }

      // Save changes
      BudgetData.saveData();

      // Reset editing state
      _isEditing = false;
      _editingItem = null;
      _editingRowIndex = null;
      _editingCategory = null;
      _originalValue = null;
      _editingController.clear();
    });
  }

  /// Cancel editing without committing changes.
  void _cancelEditing() {
    if (!_isEditing) return;
    setState(() {
      _isEditing = false;
      _editingItem = null;
      _editingRowIndex = null;
      _editingCategory = null;
      _originalValue = null;
      _editingController.clear();
    });
  }

  /// Helper that builds the "Income", "Expenses", or "Savings" sections
  Widget _buildCategorySection(
      {required String categoryTitle,
      required Color headerColor,
      required List<BudgetItem> items}) {
    // We track total sums for tracked/budget to compute the "total" row
    double totalTracked = 0;
    double totalBudget = 0;

    // Compute sums
    for (final item in items) {
      totalTracked += item.monthly[_monthIndex];
      totalBudget += item.budget[_monthIndex];
    }

    // Build the section
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Table header row
        Container(
          color: headerColor,
          padding: EdgeInsets.symmetric(
              vertical: kPadding / 4, horizontal: kPadding),
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: Padding(
                  padding: EdgeInsets.only(left: 0),
                  child: Text(categoryTitle,
                      style: TextStyle(
                          fontWeight: FontWeight.w600, color: Colors.white)),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text('Tracked',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontWeight: FontWeight.normal, color: Colors.white)),
              ),
              Expanded(
                flex: 2,
                child: Text('Budget',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontWeight: FontWeight.normal, color: Colors.white)),
              ),
              Expanded(
                flex: 2,
                child: Text('% Compl.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontWeight: FontWeight.normal, color: Colors.white)),
              ),
              Expanded(
                flex: 2,
                child: Text('Remaining',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontWeight: FontWeight.normal, color: Colors.white)),
              ),
              Expanded(
                flex: 2,
                child: Text('Excess',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontWeight: FontWeight.normal, color: Colors.white)),
              ),
            ],
          ),
        ),
        // Rows + total row
        // Use a ListView.builder for performance:
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length + 1, // +1 for the total row
          itemBuilder: (context, index) {
            // If it's the last index, build the "Total" row
            if (index == items.length) {
              return _buildDataRow(
                name: 'Total',
                tracked: totalTracked,
                budget: totalBudget,
                onBudgetTap: null, // total row is read-only
                isTotal: true,
                color: Colors.white,
                borderColor: Colors.grey.shade500,
                baseColor: headerColor,
                rowIndex: index,
                category: categoryTitle,
              );
            }

            // Otherwise, build normal row
            final item = items[index];
            final tracked = item.monthly[_monthIndex].toDouble();
            final budget = item.budget[_monthIndex];

            return _buildDataRow(
              name: item.name,
              tracked: tracked,
              budget: budget.toDouble(),
              onBudgetTap: () {
                _startEditing(item, index, categoryTitle, budget.toDouble());
              },
              isTotal: false,
              color: Colors.white,
              borderColor: Colors.white,
              baseColor: headerColor,
              // color: headerColor.withOpacity(0.1),
              rowIndex: index,
              category: categoryTitle,
            );
          },
        ),
      ],
    );
  }

  /// Builds a single row with columns:
  ///   Name, Tracked, Budget, % Completion, Remaining, Excess
  Widget _buildDataRow({
    required String name,
    required double tracked,
    required double budget,
    required VoidCallback? onBudgetTap,
    required bool isTotal,
    required Color color,
    required Color borderColor,
    required Color baseColor,
    required int rowIndex,
    required String category,
  }) {
    final percent = (budget == 0) ? 0 : (tracked / budget * 100);
    final double remaining = (tracked <= budget) ? (budget - tracked) : 0;
    final double excess = (tracked > budget) ? (tracked - budget) : 0;

    // Are we editing *this* row right now?
    final bool isThisRowEditing = _isEditing &&
        _editingRowIndex == rowIndex &&
        _editingCategory == category;

    return Container(
      decoration: BoxDecoration(
        color: color,
        border: Border(
          top: BorderSide(color: borderColor),
        ),
      ),
      padding:
          EdgeInsets.symmetric(vertical: kPadding / 4, horizontal: kPadding),
      child: Row(
        children: [
          // Name
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.only(left: 0),
              child: Tooltip(
                message: name,
                preferBelow: true,
                child: Text(
                  name.length > 20 ? '${name.substring(0, 20)}...' : name,
                  style: TextStyle(
                      fontWeight:
                          isTotal ? FontWeight.w600 : FontWeight.normal),
                ),
              ),
            ),
          ),
          // Tracked
          Expanded(
            flex: 2,
            child: Text(
              _formatNumber(tracked),
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal),
            ),
          ),
          // Budget (editable if not total)
          Expanded(
            flex: 2,
            child: isTotal
                ? Text(
                    _formatNumber(budget),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  )
                : GestureDetector(
                    onTap: onBudgetTap,
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: kPadding / 4),
                      child: isThisRowEditing
                          ? TextField(
                              controller: _editingController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                    vertical: kPadding / 2),
                                border: InputBorder.none,
                              ),
                              onSubmitted: (_) => _commitEditing(),
                            )
                          : Text(
                              _formatNumber(budget),
                              textAlign: TextAlign.center,
                            ),
                    ),
                  ),
          ),
          // % Completion
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  stops: [percent / 100, percent / 100],
                  colors: [
                    baseColor.withOpacity(0.2),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Text(
                '${percent.toStringAsFixed(0)}%',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.normal,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          // Remaining
          Expanded(
            flex: 2,
            child: remaining > 0
                ? Text(
                    _formatNumber(remaining),
                    textAlign: TextAlign.center,
                  )
                : const Text('-', textAlign: TextAlign.center),
          ),
          // Excess
          Expanded(
            flex: 2,
            child: excess > 0
                ? Text(
                    _formatNumber(excess),
                    textAlign: TextAlign.center,
                  )
                : const Text('-', textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }

  /// A small helper widget for the month label; uses a dropdown to select the month.
  Widget _monthSelector() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 4, horizontal: kPadding),
      color: const Color(0xFF1E2B4C), // dark navy
      child: Row(
        children: [
          const Text(
            'Breakdown – ',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
          ),
          DropdownButton<int>(
            value: _monthIndex,
            dropdownColor: const Color(0xFF1E2B4C),
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
            underline: Container(),
            isDense: true,
            padding: EdgeInsets.zero,
            onChanged: (int? newValue) {
              if (newValue != null) {
                if (_isEditing) {
                  _commitEditing();
                }
                setState(() {
                  _monthIndex = newValue;
                });
              }
            },
            items: List.generate(12, (index) {
              return DropdownMenuItem<int>(
                value: index,
                child: Text(months[index], style: TextStyle(fontSize: 14)),
              );
            }),
          ),
          const Text(
            ' 2025',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: (KeyEvent event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape &&
            _isEditing) {
          _cancelEditing(); // Using cancel instead of commit for Escape key
        }
      },
      child: GestureDetector(
        // Tap anywhere outside the TextField to unfocus and commit the changes
        onTap: () {
          FocusScope.of(context).unfocus();
          if (_isEditing) {
            _commitEditing();
          }
        },
        child: Card(
          elevation: 4,
          margin: EdgeInsets.all(kMargin),
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Month selector
                _monthSelector(),
                SizedBox(height: kMargin * 2),

                // Income section
                _buildCategorySection(
                    categoryTitle: 'Income',
                    headerColor: const Color(0xFF26A86D),
                    items: BudgetData.incomeItems),
                SizedBox(height: kMargin * 2),

                // Expenses section
                _buildCategorySection(
                    categoryTitle: 'Expenses',
                    headerColor: const Color(0xFFFE1684),
                    items: BudgetData.expenseItems),
                SizedBox(height: kMargin * 2),

                // Savings section
                _buildCategorySection(
                    categoryTitle: 'Savings',
                    headerColor: const Color(0xFF3285F3),
                    items: BudgetData.savingsItems),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Format an integer number with spaces every three digits: e.g. 12 345
  String _formatNumber(double value) {
    final number = value.toInt();
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        );
  }

  @override
  void dispose() {
    _editingController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}
