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
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.description_outlined),
            selectedIcon: Icon(Icons.description),
            label: 'Chứng từ',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outlined),
            selectedIcon: Icon(Icons.people),
            label: 'Nhân viên',
          ),
        ],
      ),
    );
  }
}
