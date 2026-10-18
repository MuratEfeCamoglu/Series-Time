import 'package:flutter_test/flutter_test.dart';
import 'package:sezonluk/features/profile/data/models.dart';
import 'package:sezonluk/features/profile/logic.dart';
import 'package:sezonluk/features/shows/data/models.dart';

void main() {
  test('isValidDisplayName 1–40 karakter ister (F2)', () {
    expect(isValidDisplayName(''), isFalse);
    expect(isValidDisplayName('   '), isFalse);
    expect(isValidDisplayName('A'), isTrue);
    expect(isValidDisplayName('a' * 40), isTrue);
    expect(isValidDisplayName('a' * 41), isFalse);
  });

  test('emoji kod noktası olarak sayılır (Postgres char_length ile aynı)', () {
    // Her 😀 UTF-16'da 2 birimdir; 40 emoji yine de 40 karakterdir.
    expect(isValidDisplayName('😀' * 40), isTrue);
    expect(isValidBio('😀' * 160), isTrue);
    expect(isValidBio('😀' * 161), isFalse);
  });

  test('isValidBio en fazla 160 karakter (F2)', () {
    expect(isValidBio(''), isTrue);
    expect(isValidBio('a' * 160), isTrue);
    expect(isValidBio('a' * 161), isFalse);
  });

  test('isValidAvatarSize 2 MB sınırı (F2)', () {
    expect(isValidAvatarSize(2 * 1024 * 1024), isTrue);
    expect(isValidAvatarSize(2 * 1024 * 1024 + 1), isFalse);
  });

  test('countryFlag ISO kodunu bayrak emojisine çevirir', () {
    expect(countryFlag('TR'), '🇹🇷');
    expect(countryFlag('de'), '🇩🇪');
  });

  group('isoCountryCodes', () {
    test('249 benzersiz, sıralı, iki büyük harfli kod içerir', () {
      expect(isoCountryCodes, hasLength(249));
      expect(isoCountryCodes.toSet(), hasLength(249));
      expect(isoCountryCodes, everyElement(matches(RegExp(r'^[A-Z]{2}$'))));
      expect([...isoCountryCodes]..sort(), isoCountryCodes);
    });

    test('filterCountryCodes önek eşleşmesi yapar', () {
      expect(filterCountryCodes(''), isoCountryCodes);
      expect(filterCountryCodes(' tr '), ['TR']);
      expect(filterCountryCodes('t'), everyElement(startsWith('T')));
      expect(filterCountryCodes('qq'), isEmpty);
    });
  });

  group('splitWatchTime (F8d, V15)', () {
    test('0 dk', () {
      expect(splitWatchTime(0), (months: 0, days: 0, hours: 0));
    });

    test('59 dk bir saatten azdır', () {
      expect(splitWatchTime(59), (months: 0, days: 0, hours: 0));
    });

    test('1 gün', () {
      expect(splitWatchTime(24 * 60), (months: 0, days: 1, hours: 0));
    });

    test('31 gün = 1 ay 1 gün (1 ay = 30 gün)', () {
      expect(splitWatchTime(31 * 24 * 60), (months: 1, days: 1, hours: 0));
    });

    test('ay, gün ve saat birlikte', () {
      expect(splitWatchTime((30 + 2) * 24 * 60 + 5 * 60 + 30), (
        months: 1,
        days: 2,
        hours: 5,
      ));
    });
  });

  group('sortByLastWatched ve coverShow (F8e, V9)', () {
    UserShow entry(int id, {DateTime? watched, String? backdrop = '/b.jpg'}) =>
        UserShow(
          show: Show(id: id, name: 'D$id', backdropPath: backdrop),
          addedAt: DateTime.utc(2026, 1, id),
          lastWatchedAt: watched,
        );

    final shows = [
      entry(1, watched: DateTime.utc(2026, 10, 1)),
      entry(2),
      entry(3, watched: DateTime.utc(2026, 10, 5)),
      entry(4),
    ];

    test('son izlenen önce, izlenmeyenler eklenmeye göre sonda', () {
      expect(sortByLastWatched(shows).map((e) => e.show.id), [3, 1, 4, 2]);
    });

    test('seçilen kapak listedeyse o kullanılır', () {
      expect(coverShow(2, shows)?.id, 2);
    });

    test('kapak seçilmemişse veya listede yoksa en son izlenen', () {
      expect(coverShow(null, shows)?.id, 3);
      expect(coverShow(99, shows)?.id, 3);
    });

    test('hiç izleme yoksa kapak yok', () {
      expect(coverShow(null, [entry(2)]), isNull);
    });

    test('arka planı olmayan dizi kapak olamaz', () {
      expect(coverShow(5, [entry(5, backdrop: null)]), isNull);
    });
  });

  group('TMDB avatarı ve kapak yolu (F2)', () {
    test('avatar yolu öneki', () {
      expect(isTmdbAvatar('tmdb:/a.jpg'), isTrue);
      expect(isTmdbAvatar('uid/1.jpg'), isFalse);
      expect(toTmdbAvatarPath('/a.jpg'), 'tmdb:/a.jpg');
      expect(fromTmdbAvatarPath('tmdb:/a.jpg'), '/a.jpg');
    });

    Profile profile({int? coverShowId, String? coverPath}) => Profile(
      id: 'u',
      username: 'u',
      displayName: 'U',
      bio: '',
      coverShowId: coverShowId,
      coverPath: coverPath,
      createdAt: DateTime.utc(2026),
    );

    final shows = [
      UserShow(
        show: const Show(id: 1, name: 'D', backdropPath: '/ana.jpg'),
        addedAt: DateTime.utc(2026),
        lastWatchedAt: DateTime.utc(2026, 10),
      ),
    ];

    test('seçilen görsel önce gelir', () {
      expect(
        profileCoverPath(
          profile(coverShowId: 1, coverPath: '/secilen.jpg'),
          shows,
        ),
        '/secilen.jpg',
      );
    });

    test('görsel seçilmemişse dizinin ana arka planı (V9)', () {
      expect(profileCoverPath(profile(coverShowId: 1), shows), '/ana.jpg');
      expect(profileCoverPath(profile(), shows), '/ana.jpg');
      expect(profileCoverPath(profile(), const []), isNull);
    });
  });

  group('sosyal bağlantılar (F2, F8i)', () {
    test('kullanıcı adı ayıklanır', () {
      expect(normalizeSocialUsername('  @Ayse_1 '), 'ayse_1');
      expect(
        normalizeSocialUsername('https://letterboxd.com/ayse_1/'),
        'ayse_1',
      );
      expect(
        normalizeSocialUsername('instagram.com/ayse.dizi?igsh=x'),
        'ayse.dizi',
      );
      expect(normalizeSocialUsername('   '), isNull);
    });

    test('Letterboxd biçimi', () {
      expect(isValidLetterboxdUsername('ayse_1'), isTrue);
      expect(isValidLetterboxdUsername('a'), isFalse);
      expect(isValidLetterboxdUsername('ayse.1'), isFalse);
      expect(isValidLetterboxdUsername('a' * 16), isFalse);
    });

    test('Instagram biçimi', () {
      expect(isValidInstagramUsername('ayse.dizi_1'), isTrue);
      expect(isValidInstagramUsername('.ayse'), isFalse);
      expect(isValidInstagramUsername('ayse.'), isFalse);
      expect(isValidInstagramUsername('ay..se'), isFalse);
      expect(isValidInstagramUsername('a' * 31), isFalse);
    });

    test('adresler', () {
      expect(letterboxdUrl('ayse_1'), 'https://letterboxd.com/ayse_1/');
      expect(instagramUrl('ayse'), 'https://www.instagram.com/ayse/');
    });
  });

  group('Puanlar grafiği (F8l)', () {
    const counts = [
      RatingCount(rating: 2, count: 1),
      RatingCount(rating: 4.5, count: 3),
    ];

    test('10 sütun, eksik puanlar 0', () {
      final histogram = ratingHistogram(counts);
      expect(histogram.map((b) => b.rating), ratingSteps);
      expect(histogram.map((b) => b.count), [0, 0, 0, 1, 0, 0, 0, 0, 3, 0]);
    });

    test('toplam ve ortalama', () {
      expect(totalRatings(counts), 4);
      expect(averageRating(counts), closeTo(3.875, 1e-9));
      expect(averageRating(const []), isNull);
    });
  });
}
