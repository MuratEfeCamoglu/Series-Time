import 'package:flutter_test/flutter_test.dart';
import 'package:sezonluk/features/shows/data/models.dart';
import 'package:sezonluk/features/suggest/logic.dart';

UserShow _entry(int id, {DateTime? lastWatchedAt}) => UserShow(
  show: Show(id: id, name: 'Dizi $id'),
  addedAt: DateTime.utc(2026, 1, 1),
  lastWatchedAt: lastWatchedAt,
);

void main() {
  group('toggleGenre (F18b)', () {
    test('seçili olmayan tür eklenir, seçili tür kaldırılır', () {
      expect(toggleGenre({18}, 35).selection, {18, 35});
      expect(toggleGenre({18, 35}, 18).selection, {35});
      expect(toggleGenre({18}, 18).selection, isEmpty);
    });

    test('4. seçim eklenmez ve reddedildi bilgisi döner', () {
      final result = toggleGenre({18, 35, 80}, 99);
      expect(result.rejected, isTrue);
      expect(result.selection, {18, 35, 80});
    });

    test('3 tür seçiliyken biri kaldırılabilir', () {
      final result = toggleGenre({18, 35, 80}, 80);
      expect(result.rejected, isFalse);
      expect(result.selection, {18, 35});
    });
  });

  group('defaultGenreSelection (F18c)', () {
    test('saklanan seçim önce gelir', () {
      expect(defaultGenreSelection(stored: [80], topGenres: [18, 35]), {80});
    });

    test('saklanan boş seçim de korunur', () {
      expect(defaultGenreSelection(stored: [], topGenres: [18]), isEmpty);
    });

    test('saklanan yoksa en sık 3 tür', () {
      expect(defaultGenreSelection(stored: null, topGenres: [18, 35, 80, 99]), {
        18,
        35,
        80,
      });
    });

    test('liste boşsa hiçbiri', () {
      expect(defaultGenreSelection(stored: null, topGenres: []), isEmpty);
    });
  });

  test('withoutShows listedeki dizileri ayıklar (F18e)', () {
    final results = [
      const Show(id: 1, name: 'A'),
      const Show(id: 2, name: 'B'),
    ];
    expect(withoutShows(results, {1}).map((s) => s.id), [2]);
  });

  group('lastWatchedShow (F18f)', () {
    test('en son izlenen dizi', () {
      final show = lastWatchedShow([
        _entry(1, lastWatchedAt: DateTime.utc(2026, 10, 1)),
        _entry(2, lastWatchedAt: DateTime.utc(2026, 10, 10)),
        _entry(3),
      ]);
      expect(show?.id, 2);
    });

    test('hiç bölüm izlenmemişse null', () {
      expect(lastWatchedShow([_entry(1)]), isNull);
      expect(lastWatchedShow(const []), isNull);
    });
  });

  test('tür adı İngilizce arayüzde TMDB İngilizce adıyla (F21b)', () {
    expect(genreLabel(id: 18, cachedName: 'Dram', english: true), 'Drama');
    expect(genreLabel(id: 18, cachedName: 'Dram', english: false), 'Dram');
    expect(genreLabel(id: 1, cachedName: 'Yeni', english: true), 'Yeni');
  });
}
