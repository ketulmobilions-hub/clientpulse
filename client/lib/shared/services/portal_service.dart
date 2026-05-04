import 'package:dio/dio.dart';

import '../models/portal_comment.dart';
import '../models/portal_overview.dart';
import '../models/portal_update.dart';
import '../utils/api_utils.dart';
import 'api_service.dart';

// Hex-only share tokens — same regex as backend SHARE_TOKEN_RE.
final _shareTokenRe = RegExp(r'^[a-f0-9]{32,128}$');

class PortalException implements Exception {
  const PortalException(this.code, this.message);
  final String code;
  final String message;

  bool get isInvalidToken => code == 'INVALID_TOKEN' || code == 'NOT_FOUND';

  @override
  String toString() => message;
}

class PortalService {
  const PortalService(this._api);
  final ApiService _api;

  Future<PortalOverview> getPortalOverview(
    String token, {
    CancelToken? cancelToken,
  }) async {
    _validateToken(token);
    try {
      final res = await _api.get<Map<String, dynamic>>(
        '/portal/$token',
        cancelToken: cancelToken,
      );
      final data = tryUnwrapApiData(res.data);
      if (data == null) throw const PortalException('PARSE_ERROR', 'Unexpected response format');
      final overview = PortalOverview.fromJson(data);
      // Sort milestones by position — backend guarantees position but display order is a client concern.
      final sorted = [...overview.milestones]..sort((a, b) => a.position.compareTo(b.position));
      return overview.copyWith(milestones: sorted);
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) rethrow;
      throw _mapDioError(e);
    } on PortalException {
      rethrow;
    } catch (e) {
      throw PortalException('UNEXPECTED', 'Unexpected error: $e');
    }
  }

  Future<({List<PortalUpdate> updates, int total})> listPortalUpdates(
    String token, {
    int page = 1,
    int limit = 20,
    CancelToken? cancelToken,
  }) async {
    _validateToken(token);
    try {
      final res = await _api.get<Map<String, dynamic>>(
        '/portal/$token/updates',
        params: {'page': page, 'limit': limit},
        cancelToken: cancelToken,
      );
      final data = tryUnwrapApiData(res.data);
      if (data == null) throw const PortalException('PARSE_ERROR', 'Unexpected response format');
      final rawUpdates = data['updates'];
      if (rawUpdates is! List) throw const PortalException('PARSE_ERROR', 'Unexpected response format');
      final pagination = data['pagination'];
      // Use (as num) to safely handle both int and double JSON numbers.
      final total = pagination is Map ? ((pagination['total'] as num?)?.toInt() ?? 0) : 0;
      final updates = rawUpdates.map((u) {
        if (u is! Map<String, dynamic>) {
          throw const PortalException('PARSE_ERROR', 'Unexpected element in updates list');
        }
        return PortalUpdate.fromJson(u);
      }).toList();
      return (updates: updates, total: total);
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) rethrow;
      throw _mapDioError(e);
    } on PortalException {
      rethrow;
    } catch (e) {
      throw PortalException('UNEXPECTED', 'Unexpected error: $e');
    }
  }

  Future<PortalComment> createPortalComment({
    required String token,
    required String updateId,
    required String authorName,
    required String body,
    CancelToken? cancelToken,
  }) async {
    _validateToken(token);
    try {
      final res = await _api.post<Map<String, dynamic>>(
        '/portal/$token/updates/$updateId/comments',
        data: {'author_name': authorName, 'body': body},
        cancelToken: cancelToken,
      );
      final data = tryUnwrapApiData(res.data);
      if (data == null) throw const PortalException('PARSE_ERROR', 'Unexpected response format');
      final comment = data['comment'];
      if (comment is! Map<String, dynamic>) {
        throw const PortalException('PARSE_ERROR', 'Unexpected response format');
      }
      return PortalComment.fromJson(comment);
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) rethrow;
      throw _mapDioError(e);
    } on PortalException {
      rethrow;
    } catch (e) {
      throw PortalException('UNEXPECTED', 'Unexpected error: $e');
    }
  }

  Future<List<PortalComment>> listPortalComments(
    String token,
    String updateId, {
    CancelToken? cancelToken,
  }) async {
    _validateToken(token);
    try {
      final res = await _api.get<Map<String, dynamic>>(
        '/portal/$token/updates/$updateId/comments',
        cancelToken: cancelToken,
      );
      final data = tryUnwrapApiData(res.data);
      if (data == null) throw const PortalException('PARSE_ERROR', 'Unexpected response format');
      final rawComments = data['comments'];
      if (rawComments is! List) throw const PortalException('PARSE_ERROR', 'Unexpected response format');
      return rawComments.map((c) {
        if (c is! Map<String, dynamic>) {
          throw const PortalException('PARSE_ERROR', 'Unexpected element in comments list');
        }
        return PortalComment.fromJson(c);
      }).toList();
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) rethrow;
      throw _mapDioError(e);
    } on PortalException {
      rethrow;
    } catch (e) {
      throw PortalException('UNEXPECTED', 'Unexpected error: $e');
    }
  }

  void _validateToken(String token) {
    if (!_shareTokenRe.hasMatch(token)) {
      throw const PortalException('INVALID_TOKEN', 'Invalid or expired token');
    }
  }

  PortalException _mapDioError(DioException e) {
    if (e.response?.statusCode == 429) {
      return const PortalException(
        'RATE_LIMITED',
        'Too many comments. Please wait a few minutes and try again.',
      );
    }
    final body = e.response?.data;
    if (body is Map<String, dynamic>) {
      final err = body['error'];
      if (err is Map<String, dynamic>) {
        final code = err['code']?.toString() ?? 'REQUEST_FAILED';
        final message = err['message']?.toString() ?? 'Request failed';
        return PortalException(code, message);
      }
    }
    return const PortalException('REQUEST_FAILED', 'Request failed');
  }
}
