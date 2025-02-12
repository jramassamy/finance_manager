import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:finance_manager/features/budget/data.dart';

// Configurable styling variables
const double kHeaderFontSize = 14.0;
const double kMonthFontSize = 12.0;
const double kCellFontSize = 12.0;
const EdgeInsets kHeaderPadding = EdgeInsets.all(2.0);
const EdgeInsets kCellPadding = EdgeInsets.all(4.0);
const double kSectionSpacing = 16.0;
const double kRowSpacing = 0.5;

class BudgetTableSection extends StatefulWidget {
  final String title;
  final Color backgroundColor;
  final List<BudgetItem> items;
  final bool isExpanded;
  final bool allowEditing;
  const BudgetTableSection({
    super.key,
    required this.title,
    required this.backgroundColor,
    required this.items,
    required this.isExpanded,
    required this.allowEditing
  });

  @override
  State<BudgetTableSection> createState() => _BudgetTableSectionState();
}

class _BudgetTableSectionState extends State<BudgetTableSection>
    with SingleTickerProviderStateMixin {
  final TextEditingController _editingController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  bool _isEditing = false;
  int? _editingIndex;
  BudgetItem? _editingItem;
  num _previousValue = 0;
  late bool _isExpanded;
  late AnimationController _animationController;
  late Animation<double> _animation;
  late BudgetItem _totalItem;

  @override
  void initState() {
    super.initState();
    
    _isExpanded = widget.isExpanded;
    _calculateTotals();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    if (_isExpanded) {
      _animationController.value = 1.0;
    }
  }

  void _calculateTotals() {
    final totalMonthly = List<num>.generate(12, (monthIndex) {
      num monthTotal = 0;
      for (final item in widget.items) {
        monthTotal += item.monthly[monthIndex];
      }

      monthTotal = double.parse(monthTotal.toStringAsFixed(2));

      return monthTotal;
    });
    _totalItem = BudgetItem(name: 'Total', monthly: totalMonthly, budget: totalMonthly);
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
        expression = expression.replaceAllMapped(
          RegExp(r'(\d*\.?\d+)[\*\/](\d*\.?\d+)'),
          (match) {
            final num a = num.parse(match[1]!);
            final num b = num.parse(match[2]!);
            if (match[0]!.contains('*')) {
              return (a * b).toString();
            } else {
              return (a / b).toString();
            }
          }
        );
      }

      // Then handle addition and subtraction
      final numbers = expression.split(RegExp(r'[\+\-]'));
      final operators = expression.split(RegExp(r'[0-9\.]+')).where((op) => op.isNotEmpty).toList();
      
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
      return _previousValue;
    }
  }

  void _commitEditing() {
    if (!_isEditing || _editingItem == null || _editingIndex == null || !widget.allowEditing) return;

    if(_editingController.text.trim().isEmpty) {
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

    // Round to 2 decimal places if it's a double
    if (parsed is double) {
      parsed = double.parse(parsed.toStringAsFixed(2));
    }

    setState(() {
      _editingItem!.monthly[_editingIndex!] = parsed;
      _calculateTotals();
      _isEditing = false;
      _editingIndex = null;
      _editingItem = null;
      _previousValue = 0;
      _editingController.clear();
    });

    // Save changes to persistent storage
    BudgetData.saveData();
  }

  void _startEditing(BudgetItem item, int monthIndex) {
    if(!widget.allowEditing) return;
    
    if (_isEditing && (_editingItem != item || _editingIndex != monthIndex)) {
      _commitEditing();
    }

    setState(() {
      _isEditing = true;
      _editingItem = item;
      _editingIndex = monthIndex;
      _previousValue = item.monthly[monthIndex];
      _editingController.text = _previousValue.toString().replaceFirst('.0', '');
      // _editingController.text = '';
    });
  }

  @override
  Widget build(BuildContext context) {
      return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: (KeyEvent event) {
        if (event is KeyDownEvent && 
            event.logicalKey == LogicalKeyboardKey.escape && 
            _isEditing) {
          _commitEditing();
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        InkWell(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
              if (_isExpanded) {
                _animationController.forward();
              } else {
                _animationController.reverse();
              }
            });
          },
          child: Container(
            width: double.infinity,
            color: widget.backgroundColor,
            padding: kHeaderPadding,
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Row(
                    children: [
                      RotationTransition(
                        turns: Tween(begin: 0.0, end: 0.5).animate(_animation),
                        child: const Icon(Icons.expand_more, color: Colors.white),
                      ),
                      Text(
                        widget.title,
                        style: TextStyle(
                          fontSize: kHeaderFontSize,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                ...List.generate(12, (index) => 
                  Expanded(
                    flex: 2,
                    child: Text(
                      months[index],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: kMonthFontSize,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    months.last,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: kMonthFontSize,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizeTransition(
          sizeFactor: _animation,
          axisAlignment: -1,
          child: Column(
            children: [
              for (final item in widget.items) _buildRow(item, isBold: false),
            ],
          ),
        ),
          _buildRow(_totalItem, isBold: true),
        ],
      ),
    );
  }

  Widget _buildRow(BudgetItem item, {required bool isBold}) {
    final backgroundColor =
        isBold ? Colors.white : widget.backgroundColor.withOpacity(0.2);
    num itemYearTotal = item.monthly.fold<num>(0, (sum, m) => sum + m);
    itemYearTotal = double.parse(itemYearTotal.toStringAsFixed(2));
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(bottom: BorderSide(color: Colors.grey[500]!, width: kRowSpacing)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Padding(
              padding: kCellPadding,
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
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Text(
                            item.name,
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
                  message: item.name,
                  preferBelow: true,
                  child: Text(
                    MediaQuery.of(context).size.width >= 1024 
                        ? (item.name.length > 15 ? '${item.name.substring(0, 15)}...' : item.name)
                        : (item.name.length > 10 ? '${item.name.substring(0, 10)}.' : item.name),
                    style: TextStyle(
                      fontSize: kCellFontSize,
                      fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          ),
          ...List.generate(12, (index) {
            final isCellEditing =
                _isEditing && _editingItem == item && _editingIndex == index;

            return Expanded(
              flex: 2,
              child: Container(
                decoration: BoxDecoration(
                  border: Border(left: BorderSide(color: Colors.grey[500]!, width: kRowSpacing)),
                ),
                child: InkWell(
                  onTap: isBold ? null : () => _startEditing(item, index),
                  child: Padding(
                    padding: kCellPadding,
                    child: isCellEditing
                        ? TextField(
                            controller: _editingController,
                            keyboardType: TextInputType.text,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'[0-9\.\,\+\-\*\/\s]')),
                            ],
                            autofocus: true,
                            textAlign: TextAlign.right,
                            style: TextStyle(fontSize: kCellFontSize),
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 6),
                              border: InputBorder.none,
                            ),
                            onSubmitted: (_) => _commitEditing(),
                          )
                        : Text(
                            _formatNumber(double.parse(item.monthly[index].toStringAsFixed(2))),
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: kCellFontSize,
                              fontWeight:
                                  isBold ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                  ),
                ),
              ),
            );
          }),
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                border: Border(left: BorderSide(color: Colors.grey, width: kRowSpacing)),
              ),
              child: Padding(
                padding: kCellPadding,
                child: Text(
                  _formatNumber(double.parse(itemYearTotal.toStringAsFixed(2))),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                      fontSize: kCellFontSize,
                      fontWeight: isBold ? FontWeight.w600 : FontWeight.normal),
                ),
              ),
            ),
          ),
        ],
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
    _animationController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}
