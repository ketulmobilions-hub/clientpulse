import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:clientpulse/shared/services/api_service.dart';
import 'package:clientpulse/shared/services/storage_service.dart';

class _MockApiService extends Mock implements ApiService {}

class _MockHttpClient extends Mock implements http.Client {}

class _FakeStreamedResponse extends Fake implements http.StreamedResponse {
  _FakeStreamedResponse(int statusCode)
      : statusCode = statusCode,
        stream = http.ByteStream.fromBytes([]);

  @override
  final int statusCode;

  @override
  final http.ByteStream stream;
}

void main() {
  late _MockApiService api;
  late _MockHttpClient httpClient;
  late StorageService sut;

  const updateId = 'update-abc';
  const fileName = 'report.pdf';
  const mimeType = 'application/pdf';
  final bytes = Uint8List.fromList(List.filled(100, 0));

  final signedUrlResponse = _makeApiResponse({
    'data': {
      'signedUrl': 'https://storage.example.com/signed?token=x',
      'publicUrl': 'https://storage.example.com/public/report.pdf',
      'path': 'attachments/update-abc/report.pdf',
    },
  });

  final saveAttachmentResponse = _makeApiResponse({
    'data': {
      'attachment': {
        'id': 'att-1',
        'update_id': updateId,
        'file_name': fileName,
        'file_url': 'https://storage.example.com/public/report.pdf',
        'file_size': 100,
        'mime_type': mimeType,
        'uploaded_by': 'user-1',
        'created_at': '2026-01-01T00:00:00Z',
      },
    },
  });

  setUp(() {
    api = _MockApiService();
    httpClient = _MockHttpClient();
    sut = StorageService(api, httpClient: httpClient);

    registerFallbackValue(Uri.parse('https://example.com'));
    registerFallbackValue(http.StreamedRequest('PUT', Uri.parse('https://example.com')));
  });

  group('uploadAttachment — happy path', () {
    setUp(() {
      when(() => api.post<Map<String, dynamic>>(
            '/updates/$updateId/attachments/signed-url',
            data: any(named: 'data'),
          )).thenAnswer((_) async => signedUrlResponse);

      when(() => httpClient.send(any())).thenAnswer((_) async =>
          _FakeStreamedResponse(200));

      when(() => api.post<Map<String, dynamic>>(
            '/updates/$updateId/attachments',
            data: any(named: 'data'),
          )).thenAnswer((_) async => saveAttachmentResponse);
    });

    test('returns Attachment with correct fields', () async {
      final result = await sut.uploadAttachment(
        updateId: updateId,
        fileName: fileName,
        bytes: bytes,
        mimeType: mimeType,
      );

      expect(result.id, 'att-1');
      expect(result.updateId, updateId);
      expect(result.fileName, fileName);
      expect(result.fileUrl, 'https://storage.example.com/public/report.pdf');
    });

    test('calls all 3 API steps in order', () async {
      await sut.uploadAttachment(
        updateId: updateId,
        fileName: fileName,
        bytes: bytes,
        mimeType: mimeType,
      );

      verifyInOrder([
        () => api.post<Map<String, dynamic>>(
              '/updates/$updateId/attachments/signed-url',
              data: any(named: 'data'),
            ),
        () => httpClient.send(any()),
        () => api.post<Map<String, dynamic>>(
              '/updates/$updateId/attachments',
              data: any(named: 'data'),
            ),
      ]);
    });

    test('onProgress called with increasing values ending at 1.0', () async {
      final progress = <double>[];

      await sut.uploadAttachment(
        updateId: updateId,
        fileName: fileName,
        bytes: bytes,
        mimeType: mimeType,
        onProgress: progress.add,
      );

      expect(progress, isNotEmpty);
      expect(progress.last, 1.0);
      for (var i = 1; i < progress.length; i++) {
        expect(progress[i], greaterThanOrEqualTo(progress[i - 1]));
      }
    });

    test('onProgress reports intermediate values for multi-chunk payload', () async {
      // 200 KB = 3 full 64 KB chunks + 1 partial (8 KB) = 4 onProgress calls.
      final largeBytes = Uint8List(200 * 1024);
      final progress = <double>[];

      await sut.uploadAttachment(
        updateId: updateId,
        fileName: fileName,
        bytes: largeBytes,
        mimeType: mimeType,
        onProgress: progress.add,
      );

      expect(progress.length, greaterThan(1));
      expect(progress.last, 1.0);
      expect(progress.first, lessThan(1.0));
      for (var i = 1; i < progress.length; i++) {
        expect(progress[i], greaterThanOrEqualTo(progress[i - 1]));
      }
    });
  });

  group('uploadAttachment — oversized file', () {
    test('throws before calling backend', () async {
      final bigBytes = Uint8List(11 * 1024 * 1024);

      await expectLater(
        () => sut.uploadAttachment(
          updateId: updateId,
          fileName: 'big.pdf',
          bytes: bigBytes,
          mimeType: mimeType,
        ),
        throwsA(
          isA<StorageServiceException>()
              .having((e) => e.message, 'message', contains('10 MB')),
        ),
      );

      verifyNever(() => api.post<Map<String, dynamic>>(any(), data: any(named: 'data')));
    });
  });

  group('uploadAttachment — signed URL request fails', () {
    test('throws StorageServiceException, no PUT attempted', () async {
      when(() => api.post<Map<String, dynamic>>(
            '/updates/$updateId/attachments/signed-url',
            data: any(named: 'data'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(),
        response: Response(
          requestOptions: RequestOptions(),
          statusCode: 403,
          data: {'error': 'Forbidden'},
        ),
      ));

      await expectLater(
        () => sut.uploadAttachment(
          updateId: updateId,
          fileName: fileName,
          bytes: bytes,
          mimeType: mimeType,
        ),
        throwsA(isA<StorageServiceException>()),
      );

      verifyNever(() => httpClient.send(any()));
    });
  });

  group('uploadAttachment — PUT to Supabase fails', () {
    test('throws StorageServiceException with status code', () async {
      when(() => api.post<Map<String, dynamic>>(
            '/updates/$updateId/attachments/signed-url',
            data: any(named: 'data'),
          )).thenAnswer((_) async => signedUrlResponse);

      when(() => httpClient.send(any())).thenAnswer((_) async =>
          _FakeStreamedResponse(403));

      await expectLater(
        () => sut.uploadAttachment(
          updateId: updateId,
          fileName: fileName,
          bytes: bytes,
          mimeType: mimeType,
        ),
        throwsA(
          isA<StorageServiceException>()
              .having((e) => e.message, 'message', contains('403')),
        ),
      );

      verifyNever(() => api.post<Map<String, dynamic>>(
            '/updates/$updateId/attachments',
            data: any(named: 'data'),
          ));
    });
  });

  group('uploadAttachment — save metadata fails', () {
    test('throws StorageServiceException after successful PUT', () async {
      when(() => api.post<Map<String, dynamic>>(
            '/updates/$updateId/attachments/signed-url',
            data: any(named: 'data'),
          )).thenAnswer((_) async => signedUrlResponse);

      when(() => httpClient.send(any())).thenAnswer((_) async =>
          _FakeStreamedResponse(200));

      when(() => api.post<Map<String, dynamic>>(
            '/updates/$updateId/attachments',
            data: any(named: 'data'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(),
        response: Response(
          requestOptions: RequestOptions(),
          statusCode: 409,
          data: {'error': {'message': 'Max 3 attachments'}},
        ),
      ));

      await expectLater(
        () => sut.uploadAttachment(
          updateId: updateId,
          fileName: fileName,
          bytes: bytes,
          mimeType: mimeType,
        ),
        throwsA(
          isA<StorageServiceException>()
              .having((e) => e.message, 'message', 'Max 3 attachments'),
        ),
      );
    });
  });

  group('deleteAttachment', () {
    test('succeeds when API returns 200', () async {
      when(() => api.delete<void>('/attachments/att-1'))
          .thenAnswer((_) async => Response(
                requestOptions: RequestOptions(),
                statusCode: 200,
              ));

      await expectLater(
        sut.deleteAttachment('att-1'),
        completes,
      );
    });

    test('wraps DioException as StorageServiceException', () async {
      when(() => api.delete<void>('/attachments/att-1'))
          .thenThrow(DioException(
        requestOptions: RequestOptions(),
        response: Response(
          requestOptions: RequestOptions(),
          statusCode: 404,
          data: {'error': {'message': 'Attachment not found'}},
        ),
      ));

      await expectLater(
        sut.deleteAttachment('att-1'),
        throwsA(
          isA<StorageServiceException>()
              .having((e) => e.message, 'message', 'Attachment not found'),
        ),
      );
    });

    test('wraps generic exception as StorageServiceException', () async {
      when(() => api.delete<void>('/attachments/att-1'))
          .thenThrow(Exception('network failure'));

      await expectLater(
        sut.deleteAttachment('att-1'),
        throwsA(isA<StorageServiceException>()),
      );
    });
  });
}

Response<Map<String, dynamic>> _makeApiResponse(Map<String, dynamic> body) =>
    Response(
      requestOptions: RequestOptions(),
      statusCode: 200,
      data: body,
    );
