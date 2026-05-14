import 'package:cis_crm/core/error/failures.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppFailure', () {
    test('NetworkFailure has default message', () {
      const f = NetworkFailure();
      expect(f.message, 'No internet connection.');
    });

    test('ServerFailure carries statusCode', () {
      const f = ServerFailure('error', statusCode: 500);
      expect(f.statusCode, 500);
      expect(f.props, ['error', 500]);
    });

    test('ValidationFailure carries fieldErrors', () {
      const f = ValidationFailure('bad input', fieldErrors: {'email': 'taken'});
      expect(f.fieldErrors, {'email': 'taken'});
    });

    test('Equatable works across subtypes', () {
      expect(const NetworkFailure(), equals(const NetworkFailure()));
      expect(
        const ServerFailure('a', statusCode: 1),
        equals(const ServerFailure('a', statusCode: 1)),
      );
    });
  });
}
