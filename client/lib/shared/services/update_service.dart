import 'dart:async';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import '../models/update.dart';
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
      final data = _unwrapData(res.data);
      final update = data['update'];
      if (update is! Map<String, dynamic>) {
        throw const UpdateServiceException('Unexpected response format');
      }
      return Update.fromJson(update);
    } on DioException catch (e) {
      throw UpdateServiceException(_extractMessage(e));
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
      final data = _unwrapData(res.data);
      final updates = data['updates'];
      if (updates is! List) throw const UpdateServiceException('Unexpected response format');
      return updates.map((u) {
        if (u is! Map<String, dynamic>) {
          throw const UpdateServiceException('Unexpected element in updates list');
        }
        return Update.fromJson(u);
      }).toList();
    } on DioException catch (e) {
      throw UpdateServiceException(_extractMessage(e));
    } on UpdateServiceException {
      rethrow;
    } catch (e) {
      throw UpdateServiceException('Unexpected error: $e');
    }
  }

  /// Returns { signedUrl, publicUrl, path } for direct PUT to Supabase Storage.
  Future<Map<String, String>> getAttachmentSignedUrl(
    String updateId, {
    required String fileName,
    required String mimeType,
  }) async {
    try {
      final res = await _api.post<Map<String, dynamic>>(
        '/updates/$updateId/attachments/signed-url',
        data: {'file_name': fileName, 'mime_type': mimeType},
      );
      final data = _unwrapData(res.data);
      return {
        'signedUrl': data['signedUrl'] as String,
        'publicUrl': data['publicUrl'] as String,
        'path': data['path'] as String,
      };
    } on DioException catch (e) {
      throw UpdateServiceException(_extractMessage(e));
    } on UpdateServiceException {
      rethrow;
    } catch (e) {
      throw UpdateServiceException('Unexpected error: $e');
    }
  }

  /// Saves attachment metadata after the file has been PUT to Supabase Storage.
  Future<void> saveAttachment(
    String updateId, {
    required String fileUrl,
    required String fileName,
    required int fileSize,
    required String mimeType,
  }) async {
    try {
      await _api.post<Map<String, dynamic>>(
        '/updates/$updateId/attachments',
        data: {
          'file_url': fileUrl,
          'file_name': fileName,
          'file_size': fileSize,
          'mime_type': mimeType,
        },
      );
    } on DioException catch (e) {
      throw UpdateServiceException(_extractMessage(e));
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
      throw UpdateServiceException(_extractMessage(e));
    } on UpdateServiceException {
      rethrow;
    } catch (e) {
      throw UpdateServiceException('Unexpected error: $e');
    }
  }

  /// Uploads file bytes directly to Supabase Storage via a signed URL.
  static Future<void> uploadToSignedUrl(
    String signedUrl,
    List<int> bytes,
    String mimeType,
  ) async {
    final http.Response response;
    try {
      response = await http
          .put(
            Uri.parse(signedUrl),
            headers: {'Content-Type': mimeType},
            body: bytes,
          )
          .timeout(const Duration(minutes: 5));
    } on TimeoutException {
      throw const UpdateServiceException('Upload timed out after 5 minutes');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final detail = response.body.isNotEmpty ? ': ${response.body}' : '';
      throw UpdateServiceException('Upload failed (${response.statusCode})$detail');
    }
  }

  static Map<String, dynamic> _unwrapData(dynamic responseData) {
    if (responseData is! Map<String, dynamic>) {
      throw const UpdateServiceException('Unexpected response format');
    }
    final data = responseData['data'];
    if (data is! Map<String, dynamic>) {
      throw const UpdateServiceException('Unexpected response format');
    }
    return data;
  }

  static String _extractMessage(DioException e) {
    final body = e.response?.data;
    if (body is Map<String, dynamic>) {
      final err = body['error'];
      if (err is Map<String, dynamic>) {
        return err['message']?.toString() ?? 'Request failed';
      }
    }
    return 'Request failed';
  }
}
