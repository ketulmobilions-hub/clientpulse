import 'dart:async';

import 'package:clientpulse/features/portal/presentation/widgets/portal_update_card.dart';
import 'package:clientpulse/shared/models/portal_comment.dart';
import 'package:clientpulse/shared/models/portal_update.dart';
import 'package:clientpulse/shared/models/update.dart';
import 'package:clientpulse/shared/providers/portal_service_provider.dart';
import 'package:clientpulse/shared/services/api_service.dart';
import 'package:clientpulse/shared/services/portal_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockApiService extends Mock implements ApiService {}

const _kToken = 'abcdef1234567890abcdef1234567890';

PortalUpdate _update({String id = 'upd-1'}) => PortalUpdate(
      id: id,
      title: 'Sprint 1 complete',
      body: 'All tasks done.',
      category: UpdateCategory.progress,
      position: 0,
      createdAt: DateTime(2026, 4, 1),
      updatedAt: DateTime(2026, 4, 1),
    );

PortalComment _comment() => PortalComment(
      id: 'cmt-1',
      updateId: 'upd-1',
      authorName: 'Alice',
      body: 'Great progress!',
      createdAt: DateTime(2026, 4, 2),
    );

Response<T> _ok<T>(T data) => Response(
      data: data,
      statusCode: 201,
      requestOptions: RequestOptions(),
    );

DioException _serverError() => DioException(
      requestOptions: RequestOptions(),
      response: Response(
        statusCode: 500,
        data: {
          'error': {'code': 'SERVER_ERROR', 'message': 'Internal error'}
        },
        requestOptions: RequestOptions(),
      ),
      type: DioExceptionType.badResponse,
    );

DioException _rateLimitError() => DioException(
      requestOptions: RequestOptions(),
      response: Response(
        statusCode: 429,
        data: {},
        requestOptions: RequestOptions(),
      ),
      type: DioExceptionType.badResponse,
    );

DioException _networkTimeout() => DioException(
      requestOptions: RequestOptions(),
      type: DioExceptionType.connectionTimeout,
    );

Widget _wrap(PortalUpdate update, PortalService svc) => ProviderScope(
      overrides: [
        portalServiceProvider.overrideWith((_) async => svc),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: PortalUpdateCard(update: update, token: _kToken),
        ),
      ),
    );

const _kCommentJson = {
  'success': true,
  'data': {
    'comment': {
      'id': 'cmt-1',
      'update_id': 'upd-1',
      'parent_id': null,
      'author_name': 'Alice',
      'body': 'Great progress!',
      'created_at': '2026-04-02T00:00:00.000Z',
      'updated_at': '2026-04-02T00:00:00.000Z',
    }
  }
};

