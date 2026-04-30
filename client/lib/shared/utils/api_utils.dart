import 'package:dio/dio.dart';

/// Extracts a human-readable error message from a [DioException].
/// Handles `{ error: { message: "..." } }` (backend format) and
/// `{ error: "string" }` (proxy format, e.g. Render's Bad Gateway).
String extractDioErrorMessage(DioException e) {
  final body = e.response?.data;
  if (body is Map<String, dynamic>) {
    final err = body['error'];
    if (err is Map<String, dynamic>) {
      return err['message']?.toString() ?? 'Request failed';
    }
    if (err is String && err.isNotEmpty) return err;
  }
  return 'Request failed';
}

/// Unwraps `{ data: { ... } }` envelope. Returns null if shape is wrong.
Map<String, dynamic>? tryUnwrapApiData(dynamic responseData) {
  if (responseData is! Map<String, dynamic>) return null;
  final data = responseData['data'];
  if (data is! Map<String, dynamic>) return null;
  return data;
}
