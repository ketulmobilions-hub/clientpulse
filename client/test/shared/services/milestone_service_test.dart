import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:clientpulse/shared/models/milestone.dart';
import 'package:clientpulse/shared/services/api_service.dart';
import 'package:clientpulse/shared/services/milestone_service.dart';

class _MockApiService extends Mock implements ApiService {}

Response<Map<String, dynamic>> _ok(Map<String, dynamic> body) => Response(
      data: body,
      statusCode: 200,
      requestOptions: RequestOptions(path: ''),
    );

Response<void> _noContent() => Response(
      statusCode: 204,
      requestOptions: RequestOptions(path: ''),
    );

Map<String, dynamic> _milestoneJson({
  String id = 'ms-1',
  String projectId = 'proj-1',
  String title = 'Launch MVP',
  String? dueDate = '2026-05-11',
  bool completed = false,
  int position = 0,
}) =>
    {
      'id': id,
      'project_id': projectId,
      'title': title,
      'due_date': dueDate,
      'completed': completed,
      'completed_at': null,
      'position': position,
      'created_at': '2026-01-01T00:00:00Z',
      'updated_at': '2026-01-01T00:00:00Z',
    };

void main() {
  late _MockApiService api;
  late MilestoneService sut;

  setUp(() {
    api = _MockApiService();
    sut = MilestoneService(api);
  });

  group('MilestoneStatus.displayLabel', () {
    test('returns correct labels', () {
      expect(MilestoneStatus.upcoming.displayLabel, 'Upcoming');
      expect(MilestoneStatus.delayed.displayLabel, 'Delayed');
      expect(MilestoneStatus.completed.displayLabel, 'Completed');
    });
  });

  group('MilestoneStatusX.status derived from Milestone', () {
    Milestone make({required bool completed, String? dueDate}) => Milestone(
          id: 'id-1',
          projectId: 'proj-1',
          title: 'Test',
          dueDate: dueDate,
          completed: completed,
          completedAt: null,
          position: 0,
          createdAt: '2026-01-01T00:00:00Z',
          updatedAt: '2026-01-01T00:00:00Z',
        );

    test('completed=true yields Completed regardless of due_date', () {
      expect(make(completed: true).status, MilestoneStatus.completed);
      expect(make(completed: true, dueDate: '2000-01-01').status,
          MilestoneStatus.completed);
    });

    test('past due_date + not completed yields Delayed', () {
      expect(make(completed: false, dueDate: '2020-01-01').status,
          MilestoneStatus.delayed);
    });

    test('future due_date + not completed yields Upcoming', () {
      expect(make(completed: false, dueDate: '2099-12-31').status,
          MilestoneStatus.upcoming);
    });

    test('null due_date + not completed yields Upcoming', () {
      expect(make(completed: false).status, MilestoneStatus.upcoming);
    });

    test('invalid date string + not completed yields Upcoming', () {
      expect(make(completed: false, dueDate: 'not-a-date').status,
          MilestoneStatus.upcoming);
    });
  });

  group('Milestone.fromJson', () {
    test('deserializes all fields correctly', () {
      final m = Milestone.fromJson(_milestoneJson());
      expect(m.id, 'ms-1');
      expect(m.projectId, 'proj-1');
      expect(m.title, 'Launch MVP');
      expect(m.dueDate, '2026-05-11');
      expect(m.completed, isFalse);
      expect(m.completedAt, isNull);
      expect(m.position, 0);
    });

    test('handles null due_date', () {
      final m = Milestone.fromJson(_milestoneJson(dueDate: null));
      expect(m.dueDate, isNull);
    });

    test('round-trips through toJson', () {
      final m = Milestone.fromJson(_milestoneJson());
      final out = m.toJson();
      expect(out['project_id'], 'proj-1');
      expect(out['due_date'], '2026-05-11');
      expect(out['completed'], isFalse);
      expect(out['position'], 0);
    });
  });

  group('MilestoneService.listMilestones', () {
    test('returns parsed list on success', () async {
      when(() => api.get<Map<String, dynamic>>('/projects/proj-1/milestones'))
          .thenAnswer((_) async => _ok({
                'success': true,
                'data': {'milestones': [_milestoneJson()]},
              }));

      final list = await sut.listMilestones('proj-1');
      expect(list.length, 1);
      expect(list.first.id, 'ms-1');
    });

    test('returns empty list when milestones array is empty', () async {
      when(() => api.get<Map<String, dynamic>>('/projects/proj-1/milestones'))
          .thenAnswer((_) async => _ok({
                'success': true,
                'data': {'milestones': []},
              }));

      final list = await sut.listMilestones('proj-1');
      expect(list, isEmpty);
    });

    test('throws MilestoneServiceException on missing data key', () async {
      when(() => api.get<Map<String, dynamic>>('/projects/proj-1/milestones'))
          .thenAnswer((_) async => _ok({'success': true}));

      await expectLater(
        sut.listMilestones('proj-1'),
        throwsA(isA<MilestoneServiceException>()),
      );
    });

    test('throws MilestoneServiceException on DioException', () async {
      when(() => api.get<Map<String, dynamic>>('/projects/proj-1/milestones'))
          .thenThrow(DioException(
        requestOptions: RequestOptions(path: ''),
        response: Response(
          statusCode: 500,
          data: {'error': {'code': 'SERVER_ERROR', 'message': 'Internal error'}},
          requestOptions: RequestOptions(path: ''),
        ),
      ));

      await expectLater(
        sut.listMilestones('proj-1'),
        throwsA(isA<MilestoneServiceException>()),
      );
    });
  });

  group('MilestoneService.createMilestone', () {
    test('returns created milestone on success', () async {
      when(() => api.post<Map<String, dynamic>>(
            '/projects/proj-1/milestones',
            data: any(named: 'data'),
          )).thenAnswer((_) async => _ok({
            'success': true,
            'data': {'milestone': _milestoneJson(title: 'New Milestone')},
          }));

      final m = await sut.createMilestone('proj-1', title: 'New Milestone');
      expect(m.title, 'New Milestone');
    });

    test('throws MilestoneServiceException on missing milestone key', () async {
      when(() => api.post<Map<String, dynamic>>(
            '/projects/proj-1/milestones',
            data: any(named: 'data'),
          )).thenAnswer((_) async => _ok({
            'success': true,
            'data': {'other': 'value'},
          }));

      await expectLater(
        sut.createMilestone('proj-1', title: 'Test'),
        throwsA(isA<MilestoneServiceException>()),
      );
    });
  });

  group('MilestoneService.updateMilestone', () {
    test('returns updated milestone on success', () async {
      when(() => api.patch<Map<String, dynamic>>(
            '/milestones/ms-1',
            data: any(named: 'data'),
          )).thenAnswer((_) async => _ok({
            'success': true,
            'data': {'milestone': _milestoneJson(completed: true)},
          }));

      final m = await sut.updateMilestone('ms-1', completed: true);
      expect(m.completed, isTrue);
    });

    test('sends due_date: null when clearDueDate=true', () async {
      Map<String, dynamic>? capturedBody;
      when(() => api.patch<Map<String, dynamic>>(
            '/milestones/ms-1',
            data: any(named: 'data'),
          )).thenAnswer((invocation) async {
        capturedBody = invocation.namedArguments[const Symbol('data')]
            as Map<String, dynamic>;
        return _ok({
          'success': true,
          'data': {'milestone': _milestoneJson(dueDate: null)},
        });
      });

      await sut.updateMilestone('ms-1', clearDueDate: true);
      expect(capturedBody!.containsKey('due_date'), isTrue);
      expect(capturedBody!['due_date'], isNull);
    });

    test('throws MilestoneServiceException when no fields provided', () async {
      await expectLater(
        sut.updateMilestone('ms-1'),
        throwsA(isA<MilestoneServiceException>()),
      );
    });
  });

  group('MilestoneService.deleteMilestone', () {
    test('completes without error on 204', () async {
      when(() => api.delete<void>('/milestones/ms-1'))
          .thenAnswer((_) async => _noContent());

      await expectLater(sut.deleteMilestone('ms-1'), completes);
    });

    test('throws MilestoneServiceException on DioException', () async {
      when(() => api.delete<void>('/milestones/ms-1')).thenThrow(
        DioException(requestOptions: RequestOptions(path: '')),
      );

      await expectLater(
        sut.deleteMilestone('ms-1'),
        throwsA(isA<MilestoneServiceException>()),
      );
    });
  });
}
