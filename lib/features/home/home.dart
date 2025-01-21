import 'package:flutter/material.dart';
import 'package:finance_manager/features/settings/settings.dart';
import '../dashboard/dashboard.dart';
import '../budget/budget.dart';

class HomePageWithMenu extends StatefulWidget {
  @override
  State<HomePageWithMenu> createState() => _HomePageWithMenuState();
}

class _HomePageWithMenuState extends State<HomePageWithMenu> {
  var selectedIndex = 0;

  @override
  Widget build(BuildContext context) {

    Widget page;
    switch (selectedIndex) {
      case 0:
        page = DashboardPage();
        break;
      case 1:
        page = BudgetPage();
        break;
      case 2:
        page = SettingsPage();
        break;
      default:
        throw UnimplementedError('no widget for $selectedIndex');
    }

    return Theme(
      data: ThemeData(
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.black,
          indicatorColor: Colors.white,
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(color: Colors.white),
          ),
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: page,
        bottomNavigationBar: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: (value) {
            setState(() {
              selectedIndex = value;
            });
          },
          destinations: [
            NavigationDestination(
              icon: Icon(Icons.home, color: selectedIndex == 0 ? Colors.black : Colors.white),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.table_chart, color: selectedIndex == 1 ? Colors.black : Colors.white),
              label: 'Budget', 
            ),
            NavigationDestination(
              icon: Icon(Icons.settings, color: selectedIndex == 2 ? Colors.black : Colors.white),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}