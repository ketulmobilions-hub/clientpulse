import 'package:dio/dio.dart';

/// Thrown by [ApiService] interceptor when the session expires (401).
/// After receiving this, [AuthNotifier.logout] has already been called —
/// callers should ignore it; the router will redirect to /login.
class SessionExpiredException implements Exception {
  const SessionExpiredException();
}

// Callers use typed methods — never access _dio directly.
class ApiService {
  final Dio _dio;

  ApiService({
    required String baseUrl,
    required Future<String?> Function() getToken,
    Future<void> Function()? onUnauthorized,
  }) : _dio = Dio(BaseOptions(baseUrl: baseUrl)) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (err, handler) async {
          if (err.response?.statusCode == 401 && onUnauthorized != null) {
            await onUnauthorized();
            // Replace the 401 with a typed sentinel so callers can distinguish
            // "session expired, router is handling it" from real network errors.
            handler.reject(DioException(
              requestOptions: err.requestOptions,
              error: const SessionExpiredException(),
            ));
            return;
          }
          handler.next(err);
        },
      ),
    );
  }

  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? params}) =>
      _dio.get(path, queryParameters: params);

  Future<Response<T>> post<T>(String path, {Object? data}) =>
      _dio.post(path, data: data);

  Future<Response<T>> put<T>(String path, {Object? data}) =>
      _dio.put(path, data: data);

  Future<Response<T>> patch<T>(String path, {Object? data}) =>
      _dio.patch(path, data: data);

  Future<Response<T>> delete<T>(String path, {Object? data}) =>
      _dio.delete(path, data: data);
}
