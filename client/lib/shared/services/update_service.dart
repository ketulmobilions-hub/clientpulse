import 'package:dio/dio.dart';
import '../models/update.dart';
import '../utils/api_utils.dart';
import 'api_service.dart';

class UpdateServiceException implements Exception {
  const UpdateServiceException(this.message);
  final String message;

  @override
  String toString() => message;
}

class UpdateService {
  const UpdateService(this._api);
  final ApiService _api;

  Future<Update> createUpdate(
    String projectId, {
    required String title,
    required String body,
    required UpdateCategory category,
    String status = 'draft',
  }) async {
    try {
      final res = await _api.post<Map<String, dynamic>>(
        '/projects/$projectId/updates',
        data: {
          'title': title,
          'body': body,
          'category': category.apiValue,
          'status': status,
        },
      );
      final data = tryUnwrapApiData(res.data);
      if (data == null) throw const UpdateServiceException('Unexpected response format');
      final update = data['update'];
      if (update is! Map<String, dynamic>) {
        throw const UpdateServiceException('Unexpected response format');
      }
      return Update.fromJson(update);
    } on DioException catch (e) {
      throw UpdateServiceException(extractDioErrorMessage(e));
    } on UpdateServiceException {
      rethrow;
    } catch (e) {
      throw UpdateServiceException('Unexpected error: $e');
    }
  }

  Future<List<Update>> listUpdates(String projectId) async {
    try {
      final res = await _api.get<Map<String, dynamic>>(
        '/projects/$projectId/updates',
      );
      final data = tryUnwrapApiData(res.data);
      if (data == null) throw const UpdateServiceException('Unexpected response format');
      final updates = data['updates'];
      if (updates is! List) throw const UpdateServiceException('Unexpected response format');
      return updates.map((u) {
        if (u is! Map<String, dynamic>) {
          throw const UpdateServiceException('Unexpected element in updates list');
        }
        return Update.fromJson(u);
      }).toList();
    } on DioException catch (e) {
      throw UpdateServiceException(extractDioErrorMessage(e));
    } on UpdateServiceException {
      rethrow;
    } catch (e) {
      throw UpdateServiceException('Unexpected error: $e');
    }
  }

  Future<void> deleteUpdate(String updateId) async {
    try {
      await _api.delete<void>('/updates/$updateId');
    } on DioException catch (e) {
      throw UpdateServiceException(extractDioErrorMessage(e));
    } on UpdateServiceException {
      rethrow;
    } catch (e) {
      throw UpdateServiceException('Unexpected error: $e');
    }
  }
}
