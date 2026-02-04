import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/constants/api_constants.dart';
import '../models/monthly_report_model.dart';

class MonthlyReportRepository {
  /// Lấy báo cáo theo tháng
  /// [month] format: "MM/yyyy" hoặc "yyyy-MM"
  Future<MonthlyReportModel> getMonthlyReport(String month) async {
    try {
      final url = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.monthlyReport}?month=$month',
      );

      final response = await http.get(url, headers: ApiConstants.headers);

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final jsonData = json.decode(decodedBody);

        if (jsonData['success'] == true && jsonData['data'] != null) {
          return MonthlyReportModel.fromJson(jsonData['data']);
        } else {
          throw Exception(jsonData['message'] ?? 'Lỗi không xác định');
        }
      } else {
        throw Exception(
          'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      throw Exception('Lỗi khi tải báo cáo: $e');
    }
  }

  /// Lấy báo cáo cho nhiều tháng
  Future<List<MonthlyReportModel>> getMultipleMonthReports(
    List<String> months,
  ) async {
    final reports = <MonthlyReportModel>[];

    for (final month in months) {
      try {
        final report = await getMonthlyReport(month);
        reports.add(report);
      } catch (e) {
        print('Lỗi khi tải báo cáo tháng $month: $e');
        // Continue với tháng tiếp theo
      }
    }

    return reports;
  }

  /// Kiểm tra API có hoạt động không
  Future<bool> checkApiHealth() async {
    try {
      final currentMonth = _formatCurrentMonth();
      await getMonthlyReport(currentMonth);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Format tháng hiện tại
  String _formatCurrentMonth() {
    final now = DateTime.now();
    return '${now.month.toString().padLeft(2, '0')}/${now.year}';
  }
}
