import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sezonluk/core/failures.dart';
import 'package:sezonluk/features/episode_feedback/data/models.dart';
import 'package:sezonluk/features/episode_feedback/screens/episode_screen.dart';
import 'package:sezonluk/features/moderation/logic.dart';
import 'package:sezonluk/features/tracking/screens/shows_screen.dart';

import '../../helpers.dart';

EpisodeComment _comment(
  String id, {
  String userId = '22222222-2222-2222-2222-222222222222',
  String body = 'Yorum',
  bool spoiler = false,
  int likes = 0,
  bool liked = false,
  DateTime? createdAt,
}) => EpisodeComment(
  id: id,
  userId: userId,
  username: 'burak',
  displayName: 'Burak',
  body: body,
  isSpoiler: spoiler,
  createdAt: createdAt ?? DateTime.utc(2026, 10, 17, 10),
  likeCount: likes,
  likedByMe: liked,
);

/// [watched]: bölüm izlenmiş mi (spoiler kapısı, F11c).
Future<TestBackend> _openEpisode(
  WidgetTester tester, {
  bool watched = true,
  List<EpisodeComment> comments = const [],
  void Function(TestBackend backend)? setUp,
}) async {
  // Ekran uzun; yorumlar ilk ekranda çizilsin.
  tester.view
    ..physicalSize = const Size(800, 2400)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final backend = TestBackend();
  when(() => backend.tracking.fetchWatchedEpisodeIds(1399))
      .thenAnswer((_) async => watched ? {100} : <int>{});
  when(() => backend.feedback.fetchComments(100, before: any(named: 'before')))
      .thenAnswer((_) async => comments);
  setUp?.call(backend);
  await backend.pumpApp(tester);
  GoRouter.of(tester.element(find.byType(ShowsScreen))).push('/episode/100');
  await tester.pumpAndSettle();
  expect(find.byType(EpisodeScreen), findsOneWidget);
  return backend;
}

