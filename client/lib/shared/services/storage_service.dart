import 'dart:async';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import '../models/attachment.dart';
import '../utils/api_utils.dart';
import 'api_service.dart';

class StorageServiceException implements Exception {
  const StorageServiceException(this.message);
  final String message;

  @override
  String toString() => message;
}

const _kMaxFileSizeBytes = 10 * 1024 * 1024;

class StorageService {
  const StorageService(this._api, {http.Client? httpClient})
      : _httpClient = httpClient;

  final ApiService _api;
  final http.Client? _httpClient;

  /// Orchestrates the full 3-step upload flow:
  /// 1. Get signed URL from backend
  /// 2. PUT bytes directly to Supabase Storage
  /// 3. Save attachment metadata to backend
  ///
  /// [onProgress] receives values 0.0–1.0 as bytes are written to the stream.
  Future<Attachment> uploadAttachment({
    required String updateId,
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
    void Function(double progress)? onProgress,
  }) async {
    if (bytes.length > _kMaxFileSizeBytes) {
      throw StorageServiceException('$fileName exceeds the 10 MB limit');
    }

    // Step 1: get signed URL
    final Map<String, String> urls;
    try {
      final res = await _api.post<Map<String, dynamic>>(
        '/updates/$updateId/attachments/signed-url',
        data: {'file_name': fileName, 'mime_type': mimeType},
      );
      final data = tryUnwrapApiData(res.data);
      if (data == null) throw const StorageServiceException('Unexpected response format');
      urls = {
        'signedUrl': _requireString(data, 'signedUrl'),
        'publicUrl': _requireString(data, 'publicUrl'),
      };
    } on DioException catch (e) {
      throw StorageServiceException(extractDioErrorMessage(e));
    } on StorageServiceException {
      rethrow;
    } catch (e) {
      throw StorageServiceException('Failed to get upload URL: $e');
    }

    // Step 2: PUT directly to Supabase Storage (no JWT — signed URL is self-authenticating)
    await _uploadBytes(urls['signedUrl']!, bytes, mimeType, onProgress);

    // Step 3: save metadata to backend
    try {
      final res = await _api.post<Map<String, dynamic>>(
        '/updates/$updateId/attachments',
        data: {
          'file_url': urls['publicUrl'],
          'file_name': fileName,
          'file_size': bytes.length,
          'mime_type': mimeType,
        },
      );
      final data = tryUnwrapApiData(res.data);
      if (data == null) throw const StorageServiceException('Unexpected response format');
      final attachment = data['attachment'];
      if (attachment is! Map<String, dynamic>) {
        throw const StorageServiceException('Unexpected response format');
      }
      return Attachment.fromJson(attachment);
    } on DioException catch (e) {
      throw StorageServiceException(extractDioErrorMessage(e));
    } on StorageServiceException {
      rethrow;
    } catch (e) {
      throw StorageServiceException('Failed to save attachment: $e');
    }
  }

  /// Deletes an attachment by ID — removes both the DB record and the storage file.
  Future<void> deleteAttachment(String attachmentId) async {
    try {
      await _api.delete<void>('/attachments/$attachmentId');
    } on DioException catch (e) {
      throw StorageServiceException(extractDioErrorMessage(e));
    } on StorageServiceException {
      rethrow;
    } catch (e) {
      throw StorageServiceException('Failed to delete attachment: $e');
    }
  }

  Future<void> _uploadBytes(
    String signedUrl,
    Uint8List bytes,
    String mimeType,
    void Function(double)? onProgress,
  ) async {
    final client = _httpClient ?? http.Client();
    try {
      final request = http.StreamedRequest('PUT', Uri.parse(signedUrl))
        ..headers['Content-Type'] = mimeType
        ..headers['Content-Length'] = bytes.length.toString()
        // x-upsert: true makes the upload idempotent — if the same path already
        // exists (e.g. a retry after a transient failure), Supabase overwrites
        // instead of returning 409 Conflict.
        ..headers['x-upsert'] = 'true';

      // Write chunks to the sink synchronously before sending. Don't await
      // sink.close() — the HTTP client drains the stream; awaiting done would
      // deadlock if the client never reads (e.g. in tests with a mock client).
      _writeChunks(request, bytes, onProgress);

      final http.StreamedResponse response;
      try {
        response = await client.send(request).timeout(const Duration(minutes: 5));
      } on TimeoutException {
        throw const StorageServiceException('Upload timed out after 5 minutes');
      }

      // Drain response stream to release connection resources.
      final body = await response.stream.bytesToString();
      final statusCode = response.statusCode;
      if (statusCode < 200 || statusCode >= 300) {
        final detail = body.isNotEmpty ? ': $body' : '';
        throw StorageServiceException('Upload failed ($statusCode)$detail');
      }
    } finally {
      if (_httpClient == null) client.close();
    }
  }

  static void _writeChunks(
    http.StreamedRequest request,
    Uint8List bytes,
    void Function(double)? onProgress,
  ) {
    const chunkSize = 65536; // 64 KB
    final total = bytes.length;
    if (total == 0) {
      onProgress?.call(1.0);
    } else {
      for (var offset = 0; offset < total; offset += chunkSize) {
        final end = (offset + chunkSize).clamp(0, total);
        request.sink.add(bytes.sublist(offset, end));
        onProgress?.call(end / total);
      }
    }
    request.sink.close(); // fire-and-forget — don't await .done
  }

  static String _requireString(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is! String) {
      throw StorageServiceException('Missing $key in response');
    }
    return value;
  }
}
