import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/certificate_provider.dart';
import '../../providers/employee_provider.dart';

class EmployeeDetailScreen extends StatefulWidget {
  const EmployeeDetailScreen({super.key});

  @override
  State<EmployeeDetailScreen> createState() => _EmployeeDetailScreenState();
}

class _EmployeeDetailScreenState extends State<EmployeeDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final employee = context.read<EmployeeProvider>().selectedEmployee;
      if (employee != null) {
        context.read<CertificateProvider>().loadCertificates(
          manv: employee.manv,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EmployeeProvider>(
      builder: (context, employeeProvider, _) {
        final employee = employeeProvider.selectedEmployee;

        if (employee == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Chi tiết nhân viên')),
            body: const Center(
              child: Text('Không tìm thấy thông tin nhân viên'),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Chi tiết nhân viên')),
          body: Column(
            children: [
              // Employee Info Card
              Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.primaryContainer,
                        child: Text(
                          employee.tennhanvien.isNotEmpty
                              ? employee.tennhanvien[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            fontSize: 32,
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        employee.tennhanvien,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _InfoRow(
                        icon: Icons.badge,
                        label: 'Mã NV',
                        value: employee.manv,
                      ),
                      _InfoRow(
                        icon: Icons.business,
                        label: 'Phòng ban',
                        value: employee.tenphongban ?? employee.mapb,
                      ),
                    ],
                  ),
                ),
              ),

              // Certificates Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Chứng từ cấp phát',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        // TODO: Create new certificate
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Tạo mới'),
                    ),
                  ],
                ),
              ),

              // Certificates List
              Expanded(
                child: Consumer<CertificateProvider>(
                  builder: (context, certProvider, _) {
                    if (certProvider.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (certProvider.certificates.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.description_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Chưa có chứng từ nào',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: certProvider.certificates.length,
                      itemBuilder: (context, index) {
                        final cert = certProvider.certificates[index];
                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.description),
                            title: Text(cert.mact),
                            subtitle: Text('Ngày: ${cert.displayDate}'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              // TODO: View certificate details
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
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text('$label: ', style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
