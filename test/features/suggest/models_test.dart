import 'package:flutter_test/flutter_test.dart';
import 'package:sezonluk/features/suggest/data/models.dart';

void main() {
  test('Genre.fromJson genres kolonlarını ayrıştırır', () {
    final genre = Genre.fromJson({
      'id': 18,
      'name': 'Dram',
      'last_synced_at': '2026-10-17T00:00:00Z',
    });

    expect(genre.id, 18);
    expect(genre.name, 'Dram');
  });
}