void main() {
  testWidgets(
    'üstte bölüm bilgisi; İzlendi düğmesi bölümü işaretler ve geri alır (F5a)',
    (tester) async {
      final backend = await _openEpisode(tester, watched: false);
      when(() => backend.tracking.markEpisode(episodeId: 100, showId: 1399))
          .thenAnswer((_) async {});

      expect(find.text('S01 | B01'), findsOneWidget);
      expect(find.text('Kış Geliyor'), findsOneWidget);
      expect(find.text('İzledim olarak işaretle'), findsOneWidget);

      await tester.tap(find.byKey(const Key('episode.watched')));
      await tester.pumpAndSettle();

      verify(() => backend.tracking.markEpisode(episodeId: 100, showId: 1399))
          .called(1);
      expect(find.text('İzlendi'), findsOneWidget);
    },
  );

  group('F9 tepkiler', () {
    testWidgets('12 tepki; yüzdeler tepki verdikten sonra görünür', (
      tester,
    ) async {
      final backend = await _openEpisode(
        tester,
        setUp: (b) =>
            when(() => b.feedback.fetchReactionCounts(100))
                .thenAnswer((_) async => {ReactionType.funny: 3}),
      );
      when(() => backend.feedback.setReaction(100, ReactionType.love))
          .thenAnswer((_) async {});

      for (final label in [
        'Komik',
        'Bayıldım',
        'Şok oldum',
        'Hüzünlendim',
        'Sinirlendim',
        'Sıkıldım',
        'Kafam yandı',
        'Korktum',
        'Efsane',
        'Düşündürdü',
        'Duygulandım',
        'Gerildim',
      ]) {
        expect(find.text(label), findsOneWidget);
      }
      expect(find.byKey(const Key('reaction.love.percent')), findsNothing);

      await tester.tap(find.byKey(const Key('reaction.love')));
      await tester.pumpAndSettle();

      verify(() => backend.feedback.setReaction(100, ReactionType.love))
          .called(1);
      expect(find.text('%25'), findsOneWidget);
      expect(find.text('%75'), findsOneWidget);
    });

    testWidgets('aynı tepkiye dokunmak kaldırır (F9b)', (tester) async {
      final backend = await _openEpisode(
        tester,
        setUp: (b) {
          when(() => b.feedback.fetchMyReaction(100))
              .thenAnswer((_) async => ReactionType.sad);
          when(() => b.feedback.fetchReactionCounts(100))
              .thenAnswer((_) async => {ReactionType.sad: 1});
        },
      );
      when(() => backend.feedback.setReaction(100, null))
          .thenAnswer((_) async {});
      expect(find.text('%100'), findsOneWidget);

      await tester.tap(find.byKey(const Key('reaction.sad')));
      await tester.pumpAndSettle();

      verify(() => backend.feedback.setReaction(100, null)).called(1);
      expect(find.byKey(const Key('reaction.sad.percent')), findsNothing);
    });

    testWidgets('tepki kaydedilemezse geri alınır', (tester) async {
      final backend = await _openEpisode(tester);
      when(() => backend.feedback.setReaction(100, ReactionType.angry))
          .thenThrow(const AppFailure(AppFailureType.network));

      await tester.tap(find.byKey(const Key('reaction.angry')));
      await tester.pumpAndSettle();

      expect(find.text('Kaydedilemedi, tekrar dene.'), findsOneWidget);
      expect(find.byKey(const Key('reaction.angry.percent')), findsNothing);
    });
  });

  group('F10 bölümün yıldızı', () {
    testWidgets('kadro yoksa ileti gösterilir (F10d)', (tester) async {
      await _openEpisode(tester);
      expect(find.text('Bu bölüm için oyuncu bilgisi yok'), findsOneWidget);
    });

    testWidgets('oy verilir, en çok oy alanlar yüzdeleriyle görünür (F10a–c)', (
      tester,
    ) async {
      final backend = await _openEpisode(
        tester,
        setUp: (b) => when(() => b.feedback.fetchCredits(100)).thenAnswer(
          (_) async => const [
            CastMember(
              personId: 1,
              name: 'Oyuncu A',
              character: 'Rol A',
              order: 0,
            ),
            CastMember(
              personId: 2,
              name: 'Oyuncu B',
              character: 'Rol B',
              order: 1,
            ),
          ],
        ),
      );
      when(() => backend.feedback.voteStar(100, 2)).thenAnswer((_) async {});
      when(() => backend.feedback.fetchStarStats(100)).thenAnswer(
        (_) async => const [
          StarStat(personId: 2, name: 'Oyuncu B', votes: 3, totalVotes: 4),
          StarStat(personId: 1, name: 'Oyuncu A', votes: 1, totalVotes: 4),
        ],
      );
      expect(find.text('Rol A'), findsOneWidget);
      expect(find.text('En çok oy alanlar'), findsNothing);

      await tester.tap(find.byKey(const Key('star.2')));
      await tester.pumpAndSettle();

      verify(() => backend.feedback.voteStar(100, 2)).called(1);
      expect(find.text('En çok oy alanlar'), findsOneWidget);
      expect(find.text('%75'), findsOneWidget);
      expect(find.text('%25'), findsOneWidget);
    });
  });

  group('F11 yorumlar', () {
    testWidgets(
      'izlenmemiş bölümde yorumlar gizli; "Yine de göster" açar (F11c)',
      (tester) async {
        await _openEpisode(
          tester,
          watched: false,
          comments: [_comment('c1', body: 'Gizli yorum')],
        );

        expect(
          find.text('Bu bölümü izlemedin, yorumlar spoiler içerebilir'),
          findsOneWidget,
        );
        expect(find.text('Gizli yorum'), findsNothing);

        await tester.tap(find.byKey(const Key('comments.showAnyway')));
        await tester.pumpAndSettle();
        expect(find.text('Gizli yorum'), findsOneWidget);
      },
    );

    testWidgets(
      'spoiler işaretli yorum bulanık başlar, dokununca açılır (F11b)',
      (tester) async {
        await _openEpisode(
          tester,
          comments: [_comment('c1', body: 'Sürpriz', spoiler: true)],
        );

        expect(find.byKey(const Key('comment.reveal.c1')), findsOneWidget);
        expect(
          find.text('Spoiler içeriyor — görmek için dokun'),
          findsOneWidget,
        );

        await tester.tap(find.byKey(const Key('comment.reveal.c1')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('comment.reveal.c1')), findsNothing);
        expect(find.text('Sürpriz'), findsOneWidget);
      },
    );

    testWidgets('yorum gönderilir ve liste yenilenir (F11a)', (tester) async {
      final backend = await _openEpisode(tester);
      when(
        () => backend.feedback.postComment(
          100,
          body: 'Muhteşem',
          isSpoiler: true,
        ),
      ).thenAnswer((_) async {});

      await tester.tap(find.byKey(const Key('comment.send')));
      await tester.pumpAndSettle();
      expect(find.text('Yorum 1–500 karakter olmalı.'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('comment.body')), 'Muhteşem');
      await tester.tap(find.byKey(const Key('comment.spoiler')));
      when(
        () => backend.feedback.fetchComments(100, before: any(named: 'before')),
      ).thenAnswer(
        (_) async => [
          _comment('c9', userId: testUserId, body: 'Muhteşem', spoiler: true),
        ],
      );
      await tester.tap(find.byKey(const Key('comment.send')));
      await tester.pumpAndSettle();

      verify(
        () => backend.feedback.postComment(
          100,
          body: 'Muhteşem',
          isSpoiler: true,
        ),
      ).called(1);
      expect(find.byKey(const Key('comment.reveal.c9')), findsOneWidget);
    });

    testWidgets('hız sınırı hatası gösterilir (F11f)', (tester) async {
      final backend = await _openEpisode(tester);
      when(
        () => backend.feedback.postComment(
          100,
          body: any(named: 'body'),
          isSpoiler: any(named: 'isSpoiler'),
        ),
      ).thenThrow(const AppFailure(AppFailureType.commentRateLimited));

      await tester.enterText(find.byKey(const Key('comment.body')), 'Bir daha');
      await tester.tap(find.byKey(const Key('comment.send')));
      await tester.pumpAndSettle();

      expect(
        find.text('Çok hızlı yorum yapıyorsun. Biraz bekleyip tekrar dene.'),
        findsOneWidget,
      );
    });

    testWidgets('yasaklı kelime hatası gösterilir (F11g, F15d)', (
      tester,
    ) async {
      final backend = await _openEpisode(tester);
      when(
        () => backend.feedback.postComment(
          100,
          body: any(named: 'body'),
          isSpoiler: any(named: 'isSpoiler'),
        ),
      ).thenThrow(const AppFailure(AppFailureType.commentBannedWord));

      await tester.enterText(find.byKey(const Key('comment.body')), 'kötü söz');
      await tester.tap(find.byKey(const Key('comment.send')));
      await tester.pumpAndSettle();

      expect(find.text('Yorumun uygunsuz bir ifade içeriyor.'), findsOneWidget);
    });

    testWidgets(
      'başkasının yorumu beğenilir; kendi yorumu beğenilemez (F11e)',
      (tester) async {
        final backend = await _openEpisode(
          tester,
          comments: [
            _comment('c1', likes: 2),
            _comment('c2', userId: testUserId, body: 'Benim'),
          ],
        );
        when(() => backend.feedback.setLike('c1', liked: true))
            .thenAnswer((_) async {});

        await tester.tap(find.byKey(const Key('comment.like.c1')));
        await tester.pump();
        expect(find.text('3'), findsOneWidget);
        verify(() => backend.feedback.setLike('c1', liked: true)).called(1);

        final ownLike = tester.widget<IconButton>(
          find.byKey(const Key('comment.like.c2')),
        );
        expect(ownLike.onPressed, isNull);
      },
    );

    testWidgets('kendi yorumunu onayla siler (F11e)', (tester) async {
      final backend = await _openEpisode(
        tester,
        comments: [_comment('c2', userId: testUserId, body: 'Benim')],
      );
      when(() => backend.feedback.deleteComment('c2')).thenAnswer((_) async {});

      await tester.tap(find.byKey(const Key('comment.menu.c2')));
      await tester.pumpAndSettle();
      expect(find.text('Şikayet et'), findsNothing);
      await tester.tap(find.text('Sil'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm.ok')));
      await tester.pumpAndSettle();

      verify(() => backend.feedback.deleteComment('c2')).called(1);
      expect(find.text('Benim'), findsNothing);
    });

    testWidgets(
      'daha fazla yorum son yorumun tarihinden öncesini ister (F11d)',
      (tester) async {
        final page = [
          for (var i = 0; i < 20; i++)
            _comment('c$i', createdAt: DateTime.utc(2026, 10, 17, 10, 59 - i)),
        ];
        final backend = await _openEpisode(tester, comments: page);
        when(
          () => backend.feedback.fetchComments(
            100,
            before: DateTime.utc(2026, 10, 17, 10, 40),
          ),
        ).thenAnswer((_) async => [_comment('eski', body: 'En eski')]);

        // Yorumlar tek bir sütunda çizilir; düğme var ama ekran dışında olabilir.
        await tester.ensureVisible(find.byKey(const Key('comments.loadMore')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('comments.loadMore')));
        await tester.pumpAndSettle();

        expect(find.text('En eski'), findsOneWidget);
        expect(find.byKey(const Key('comments.loadMore')), findsNothing);
      },
    );
  });

  group('F15 moderasyon', () {
    testWidgets('yorum şikayet edilir ve hemen gizlenir (F15a)', (
      tester,
    ) async {
      final backend = await _openEpisode(
        tester,
        comments: [_comment('c1', body: 'Kaba yorum')],
      );
      when(
        () => backend.moderation.report(
          target: ReportTarget.comment,
          targetId: 'c1',
          reason: ReportReason.harassment,
        ),
      ).thenAnswer((_) async {});

      await tester.tap(find.byKey(const Key('comment.menu.c1')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Şikayet et'));
      await tester.pumpAndSettle();
      for (final reason in [
        'Spam',
        'Taciz',
        'Spoiler',
        'Uygunsuz içerik',
        'Diğer',
      ]) {
        expect(find.text(reason), findsOneWidget);
      }
      await tester.tap(find.byKey(const Key('report.harassment')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('report.send')));
      await tester.pumpAndSettle();

      verify(
        () => backend.moderation.report(
          target: ReportTarget.comment,
          targetId: 'c1',
          reason: ReportReason.harassment,
        ),
      ).called(1);
      expect(find.text('Kaba yorum'), findsNothing);
      expect(find.text('Şikayetin alındı. İnceleyeceğiz.'), findsOneWidget);
    });

    testWidgets('yorum sahibi engellenir, yorumları yeniden çekilir (F15b)', (
      tester,
    ) async {
      final backend = await _openEpisode(
        tester,
        comments: [_comment('c1', body: 'Rahatsız edici')],
      );
      when(
        () => backend.moderation.block('22222222-2222-2222-2222-222222222222'),
      ).thenAnswer((_) async {});

      await tester.tap(find.byKey(const Key('comment.menu.c1')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Engelle'));
      await tester.pumpAndSettle();
      expect(find.text('Burak engellensin mi?'), findsOneWidget);
      when(
        () => backend.feedback.fetchComments(100, before: any(named: 'before')),
      ).thenAnswer((_) async => const []);
      await tester.tap(find.byKey(const Key('confirm.ok')));
      await tester.pumpAndSettle();

      verify(
        () => backend.moderation.block('22222222-2222-2222-2222-222222222222'),
      ).called(1);
      expect(find.text('Rahatsız edici'), findsNothing);
      expect(find.text('Burak engellendi.'), findsOneWidget);
    });
  });

  group('F20 puan ve beğeni', () {
    testWidgets(
      'yıldızın yarısına dokununca buçuk puan verilir, ortalama yenilenir',
      (tester) async {
        final backend = await _openEpisode(tester);
        when(() => backend.feedback.setRating(100, 3.5))
            .thenAnswer((_) async {});
        await tester.ensureVisible(find.byKey(const Key('rating.star.3')));
        await tester.pumpAndSettle();
        expect(find.text('Henüz puan verilmedi.'), findsOneWidget);

        when(() => backend.feedback.fetchRatingSummary(100)).thenAnswer(
          (_) async => const RatingSummary(
            average: 3.5,
            ratingCount: 1,
            likeCount: 0,
            liked: false,
            myRating: 3.5,
          ),
        );
        final star = find.byKey(const Key('rating.star.3'));
        await tester.tapAt(tester.getTopLeft(star) + const Offset(5, 20));
        await tester.pumpAndSettle();

        verify(() => backend.feedback.setRating(100, 3.5)).called(1);
        expect(find.byKey(const Key('rating.mine')), findsOneWidget);
        expect(find.text('3,5'), findsOneWidget);
        expect(find.text('Ortalama 3,5 · 1 puan'), findsOneWidget);
      },
    );

    testWidgets('kalp bölümü beğenir; sayı beklemeden artar (F20b, F20c)', (
      tester,
    ) async {
      final backend = await _openEpisode(
        tester,
        setUp: (b) => when(() => b.feedback.fetchRatingSummary(100)).thenAnswer(
          (_) async =>
              const RatingSummary(ratingCount: 0, likeCount: 4, liked: false),
        ),
      );
      when(() => backend.feedback.setEpisodeLike(100, liked: true))
          .thenAnswer((_) async {});

      expect(find.text('4'), findsOneWidget);
      await tester.tap(find.byKey(const Key('episode.like')));
      await tester.pump();

      expect(find.text('5'), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsOneWidget);
      verify(() => backend.feedback.setEpisodeLike(100, liked: true)).called(1);
    });
  });
}
