import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/constants/api_constants.dart';

class ApiService {
  // GET request
  Future<dynamic> get(String endpoint, {Map<String, String>? params}) async {
    try {
      var uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
      if (params != null && params.isNotEmpty) {
        uri = uri.replace(queryParameters: params);
      }

      final response = await http
          .get(uri, headers: ApiConstants.headers)
          .timeout(const Duration(seconds: 30));

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Lỗi kết nối: $e');
    }
  }

  // POST request
  Future<dynamic> post(String endpoint, {Map<String, dynamic>? body}) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConstants.baseUrl}$endpoint'),
            headers: ApiConstants.headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 30));

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Lỗi kết nối: $e');
    }
  }

  // PUT request
  Future<dynamic> put(String endpoint, {Map<String, dynamic>? body}) async {
    try {
      final response = await http
          .put(
            Uri.parse('${ApiConstants.baseUrl}$endpoint'),
            headers: ApiConstants.headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 30));

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Lỗi kết nối: $e');
    }
  }

  // DELETE request
  Future<dynamic> delete(String endpoint) async {
    try {
      final response = await http
          .delete(
            Uri.parse('${ApiConstants.baseUrl}$endpoint'),
            headers: ApiConstants.headers,
          )
          .timeout(const Duration(seconds: 30));

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Lỗi kết nối: $e');
    }
  }

  // Handle response
  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else if (response.statusCode == 404) {
      throw Exception('Không tìm thấy dữ liệu');
    } else if (response.statusCode == 500) {
      throw Exception('Lỗi máy chủ');
    } else {
      throw Exception('Lỗi: ${response.statusCode}');
    }
  }
}
