import 'package:flutter/material.dart';
import 'package:finance_manager/features/budget/data.dart';
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _selectedCategory = 'Income'; // Default category

  Future<void> _downloadData(BuildContext context) async {
    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 16),
            Text('Downloading data...'),
          ],
        ),
        duration: Duration(seconds: 1),
      ),
    );

    // Attempt download
    final success = await BudgetData.downloadData();

    if (context.mounted) {
      // Clear the loading snackbar
      ScaffoldMessenger.of(context).clearSnackBars();
      
      // Show success/error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Data downloaded successfully' : 'Failed to download data',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _uploadAndSaveData() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();
      
      if (result != null) {
        final file = File(result.files.single.path!);
        final jsonString = await file.readAsString();
        final jsonData = jsonDecode(jsonString);

        // Validate data structure
        if (!_validateJsonStructure(jsonData)) {
          throw Exception('Invalid file structure');
        }

        // Parse and validate items
        final List<BudgetItem> newIncomeItems = _parseAndValidateItems(jsonData['incomeItems']);
        final List<BudgetItem> newExpenseItems = _parseAndValidateItems(jsonData['expenseItems']);
        final List<BudgetItem> newSavingsItems = _parseAndValidateItems(jsonData['savingsItems']);

        // If we got here, validation passed - update data
        setState(() {
          BudgetData.incomeItems = newIncomeItems;
          BudgetData.expenseItems = newExpenseItems;
          BudgetData.savingsItems = newSavingsItems;
        });

        // Save to persistent storage
        await BudgetData.saveData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data imported and saved successfully')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to import data: ${e.toString()}')),
        );
      }
    }
  }

  bool _validateJsonStructure(Map<String, dynamic> json) {
    return json.containsKey('incomeItems') && 
           json.containsKey('expenseItems') && 
           json.containsKey('savingsItems') &&
           json['incomeItems'] is List &&
           json['expenseItems'] is List &&
           json['savingsItems'] is List;
  }

  List<BudgetItem> _parseAndValidateItems(List<dynamic> items) {
    return items.map((item) {
      // Verify each item has required fields
      if (!item.containsKey('name') || 
          !item.containsKey('monthly') || 
          !item.containsKey('budget')) {
        throw Exception('Invalid item structure');
      }

      // Verify lists have correct length and numeric values
      if (item['monthly'] is! List || 
          item['monthly'].length != 12 ||
          item['budget'] is! List || 
          item['budget'].length != 12) {
        throw Exception('Invalid monthly/budget data');
      }

      // Create and return BudgetItem
      return BudgetItem.fromJson(item);
    }).toList();
  }

  void _saveNewBudgetItem() {
    if (_formKey.currentState!.validate()) {
      final newItem = BudgetItem(
        name: _nameController.text,
        monthly: List.filled(12, 0), // Default all months to 0
        budget: List.filled(12, 0), // Default all budgets to 0
      );

      setState(() {
        switch (_selectedCategory) {
          case 'Income':
            BudgetData.incomeItems.add(newItem);
            break;
          case 'Expenses':
            BudgetData.expenseItems.add(newItem);
            break;
          case 'Savings':
            BudgetData.savingsItems.add(newItem);
            break;
        }
      });

      // Save to persistent storage
      BudgetData.saveData();

      // Reset form
      _nameController.clear();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Budget item added successfully')),
      );
    }
  }

  void _deleteBudgetItem(BudgetItem item, String category) {
    setState(() {
      switch (category) {
        case 'Income':
          BudgetData.incomeItems.remove(item);
          break;
        case 'Expenses':
          BudgetData.expenseItems.remove(item);
          break;
        case 'Savings':
          BudgetData.savingsItems.remove(item);
          break;
      }
    });
    BudgetData.saveData();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Budget item deleted')),
    );
  }

  void _editBudgetItem(BudgetItem item, String category, String newName) {
    setState(() {
      item.name = newName;
    });
    BudgetData.saveData();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Budget item updated')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Container(),
        leadingWidth: 0,
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            IconButton(
              icon: const Icon(Icons.file_download),
              onPressed: () => _downloadData(context),
              tooltip: 'Export Data',
            ),
            IconButton(
              icon: const Icon(Icons.file_upload), 
              onPressed: _uploadAndSaveData,
              tooltip: 'Import Data',
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Add New Item Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Add New Budget Item',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Item Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter an item name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(),
                        ),
                        items: ['Income', 'Expenses', 'Savings']
                            .map((String category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedCategory = newValue!;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: _saveNewBudgetItem,
                          icon: const Icon(Icons.save),
                          label: const Text('Save Budget Item'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Existing Items List
            const Text(
              'Manage Existing Items',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Income Items
            _buildCategorySection('Income', BudgetData.incomeItems),
            
            // Expense Items
            _buildCategorySection('Expenses', BudgetData.expenseItems),
            
            // Savings Items
            _buildCategorySection('Savings', BudgetData.savingsItems),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection(String category, List<BudgetItem> items) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        title: Text(category),
        children: items.map((item) => _buildItemTile(item, category)).toList(),
      ),
    );
  }

  Widget _buildItemTile(BudgetItem item, String category) {
    final TextEditingController editController = TextEditingController(text: item.name);
    bool isEditing = false;
    
    return StatefulBuilder(
      builder: (context, setState) {
        return ListTile(
          leading: IconButton(
            icon: Icon(
              isEditing ? Icons.check : Icons.edit,
              color: Colors.grey,
            ),
            onPressed: () {
              if (isEditing) {
                if (editController.text.isNotEmpty) {
                  _editBudgetItem(item, category, editController.text);
                }
              }
              setState(() {
                isEditing = !isEditing;
              });
            },
          ),
          title: isEditing
            ? TextFormField(
                controller: editController,
                autofocus: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                onFieldSubmitted: (newValue) {
                  if (newValue.isNotEmpty) {
                    _editBudgetItem(item, category, newValue);
                    setState(() {
                      isEditing = false;
                    });
                  }
                },
              )
            : Text(item.name),
          trailing: IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Item'),
                  content: Text('Are you sure you want to delete "${item.name}"?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _deleteBudgetItem(item, category);
                      },
                      child: const Text('Delete', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      }
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}
