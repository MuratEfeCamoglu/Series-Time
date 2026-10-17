/// F12 saf kuralları: takip listeleri ve iyimser sayı güncellemesi.
library;

import 'data/models.dart';

/// F12(c): takipçi ve takip edilen listeleri 30'arlı sayfalar.
const followListPageSize = 30;

/// Adlar `get_follow_list(list)` parametresiyle aynıdır.
enum FollowList { followers, following }

/// F12(d): kişi kendini takip edemez; düğme kendi profilinde hiç gösterilmez.
bool canFollow({required String viewerId, required String targetId}) =>
    viewerId != targetId;

/// F12(b): takip/bırakma sonucu hedefin takipçi sayısı sunucuyu beklemeden değişir.
ProfileCounts withFollowerChange(
  ProfileCounts counts, {
  required bool follow,
}) => ProfileCounts(
  followers: (counts.followers + (follow ? 1 : -1)).clamp(0, 1 << 30),
  following: counts.following,
  badges: counts.badges,
);

bool hasMoreFollows(int lastPageLength) => lastPageLength >= followListPageSize;
