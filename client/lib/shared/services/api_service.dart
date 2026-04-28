import 'package:dio/dio.dart';
import '../../core/config/app_config.dart';

// JWT interceptor added in issue #7 (agency auth).
// Callers use typed methods — never access _dio directly.
class ApiService {
  final Dio _dio;

  ApiService(AppConfig config)
      : _dio = Dio(BaseOptions(baseUrl: config.apiBaseUrl));

  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? params}) =>
      _dio.get(path, queryParameters: params);

  Future<Response<T>> post<T>(String path, {Object? data}) =>
      _dio.post(path, data: data);

  Future<Response<T>> put<T>(String path, {Object? data}) =>
      _dio.put(path, data: data);

  Future<Response<T>> delete<T>(String path) => _dio.delete(path);
}
