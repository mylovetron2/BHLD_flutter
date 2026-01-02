import 'package:flutter/material.dart';

import '../certificate/certificate_unified_screen.dart';
import '../employee/employee_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const CertificateUnifiedScreen(),
    const EmployeeListScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // Ensure selectedIndex is within bounds after hot reload
    if (_selectedIndex >= _screens.length) {
      _selectedIndex = 0;
    }

    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          height: 70,
          backgroundColor: Colors.white,
          indicatorColor: Theme.of(
            context,
          ).colorScheme.primary.withOpacity(0.15),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.description_outlined),
              selectedIcon: Icon(
                Icons.description,
                color: Theme.of(context).colorScheme.primary,
              ),
              label: 'Chứng từ',
            ),
            NavigationDestination(
              icon: const Icon(Icons.people_outlined),
              selectedIcon: Icon(
                Icons.people,
                color: Theme.of(context).colorScheme.primary,
              ),
              label: 'Nhân viên',
            ),
          ],
        ),
      ),
    );
  }
}
