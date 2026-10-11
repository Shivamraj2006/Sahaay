import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class ApiException implements Exception {
  final String code;
  final String message;
  final String? requestId;
  final int statusCode;

  ApiException({
    required this.code,
    required this.message,
    this.requestId,
    required this.statusCode,
  });

  @override
  String toString() => 'ApiException [$code] ($statusCode): $message';
}

class ApiClient {
  String? _authToken;

  void setAuthToken(String? token) {
    _authToken = token;
  }

  Map<String, String> _buildHeaders() {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  Future<dynamic> get(String endpoint) async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}$endpoint');
    try {
      final response = await http
          .get(url, headers: _buildHeaders())
          .timeout(const Duration(seconds: AppConfig.apiTimeoutSeconds));
      return _handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> post(String endpoint, {Map<String, dynamic>? body}) async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}$endpoint');
    try {
      final response = await http
          .post(
            url,
            headers: _buildHeaders(),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: AppConfig.apiTimeoutSeconds));
      return _handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> patch(String endpoint, {Map<String, dynamic>? body}) async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}$endpoint');
    try {
      final response = await http
          .patch(
            url,
            headers: _buildHeaders(),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: AppConfig.apiTimeoutSeconds));
      return _handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  dynamic _handleResponse(http.Response response) {
    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      decoded = {'message': response.body};
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    // Standard error envelope from Sahaay backend
    if (decoded is Map<String, dynamic> && decoded.containsKey('error')) {
      final err = decoded['error'];
      throw ApiException(
        code: err['code'] ?? 'UNKNOWN_ERROR',
        message: err['message'] ?? 'An error occurred',
        requestId: err['requestId'],
        statusCode: response.statusCode,
      );
    }

    throw ApiException(
      code: 'HTTP_${response.statusCode}',
      message: decoded['message'] ?? 'Unexpected server response',
      statusCode: response.statusCode,
    );
  }
}

final apiClient = ApiClient();
