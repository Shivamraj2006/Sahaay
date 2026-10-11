/// Standard Sahaay Error shape conforming to Section 5 of Shared Contract:
/// {
///   "error": {
///     "code": "EMERGENCY_ALREADY_ASSIGNED",
///     "message": "This emergency has already been assigned.",
///     "requestId": "opaque-request-id",
///     "details": {}
///   }
/// }
class ApiException implements Exception {
  final String code;
  final String message;
  final String? requestId;
  final Map<String, dynamic>? details;
  final int? statusCode;

  ApiException({
    required this.code,
    required this.message,
    this.requestId,
    this.details,
    this.statusCode,
  });

  factory ApiException.fromJson(Map<String, dynamic> json, {int? statusCode}) {
    final errorObj = json['error'] as Map<String, dynamic>? ?? json;
    return ApiException(
      code: errorObj['code'] as String? ?? 'UNKNOWN_ERROR',
      message: errorObj['message'] as String? ?? 'An unexpected error occurred.',
      requestId: errorObj['requestId'] as String?,
      details: errorObj['details'] as Map<String, dynamic>?,
      statusCode: statusCode,
    );
  }

  factory ApiException.networkError(dynamic error) {
    return ApiException(
      code: 'NETWORK_ERROR',
      message: 'Unable to reach Sahaay servers. Please check your internet connection.',
      details: {'originalError': error.toString()},
    );
  }

  factory ApiException.unauthorized() {
    return ApiException(
      code: 'UNAUTHORIZED',
      message: 'Session has expired. Please sign in again.',
      statusCode: 401,
    );
  }

  @override
  String toString() => 'ApiException(code: $code, message: $message, statusCode: $statusCode)';
}
