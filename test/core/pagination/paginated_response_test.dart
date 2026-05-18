import 'package:cis_crm/core/pagination/paginated_response.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PaginatedResponse', () {
    test('hasMore is true when there are more pages', () {
      final response = PaginatedResponse<String>(
        items: List.generate(25, (i) => 'item_$i'),
        page: 1,
        perPage: 25,
        total: 100,
      );

      expect(response.hasMore, isTrue);
      expect(response.nextPage, equals(2));
    });

    test('hasMore is false on last page', () {
      final response = PaginatedResponse<String>(
        items: List.generate(10, (i) => 'item_$i'),
        page: 4,
        perPage: 25,
        total: 100,
      );

      expect(response.hasMore, isFalse);
    });

    test('hasMore is false when total equals items on single page', () {
      const response = PaginatedResponse<String>(
        items: ['a', 'b'],
        page: 1,
        perPage: 25,
        total: 2,
      );

      expect(response.hasMore, isFalse);
    });

    test('empty() creates an empty response', () {
      final response = PaginatedResponse.empty<String>();

      expect(response.items, isEmpty);
      expect(response.page, equals(1));
      expect(response.perPage, equals(25));
      expect(response.total, equals(0));
      expect(response.hasMore, isFalse);
    });

    test('equality works correctly', () {
      const a = PaginatedResponse<String>(
        items: ['x'],
        page: 1,
        perPage: 25,
        total: 1,
      );
      const b = PaginatedResponse<String>(
        items: ['x'],
        page: 1,
        perPage: 25,
        total: 1,
      );
      const c = PaginatedResponse<String>(
        items: ['x'],
        page: 2,
        perPage: 25,
        total: 1,
      );

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });
}
