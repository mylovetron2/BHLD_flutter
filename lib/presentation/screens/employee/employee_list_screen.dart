import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/employee_provider.dart';
import 'employee_detail_screen.dart';

class EmployeeListScreen extends StatefulWidget {
  const EmployeeListScreen({super.key});

  @override
  State<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends State<EmployeeListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EmployeeProvider>().loadEmployees();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch() {
    context.read<EmployeeProvider>().loadEmployees(
      search: _searchController.text.trim(),
    );
  }

  Future<void> _editEmployeeName(BuildContext context, dynamic employee) async {
    final nameController = TextEditingController(
      text: employee.tennhanvien.isNotEmpty ? employee.tennhanvien : '',
    );

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chỉnh sửa tên nhân viên'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mã NV: ${employee.manv}',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Tên nhân viên',
                hintText: 'Nhập tên nhân viên',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
              textCapitalization: TextCapitalization.words,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context, nameController.text.trim());
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      if (context.mounted) {
        // Show loading
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );

        // Call API to update
        final success = await context
            .read<EmployeeProvider>()
            .updateEmployeeName(employee.manv, result);

        if (context.mounted) {
          // Close loading dialog
          Navigator.pop(context);

          // Show result
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                success
                    ? 'Đã cập nhật tên: $result'
                    : 'Lỗi cập nhật tên nhân viên',
              ),
              backgroundColor: success ? Colors.green : Colors.red,
            ),
          );
        }
      }
    }

    nameController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Danh sách nhân viên')),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm theo mã hoặc tên...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch();
                        },
                      )
                    : null,
              ),
              onSubmitted: (_) => _performSearch(),
              onChanged: (value) => setState(() {}),
            ),
          ),

          // Employee List
          Expanded(
            child: Consumer<EmployeeProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Lỗi: ${provider.error}',
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => provider.loadEmployees(),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  );
                }

                if (provider.employees.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Không tìm thấy nhân viên',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: provider.employees.length,
                  itemBuilder: (context, index) {
                    final employee = provider.employees[index];
                    final displayName = employee.tennhanvien.isNotEmpty
                        ? employee.tennhanvien
                        : 'NV ${employee.manv}';
                    final hasName = employee.tennhanvien.isNotEmpty;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: hasName
                              ? Theme.of(context).colorScheme.primaryContainer
                              : Colors.grey.shade200,
                          child: Text(
                            hasName
                                ? employee.tennhanvien[0].toUpperCase()
                                : employee.manv.substring(0, 1),
                            style: TextStyle(
                              color: hasName
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.grey.shade600,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                displayName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: hasName ? null : Colors.grey.shade600,
                                ),
                              ),
                            ),
                            if (!hasName)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Chưa có tên',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.orange.shade900,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text('Mã NV: ${employee.manv}'),
                            Text(
                              'Phòng ban: ${employee.tenphongban ?? employee.mapb}',
                            ),
                          ],
                        ),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              tooltip: 'Sửa tên',
                              onPressed: () =>
                                  _editEmployeeName(context, employee),
                            ),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                        onTap: () {
                          provider.setSelectedEmployee(employee);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const EmployeeDetailScreen(),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
