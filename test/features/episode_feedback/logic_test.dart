import 'package:flutter_test/flutter_test.dart';
import 'package:sezonluk/features/episode_feedback/data/models.dart';
import 'package:sezonluk/features/episode_feedback/logic.dart';

void main() {
  group('reactionPercentages (F9c)', () {
    test('toplam her zaman 100', () {
      final percentages = reactionPercentages({
        ReactionType.funny: 1,
        ReactionType.love: 1,
        ReactionType.sad: 1,
      });
      expect(percentages.values.fold(0, (a, b) => a + b), 100);
      expect(percentages[ReactionType.funny], 34);
      expect(percentages[ReactionType.love], 33);
      expect(percentages[ReactionType.sad], 33);
      expect(percentages[ReactionType.bored], 0);
    });

    test('tek tepki %100', () {
      expect(
        reactionPercentages({ReactionType.angry: 7})[ReactionType.angry],
        100,
      );
    });

    test('hiç tepki yoksa hepsi 0', () {
      expect(reactionPercentages({}).values, everyElement(0));
    });
  });

  group('tepki değiştirme (F9b)', () {
    test('aynı tepki kaldırır, farklı tepki değiştirir', () {
      expect(nextReaction(ReactionType.love, ReactionType.love), isNull);
      expect(
        nextReaction(ReactionType.love, ReactionType.sad),
        ReactionType.sad,
      );
      expect(nextReaction(null, ReactionType.sad), ReactionType.sad);
    });

    test('iyimser sayılar', () {
      final counts = {ReactionType.love: 2, ReactionType.sad: 1};
      expect(applyReactionChange(counts, ReactionType.love, ReactionType.sad), {
        ReactionType.love: 1,
        ReactionType.sad: 2,
      });
      expect(
        applyReactionChange(
          counts,
          null,
          ReactionType.funny,
        )[ReactionType.funny],
        1,
      );
      expect(
        applyReactionChange(counts, ReactionType.sad, null)[ReactionType.sad],
        0,
      );
    });

    test('sayı eksiye düşmez', () {
      expect(
        applyReactionChange({}, ReactionType.love, null)[ReactionType.love],
        0,
      );
    });
  });

  test('votePercent yuvarlar; oy yoksa 0 (F10c)', () {
    expect(votePercent(1, 3), 33);
    expect(votePercent(2, 3), 67);
    expect(votePercent(0, 0), 0);
  });

  group('isValidCommentBody (F11a)', () {
    test('1–500 karakter, kırpılarak', () {
      expect(isValidCommentBody(''), isFalse);
      expect(isValidCommentBody('   '), isFalse);
      expect(isValidCommentBody('a'), isTrue);
      expect(isValidCommentBody('a' * 500), isTrue);
      expect(isValidCommentBody('a' * 501), isFalse);
    });

    test('emoji tek karakter sayılır', () {
      expect(isValidCommentBody('😀' * 500), isTrue);
    });
  });

  group('isSpoilerGateClosed (F11c)', () {
    test('izlenmemiş bölümde kapalı, "Yine de göster" ile açılır', () {
      expect(isSpoilerGateClosed(watched: false, revealed: false), isTrue);
      expect(isSpoilerGateClosed(watched: false, revealed: true), isFalse);
    });

    test('izlenmiş bölümde açık', () {
      expect(isSpoilerGateClosed(watched: true, revealed: false), isFalse);
    });

    test('izlenme bilgisi yüklenmeden kapalı', () {
      expect(isSpoilerGateClosed(watched: null, revealed: false), isTrue);
    });
  });

  test('hasMoreComments tam sayfada true (F11d)', () {
    expect(hasMoreComments(20), isTrue);
    expect(hasMoreComments(19), isFalse);
  });
}
