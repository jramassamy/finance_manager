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
  num _previousValue = 0;
  String? _editingField; // 'tracked' or 'budget'
  final TextEditingController _editingController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  /// Begin editing a particular (item, rowIndex, category).
  /// If already editing another cell, commit that first.
  void _startEditing(BudgetItem item, int rowIndex, String category,
      double value, String field) {
    if (_isEditing &&
        (_editingItem != item ||
            _editingRowIndex != rowIndex ||
            _editingCategory != category ||
            _editingField != field)) {
      _commitEditing(); // commit/cancel the previous editing
    }

    setState(() {
      _isEditing = true;
      _editingItem = item;
      _editingRowIndex = rowIndex;
      _editingCategory = category;
      _editingField = field;
      _previousValue = value;
      _editingController.text = value.toString().replaceFirst('.0', '');
      // _editingController.text = '';
    });
  }

  /// Commit the value from [_editingController] to the relevant budget list.
  void _commitEditing() {
    if (!_isEditing || _editingItem == null || _editingRowIndex == null) {
      return;
    }

    if (_editingController.text.trim().isEmpty) {
      _editingController.text = _formatNumber(_previousValue);
    }

    String newValue = _editingController.text.trim().replaceAll('=', '').replaceAll(' ', '');
    num parsed;

    // Check if the input contains arithmetic operators
    if (newValue.contains(RegExp(r'[\+\-\*\/]'))) {
      // Remove any equal signs from the expression
      parsed = _evaluateExpression(newValue);
    } else {
      parsed = num.tryParse(newValue) ?? _previousValue;
    }

    if (parsed is double) {
      parsed = double.parse(parsed.toStringAsFixed(2));
    }

    setState(() {
      if (_editingCategory == 'Income') {
        if (_editingField == 'tracked') {
          BudgetData.incomeItems[_editingRowIndex!].monthly[_monthIndex] =
              parsed;
        } else {
          BudgetData.incomeItems[_editingRowIndex!].budget[_monthIndex] =
              parsed;
        }
      } else if (_editingCategory == 'Expenses') {
        if (_editingField == 'tracked') {
          BudgetData.expenseItems[_editingRowIndex!].monthly[_monthIndex] =
              parsed;
        } else {
          BudgetData.expenseItems[_editingRowIndex!].budget[_monthIndex] =
              parsed;
        }
      } else if (_editingCategory == 'Savings') {
        if (_editingField == 'tracked') {
          BudgetData.savingsItems[_editingRowIndex!].monthly[_monthIndex] =
              parsed;
        } else {
          BudgetData.savingsItems[_editingRowIndex!].budget[_monthIndex] =
              parsed;
        }
      }

      // Save changes
      BudgetData.saveData();
      BudgetData.notifyDataChanged();
      // Reset editing state
      _isEditing = false;
      _editingItem = null;
      _editingRowIndex = null;
      _editingCategory = null;
      _editingField = null;
      _previousValue = 0;
      _editingController.clear();
    });
  }

  num _evaluateExpression(String expression) {
    // Remove all spaces from the expression
    expression = expression.replaceAll(' ', '');
    expression = expression.replaceAll(',', '.');

    // Check if expression contains any invalid characters
    if (!RegExp(r'^[0-9\.\+\-\*\/]+$').hasMatch(expression)) {
      return 0;
    }

    // Check for consecutive operators
    if (RegExp(r'[\+\-\*\/]{2,}').hasMatch(expression)) {
      return 0;
    }

    try {
      // First handle multiplication and division
      while (expression.contains(RegExp(r'[\*\/]'))) {
        expression = expression
            .replaceAllMapped(RegExp(r'(\d*\.?\d+)[\*\/](\d*\.?\d+)'), (match) {
          final num a = num.parse(match[1]!);
          final num b = num.parse(match[2]!);
          if (match[0]!.contains('*')) {
            return (a * b).toString();
          } else {
            return (a / b).toString();
          }
        });
      }

      // Then handle addition and subtraction
      final numbers = expression.split(RegExp(r'[\+\-]'));
      final operators = expression
          .split(RegExp(r'[0-9\.]+'))
          .where((op) => op.isNotEmpty)
          .toList();

      num result = num.parse(numbers[0]);
      for (int i = 0; i < operators.length; i++) {
        final nextNum = num.parse(numbers[i + 1]);
        if (operators[i] == '+') {
          result += nextNum;
        } else if (operators[i] == '-') {
          result -= nextNum;
        }
      }
      return result;
    } catch (e) {
      return 0;
    }
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

    totalTracked = double.parse(totalTracked.toStringAsFixed(2));
    totalBudget = double.parse(totalBudget.toStringAsFixed(2));

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
                child: Text('Limit',
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
                child: Text('Remain.',
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
        // Scrollable rows container with fixed height
        Container(
          constraints: BoxConstraints(
            maxHeight: (29.5) * 8, // Max height for 8 rows
          ),
          child: ListView.builder(
            shrinkWrap: true,
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final tracked =
                  double.parse(item.monthly[_monthIndex].toStringAsFixed(2));
              final budget =
                  double.parse(item.budget[_monthIndex].toStringAsFixed(2));

              return _buildDataRow(
                name: item.name,
                tracked: tracked,
                budget: budget,
                onTrackedTap: () {
                  _startEditing(item, index, categoryTitle, tracked, 'tracked');
                },
                onBudgetTap: () {
                  _startEditing(item, index, categoryTitle, budget, 'budget');
                },
                isTotal: false,
                color: Colors.white,
                borderColor: Colors.white,
                baseColor: headerColor,
                rowIndex: index,
                category: categoryTitle,
              );
            },
          ),
        ),
        // Total row (always visible at bottom)
        _buildDataRow(
          name: 'Total',
          tracked: totalTracked,
          budget: totalBudget,
          onTrackedTap: null,
          onBudgetTap: null,
          isTotal: true,
          color: Colors.white,
          borderColor: Colors.grey.shade400,
          baseColor: headerColor,
          rowIndex: items.length,
          category: categoryTitle,
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
    required VoidCallback? onTrackedTap,
    required VoidCallback? onBudgetTap,
    required bool isTotal,
    required Color color,
    required Color borderColor,
    required Color baseColor,
    required int rowIndex,
    required String category,
  }) {
    final percent = (budget == 0) ? 0 : (tracked / budget * 100);
    double remaining = (tracked <= budget) ? (budget - tracked) : 0;
    double excess = (tracked > budget) ? (tracked - budget) : 0;

    remaining = double.parse(remaining.toStringAsFixed(2));
    excess = double.parse(excess.toStringAsFixed(2));

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
      margin: isTotal ? EdgeInsets.only(top: 4) : EdgeInsets.zero,
      padding: isTotal
          ? EdgeInsets.only(
              top: kPadding / 2,
              bottom: kPadding,
              left: kPadding,
              right: kPadding)
          : EdgeInsets.symmetric(vertical: kPadding / 4, horizontal: kPadding),
      child: Row(
        children: [
          // Name
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.only(left: 0),
              child: GestureDetector(
                onTap: () {
                  final overlay = Overlay.of(context);
                  final renderBox = context.findRenderObject() as RenderBox;
                  final position = renderBox.localToGlobal(Offset.zero);

                  final entry = OverlayEntry(
                    builder: (context) => Positioned(
                      left: position.dx,
                      top: position.dy + renderBox.size.height,
                      child: Material(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          child: Text(
                            name,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  );

                  overlay.insert(entry);
                  Future.delayed(const Duration(seconds: 1), () {
                    entry.remove();
                  });
                },
                child: Tooltip(
                  message: name,
                  preferBelow: true,
                  child: Text(
                    MediaQuery.of(context).size.width >= 1024
                        ? (name.length > 15
                            ? '${name.substring(0, 15)}...'
                            : name)
                        : (name.length > 10
                            ? '${name.substring(0, 10)}.'
                            : name),
                    style: TextStyle(
                        fontWeight:
                            isTotal ? FontWeight.w600 : FontWeight.normal),
                  ),
                ),
              ),
            ),
          ),
          // Tracked (editable if not total)
          Expanded(
            flex: 2,
            child: isTotal
                ? Text(
                    _formatNumber(tracked),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  )
                : GestureDetector(
                    onTap: onTrackedTap,
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: kPadding / 4),
                      child: isThisRowEditing && _editingField == 'tracked'
                          ? TextField(
                              controller: _editingController,
                              autofocus: true,
                            keyboardType: TextInputType.text,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'[0-9\.\,\+\-\*\/\s]')),
                            ],
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
                              _formatNumber(tracked),
                              textAlign: TextAlign.center,
                            ),
                    ),
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
                      child: isThisRowEditing && _editingField == 'budget'
                          ? TextField(
                              controller: _editingController,
                              autofocus: true,
                            keyboardType: TextInputType.text,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'[0-9\.\,\+\-\*\/\s]')),
                            ],
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

  /// Helper that builds the Finance section showing investment potential and patrimony
  Widget _buildFinanceSection() {
    // Define the header color for the Finance section
    final Color headerColor = const Color(0xFF1E2B4C); // dark navy color

    // Calculate the financial metrics
    num toInvest = BudgetData.findByName(BudgetData.remainingItems, 'remaining').monthly[_monthIndex];
    toInvest = num.parse(toInvest.toStringAsFixed(2));
    num patrimony = BudgetData.findByName(BudgetData.patrimoineItems, 'patrimoine').monthly[_monthIndex];
    patrimony = num.parse(patrimony.toStringAsFixed(2));

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
                  child: Text('Finance',
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
              Expanded(flex: 2, child: Text('')),
              Expanded(flex: 2, child: Text('')),
              Expanded(flex: 2, child: Text('')),
              Expanded(flex: 2, child: Text('')),
            ],
          ),
        ),
        // To Invest row
        _buildFinanceRow(
          name: '€ To Invest',
          value: toInvest,
          color: Colors.white,
          borderColor: Colors.white,
          baseColor: headerColor, // Add this parameter
        ),
        // Patrimony row
        _buildFinanceRow(
          name: 'Patrimoine',
          value: patrimony,
          color: Colors.white,
          borderColor: Colors.white,
          baseColor: headerColor, // Add this parameter
        ),
      ],
    );
  }

  /// Builds a single row for the finance section
  Widget _buildFinanceRow(
      {required String name,
      required num value,
      required Color color,
      required Color borderColor,
      required Color baseColor}) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        border: Border(
          top: BorderSide(color: borderColor),
        ),
      ),
      margin: EdgeInsets.zero,
      padding:
          EdgeInsets.symmetric(vertical: kPadding / 4, horizontal: kPadding),
      child: Row(
        children: [
          // Name
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.only(left: 0),
              child: GestureDetector(
                onTap: () {
                  final overlay = Overlay.of(context);
                  final renderBox = context.findRenderObject() as RenderBox;
                  final position = renderBox.localToGlobal(Offset.zero);

                  final entry = OverlayEntry(
                    builder: (context) => Positioned(
                      left: position.dx,
                      top: position.dy + renderBox.size.height,
                      child: Material(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          child: Text(
                            name,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  );

                  overlay.insert(entry);
                  Future.delayed(const Duration(seconds: 1), () {
                    entry.remove();
                  });
                },
                child: Tooltip(
                  message: name,
                  preferBelow: true,
                  child: Text(
                    MediaQuery.of(context).size.width >= 1024
                        ? (name.length > 15
                            ? '${name.substring(0, 15)}...'
                            : name)
                        : (name.length > 10
                            ? '${name.substring(0, 10)}.'
                            : name),
                    style: TextStyle(fontWeight: FontWeight.normal),
                  ),
                ),
              ),
            ),
          ),
          // Tracked (editable if not total)
          Expanded(
              flex: 2,
              child: Text(
                _formatNumber(value),
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w500),
              )),
          // Budget (editable if not total)
          Expanded(
            flex: 2,
            child: Text(
              '',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          // % Completion
          Expanded(
            flex: 2,
            child: Text(
              '',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ), // Remaining
          Expanded(
            flex: 2,
            child: Text(
              '',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          )
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
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: (KeyEvent event) {
        debugPrint('Escape key pressed');
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape &&
            _isEditing) {
          _commitEditing();
        }
      },
      child: GestureDetector(
        // Tap anywhere outside the TextField to unfocus and commit the changes
        onTap: () {
          if (_isEditing) {
            _commitEditing();
          }
        },
        child: Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
            side: BorderSide.none,
          ),
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

                const SizedBox(height: 8),

                _buildFinanceSection()
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatNumber(num number) {
    final String numStr = number.toString();
    return numStr.endsWith('.0')
        ? numStr.substring(0, numStr.length - 2).replaceAllMapped(
              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
              (match) => '${match[1]} ',
            )
        : numStr.replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (match) => '${match[1]} ',
          );
  }

  @override
  void dispose() {
    _editingController.dispose();
    _focusNode.dispose();
    BudgetData.dispose(); // dispose by principle, but as it's shared, it does nothing
    super.dispose();
  }
}
