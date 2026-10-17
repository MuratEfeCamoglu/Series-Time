import 'package:flutter_test/flutter_test.dart';
import 'package:sezonluk/features/shows/data/models.dart';
import 'package:sezonluk/features/shows/logic.dart';

Season _season(int number) =>
    Season(id: number, showId: 1, seasonNumber: number);

Episode _episode({int season = 1, DateTime? airDate}) => Episode(
  id: 1,
  showId: 1,
  seasonNumber: season,
  episodeNumber: 1,
  airDate: airDate,
);

void main() {
  group('showRunStatus', () {
    test('bitmiş ve iptal edilmiş diziler "bitti"', () {
      expect(showRunStatus('Ended'), ShowRunStatus.ended);
      expect(showRunStatus('Canceled'), ShowRunStatus.ended);
    });

    test('yayında veya yapımda olanlar "devam ediyor"', () {
      expect(showRunStatus('Returning Series'), ShowRunStatus.ongoing);
      expect(showRunStatus('In Production'), ShowRunStatus.ongoing);
      expect(showRunStatus('Planned'), ShowRunStatus.ongoing);
    });

    test('bilinmeyen veya boş durum', () {
      expect(showRunStatus(null), ShowRunStatus.unknown);
      expect(showRunStatus('Başka'), ShowRunStatus.unknown);
    });
  });

  group('splitSeasons', () {
    test('sezon 0 özel bölümlere ayrılır, diğerleri artan sırada', () {
      final split = splitSeasons([_season(2), _season(0), _season(1)]);

      expect(split.regular.map((s) => s.seasonNumber), [1, 2]);
      expect(split.specials.map((s) => s.seasonNumber), [0]);
    });

    test('özel bölüm yoksa liste boş', () {
      expect(splitSeasons([_season(1)]).specials, isEmpty);
      expect(splitSeasons(const []).regular, isEmpty);
    });
  });

  group('isAired', () {
    final now = DateTime.utc(2026, 10, 17, 12);

    test('bugün ve geçmişte yayınlanan bölüm yayınlanmıştır', () {
      expect(
        isAired(_episode(airDate: DateTime.utc(2026, 10, 17)), now),
        isTrue,
      );
      expect(isAired(_episode(airDate: DateTime.utc(2020, 1, 1)), now), isTrue);
    });

    test('gelecekteki bölüm yayınlanmamıştır', () {
      expect(
        isAired(_episode(airDate: DateTime.utc(2026, 10, 18)), now),
        isFalse,
      );
    });

    test('tarihsiz bölüm yayınlanmamış sayılır (R6)', () {
      expect(isAired(_episode(), now), isFalse);
    });

    test('sezon 0 bölümü yayınlanmış sayılmaz', () {
      expect(
        isAired(_episode(season: 0, airDate: DateTime.utc(2020, 1, 1)), now),
        isFalse,
      );
    });

    test('karşılaştırma UTC tarihle yapılır', () {
      // UTC'de 17 Ekim 23:30, İstanbul'da 18 Ekim 02:30.
      final lateUtc = DateTime.utc(2026, 10, 17, 23, 30);
      expect(
        isAired(_episode(airDate: DateTime.utc(2026, 10, 18)), lateUtc),
        isFalse,
      );
    });
  });

  group('isReleased', () {
    final now = DateTime.utc(2026, 10, 17, 12);

    test('yayın tarihi geçmiş özel bölüm işaretlenebilir', () {
      expect(
        isReleased(_episode(season: 0, airDate: DateTime.utc(2020, 1, 1)), now),
        isTrue,
      );
    });

    test('gelecekteki ve tarihsiz bölüm işaretlenemez (F5d)', () {
      expect(
        isReleased(_episode(airDate: DateTime.utc(2026, 10, 18)), now),
        isFalse,
      );
      expect(isReleased(_episode(), now), isFalse);
    });
  });

  test('episodeLabel İzleme Listesi biçimi (F6b)', () {
    expect(episodeLabel(3, 7), 'S03 | B07');
  });

  test('episodeCode iki haneli doldurur', () {
    expect(episodeCode(1, 5), 'S01B05');
    expect(episodeCode(12, 103), 'S12B103');
  });
}
