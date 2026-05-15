import 'package:cis_crm/core/error/exceptions.dart';
import 'package:cis_crm/features/files/data/datasources/file_remote_datasource.dart';
import 'package:cis_crm/features/files/data/models/file_attachment_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late FileRemoteDatasourceImpl datasource;

  final tJson = <String, dynamic>{
    'id': '1',
    'filename': 'test.pdf',
    'content_type': 'application/pdf',
    'size_bytes': 1024,
    's3_key': 'files/1/test.pdf',
    'content_hash': 'abc123',
    'parent_type': 'contact',
    'parent_id': 'c1',
    'uploaded_by': 'u1',
    'created_at': '2026-01-01T00:00:00.000Z',
  };

  setUp(() {
    mockDio = MockDio();
    datasource = FileRemoteDatasourceImpl(dio: mockDio);
  });

  group('getMetadata', () {
    test('returns FileAttachmentModel on success', () async {
      when(() => mockDio.get<Map<String, dynamic>>(any())).thenAnswer(
        (_) async => Response(
          data: tJson,
          statusCode: 200,
          requestOptions: RequestOptions(),
        ),
      );

      final result = await datasource.getMetadata('1');

      expect(result, isA<FileAttachmentModel>());
      expect(result.id, '1');
      expect(result.filename, 'test.pdf');
    });

    test('throws ServerException on DioException without AppException', () {
      when(() => mockDio.get<Map<String, dynamic>>(any())).thenThrow(
        DioException(
          requestOptions: RequestOptions(),
          message: 'not found',
        ),
      );

      expect(
        () => datasource.getMetadata('1'),
        throwsA(isA<ServerException>()),
      );
    });

    test('rethrows AppException from DioException.error', () {
      when(() => mockDio.get<Map<String, dynamic>>(any())).thenThrow(
        DioException(
          requestOptions: RequestOptions(),
          error: const UnauthorizedException(),
        ),
      );

      expect(
        () => datasource.getMetadata('1'),
        throwsA(isA<UnauthorizedException>()),
      );
    });
  });

  group('delete', () {
    test('completes on success', () async {
      when(() => mockDio.delete<void>(any())).thenAnswer(
        (_) async => Response(
          statusCode: 204,
          requestOptions: RequestOptions(),
        ),
      );

      await expectLater(datasource.delete('1'), completes);
    });

    test('throws ServerException on failure', () {
      when(() => mockDio.delete<void>(any())).thenThrow(
        DioException(
          requestOptions: RequestOptions(),
          message: 'server error',
        ),
      );

      expect(
        () => datasource.delete('1'),
        throwsA(isA<ServerException>()),
      );
    });
  });

  group('download', () {
    test('returns bytes on success', () async {
      when(
        () => mockDio.get<List<int>>(
          any(),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: [1, 2, 3],
          statusCode: 200,
          requestOptions: RequestOptions(),
        ),
      );

      final result = await datasource.download('1');

      expect(result, [1, 2, 3]);
    });
  });

  group('getPreviewUrl', () {
    test('returns url string on success', () async {
      when(() => mockDio.get<Map<String, dynamic>>(any())).thenAnswer(
        (_) async => Response(
          data: <String, dynamic>{'url': 'https://example.com/preview'},
          statusCode: 200,
          requestOptions: RequestOptions(),
        ),
      );

      final result = await datasource.getPreviewUrl('1');

      expect(result, 'https://example.com/preview');
    });
  });
}
