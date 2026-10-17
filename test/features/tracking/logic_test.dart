import 'package:flutter_test/flutter_test.dart';
import 'package:sezonluk/features/shows/data/models.dart';
import 'package:sezonluk/features/tracking/data/models.dart';
import 'package:sezonluk/features/tracking/logic.dart';

final _now = DateTime.utc(2026, 10, 17, 12);

WatchlistItem _item(int showId, {DateTime? lastWatchedAt, DateTime? addedAt}) =>
    WatchlistItem(
      showId: showId,
      name: 'Dizi $showId',
      addedAt: addedAt ?? DateTime.utc(2026, 1, 1),
      lastWatchedAt: lastWatchedAt,
      nextEpisodeId: showId * 100,
      nextSeasonNumber: 1,
      nextEpisodeNumber: 1,
      airedCount: 10,
      watchedCount: 0,
    );

Episode _episode(int number, {int season = 1, DateTime? airDate}) => Episode(
  id: season * 100 + number,
  showId: 1,
  seasonNumber: season,
  episodeNumber: number,
  airDate: airDate,
);

UpcomingEpisode _upcoming(int id, DateTime airDate) => UpcomingEpisode(
  episodeId: id,
  showId: 1,
  showName: 'Dizi',
  seasonNumber: 1,
  episodeNumber: id,
  airDate: airDate,
);

