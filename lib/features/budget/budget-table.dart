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

  const BudgetTableSection({
    super.key,
    required this.title,
    required this.backgroundColor,
    required this.items,
    required this.isExpanded,
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
  String? _originalValue;

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
      return monthTotal;
    });
    _totalItem = BudgetItem(name: 'Total', monthly: totalMonthly, budget: totalMonthly);
  }

  void _commitEditing() {
    if (!_isEditing || _editingItem == null || _editingIndex == null) return;

    if(_editingController.text.trim().isEmpty) {
      _editingController.text = _originalValue!;
    }

    final newValue = _editingController.text.trim();
    num parsed = num.tryParse(newValue) ?? 0;

    if (parsed is double) {
      parsed = double.parse(parsed.toStringAsFixed(2));
    }

    setState(() {
      _editingItem!.monthly[_editingIndex!] = parsed;
      _calculateTotals();
      _isEditing = false;
      _editingIndex = null;
      _editingItem = null;
      _originalValue = null;
      _editingController.clear();
    });

    // Save changes to persistent storage
    BudgetData.saveData();
  }

  void _startEditing(BudgetItem item, int monthIndex) {
    if (_isEditing && (_editingItem != item || _editingIndex != monthIndex)) {
      _commitEditing();
    }

    setState(() {
      _isEditing = true;
      _editingItem = item;
      _editingIndex = monthIndex;
      _originalValue = item.monthly[monthIndex].toString();
      _editingController.text = '';
      // _editingController.text = _originalValue!;
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
    final itemYearTotal = item.monthly.fold<num>(0, (sum, m) => sum + m);

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
              child: Text(
                item.name,
                style: TextStyle(
                    fontSize: kCellFontSize,
                    fontWeight: isBold ? FontWeight.w600 : FontWeight.normal),
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
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
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
                            _formatNumber(item.monthly[index].toDouble()),
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
                  _formatNumber(itemYearTotal.toDouble()),
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
