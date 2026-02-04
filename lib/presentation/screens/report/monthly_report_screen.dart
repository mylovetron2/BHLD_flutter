import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../data/models/monthly_report_model.dart';
import '../../../data/services/pdf_export_service.dart';
import '../../providers/monthly_report_provider.dart';

class MonthlyReportScreen extends StatefulWidget {
  const MonthlyReportScreen({super.key});

  @override
  State<MonthlyReportScreen> createState() => _MonthlyReportScreenState();
}

class _MonthlyReportScreenState extends State<MonthlyReportScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReport();
    });
  }

  void _loadReport() {
    final month = DateFormat('MM/yyyy').format(_selectedDate);
    context.read<MonthlyReportProvider>().loadMonthlyReport(month);
  }

  Future<void> _selectMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
      helpText: 'Chọn tháng báo cáo',
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
      _loadReport();
    }
  }

  Future<void> _exportSummaryPdf(ExportAction action) async {
    final provider = context.read<MonthlyReportProvider>();

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Đang tạo PDF thống kê...'),
                ],
              ),
            ),
          ),
        ),
      );

      await provider.exportReport(action, summaryOnly: true);

      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã tạo PDF thống kê'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _exportDetailPdf(ExportAction action) async {
    final provider = context.read<MonthlyReportProvider>();

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Đang tạo PDF chi tiết...'),
                ],
              ),
            ),
          ),
        ),
      );

      await provider.exportReport(action);

      if (mounted) Navigator.pop(context); // Close loading dialog

      if (mounted) {
        String message = '';
        switch (action) {
          case ExportAction.save:
            message = 'Đã lưu PDF thành công';
            break;
          case ExportAction.share:
            message = 'Đã chia sẻ PDF';
            break;
          case ExportAction.print:
            message = 'Đang chuẩn bị in...';
            break;
          default:
            message = 'Hoàn thành';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade700, Colors.blue.shade900],
            ),
          ),
        ),
        title: const Text('Báo cáo theo tháng'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReport,
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: Column(
        children: [
          // Month Selector
          _buildMonthSelector(),
          // Statistics Card
          _buildStatisticsCard(),
          // Report Content
          Expanded(child: _buildReportContent()),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: 'summary_fab',
            onPressed: () => _exportSummaryPdf(ExportAction.preview),
            backgroundColor: Colors.orange,
            icon: const Icon(Icons.bar_chart),
            label: const Text('Thống kê'),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'detail_fab',
            onPressed: () => _exportDetailPdf(ExportAction.preview),
            icon: const Icon(Icons.list_alt),
            label: const Text('Chi tiết'),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.blue.shade50,
      child: InkWell(
        onTap: _selectMonth,
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: Colors.blue.shade700, size: 20),
            const SizedBox(width: 8),
            Text(
              'Tháng: ${DateFormat('MM/yyyy').format(_selectedDate)}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsCard() {
    return Consumer<MonthlyReportProvider>(
      builder: (context, provider, child) {
        if (provider.report == null) return const SizedBox();

        final stats = provider.getStatistics();
        final completionRate = stats['completionRate'] as double;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.grey.shade100,
          child: Row(
            children: [
              _buildCompactStat(
                Icons.business,
                '${stats['totalDepartments']} PB',
                Colors.blue,
              ),
              const SizedBox(width: 12),
              _buildCompactStat(
                Icons.people,
                '${stats['totalEmployees']} NV',
                Colors.green,
              ),
              const SizedBox(width: 12),
              _buildCompactStat(
                Icons.check_circle,
                '${stats['totalEquipmentAllocated']}',
                Colors.orange,
              ),
              const Spacer(),
              Text(
                '${completionRate.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: completionRate >= 80 ? Colors.green : Colors.orange,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCompactStat(IconData icon, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildReportContent() {
    return Consumer<MonthlyReportProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Lỗi khi tải báo cáo',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    provider.error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _loadReport,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
          );
        }

        if (provider.report == null || provider.report!.departments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.description_outlined,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'Chưa có dữ liệu',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        // Show report as table with sticky header
        return Stack(
          children: [
            // Main content with padding for header
            Padding(
              padding: const EdgeInsets.only(
                top: 40,
              ), // Space for sticky header
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: _buildReportTable(provider.report!),
                ),
              ),
            ),
            // Sticky header
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.grey.shade200,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildStickyHeaderCell('STT', width: 40),
                      _buildStickyHeaderCell('Tên', width: 150),
                      _buildStickyHeaderCell('Giày', width: 50),
                      _buildStickyHeaderCell('Mũ', width: 50),
                      _buildStickyHeaderCell('Áo quần', width: 70),
                      _buildStickyHeaderCell('Kính', width: 50),
                      _buildStickyHeaderCell('Áo mưa', width: 70),
                      _buildStickyHeaderCell('Nút tai', width: 60),
                      _buildStickyHeaderCell('Phim', width: 50),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStickyHeaderCell(String text, {required double width}) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        border: Border.all(color: Colors.grey.shade400, width: 1),
      ),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        textAlign: TextAlign.center,
      ),
    );
  }

  // Danh sách thiết bị chuẩn
  static const List<String> _standardEquipment = [
    'Giày',
    'Mũ',
    'Áo quần',
    'Kính',
    'Áo mưa',
    'Nút tai',
    'Phim',
  ];

  Widget _buildReportTable(MonthlyReportModel report) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: report.departments.map((department) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Department header
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.blue.shade700,
              child: Text(
                department.departmentName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            // Table (without header, using sticky header above)
            Table(
              border: TableBorder.all(color: Colors.grey.shade400, width: 1),
              columnWidths: const {
                0: FixedColumnWidth(40), // STT
                1: FixedColumnWidth(150), // Tên
                2: FixedColumnWidth(50), // Giày
                3: FixedColumnWidth(50), // Mũ
                4: FixedColumnWidth(70), // Quần áo
                5: FixedColumnWidth(50), // Kính
                6: FixedColumnWidth(70), // Áo mưa
                7: FixedColumnWidth(60), // Nút tai
                8: FixedColumnWidth(50), // Phim
                9: FixedColumnWidth(70), // Kỳ nhận
              },
              children: [
                // Data rows only
                ...department.employees.asMap().entries.map((entry) {
                  final index = entry.key + 1;
                  final employee = entry.value;
                  final displayName = employee.employeeName.isNotEmpty
                      ? employee.employeeName
                      : 'NV ${employee.employeeCode}';

                  return TableRow(
                    children: [
                      _buildTableDataCell(index.toString(), centered: true),
                      _buildTableDataCell(displayName),
                      ..._standardEquipment.map((equipName) {
                        final status = employee.equipmentStatus[equipName];
                        final received = status?.received ?? 0;
                        return _buildTableCheckCell(received);
                      }),
                    ],
                  );
                }),
              ],
            ),
            const SizedBox(height: 16),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildTableHeaderCell(String text) {
    return Container(
      padding: const EdgeInsets.all(8),
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTableDataCell(String text, {bool centered = false}) {
    return Container(
      padding: const EdgeInsets.all(6),
      alignment: centered ? Alignment.center : Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(fontSize: 11),
        textAlign: centered ? TextAlign.center : TextAlign.left,
      ),
    );
  }

  Widget _buildTableCheckCell(int received) {
    return Container(
      padding: const EdgeInsets.all(6),
      alignment: Alignment.center,
      child: received > 0
          ? Text(
              received > 1 ? received.toString() : '✓',
              style: TextStyle(
                fontSize: received > 1 ? 11 : 16,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            )
          : const SizedBox(),
    );
  }
}
