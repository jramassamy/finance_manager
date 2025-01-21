import 'dart:convert';
import 'dart:io';
import 'package:download/download.dart';
import 'package:path_provider/path_provider.dart';


final List<String> months = [
  'janv',
  'févr',
  'mars',
  'avr',
  'mai',
  'juin',
  'juil',
  'août',
  'sept',
  'oct',
  'nov',
  'déc',
  '2025'
];

class BudgetItem {
  String name;
  final List<num> monthly;
  final List<num> budget;  // New field for budget values

  BudgetItem({
    required this.name, 
    required this.monthly,
    required this.budget,  // Optional budget parameter
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'monthly': monthly,
        'budget': budget,  // Add budget to JSON
      };

  factory BudgetItem.fromJson(Map<String, dynamic> json) {
    return BudgetItem(
      name: json['name'],
      monthly: List<num>.from(json['monthly']),
      budget: json['budget'] != null 
          ? List<num>.from(json['budget'])
          : List<num>.from(json['monthly']),  // Fallback for older data
    );
  }
}

class BudgetData {
  static const String fileName = 'budget_data.json';
  static const String downloadFileName = 'budget_data_export.json';

  static List<BudgetItem> incomeItems = [];
  static List<BudgetItem> expenseItems = [];
  static List<BudgetItem> savingsItems = [];


  // Default data with everything set to 1000
  static final List<BudgetItem> _defaultIncomeItems = [
    BudgetItem(name: 'Employment (Net)', monthly: List.filled(12, 1000), budget: List.filled(12, 1000)),
    BudgetItem(name: 'Side Hustle (Net)', monthly: List.filled(12, 1000), budget: List.filled(12, 1000)),
    BudgetItem(name: 'Dividends', monthly: List.filled(12, 1000), budget: List.filled(12, 1000)),
  ];

  static final List<BudgetItem> _defaultExpenseItems = [
    BudgetItem(name: 'Housing', monthly: List.filled(12, 1000), budget: List.filled(12, 1000)),
    BudgetItem(name: 'Utilities', monthly: List.filled(12, 1000), budget: List.filled(12, 1000)),
    BudgetItem(name: 'Groceries', monthly: List.filled(12, 1000), budget: List.filled(12, 1000)),
    BudgetItem(name: 'Transportation', monthly: List.filled(12, 1000), budget: List.filled(12, 1000)),
    BudgetItem(name: 'Insurances', monthly: List.filled(12, 1000), budget: List.filled(12, 1000)),
    BudgetItem(name: 'Clothing', monthly: List.filled(12, 1000), budget: List.filled(12, 1000)),
    BudgetItem(name: 'Body Care & Medicine', monthly: List.filled(12, 1000), budget: List.filled(12, 1000)),
    BudgetItem(name: 'Media', monthly: List.filled(12, 1000), budget: List.filled(12, 1000)),
    BudgetItem(name: 'Fun & Vacation', monthly: List.filled(12, 1000), budget: List.filled(12, 1000)),
  ];

  static final List<BudgetItem> _defaultSavingsItems = [
    BudgetItem(name: 'Safety Net', monthly: List.filled(12, 1000), budget: List.filled(12, 1000)),
    BudgetItem(name: 'Rebalancing', monthly: List.filled(12, 1000), budget: List.filled(12, 1000)),
    BudgetItem(name: 'Actions', monthly: List.filled(12, 1000), budget: List.filled(12, 1000)),
    BudgetItem(name: 'Crypto', monthly: List.filled(12, 1000), budget: List.filled(12, 1000)),
  ];

  // Getters for computed items
  static List<BudgetItem> get remainingItems => [
        BudgetItem(
          name: 'Remaining',
          monthly: List.generate(12, (index) {
            num incomeTotal =
                incomeItems.fold(0, (sum, item) => sum + item.monthly[index]);
            num expenseTotal =
                expenseItems.fold(0, (sum, item) => sum + item.monthly[index]);
            return incomeTotal - expenseTotal;
          }),
          budget: List.generate(12, (index) {
            num incomeBudget =
                incomeItems.fold(0, (sum, item) => sum + item.budget[index]);
            num expenseBudget =
                expenseItems.fold(0, (sum, item) => sum + item.budget[index]);
            return incomeBudget - expenseBudget;
          }),
        ),
      ];

  static List<BudgetItem> get patrimoineItems => [
        BudgetItem(
          name: 'Patrimoine',
          monthly: List.generate(12, (index) {
            num incomeTotal =
                incomeItems.fold(0, (sum, item) => sum + item.monthly[index]);
            num savingsTotal =
                savingsItems.fold(0, (sum, item) => sum + item.monthly[index]);
            num expenseTotal =
                expenseItems.fold(0, (sum, item) => sum + item.monthly[index]);
            return incomeTotal + savingsTotal - expenseTotal;
          }),
          budget: List.generate(12, (index) {
            num incomeBudget =
                incomeItems.fold(0, (sum, item) => sum + item.budget[index]);
            num savingsBudget =
                savingsItems.fold(0, (sum, item) => sum + item.budget[index]);
            num expenseBudget =
                expenseItems.fold(0, (sum, item) => sum + item.budget[index]);
            return incomeBudget + savingsBudget - expenseBudget;
          }),
        ),
      ];

  // JSON serialization
  static Map<String, dynamic> toJson() => {
        'incomeItems': incomeItems.map((item) => item.toJson()).toList(),
        'expenseItems': expenseItems.map((item) => item.toJson()).toList(),
        'savingsItems': savingsItems.map((item) => item.toJson()).toList(),
      };

  static void fromJson(Map<String, dynamic> json) {
    incomeItems = (json['incomeItems'] as List)
        .map((item) => BudgetItem.fromJson(item))
        .toList();
    expenseItems = (json['expenseItems'] as List)
        .map((item) => BudgetItem.fromJson(item))
        .toList();
    savingsItems = (json['savingsItems'] as List)
        .map((item) => BudgetItem.fromJson(item))
        .toList();
  }

  // File operations
  static Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  static Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/$fileName');
  }

  static Future<File> get _downloadFile async {
    final directory = await getDownloadsDirectory();
    return File('${directory?.path}/$downloadFileName');
  }

  // Initialize data
  static Future<void> initialize() async {
    try {
      final file = await _localFile;
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final jsonData = json.decode(jsonString);
        fromJson(jsonData);
      } else {
        // Set default values if file doesn't exist
        incomeItems = _defaultIncomeItems;
        expenseItems = _defaultExpenseItems;
        savingsItems = _defaultSavingsItems;
        // Save the default data
        await saveData();
      }
    } catch (e) {
      // Fallback to defaults if there's any error
      incomeItems = _defaultIncomeItems;
      expenseItems = _defaultExpenseItems;
      savingsItems = _defaultSavingsItems;
    }
  }

  // Save data
  static Future<void> saveData() async {
    final file = await _localFile;
    final jsonData = json.encode(toJson());
    await file.writeAsString(jsonData);
  }

  // Download data
  static Future<bool> downloadData() async {
    try {
      final jsonData = json.encode(toJson());
      final stream = Stream.fromIterable(jsonData.codeUnits);
      await download(stream, 'budget_data_export.json');
      
      return true;
    } catch (e) {
      print('Error downloading data: $e');
      return false;
    }
  }
}