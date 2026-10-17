/// F9–F11 saf kuralları: tepki yüzdeleri, iyimser tepki sayıları, yıldız yüzdesi,
/// yorum doğrulama ve spoiler kapısı.
library;

import 'data/models.dart';

const maxCommentLength = 500;
const commentPageSize = 20;

/// F10(c): oy verdikten sonra gösterilen kişi sayısı (sunucu da 5 döner).
const topStarCount = 5;

/// F9(c): yüzdeler, toplamı tam 100 olacak biçimde en büyük kalan yöntemiyle yuvarlanır.
/// Hiç tepki yoksa hepsi 0.
Map<ReactionType, int> reactionPercentages(Map<ReactionType, int> counts) {
  final total = counts.values.fold(0, (sum, c) => sum + c);
  if (total == 0) return {for (final type in ReactionType.values) type: 0};

  final floors = <ReactionType, int>{};
  final remainders = <ReactionType, double>{};
  for (final type in ReactionType.values) {
    final exact = (counts[type] ?? 0) * 100 / total;
    floors[type] = exact.floor();
    remainders[type] = exact - exact.floor();
  }
  var missing = 100 - floors.values.fold(0, (sum, p) => sum + p);
  // Eşit kalanlarda tepki sırası (enum sırası) korunur; sonuç her seferinde aynıdır.
  final byRemainder = [...ReactionType.values]
    ..sort((a, b) => remainders[b]!.compareTo(remainders[a]!));
  for (final type in byRemainder) {
    if (missing == 0) break;
    floors[type] = floors[type]! + 1;
    missing--;
  }
  return floors;
}

/// F9(b): aynı tepkiye tekrar dokunmak tepkiyi kaldırır; başkasına dokunmak değiştirir.
ReactionType? nextReaction(ReactionType? current, ReactionType tapped) =>
    current == tapped ? null : tapped;

/// İyimser güncelleme: [previous] tepkisi bir azalır, [next] bir artar.
Map<ReactionType, int> applyReactionChange(
  Map<ReactionType, int> counts,
  ReactionType? previous,
  ReactionType? next,
) {
  final updated = {...counts};
  if (previous != null) {
    updated[previous] = ((updated[previous] ?? 0) - 1).clamp(0, 1 << 30);
  }
  if (next != null) updated[next] = (updated[next] ?? 0) + 1;
  return updated;
}

int votePercent(int votes, int total) =>
    total <= 0 ? 0 : (votes * 100 / total).round();

/// F11(a): kırpılmış metin 1–500 karakter (Postgres `char_length` gibi kod noktası sayılır).
bool isValidCommentBody(String body) {
  final length = body.trim().runes.length;
  return length >= 1 && length <= maxCommentLength;
}

/// F11(c): bölümü izlenmiş işaretlememiş kullanıcıya yorumlar, "Yine de göster" denene
/// kadar gizlidir. İzlenme bilgisi henüz yüklenmediyse ([watched] null) de gizli kalır.
bool isSpoilerGateClosed({required bool? watched, required bool revealed}) =>
    watched != true && !revealed;

/// Sonraki sayfa var mı: son sayfa tam doluysa olabilir.
bool hasMoreComments(int lastPageLength) => lastPageLength >= commentPageSize;

/// F20(a): 5 yıldız, 0,5 adım.
const maxRatingStars = 5;

enum StarFill { full, half, empty }

/// Yıldızın sol yarısı buçuk, sağ yarısı tam puan verir.
double ratingFromTap({required int starIndex, required bool leftHalf}) =>
    starIndex + (leftHalf ? 0.5 : 1.0);

/// Aynı puana tekrar dokunmak puanı kaldırır.
double? nextRating(double? current, double tapped) =>
    current == tapped ? null : tapped;

StarFill starFill(double? rating, int starIndex) {
  final value = rating ?? 0;
  if (value >= starIndex + 1) return StarFill.full;
  if (value >= starIndex + 0.5) return StarFill.half;
  return StarFill.empty;
}

/// "4,5" — Türkçe ondalık ayırıcı.
String formatRating(double rating) =>
    rating.toStringAsFixed(1).replaceAll('.', ',');
