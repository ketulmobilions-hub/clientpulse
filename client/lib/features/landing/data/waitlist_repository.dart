import 'package:dio/dio.dart';
import '../../../shared/services/api_service.dart';

class WaitlistException implements Exception {
  WaitlistException(this.message);
  final String message;
  @override
  String toString() => message;
}

class WaitlistRepository {
  WaitlistRepository(this._api);
  final ApiService _api;

  Future<void> submit({
    required String email,
    String? referrer,
    String? utmSource,
  }) async {
    try {
      await _api.post<Map<String, dynamic>>(
        '/waitlist',
        data: {
          'email': email,
          if (referrer != null) 'referrer': referrer,
          if (utmSource != null) 'utmSource': utmSource,
        },
      );
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 429) {
        throw WaitlistException('Too many requests. Try again in a minute.');
      }
      if (code != null && code >= 400 && code < 500) {
        String? msg;
        final data = e.response?.data;
        if (data is Map) {
          final err = data['error'];
          if (err is Map) {
            final m = err['message'];
            if (m is String) msg = m;
          }
        }
        throw WaitlistException(msg ?? 'Could not save your email.');
      }
      throw WaitlistException('Network error. Try again.');
    }
  }
}