void main() {
  group('watchProgress', () {
    test('izlenen / yayınlanan', () {
      expect(watchProgress(3, 4), 0.75);
    });

    test('yayınlanmış bölüm yoksa 0 (boş dizi)', () {
      expect(watchProgress(0, 0), 0);
    });

    test('1\'i aşmaz', () {
      expect(watchProgress(5, 4), 1);
    });
  });

  group('sortWatchlist (F6g)', () {
    test('hiç izlenmemişler eklenme tarihine göre azalan, en üstte', () {
      final sorted = sortWatchlist([
        _item(1, lastWatchedAt: DateTime.utc(2026, 10, 16)),
        _item(2, addedAt: DateTime.utc(2026, 5, 1)),
        _item(3, lastWatchedAt: DateTime.utc(2026, 10, 10)),
        _item(4, addedAt: DateTime.utc(2026, 6, 1)),
      ]);

      expect(sorted.map((i) => i.showId), [4, 2, 1, 3]);
    });
  });

  group('splitWatchlist (F6a, F6e)', () {
    test('başlanmamış, son 30 gün ve daha eski ayrı bölümlere gider', () {
      final split = splitWatchlist([
        _item(1, lastWatchedAt: _now.subtract(const Duration(days: 30))),
        _item(2, lastWatchedAt: _now.subtract(const Duration(days: 31))),
        _item(3),
      ], _now);

      expect(split.upNext.map((i) => i.showId), [1]);
      expect(split.notStarted.map((i) => i.showId), [3]);
      expect(split.notRecently.map((i) => i.showId), [2]);
    });

    test('boş liste', () {
      final split = splitWatchlist(const [], _now);
      expect(split.upNext, isEmpty);
      expect(split.notStarted, isEmpty);
      expect(split.notRecently, isEmpty);
    });
  });

  group('kart ayrıntıları (F6b)', () {
    test('sıradakinden sonra kalan bölüm sayısı', () {
      expect(remainingAfterNext(_item(1)), 9); // 10 yayınlanmış, 0 izlenmiş
      final last = WatchlistItem(
        showId: 1,
        name: 'D',
        addedAt: DateTime.utc(2026),
        nextEpisodeId: 1,
        nextSeasonNumber: 1,
        nextEpisodeNumber: 10,
        airedCount: 10,
        watchedCount: 9,
      );
      expect(remainingAfterNext(last), 0);
    });

    test('sezon başı yalnızca ilk bölüm', () {
      expect(isSeasonPremiere(1), isTrue);
      expect(isSeasonPremiere(2), isFalse);
    });
  });

  group('dizi detayı bölümler sekmesi', () {
    final past = DateTime.utc(2026, 10, 1);
    final episodes = [
      _episode(2, airDate: past),
      _episode(1, airDate: past),
      _episode(3, airDate: DateTime.utc(2026, 11, 1)),
      _episode(1, season: 0, airDate: past),
    ];

    test('sıradaki: izlenmemiş ilk yayınlanmış normal bölüm', () {
      expect(nextUnwatchedEpisode(episodes, {}, _now)?.id, 101);
      expect(nextUnwatchedEpisode(episodes, {101}, _now)?.id, 102);
    });

    test('hepsi izlendiyse sıradaki yok (gelecek ve özel bölüm sayılmaz)', () {
      expect(nextUnwatchedEpisode(episodes, {101, 102}, _now), isNull);
    });

    test('sezon ilerlemesi yayınlanmış bölümlerden', () {
      final season1 = episodes.where((e) => e.seasonNumber == 1).toList();
      expect(seasonProgress(season1, {101}, _now), (watched: 1, released: 2));
    });
  });

  group('Yaklaşan (F7)', () {
    test('bugün, yarın ve sonrası', () {
      expect(
        upcomingDayKind(DateTime.utc(2026, 10, 17), _now),
        UpcomingDay.today,
      );
      expect(
        upcomingDayKind(DateTime.utc(2026, 10, 18), _now),
        UpcomingDay.tomorrow,
      );
      expect(
        upcomingDayKind(DateTime.utc(2026, 10, 19), _now),
        UpcomingDay.later,
      );
    });

    test('aynı güne düşen bölümler tek grupta, gruplar artan tarihte', () {
      final groups = groupUpcoming([
        _upcoming(3, DateTime.utc(2026, 10, 20)),
        _upcoming(1, DateTime.utc(2026, 10, 18)),
        _upcoming(2, DateTime.utc(2026, 10, 18)),
      ]);

      expect(groups.map((g) => g.date), [
        DateTime.utc(2026, 10, 18),
        DateTime.utc(2026, 10, 20),
      ]);
      expect(groups.first.episodes.map((e) => e.episodeId), [1, 2]);
    });

    test('boş liste boş grup verir', () {
      expect(groupUpcoming(const []), isEmpty);
    });
  });

  group('iyimser işaretleme kümeleri (F5b, F5c, F5d)', () {
    final past = DateTime.utc(2026, 10, 1);
    final future = DateTime.utc(2026, 11, 1);
    final season = [
      _episode(1, airDate: past),
      _episode(2, airDate: past),
      _episode(3, airDate: future),
      _episode(4),
    ];

    test('sezonun tamamı: yalnızca yayınlanmış bölümler', () {
      expect(markableEpisodeIds(season, _now), {101, 102});
    });

    test('buraya kadar: hedef ve önceki yayınlanmışlar', () {
      expect(episodeIdsUntil(season, season[1], _now), {101, 102});
      expect(episodeIdsUntil(season, season[0], _now), {101});
    });

    test('buraya kadar: gelecekteki hedefte yalnızca yayınlanmışlar', () {
      expect(episodeIdsUntil(season, season[2], _now), {101, 102});
    });

    test('özel bölümde buraya kadar yalnızca kendisi', () {
      final special = _episode(5, season: 0, airDate: past);
      expect(episodeIdsUntil([special], special, _now), {special.id});
    });
  });

  group('durum grupları (F6j)', () {
    ShowStatus auto(String? tmdb, int aired, int watched) => autoShowStatus(
      tmdbStatus: tmdb,
      airedCount: aired,
      watchedCount: watched,
    );

    test('hiç izlenmemiş → İzleme Listesi', () {
      expect(auto('Ended', 10, 0), ShowStatus.watchlist);
    });

    test(
      'yayınlanmış bölümü yok (gelecek/sezon 0 sayılmaz) → İzleme Listesi',
      () {
        expect(auto('Returning Series', 0, 0), ShowStatus.watchlist);
      },
    );

    test('kısmen izlenmiş → Devam ediyor', () {
      expect(auto('Ended', 10, 4), ShowStatus.watching);
      expect(auto('Returning Series', 10, 9), ShowStatus.watching);
    });

    test('bitmiş dizinin hepsi izlendi → Bitti', () {
      expect(auto('Ended', 10, 10), ShowStatus.finished);
      expect(auto('Canceled', 3, 3), ShowStatus.finished);
    });

    test('yayını süren dizinin yayınlananların hepsi izlendi → Güncel', () {
      expect(auto('Returning Series', 10, 10), ShowStatus.upToDate);
      expect(auto('In Production', 1, 1), ShowStatus.upToDate);
    });

    test('TMDB durumu boş ve hepsi izlendi → Güncel', () {
      expect(auto(null, 5, 5), ShowStatus.upToDate);
    });

    test('elle seçim otomatiğin önüne geçer', () {
      expect(
        effectiveShowStatus(
          manual: ManualShowStatus.paused,
          auto: ShowStatus.watching,
        ),
        ShowStatus.paused,
      );
      expect(
        effectiveShowStatus(
          manual: ManualShowStatus.dropped,
          auto: ShowStatus.finished,
        ),
        ShowStatus.dropped,
      );
      expect(
        effectiveShowStatus(
          manual: ManualShowStatus.planned,
          auto: ShowStatus.watching,
        ),
        ShowStatus.watchlist,
      );
      expect(
        effectiveShowStatus(manual: null, auto: ShowStatus.upToDate),
        ShowStatus.upToDate,
      );
    });

    test('çubuk doluluğu gruba göre', () {
      expect(statusProgress(ShowStatus.watchlist, 3, 10), 0);
      expect(statusProgress(ShowStatus.finished, 10, 10), 1);
      expect(statusProgress(ShowStatus.upToDate, 4, 4), 1);
      expect(statusProgress(ShowStatus.watching, 4, 8), 0.5);
      expect(statusProgress(ShowStatus.paused, 2, 8), 0.25);
      expect(statusProgress(ShowStatus.dropped, 1, 4), 0.25);
    });

    test('menü seçimi → kaydedilecek elle grup', () {
      expect(manualFor(ShowStatus.paused), ManualShowStatus.paused);
      expect(manualFor(ShowStatus.dropped), ManualShowStatus.dropped);
      expect(manualFor(ShowStatus.watchlist), ManualShowStatus.planned);
      expect(manualFor(null), isNull);
    });

    test('gruba göre filtre', () {
      ShowProgress show(
        int id,
        int aired,
        int watched, {
        ManualShowStatus? manual,
      }) => ShowProgress(
        showId: id,
        name: 'D$id',
        addedAt: DateTime.utc(2026),
        airedCount: aired,
        watchedCount: watched,
        showStatus: 'Ended',
        manualStatus: manual,
      );
      final shows = [
        show(1, 10, 10),
        show(2, 10, 3),
        show(3, 10, 3, manual: ManualShowStatus.dropped),
        show(4, 10, 0),
      ];
      expect(filterByStatus(shows, null).length, 4);
      expect(filterByStatus(shows, ShowStatus.finished).map((s) => s.showId), [
        1,
      ]);
      expect(filterByStatus(shows, ShowStatus.watching).map((s) => s.showId), [
        2,
      ]);
      expect(filterByStatus(shows, ShowStatus.dropped).map((s) => s.showId), [
        3,
      ]);
      expect(filterByStatus(shows, ShowStatus.watchlist).map((s) => s.showId), [
        4,
      ]);
    });
  });
}
