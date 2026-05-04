import 'package:dio/dio.dart';
import '../models/workspace.dart';
import 'api_service.dart';

class WorkspaceServiceException implements Exception {
  const WorkspaceServiceException(this.message);
  final String message;
}

class WorkspaceService {
  const WorkspaceService(this._api);
  final ApiService _api;

  Future<Workspace> getWorkspace() async {
    try {
      final res = await _api.get<Map<String, dynamic>>('/workspace');
      final data = _unwrap(res.data, 'workspace');
      return Workspace.fromJson(data);
    } on DioException catch (e) {
      throw WorkspaceServiceException(_extractMessage(e));
    } on WorkspaceServiceException {
      rethrow;
    } catch (e) {
      throw WorkspaceServiceException('Unexpected error: $e');
    }
  }

  Future<Workspace> updateWorkspace({String? name, String? logoUrl}) async {
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (logoUrl != null) body['logo_url'] = logoUrl;
      final res = await _api.patch<Map<String, dynamic>>('/workspace', data: body);
      final data = _unwrap(res.data, 'workspace');
      return Workspace.fromJson(data);
    } on DioException catch (e) {
      throw WorkspaceServiceException(_extractMessage(e));
    } on WorkspaceServiceException {
      rethrow;
    } catch (e) {
      throw WorkspaceServiceException('Unexpected error: $e');
    }
  }

  /// Deletes an orphaned pending-upload logo from Supabase Storage.
  /// Best-effort — callers should not await or depend on this succeeding.
  Future<void> deletePendingLogo(String logoUrl) async {
    try {
      await _api.delete<void>('/storage/logo', data: {'logo_url': logoUrl});
    } on DioException catch (e) {
      throw WorkspaceServiceException(_extractMessage(e));
    } catch (e) {
      throw WorkspaceServiceException('Failed to delete logo: $e');
    }
  }

  Future<({String signedUrl, String publicUrl, String path})> getUploadSignedUrl(
    String fileName,
  ) async {
    try {
      final res = await _api.post<Map<String, dynamic>>(
        '/storage/signed-url',
        data: {'file_name': fileName},
      );
      final d = _unwrap(res.data, null) as Map<String, dynamic>;
      return (
        signedUrl: d['signedUrl'] as String,
        publicUrl: d['publicUrl'] as String,
        path: d['path'] as String,
      );
    } on DioException catch (e) {
      throw WorkspaceServiceException(_extractMessage(e));
    } on WorkspaceServiceException {
      rethrow;
    } catch (e) {
      throw WorkspaceServiceException('Unexpected error: $e');
    }
  }

  /// Unwraps `{ success: true, data: { [key]: {...} } }` response shape.
  /// If [key] is null, returns the `data` map directly.
  static Map<String, dynamic> _unwrap(dynamic responseData, String? key) {
    if (responseData is! Map<String, dynamic>) {
      throw const WorkspaceServiceException('Unexpected response format');
    }
    final data = responseData['data'];
    if (data is! Map<String, dynamic>) {
      throw const WorkspaceServiceException('Unexpected response format');
    }
    if (key == null) return data;
    final inner = data[key];
    if (inner is! Map<String, dynamic>) {
      throw const WorkspaceServiceException('Unexpected response format');
    }
    return inner;
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
