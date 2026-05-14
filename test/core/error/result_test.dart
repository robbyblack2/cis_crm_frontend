import 'package:cis_crm/core/error/result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Result', () {
    test('Success carries data', () {
      const result = Success<int, String>(42);
      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
      expect(result.dataOrNull, 42);
      expect(result.failureOrNull, isNull);
    });

    test('Failure carries error', () {
      const result = Failure<int, String>('oops');
      expect(result.isFailure, isTrue);
      expect(result.isSuccess, isFalse);
      expect(result.failureOrNull, 'oops');
      expect(result.dataOrNull, isNull);
    });

    test('Success equality', () {
      expect(
        const Success<int, String>(1),
        equals(const Success<int, String>(1)),
      );
      expect(
        const Success<int, String>(1),
        isNot(equals(const Success<int, String>(2))),
      );
    });

    test('Failure equality', () {
      expect(
        const Failure<int, String>('a'),
        equals(const Failure<int, String>('a')),
      );
    });
  });
}
