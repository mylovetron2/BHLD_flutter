import '../../core/constants/api_constants.dart';
import '../models/allocation_history_model.dart';
import '../models/certificate_detail_model.dart';
import '../models/certificate_model.dart';
import '../models/employee_model.dart';
import '../models/equipment_model.dart';
import '../services/api_service.dart';

class BhldRepository {
  final ApiService _apiService = ApiService();

  // ===== EMPLOYEE =====
  Future<List<EmployeeModel>> getEmployees({String? search}) async {
    try {
      final params = search != null && search.isNotEmpty
          ? {'search': search}
          : null;

      final response = await _apiService.get(
        ApiConstants.employees,
        params: params,
      );

      if (response['success'] == true && response['data'] != null) {
        return (response['data'] as List)
            .map((json) => EmployeeModel.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('Lỗi tải danh sách nhân viên: $e');
    }
  }

  Future<EmployeeModel?> getEmployeeByCode(String manv) async {
    try {
      final response = await _apiService.get(
        '${ApiConstants.employees}?manv=$manv',
      );

      if (response['success'] == true && response['data'] != null) {
        return EmployeeModel.fromJson(response['data']);
      }
      return null;
    } catch (e) {
      throw Exception('Lỗi tải thông tin nhân viên: $e');
    }
  }

  // ===== CERTIFICATE =====
  Future<List<CertificateModel>> getCertificates({
    String? manv,
    String? fromDate,
    String? toDate,
  }) async {
    try {
      final params = <String, String>{};
      if (manv != null && manv.isNotEmpty) params['manv'] = manv;
      if (fromDate != null && fromDate.isNotEmpty) {
        params['from_date'] = fromDate;
      }
      if (toDate != null && toDate.isNotEmpty) params['to_date'] = toDate;

      final response = await _apiService.get(
        ApiConstants.certificates,
        params: params.isNotEmpty ? params : null,
      );

      if (response['success'] == true && response['data'] != null) {
        return (response['data'] as List)
            .map((json) => CertificateModel.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('Lỗi tải danh sách chứng từ: $e');
    }
  }

  Future<CertificateModel?> getCertificateByCode(String mact) async {
    try {
      final response = await _apiService.get(
        '${ApiConstants.certificates}?mact=$mact',
      );

      if (response['success'] == true && response['data'] != null) {
        return CertificateModel.fromJson(response['data']);
      }
      return null;
    } catch (e) {
      throw Exception('Lỗi tải thông tin chứng từ: $e');
    }
  }

  Future<bool> createCertificate(CertificateModel certificate) async {
    try {
      final response = await _apiService.post(
        ApiConstants.certificates,
        body: certificate.toJson(),
      );

      return response['success'] == true;
    } catch (e) {
      throw Exception('Lỗi tạo chứng từ: $e');
    }
  }

  // ===== CERTIFICATE DETAIL =====
  Future<List<CertificateDetailModel>> getCertificateDetails(
    String mact,
  ) async {
    try {
      final response = await _apiService.get(
        '${ApiConstants.certificateDetails}?mact=$mact',
      );

      if (response['success'] == true && response['data'] != null) {
        return (response['data'] as List)
            .map((json) => CertificateDetailModel.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('Lỗi tải chi tiết chứng từ: $e');
    }
  }

  // ===== EQUIPMENT =====
  Future<List<EquipmentModel>> getEquipment({String? search}) async {
    try {
      final params = search != null && search.isNotEmpty
          ? {'search': search}
          : null;

      final response = await _apiService.get(
        ApiConstants.equipment,
        params: params,
      );

      if (response['success'] == true && response['data'] != null) {
        return (response['data'] as List)
            .map((json) => EquipmentModel.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('Lỗi tải danh sách thiết bị: $e');
    }
  }

  // ===== ALLOCATION =====
  Future<Map<String, dynamic>> allocateEquipment({
    required String mact,
    required int mavt,
    required String ngnhan,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConstants.allocate,
        body: {'mact': mact, 'mavt': mavt, 'ngnhan': ngnhan},
      );

      return {
        'success': response['success'] == true,
        'message': response['message'] ?? '',
        'data': response['data'],
      };
    } catch (e) {
      throw Exception('Lỗi cấp phát thiết bị: $e');
    }
  }

  Future<Map<String, dynamic>> deallocateEquipment({
    required String mact,
    required int mavt,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConstants.deallocate,
        body: {'mact': mact, 'mavt': mavt},
      );

      return {
        'success': response['success'] == true,
        'message': response['message'] ?? '',
      };
    } catch (e) {
      throw Exception('Lỗi trả thiết bị: $e');
    }
  }

  // ===== ALLOCATION HISTORY =====
  Future<List<AllocationHistoryModel>> getAllocationHistory({
    String? manv,
    int? mavt,
    String? fromDate,
    String? toDate,
    String? status,
  }) async {
    try {
      final params = <String, String>{};
      if (manv != null && manv.isNotEmpty) params['manv'] = manv;
      if (mavt != null && mavt > 0) params['mavt'] = mavt.toString();
      if (fromDate != null && fromDate.isNotEmpty) {
        params['from_date'] = fromDate;
      }
      if (toDate != null && toDate.isNotEmpty) params['to_date'] = toDate;
      if (status != null && status.isNotEmpty) params['status'] = status;

      final response = await _apiService.get(
        ApiConstants.allocationHistory,
        params: params.isNotEmpty ? params : null,
      );

      if (response['success'] == true && response['data'] != null) {
        return (response['data'] as List)
            .map((json) => AllocationHistoryModel.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('Lỗi tải lịch sử cấp phát: $e');
    }
  }
}