void main() {
  late _MockApiService mockApi;
  late PortalService svc;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    mockApi = _MockApiService();
    svc = PortalService(mockApi);
  });

  group('PortalUpdateCard', () {
    testWidgets('shows title; comment form hidden when collapsed',
        (tester) async {
      await tester.pumpWidget(_wrap(_update(), svc));
      await tester.pump();

      expect(find.text('Sprint 1 complete'), findsOneWidget);
      expect(find.text('Your name'), findsNothing);
      expect(find.text('Comment'), findsNothing);
    });

    testWidgets('expanding card reveals comment form', (tester) async {
      await tester.pumpWidget(_wrap(_update(), svc));
      await tester.pump();

      await tester.tap(find.text('Sprint 1 complete'));
      await tester.pumpAndSettle();

      expect(find.text('Your name'), findsOneWidget);
      expect(find.text('Comment'), findsOneWidget);
      expect(find.text('Submit'), findsOneWidget);
      expect(find.text('Comments'), findsOneWidget);
    });

    testWidgets('submit with empty fields shows validation error',
        (tester) async {
      await tester.pumpWidget(_wrap(_update(), svc));
      await tester.pump();

      await tester.tap(find.text('Sprint 1 complete'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Submit'));
      await tester.pump();

      expect(find.text('Name and comment are required.'), findsOneWidget);
      verifyNever(() => mockApi.post<Map<String, dynamic>>(
            any(),
            data: any(named: 'data'),
            cancelToken: any(named: 'cancelToken'),
          ));
    });

    testWidgets('whitespace-only fields treated as empty — shows validation error',
        (tester) async {
      await tester.pumpWidget(_wrap(_update(), svc));
      await tester.pump();

      await tester.tap(find.text('Sprint 1 complete'));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextField, 'Your name'), '   ');
      await tester.enterText(find.widgetWithText(TextField, 'Comment'), '   ');
      await tester.tap(find.text('Submit'));
      await tester.pump();

      expect(find.text('Name and comment are required.'), findsOneWidget);
      verifyNever(() => mockApi.post<Map<String, dynamic>>(
            any(),
            data: any(named: 'data'),
            cancelToken: any(named: 'cancelToken'),
          ));
    });

    testWidgets('successful submit adds comment inline optimistically',
        (tester) async {
      final comment = _comment();
      when(() => mockApi.post<Map<String, dynamic>>(
            '/portal/$_kToken/updates/upd-1/comments',
            data: any(named: 'data'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => _ok(_kCommentJson));

      await tester.pumpWidget(_wrap(_update(), svc));
      await tester.pump();

      await tester.tap(find.text('Sprint 1 complete'));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextField, 'Your name'), 'Alice');
      await tester.enterText(find.widgetWithText(TextField, 'Comment'), 'Great progress!');
      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();

      expect(find.text(comment.body), findsOneWidget);
      expect(find.text('Comments (1)'), findsOneWidget);
    });

    testWidgets('submit button disabled while submitting — prevents double-send',
        (tester) async {
      final completer = Completer<Response<Map<String, dynamic>>>();
      when(() => mockApi.post<Map<String, dynamic>>(
            any(),
            data: any(named: 'data'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) => completer.future);

      await tester.pumpWidget(_wrap(_update(), svc));
      await tester.pump();

      await tester.tap(find.text('Sprint 1 complete'));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextField, 'Your name'), 'Alice');
      await tester.enterText(find.widgetWithText(TextField, 'Comment'), 'Hello');

      // First tap — starts async submission.
      await tester.tap(find.text('Submit'));
      await tester.pump();

      // Button is now disabled (showing spinner — onPressed == null).
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);

      completer.complete(_ok(_kCommentJson));
      await tester.pumpAndSettle();

      // Exactly one API call.
      verify(() => mockApi.post<Map<String, dynamic>>(
            any(),
            data: any(named: 'data'),
            cancelToken: any(named: 'cancelToken'),
          )).called(1);
    });

    testWidgets('failed submit shows error message from server', (tester) async {
      when(() => mockApi.post<Map<String, dynamic>>(
            any(),
            data: any(named: 'data'),
            cancelToken: any(named: 'cancelToken'),
          )).thenThrow(_serverError());

      await tester.pumpWidget(_wrap(_update(), svc));
      await tester.pump();

      await tester.tap(find.text('Sprint 1 complete'));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextField, 'Your name'), 'Alice');
      await tester.enterText(find.widgetWithText(TextField, 'Comment'), 'Hello');
      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();

      expect(find.text('Internal error'), findsOneWidget);
    });

    testWidgets('rate limit error shows friendly message', (tester) async {
      when(() => mockApi.post<Map<String, dynamic>>(
            any(),
            data: any(named: 'data'),
            cancelToken: any(named: 'cancelToken'),
          )).thenThrow(_rateLimitError());

      await tester.pumpWidget(_wrap(_update(), svc));
      await tester.pump();

      await tester.tap(find.text('Sprint 1 complete'));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextField, 'Your name'), 'Alice');
      await tester.enterText(find.widgetWithText(TextField, 'Comment'), 'Hello');
      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();

      expect(
        find.text('Too many comments. Please wait a few minutes and try again.'),
        findsOneWidget,
      );
    });

    testWidgets('network timeout shows generic error', (tester) async {
      when(() => mockApi.post<Map<String, dynamic>>(
            any(),
            data: any(named: 'data'),
            cancelToken: any(named: 'cancelToken'),
          )).thenThrow(_networkTimeout());

      await tester.pumpWidget(_wrap(_update(), svc));
      await tester.pump();

      await tester.tap(find.text('Sprint 1 complete'));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextField, 'Your name'), 'Alice');
      await tester.enterText(find.widgetWithText(TextField, 'Comment'), 'Hello');
      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();

      // Network errors have no response body → _mapDioError returns 'Request failed'.
      expect(find.text('Request failed'), findsOneWidget);
    });

    testWidgets('author name pre-filled from SharedPreferences', (tester) async {
      SharedPreferences.setMockInitialValues({'portal_author_name': 'Bob'});

      await tester.pumpWidget(_wrap(_update(), svc));
      await tester.pump();

      await tester.tap(find.text('Sprint 1 complete'));
      await tester.pumpAndSettle();

      final nameField = tester.widget<TextField>(
        find.widgetWithText(TextField, 'Your name'),
      );
      expect(nameField.controller?.text, 'Bob');
    });
  });
}
