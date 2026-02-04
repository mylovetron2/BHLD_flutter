import 'package:flutter/foundation.dart';

import '../../data/models/monthly_report_model.dart';
import '../../data/repositories/monthly_report_repository.dart';
import '../../data/services/pdf_export_service.dart';

class MonthlyReportProvider extends ChangeNotifier {
  final MonthlyReportRepository _repository;
  final PdfExportService _pdfService;

  MonthlyReportProvider({
    MonthlyReportRepository? repository,
    PdfExportService? pdfService,
  }) : _repository = repository ?? MonthlyReportRepository(),
       _pdfService = pdfService ?? PdfExportService();

  MonthlyReportModel? _report;
  bool _isLoading = false;
  String? _error;
  String _selectedMonth = '';

  // Getters
  MonthlyReportModel? get report => _report;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get selectedMonth => _selectedMonth;

  /// Load báo cáo theo tháng
  Future<void> loadMonthlyReport(String month) async {
    _isLoading = true;
    _error = null;
    _selectedMonth = month;
    notifyListeners();

    try {
      _report = await _repository.getMonthlyReport(month);
      _error = null;
    } catch (e) {
      _error = e.toString();
      _report = null;
      debugPrint('Error loading monthly report: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Export PDF với action được chỉ định
  Future<void> exportReport(
    ExportAction action, {
    bool summaryOnly = false,
  }) async {
    if (_report == null) {
      _error = 'Chưa có dữ liệu báo cáo để xuất';
      notifyListeners();
      return;
    }

    try {
      if (summaryOnly) {
        await _pdfService.exportReport(
          report: _report!,
          action: action,
          summaryOnly: true,
        );
      } else {
        await _pdfService.exportDetailReport(report: _report!, action: action);
      }
    } catch (e) {
      _error = 'Lỗi khi xuất PDF: $e';
      debugPrint('Error exporting PDF: $e');
      notifyListeners();
      rethrow;
    }
  }

  /// Preview PDF
  Future<void> previewPdf() async {
    await exportReport(ExportAction.preview);
  }

  /// Save PDF
  Future<void> savePdf() async {
    await exportReport(ExportAction.save);
  }

  /// Share PDF
  Future<void> sharePdf() async {
    await exportReport(ExportAction.share);
  }

  /// Print PDF
  Future<void> printPdf() async {
    await exportReport(ExportAction.print);
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Reload current report
  Future<void> reload() async {
    if (_selectedMonth.isNotEmpty) {
      await loadMonthlyReport(_selectedMonth);
    }
  }

  /// Get statistics from current report
  Map<String, dynamic> getStatistics() {
    if (_report == null) return {};

    int totalDepartments = _report!.departments.length;
    int totalEmployees = 0;
    int totalEquipmentAllocated = 0;
    int totalEquipmentRequired = 0;

    for (var dept in _report!.departments) {
      totalEmployees += dept.employees.length;

      for (var emp in dept.employees) {
        for (var equipment in emp.equipmentStatus.values) {
          totalEquipmentAllocated += equipment.received;
          totalEquipmentRequired += equipment.required;
        }
      }
    }

    return {
      'totalDepartments': totalDepartments,
      'totalEmployees': totalEmployees,
      'totalEquipmentAllocated': totalEquipmentAllocated,
      'totalEquipmentRequired': totalEquipmentRequired,
      'completionRate': totalEquipmentRequired > 0
          ? (totalEquipmentAllocated / totalEquipmentRequired * 100)
          : 0.0,
    };
  }
}
