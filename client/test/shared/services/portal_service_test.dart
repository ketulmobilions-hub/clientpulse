import 'package:clientpulse/shared/models/portal_overview.dart';
import 'package:clientpulse/shared/models/portal_update.dart';
import 'package:clientpulse/shared/models/update.dart';
import 'package:clientpulse/shared/services/api_service.dart';
import 'package:clientpulse/shared/services/portal_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockApiService extends Mock implements ApiService {}

// 32 valid hex chars — passes _shareTokenRe.
const _token = 'abcdef1234567890abcdef1234567890';
const _token2 = 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';

Response<T> _ok<T>(T data) => Response(
      data: data,
      statusCode: 200,
      requestOptions: RequestOptions(),
    );

DioException _dioError(int status, Map<String, dynamic> body) => DioException(
      requestOptions: RequestOptions(),
      response: Response(
        statusCode: status,
        data: body,
        requestOptions: RequestOptions(),
      ),
      type: DioExceptionType.badResponse,
    );

void main() {
  late _MockApiService mockApi;
  late PortalService svc;

  setUp(() {
    mockApi = _MockApiService();
    svc = PortalService(mockApi);
  });

  group('getPortalOverview', () {
    const _overviewJson = {
      'success': true,
      'data': {
        'workspace': {'name': 'Acme', 'slug': 'acme', 'logo_url': null},
        'project': {
          'id': 'p1',
          'name': 'Project Alpha',
          'description': null,
          'client_name': 'Alice',
          'status': 'active',
          'start_date': null,
          'expected_end_date': null,
        },
        'milestones': [
          {'id': 'm2', 'title': 'Beta', 'due_date': null, 'completed': false, 'completed_at': null, 'position': 2},
          {'id': 'm1', 'title': 'Alpha', 'due_date': null, 'completed': true, 'completed_at': null, 'position': 1},
        ],
        'progress': {'total': 2, 'completed': 1, 'percent': 50},
      },
    };

    void _stubOverview(Map<String, dynamic> json) {
      when(() => mockApi.get<Map<String, dynamic>>(
            '/portal/$_token',
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => _ok(json));
    }

    test('returns PortalOverview on success', () async {
      _stubOverview(_overviewJson);
      final result = await svc.getPortalOverview(_token);
      expect(result, isA<PortalOverview>());
      expect(result.project.name, 'Project Alpha');
      expect(result.workspace.name, 'Acme');
      expect(result.progress.percent, 50.0);
    });

    test('sorts milestones by position ascending', () async {
      _stubOverview(_overviewJson);
      final result = await svc.getPortalOverview(_token);
      expect(result.milestones[0].title, 'Alpha');
      expect(result.milestones[1].title, 'Beta');
    });

    test('parses float percent without type error', () async {
      final data = (_overviewJson['data'] as Map<String, dynamic>);
      final json = {
        'success': true,
        'data': {...data, 'progress': {'total': 3, 'completed': 2, 'percent': 66.7}},
      };
      _stubOverview(json);
      final result = await svc.getPortalOverview(_token);
      expect(result.progress.percent, closeTo(66.7, 0.01));
    });

    test('throws PortalException INVALID_TOKEN on 401', () async {
      when(() => mockApi.get<Map<String, dynamic>>(
            '/portal/$_token2',
            cancelToken: any(named: 'cancelToken'),
          )).thenThrow(_dioError(401, {
        'success': false,
        'error': {'code': 'INVALID_TOKEN', 'message': 'Invalid or expired token'},
      }));

      await expectLater(
        svc.getPortalOverview(_token2),
        throwsA(predicate<PortalException>((e) => e.code == 'INVALID_TOKEN' && e.isInvalidToken)),
      );
    });

    test('throws PortalException INVALID_TOKEN for non-hex token without network call', () async {
      await expectLater(
        svc.getPortalOverview('not-a-valid-token'),
        throwsA(predicate<PortalException>((e) => e.isInvalidToken)),
      );
      verifyNever(() => mockApi.get<Map<String, dynamic>>(any()));
    });

    test('throws PortalException PARSE_ERROR when data key missing', () async {
      _stubOverview({'success': true, 'result': {}});
      await expectLater(
        svc.getPortalOverview(_token),
        throwsA(predicate<PortalException>((e) => e.code == 'PARSE_ERROR')),
      );
    });
  });

  group('listPortalUpdates', () {
    final _page1Json = {
      'success': true,
      'data': {
        'updates': [
          {
            'id': 'u1',
            'title': 'Week 1',
            'body': '**Done**',
            'category': 'progress',
            'position': 0,
            'created_at': '2026-01-01T00:00:00Z',
            'updated_at': '2026-01-01T00:00:00Z',
            'attachments': [],
          },
        ],
        'pagination': {'page': 1, 'limit': 20, 'total': 1},
      },
    };

    void _stubUpdates(Map<String, dynamic> json, {int page = 1, int limit = 20}) {
      when(() => mockApi.get<Map<String, dynamic>>(
            '/portal/$_token/updates',
            params: {'page': page, 'limit': limit},
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => _ok(json));
    }

    test('returns updates and total on success', () async {
      _stubUpdates(_page1Json);
      final result = await svc.listPortalUpdates(_token);
      expect(result.updates, hasLength(1));
      expect(result.updates.first, isA<PortalUpdate>());
      expect(result.updates.first.title, 'Week 1');
      expect(result.updates.first.category, UpdateCategory.progress);
      expect(result.total, 1);
    });

    test('parses createdAt as DateTime', () async {
      _stubUpdates(_page1Json);
      final result = await svc.listPortalUpdates(_token);
      expect(result.updates.first.createdAt, isA<DateTime>());
    });

    test('handles float total via num cast', () async {
      _stubUpdates({
        'success': true,
        'data': {'updates': <dynamic>[], 'pagination': {'page': 1, 'limit': 20, 'total': 42.0}},
      });
      final result = await svc.listPortalUpdates(_token);
      expect(result.total, 42);
    });

    test('requests correct page and limit', () async {
      _stubUpdates({
        'success': true,
        'data': {'updates': <dynamic>[], 'pagination': {'page': 2, 'limit': 10, 'total': 25}},
      }, page: 2, limit: 10);
      final result = await svc.listPortalUpdates(_token, page: 2, limit: 10);
      expect(result.total, 25);
      expect(result.updates, isEmpty);
    });

    test('throws PortalException on DioException for updates endpoint', () async {
      when(() => mockApi.get<Map<String, dynamic>>(
            '/portal/$_token/updates',
            params: any(named: 'params'),
            cancelToken: any(named: 'cancelToken'),
          )).thenThrow(_dioError(401, {
        'success': false,
        'error': {'code': 'INVALID_TOKEN', 'message': 'Invalid or expired token'},
      }));

      await expectLater(
        svc.listPortalUpdates(_token),
        throwsA(predicate<PortalException>((e) => e.isInvalidToken)),
      );
    });

    test('throws PortalException PARSE_ERROR when updates key missing', () async {
      _stubUpdates({
        'success': true,
        'data': {'items': <dynamic>[], 'pagination': {'total': 0}},
      });
      await expectLater(
        svc.listPortalUpdates(_token),
        throwsA(predicate<PortalException>((e) => e.code == 'PARSE_ERROR')),
      );
    });

    test('parses attachments when present', () async {
      _stubUpdates({
        'success': true,
        'data': {
          'updates': [
            {
              'id': 'u2',
              'title': 'Delivery',
              'body': 'See attached',
              'category': 'deliverable',
              'position': 0,
              'created_at': '2026-01-02T00:00:00Z',
              'updated_at': '2026-01-02T00:00:00Z',
              'attachments': [
                {
                  'id': 'a1',
                  'file_name': 'report.pdf',
                  'file_url': 'https://example.com/report.pdf',
                  'file_size': 204800,
                  'mime_type': 'application/pdf',
                  'created_at': '2026-01-02T00:00:00Z',
                },
              ],
            },
          ],
          'pagination': {'page': 1, 'limit': 20, 'total': 1},
        },
      });
      final result = await svc.listPortalUpdates(_token);
      expect(result.updates.first.attachments, hasLength(1));
      expect(result.updates.first.attachments.first.fileName, 'report.pdf');
    });
  });

  group('PortalException', () {
    test('isInvalidToken true for INVALID_TOKEN', () {
      const e = PortalException('INVALID_TOKEN', 'bad token');
      expect(e.isInvalidToken, isTrue);
    });

    test('isInvalidToken true for NOT_FOUND', () {
      const e = PortalException('NOT_FOUND', 'not found');
      expect(e.isInvalidToken, isTrue);
    });

    test('isInvalidToken false for DB_ERROR', () {
      const e = PortalException('DB_ERROR', 'db error');
      expect(e.isInvalidToken, isFalse);
    });
  });
}
