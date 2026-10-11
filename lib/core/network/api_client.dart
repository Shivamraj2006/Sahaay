import 'package:dio/dio.dart';
import '../storage/secure_storage_service.dart';
import 'api_exception.dart';
import 'app_config.dart';

class ApiClient {
  late final Dio _dio;
  final SecureStorageService _storageService;
  void Function()? onSessionExpired;

  ApiClient({
    required SecureStorageService storageService,
    this.onSessionExpired,
  }) : _storageService = storageService {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: AppConfig.connectTimeout,
        receiveTimeout: AppConfig.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storageService.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          if (error.response?.statusCode == 401) {
            await _storageService.clearAll();
            onSessionExpired?.call();
          }
          return handler.next(error);
        },
      ),
    );
  }

  Dio get dio => _dio;

  Future<dynamic> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ApiException.networkError(e);
    }
  }

  Future<dynamic> post(String path, {dynamic data}) async {
    try {
      final response = await _dio.post(path, data: data);
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ApiException.networkError(e);
    }
  }

  Future<dynamic> patch(String path, {dynamic data}) async {
    try {
      final response = await _dio.patch(path, data: data);
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ApiException.networkError(e);
    }
  }

  ApiException _handleDioError(DioException error) {
    if (error.response?.data != null && error.response!.data is Map<String, dynamic>) {
      return ApiException.fromJson(
        error.response!.data as Map<String, dynamic>,
        statusCode: error.response?.statusCode,
      );
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError) {
      return ApiException.networkError(error);
    }

    return ApiException(
      code: 'HTTP_${error.response?.statusCode ?? "UNKNOWN"}',
      message: error.message ?? 'Unknown server communication error',
      statusCode: error.response?.statusCode,
    );
  }
}
