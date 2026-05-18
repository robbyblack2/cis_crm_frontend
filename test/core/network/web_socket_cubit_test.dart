import 'dart:async';

import 'package:cis_crm/core/network/web_socket_cubit.dart';
import 'package:cis_crm/core/network/web_socket_event.dart';
import 'package:cis_crm/core/network/web_socket_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockWebSocketService extends Mock implements WebSocketService {}

void main() {
  late _MockWebSocketService mockService;
  late StreamController<WebSocketEvent> eventController;

  setUp(() {
    mockService = _MockWebSocketService();
    eventController = StreamController<WebSocketEvent>.broadcast();

    when(() => mockService.events)
        .thenAnswer((_) => eventController.stream);
    when(() => mockService.isConnected).thenReturn(false);
    when(() => mockService.connect()).thenAnswer((_) async {});
    when(() => mockService.disconnect()).thenAnswer((_) async {});
    when(() => mockService.subscribe(any())).thenReturn(null);
    when(() => mockService.unsubscribe(any())).thenReturn(null);
  });

  tearDown(() async {
    if (!eventController.isClosed) {
      await eventController.close();
    }
  });

  group('WebSocketCubit', () {
    test('initial state is disconnected', () {
      final cubit = WebSocketCubit(mockService);
      expect(cubit.state, WebSocketStatus.disconnected);
      addTearDown(cubit.close);
    });

    test(
      'connect emits connecting then connected on event',
      () async {
        final cubit = WebSocketCubit(mockService);
        addTearDown(cubit.close);

        final states = <WebSocketStatus>[];
        final sub = cubit.stream.listen(states.add);

        await cubit.connect();
        eventController.add(
          const WebSocketEvent(type: 'record.created', data: {}),
        );
        await Future<void>.delayed(Duration.zero);

        expect(states, [
          WebSocketStatus.connecting,
          WebSocketStatus.connected,
        ]);

        await sub.cancel();
      },
    );

    test(
      'connect emits connecting then connected '
      'when isConnected is true',
      () async {
        when(() => mockService.isConnected).thenReturn(true);
        final cubit = WebSocketCubit(mockService);
        addTearDown(cubit.close);

        final states = <WebSocketStatus>[];
        final sub = cubit.stream.listen(states.add);

        await cubit.connect();
        await Future<void>.delayed(Duration.zero);

        expect(states, [
          WebSocketStatus.connecting,
          WebSocketStatus.connected,
        ]);

        await sub.cancel();
      },
    );

    test('disconnect emits disconnected', () async {
      final cubit = WebSocketCubit(mockService);
      addTearDown(cubit.close);

      // Move to connected first.
      await cubit.connect();
      when(() => mockService.isConnected).thenReturn(true);
      eventController.add(
        const WebSocketEvent(type: 'ping', data: {}),
      );
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state, WebSocketStatus.connected);

      await cubit.disconnect();

      expect(cubit.state, WebSocketStatus.disconnected);
      verify(() => mockService.disconnect()).called(1);
    });

    test(
      'emits disconnected when event stream completes',
      () async {
        final cubit = WebSocketCubit(mockService);
        addTearDown(cubit.close);

        await cubit.connect();
        expect(cubit.state, WebSocketStatus.connecting);

        await eventController.close();
        await Future<void>.delayed(Duration.zero);

        expect(cubit.state, WebSocketStatus.disconnected);
      },
    );

    test('subscribe delegates to service', () {
      final cubit = WebSocketCubit(mockService);
      addTearDown(cubit.close);

      cubit.subscribe('pipeline:abc-123');

      verify(
        () => mockService.subscribe('pipeline:abc-123'),
      ).called(1);
    });

    test('unsubscribe delegates to service', () {
      final cubit = WebSocketCubit(mockService);
      addTearDown(cubit.close);

      cubit.unsubscribe('pipeline:abc-123');

      verify(
        () => mockService.unsubscribe('pipeline:abc-123'),
      ).called(1);
    });

    test('events stream mirrors service events', () async {
      final cubit = WebSocketCubit(mockService);
      addTearDown(cubit.close);

      const expected = WebSocketEvent(
        type: 'record.updated',
        data: {'id': '1'},
      );

      final future = expectLater(
        cubit.events,
        emits(
          predicate<WebSocketEvent>(
            (e) =>
                e.type == 'record.updated' &&
                e.data['id'] == '1',
          ),
        ),
      );

      eventController.add(expected);
      await future;
    });

    test('close disconnects the service', () async {
      final cubit = WebSocketCubit(mockService);

      await cubit.close();

      verify(() => mockService.disconnect()).called(1);
    });
  });

  group('WebSocketEvent.fromJson with event key', () {
    test('parses event key from protocol format', () {
      const raw =
          '{"event":"record.created","data":{"id":"123"}}';
      final event = WebSocketEvent.fromJson(raw);

      expect(event.type, 'record.created');
      expect(event.data, {'id': '123'});
    });

    test('falls back to type key when event is absent', () {
      const raw =
          '{"type":"record.updated","data":{"id":"456"}}';
      final event = WebSocketEvent.fromJson(raw);

      expect(event.type, 'record.updated');
      expect(event.data, {'id': '456'});
    });

    test('prefers event key over type key', () {
      const raw = '{"event":"record.moved",'
          '"type":"ignored","data":{"id":"789"}}';
      final event = WebSocketEvent.fromJson(raw);

      expect(event.type, 'record.moved');
    });
  });
}
