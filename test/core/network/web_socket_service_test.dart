import 'dart:convert';

import 'package:cis_crm/core/network/token_storage.dart';
import 'package:cis_crm/core/network/web_socket_event.dart';
import 'package:cis_crm/core/network/web_socket_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockTokenStorage extends Mock implements TokenStorage {}

void main() {
  late _MockTokenStorage mockTokenStorage;
  late WebSocketService service;

  setUp(() {
    mockTokenStorage = _MockTokenStorage();
    service = WebSocketService(
      baseUrl: 'https://api.example.com',
      tokenStorage: mockTokenStorage,
    );
  });

  tearDown(() async {
    await service.dispose();
  });

  group('WebSocketService', () {
    group('buildUri', () {
      test('converts https base URL to wss scheme', () {
        final uri = service.buildUri('my-token');

        expect(uri.scheme, 'wss');
        expect(uri.host, 'api.example.com');
        expect(uri.path, '/api/ws');
        expect(uri.queryParameters['token'], 'my-token');
      });

      test('converts http base URL to ws scheme', () {
        final httpService = WebSocketService(
          baseUrl: 'http://localhost:8080',
          tokenStorage: mockTokenStorage,
        );
        addTearDown(httpService.dispose);

        final uri = httpService.buildUri('tok');

        expect(uri.scheme, 'ws');
        expect(uri.host, 'localhost');
        expect(uri.port, 8080);
        expect(uri.path, '/api/ws');
        expect(uri.queryParameters['token'], 'tok');
      });

      test('includes token as query parameter', () {
        final uri = service.buildUri('eyJhbGciOiJIUzI1NiJ9.test');

        expect(uri.queryParameters['token'], 'eyJhbGciOiJIUzI1NiJ9.test');
      });
    });

    group('backoffSeconds', () {
      test('returns 1 second for first attempt', () {
        expect(service.backoffSeconds(0), 1);
      });

      test('doubles each attempt', () {
        expect(service.backoffSeconds(0), 1); // 2^0
        expect(service.backoffSeconds(1), 2); // 2^1
        expect(service.backoffSeconds(2), 4); // 2^2
        expect(service.backoffSeconds(3), 8); // 2^3
      });

      test('caps at maxBackoffSeconds (30)', () {
        expect(service.backoffSeconds(5), 30); // 2^5 = 32 -> capped at 30
        expect(service.backoffSeconds(10), 30);
      });
    });

    group('connect', () {
      test('does not connect when token is null', () async {
        when(() => mockTokenStorage.readAccess()).thenAnswer((_) async => null);

        await service.connect();

        expect(service.isConnected, isFalse);
      });

      test('does not connect when token is empty', () async {
        when(() => mockTokenStorage.readAccess()).thenAnswer((_) async => '');

        await service.connect();

        expect(service.isConnected, isFalse);
      });
    });
  });

  group('WebSocketEvent', () {
    test('fromJson parses valid JSON', () {
      const raw = '{"type":"record.created","data":{"id":"123"}}';

      final event = WebSocketEvent.fromJson(raw);

      expect(event.type, 'record.created');
      expect(event.data, {'id': '123'});
    });

    test('fromJson defaults missing type to empty string', () {
      const raw = '{"data":{"id":"1"}}';

      final event = WebSocketEvent.fromJson(raw);

      expect(event.type, '');
      expect(event.data, {'id': '1'});
    });

    test('fromJson defaults missing data to empty map', () {
      const raw = '{"type":"task.assigned"}';

      final event = WebSocketEvent.fromJson(raw);

      expect(event.type, 'task.assigned');
      expect(event.data, isEmpty);
    });

    test('fromJson throws on invalid JSON', () {
      expect(
        () => WebSocketEvent.fromJson('not json'),
        throwsA(isA<FormatException>()),
      );
    });

    test('toString includes type and data', () {
      final event = WebSocketEvent.fromJson(
        jsonEncode({'type': 'email.received', 'data': <String, dynamic>{}}),
      );

      expect(event.toString(), contains('email.received'));
    });
  });
}
