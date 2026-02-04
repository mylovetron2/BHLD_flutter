import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../models/monthly_report_model.dart';

class PdfExportService {
  // Danh sách thiết bị chuẩn theo thứ tự cột
  static const List<String> standardEquipment = [
    'Giày',
    'Mũ',
    'Áo quần',
    'Kính',
    'Áo mưa',
    'Nút tai',
    'Phim',
  ];

  /// Generate PDF từ dữ liệu báo cáo tháng
  Future<pw.Document> generateMonthlyReport(MonthlyReportModel report) async {
    final pdf = pw.Document();

    final theme = pw.ThemeData.withFont(
      base: await PdfGoogleFonts.robotoRegular(),
      bold: await PdfGoogleFonts.robotoBold(),
    );

    // Tạo trang thống kê tổng hợp nếu có
    if (report.summary != null && report.summary!.items.isNotEmpty) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape, // Ngang cho trang thống kê
          theme: theme,
          margin: const pw.EdgeInsets.all(40),
          build: (context) {
            return pw.Center(
              child: pw.Column(
                mainAxisSize: pw.MainAxisSize.min,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  _buildSummaryHeader(report.month),
                  pw.SizedBox(height: 20),
                  _buildSummaryTable(report.summary!),
                ],
              ),
            );
          },
        ),
      );
    }

    // Tạo page cho mỗi phòng ban
    for (var department in report.departments) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape, // Ngang để fit nhiều cột
          theme: theme,
          margin: const pw.EdgeInsets.all(20),
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                _buildHeader(report.month, department.departmentName),
                pw.SizedBox(height: 20),
                // Table
                _buildDepartmentTable(department),
                pw.Spacer(),
                // Footer
                _buildFooter(),
              ],
            );
          },
        ),
      );
    }

    return pdf;
  }

  /// Header cho trang thống kê tổng hợp
  pw.Widget _buildSummaryHeader(String month) {
    return pw.Column(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Text(
              'XN Địa vật lý GK',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Text(
              'THỐNG KÊ CẤP PHÁT BẢO HỘ LAO ĐỘNG',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Text(
              'Tổng hợp vật tư đã nhận tháng $month',
              style: const pw.TextStyle(fontSize: 14),
            ),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Text(
              'Ngày in: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
              style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            ),
          ],
        ),
      ],
    );
  }

  /// Bảng thống kê tổng hợp
  pw.Widget _buildSummaryTable(EquipmentSummaryModel summary) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.center,
      children: [
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey800, width: 0.5),
          columnWidths: {
            0: const pw.FixedColumnWidth(70), // Mã VT
            1: const pw.FixedColumnWidth(200), // Tên vật tư
            2: const pw.FixedColumnWidth(70), // ĐVT
            3: const pw.FixedColumnWidth(80), // Số lượng
            4: const pw.FixedColumnWidth(95), // Ghi chú
          },
          children: [
            // Header row
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey300),
              children: [
                _buildHeaderCell('Mã VT', centered: true),
                _buildHeaderCell('Tên vật tư'),
                _buildHeaderCell('ĐVT', centered: true),
                _buildHeaderCell('Số lượng', centered: true),
                _buildHeaderCell('Ghi chú'),
              ],
            ),
            // Data rows
            ...summary.items.map((item) {
              return pw.TableRow(
                children: [
                  _buildDataCell(item.code, centered: true),
                  _buildDataCell(item.name),
                  _buildDataCell(item.unit, centered: true),
                  _buildDataCell(item.quantity.toString(), centered: true),
                  _buildDataCell(''), // Ghi chú trống
                ],
              );
            }),
            // Total row
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _buildDataCell('', centered: true),
                _buildHeaderCell('Tổng cộng:', centered: false),
                _buildDataCell('', centered: true),
                _buildHeaderCell(
                  summary.totalQuantity.toString(),
                  centered: true,
                ),
                _buildDataCell(''),
              ],
            ),
          ],
        ),
      ],
    );
  }

  /// Header của báo cáo
  pw.Widget _buildHeader(String month, String departmentName) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'BÁO CÁO CHỨNG TỪ ĐÃ NHẬN',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Tháng: $month', style: const pw.TextStyle(fontSize: 14)),
            pw.Text(
              'Phòng ban: $departmentName',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'Ngày in: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
          style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
        ),
      ],
    );
  }

  /// Table cho một phòng ban
  pw.Widget _buildDepartmentTable(DepartmentReportModel department) {
    // Tính tổng số cột
    final totalColumns =
        2 + standardEquipment.length; // STT + Tên + các thiết bị

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey800, width: 0.5),
      columnWidths: {
        0: const pw.FixedColumnWidth(25), // STT - thu nhỏ
        1: const pw.FixedColumnWidth(100), // Tên - thu nhỏ
        // Các cột thiết bị - chia đều phần còn lại
        for (int i = 2; i < totalColumns; i++) i: const pw.FlexColumnWidth(1),
      },
      children: [
        // Header row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            _buildHeaderCell('Danh\nSố', centered: true),
            _buildHeaderCell('Tên'),
            ...standardEquipment.map(
              (eq) => _buildHeaderCell(eq, centered: true),
            ),
          ],
        ),
        // Data rows
        ...department.employees.asMap().entries.map((entry) {
          final index = entry.key + 1;
          final employee = entry.value;

          // Hiển thị tên hoặc mã nhân viên nếu tên null
          final displayName = employee.employeeName.isNotEmpty
              ? employee.employeeName
              : 'NV ${employee.employeeCode}';

          return pw.TableRow(
            children: [
              _buildDataCell(index.toString(), centered: true),
              _buildDataCell(displayName),
              ...standardEquipment.map((equipmentName) {
                final status = employee.equipmentStatus[equipmentName];
                final received = status?.received ?? 0;
                final hasEquipment = received > 0;
                return _buildCheckmarkCell(hasEquipment, received);
              }),
            ],
          );
        }),
      ],
    );
  }

  /// Cell cho header
  pw.Widget _buildHeaderCell(String text, {bool centered = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(4),
      alignment: centered ? pw.Alignment.center : pw.Alignment.centerLeft,
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
        textAlign: centered ? pw.TextAlign.center : pw.TextAlign.left,
      ),
    );
  }

  /// Cell cho dữ liệu
  pw.Widget _buildDataCell(String text, {bool centered = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(3),
      alignment: centered ? pw.Alignment.center : pw.Alignment.centerLeft,
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 9),
        textAlign: centered ? pw.TextAlign.center : pw.TextAlign.left,
      ),
    );
  }

  /// Cell với checkmark (✓) hoặc số lượng
  pw.Widget _buildCheckmarkCell(bool hasEquipment, int count) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(3),
      alignment: pw.Alignment.center,
      child: hasEquipment
          ? pw.Text(
              count > 1 ? count.toString() : '✓',
              style: pw.TextStyle(
                fontSize: count > 1 ? 8 : 10,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.green800,
              ),
            )
          : pw.SizedBox(), // Để trống thay vì hiển thị 0
    );
  }

  /// Footer
  pw.Widget _buildFooter() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(
              'Người lập biểu',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 40),
            pw.Text(
              '(Ký và ghi rõ họ tên)',
              style: const pw.TextStyle(fontSize: 8),
            ),
          ],
        ),
      ],
    );
  }

  /// Lưu PDF vào file
  Future<File> savePdfToFile(pw.Document pdf, String filename) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$filename');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  /// Preview PDF
  Future<void> previewPdf(pw.Document pdf) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  /// Share PDF
  Future<void> sharePdf(pw.Document pdf, String filename) async {
    final file = await savePdfToFile(pdf, filename);
    await Share.shareXFiles([
      XFile(file.path),
    ], subject: 'Báo cáo chứng từ $filename');
  }

  /// Print PDF
  Future<void> printPdf(pw.Document pdf) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  /// Generate PDF chỉ có trang thống kê
  Future<pw.Document> generateSummaryReport(MonthlyReportModel report) async {
    final pdf = pw.Document();

    final theme = pw.ThemeData.withFont(
      base: await PdfGoogleFonts.robotoRegular(),
      bold: await PdfGoogleFonts.robotoBold(),
    );

    if (report.summary != null && report.summary!.items.isNotEmpty) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          theme: theme,
          margin: const pw.EdgeInsets.all(20),
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildSummaryHeader(report.month),
                pw.SizedBox(height: 20),
                _buildSummaryTable(report.summary!),
                pw.Spacer(),
                _buildFooter(),
              ],
            );
          },
        ),
      );
    }

    return pdf;
  }

  /// Generate PDF chỉ có chi tiết phòng ban
  Future<pw.Document> generateDetailReport(MonthlyReportModel report) async {
    final pdf = pw.Document();

    final theme = pw.ThemeData.withFont(
      base: await PdfGoogleFonts.robotoRegular(),
      bold: await PdfGoogleFonts.robotoBold(),
    );

    for (var department in report.departments) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          theme: theme,
          margin: const pw.EdgeInsets.all(20),
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildHeader(report.month, department.departmentName),
                pw.SizedBox(height: 20),
                _buildDepartmentTable(department),
                pw.Spacer(),
                _buildFooter(),
              ],
            );
          },
        ),
      );
    }

    return pdf;
  }

  /// Xuất PDF đầy đủ với tất cả tùy chọn
  Future<void> exportReport({
    required MonthlyReportModel report,
    required ExportAction action,
    bool summaryOnly = false,
  }) async {
    // Generate PDF
    final pdf = summaryOnly
        ? await generateSummaryReport(report)
        : await generateMonthlyReport(report);
    final filename = summaryOnly
        ? 'ThongKe_${report.month.replaceAll('/', '_')}.pdf'
        : 'BaoCao_${report.month.replaceAll('/', '_')}.pdf';

    // Thực hiện action
    switch (action) {
      case ExportAction.save:
        final file = await savePdfToFile(pdf, filename);
        print('Đã lưu file: ${file.path}');
        break;
      case ExportAction.preview:
        await previewPdf(pdf);
        break;
      case ExportAction.share:
        await sharePdf(pdf, filename);
        break;
      case ExportAction.print:
        await printPdf(pdf);
        break;
    }
  }

  /// Xuất PDF chi tiết
  Future<void> exportDetailReport({
    required MonthlyReportModel report,
    required ExportAction action,
  }) async {
    final pdf = await generateDetailReport(report);
    final filename = 'ChiTiet_${report.month.replaceAll('/', '_')}.pdf';

    switch (action) {
      case ExportAction.save:
        final file = await savePdfToFile(pdf, filename);
        print('Đã lưu file: ${file.path}');
        break;
      case ExportAction.preview:
        await previewPdf(pdf);
        break;
      case ExportAction.share:
        await sharePdf(pdf, filename);
        break;
      case ExportAction.print:
        await printPdf(pdf);
        break;
    }
  }
}

/// Enum cho các action export
enum ExportAction {
  save, // Lưu vào device
  preview, // Xem trước và in
  share, // Chia sẻ
  print, // In trực tiếp
}
