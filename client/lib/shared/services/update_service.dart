import 'package:dio/dio.dart';
import '../models/attachment.dart';
import '../models/comment.dart';
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

  Future<({Update update, List<Attachment> attachments})> getUpdate(
    String updateId,
  ) async {
    try {
      final res = await _api.get<Map<String, dynamic>>('/updates/$updateId');
      final data = tryUnwrapApiData(res.data);
      if (data == null) throw const UpdateServiceException('Unexpected response format');
      final updateJson = data['update'];
      if (updateJson is! Map<String, dynamic>) {
        throw const UpdateServiceException('Unexpected response format');
      }
      final attachmentsJson = updateJson['attachments'];
      final attachments = attachmentsJson is List
          ? attachmentsJson
              .whereType<Map<String, dynamic>>()
              .map(Attachment.fromJson)
              .toList()
          : <Attachment>[];
      return (update: Update.fromJson(updateJson), attachments: attachments);
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

  Future<List<Comment>> listComments(String updateId) async {
    try {
      final res = await _api.get<Map<String, dynamic>>(
        '/updates/$updateId/comments',
      );
      final data = tryUnwrapApiData(res.data);
      if (data == null) throw const UpdateServiceException('Unexpected response format');
      final comments = data['comments'];
      if (comments is! List) throw const UpdateServiceException('Unexpected response format');
      return comments.map((c) {
        if (c is! Map<String, dynamic>) {
          throw const UpdateServiceException('Unexpected element in comments list');
        }
        return Comment.fromJson(c);
      }).toList();
    } on DioException catch (e) {
      throw UpdateServiceException(extractDioErrorMessage(e));
    } on UpdateServiceException {
      rethrow;
    } catch (e) {
      throw UpdateServiceException('Unexpected error: $e');
    }
  }

  Future<Comment> createComment(
    String updateId,
    String body, {
    String? parentId,
  }) async {
    try {
      final payload = <String, dynamic>{'body': body};
      if (parentId != null) payload['parent_id'] = parentId;
      final res = await _api.post<Map<String, dynamic>>(
        '/updates/$updateId/comments',
        data: payload,
      );
      final data = tryUnwrapApiData(res.data);
      if (data == null) throw const UpdateServiceException('Unexpected response format');
      final comment = data['comment'];
      if (comment is! Map<String, dynamic>) {
        throw const UpdateServiceException('Unexpected response format');
      }
      return Comment.fromJson(comment);
    } on DioException catch (e) {
      throw UpdateServiceException(extractDioErrorMessage(e));
    } on UpdateServiceException {
      rethrow;
    } catch (e) {
      throw UpdateServiceException('Unexpected error: $e');
    }
  }

  Future<Update> editUpdate(
    String updateId, {
    String? title,
    String? body,
    UpdateCategory? category,
    String? status,
    int? position,
  }) async {
    final payload = <String, dynamic>{};
    if (title != null) payload['title'] = title;
    if (body != null) payload['body'] = body;
    if (category != null) payload['category'] = category.apiValue;
    if (status != null) payload['status'] = status;
    if (position != null) payload['position'] = position;
    try {
      final res = await _api.patch<Map<String, dynamic>>(
        '/updates/$updateId',
        data: payload,
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
