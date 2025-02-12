import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:download/download.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';


final List<String> months = [
  'Janvier',
  'Février',
  'Mars',
  'Avril',
  'Mai',
  'Juin',
  'Juillet',
  'Août',
  'Septembre',
  'Octobre',
  'Novembre',
  'Décembre',
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

  static final _dataChangeController = StreamController<void>.broadcast();
  static Stream<void> get onDataChanged => _dataChangeController.stream;
  
  static List<BudgetItem> incomeItems = [];
  static List<BudgetItem> expenseItems = [];
  static List<BudgetItem> savingsItems = [];

  // Example color approximations – feel free to adjust
    static Color kDarkNavy = Color.fromRGBO(30, 43, 76, 1);
    static Color kGreen = Color.fromRGBO(38, 168, 109, 1);
    static Color kPink = Color.fromRGBO(254, 22, 132, 1);
    static Color kBlue = Color.fromRGBO(50, 133, 243, 1);
  
  // Default data with everything set to 1000
  static final List<BudgetItem> _defaultIncomeItems = [
    BudgetItem(name: 'Employment (Net)', monthly: List.filled(12, 0), budget: List.filled(12, 0)),
    BudgetItem(name: 'Side Hustle (Net)', monthly: List.filled(12, 0), budget: List.filled(12, 0)),
    BudgetItem(name: 'Dividends', monthly: List.filled(12, 0), budget: List.filled(12, 0)),
  ];

  static final List<BudgetItem> _defaultExpenseItems = [
    BudgetItem(name: 'Housing', monthly: List.filled(12, 0), budget: List.filled(12, 0)),
    BudgetItem(name: 'Utilities', monthly: List.filled(12, 0), budget: List.filled(12, 0)),
    BudgetItem(name: 'Groceries', monthly: List.filled(12, 0), budget: List.filled(12, 0)),
    BudgetItem(name: 'Transportation', monthly: List.filled(12, 0), budget: List.filled(12, 0)),
    BudgetItem(name: 'Insurances', monthly: List.filled(12, 0), budget: List.filled(12, 0)),
    BudgetItem(name: 'Clothing', monthly: List.filled(12, 0), budget: List.filled(12, 0)),
    BudgetItem(name: 'Body Care & Medicine', monthly: List.filled(12, 0), budget: List.filled(12, 0)),
    BudgetItem(name: 'Media', monthly: List.filled(12, 0), budget: List.filled(12, 0)),
    BudgetItem(name: 'Fun & Vacation', monthly: List.filled(12, 0), budget: List.filled(12, 0)),
  ];

  static final List<BudgetItem> _defaultSavingsItems = [
    BudgetItem(name: 'Safety Net', monthly: List.filled(12, 0), budget: List.filled(12, 0)),
    BudgetItem(name: 'Rebalancing', monthly: List.filled(12, 0), budget: List.filled(12, 0)),
    BudgetItem(name: 'Actions', monthly: List.filled(12, 0), budget: List.filled(12, 0)),
    BudgetItem(name: 'Crypto', monthly: List.filled(12, 0), budget: List.filled(12, 0)),
  ];

  static num remainingTotal = 0;
  static num patrimoineTotal = 0;
  // Getters for computed items
  static List<BudgetItem> get remainingItems => [
        BudgetItem(
          name: 'Monthly Remaining',
          monthly: List.generate(12, (index) {
            return incomeItems.fold(0.0, (sum, item) => sum + item.monthly[index]) -
                   expenseItems.fold(0.0, (sum, item) => sum + item.monthly[index]);
          }),
          budget: List.generate(12, (index) {
            return incomeItems.fold(0.0, (sum, item) => sum + item.budget[index]) -
                   expenseItems.fold(0.0, (sum, item) => sum + item.budget[index]);
          }),
        ),
        // BudgetItem(
        //   name: 'Cumulative Remaining',
        //   monthly: _generateCumulativeList((index) {
        //     return incomeItems.fold(0.0, (sum, item) => sum + item.monthly[index]) -
        //            expenseItems.fold(0.0, (sum, item) => sum + item.monthly[index]);
        //   }, isRemaining: true),
        //   budget: _generateCumulativeList((index) {
        //     return incomeItems.fold(0.0, (sum, item) => sum + item.budget[index]) -
        //            expenseItems.fold(0.0, (sum, item) => sum + item.budget[index]);
        //   }, isRemaining: true),
        // ),
    ];

  static List<BudgetItem> get patrimoineItems => [
        BudgetItem(
          name: 'Monthly Patrimoine',
          monthly: List.generate(12, (index) {
            return incomeItems.fold(0.0, (sum, item) => sum + item.monthly[index]) +
                   savingsItems.fold(0.0, (sum, item) => sum + item.monthly[index]) -
                   expenseItems.fold(0.0, (sum, item) => sum + item.monthly[index]);
          }),
          budget: List.generate(12, (index) {
            return incomeItems.fold(0.0, (sum, item) => sum + item.budget[index]) +
                   savingsItems.fold(0.0, (sum, item) => sum + item.budget[index]) -
                   expenseItems.fold(0.0, (sum, item) => sum + item.budget[index]);
          }),
        ),
        // BudgetItem(
        //   name: 'Cumulative Patrimoine',
        //   monthly: _generateCumulativeList((index) {
        //     return incomeItems.fold(0.0, (sum, item) => sum + item.monthly[index]) +
        //            savingsItems.fold(0.0, (sum, item) => sum + item.monthly[index]) -
        //            expenseItems.fold(0.0, (sum, item) => sum + item.monthly[index]);
        //   }),
        //   budget: _generateCumulativeList((index) {
        //     return incomeItems.fold(0.0, (sum, item) => sum + item.budget[index]) +
        //            savingsItems.fold(0.0, (sum, item) => sum + item.budget[index]) -
        //            expenseItems.fold(0.0, (sum, item) => sum + item.budget[index]);
        //   }),
        // ),
    ];

  static findByName(List<BudgetItem> items, String name) {
    return items.firstWhere((item) => item.name.toLowerCase() == name.toLowerCase());
  }

  static void updateTotal(List<num> list) {
    remainingTotal = 0;  // Reset the total
    for(int i = 0; i < list.length; i++) {
      remainingTotal += list[i];
    }
  }

  static List<num> _generateCumulativeList(num Function(int) calculator, {bool isRemaining = false}) {
    List<num> result = List.filled(12, 0);
    result[0] = calculator(0);  // January is not cumulative
    if(result[0] < 0 && isRemaining) {
      result[0] = 0;
    }
    
    for (int i = 1; i < 12; i++) {
      result[i] = result[i - 1] + calculator(i);
      if(result[i] < 0 && isRemaining) {
        result[i] = 0;
      }
    }
    return result;
  }

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

    // Add this method
  static void notifyDataChanged() {
      _dataChangeController.add(null);
  }

  // I DO NOT WANT TO CLOSE THIS
  static void dispose() {
    // if (!_dataChangeController.isClosed) {
    //   _dataChangeController.close();
    // }
  }
  
}