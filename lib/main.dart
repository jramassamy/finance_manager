import 'package:flutter/material.dart';
import 'package:finance_manager/features/budget/data.dart';
import 'package:provider/provider.dart';
import './features/home/home.dart';

void main() async {
    WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize budget data
  await BudgetData.initialize();

  runApp(MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MainAppState(),
      child: MaterialApp(
        title: 'WIP',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        ),
        home: HomePageWithMenu(),
      ),
    );
  }
}

class MainAppState extends ChangeNotifier {
}