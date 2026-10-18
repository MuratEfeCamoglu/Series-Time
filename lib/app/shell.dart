import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/notifications/logic.dart';
import '../features/notifications/providers.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Bildirimler sekmesinin dizini (F13f).
const _notificationsIndex = 2;

/// Alt menü kabuğu: Diziler · Keşfet · Bildirimler · Profil. Menü ekranın altına yapışık
/// değil; kenarlardan boşluklu, yüzen kapsül çubuktur (kullanıcı kararı 2026-10-18).
/// Gövde çubuğun arkasına uzanmaz, bu yüzden listelerin sonu çubuğun altında kalmaz.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadCountProvider).value ?? 0;
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.sm,
        ),
        child: DecoratedBox(
          key: const Key('nav.floatingBar'),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.navBarHeight / 2),
            border: Border.all(color: AppColors.border),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.navBarHeight / 2),
            child: _navigationBar(context, ref, unread),
          ),
        ),
      ),
    );
  }

  Widget _navigationBar(BuildContext context, WidgetRef ref, int unread) {
    final l10n = AppLocalizations.of(context);
    return NavigationBar(
      height: AppSpacing.navBarHeight,
      selectedIndex: navigationShell.currentIndex,
      onDestinationSelected: (index) {
        // Sekme açık kalır; her girişte liste yenilenip okundu işaretlenir (F13c).
        if (index == _notificationsIndex) {
          ref
            ..invalidate(notificationsProvider)
            ..invalidate(myWatchFeedProvider);
        }
        navigationShell.goBranch(
          index,
          // Aktif sekmeye tekrar dokunmak o sekmenin köküne döner.
          initialLocation: index == navigationShell.currentIndex,
        );
      },
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.live_tv_outlined),
          selectedIcon: const Icon(Icons.live_tv),
          label: l10n.tabShows,
        ),
        NavigationDestination(
          icon: const Icon(Icons.search),
          label: l10n.tabDiscover,
        ),
        NavigationDestination(
          key: const Key('nav.notifications'),
          tooltip: unread > 0 ? l10n.unreadNotifications(unread) : null,
          icon: Badge(
            label: Text(unreadBadgeLabel(unread)),
            isLabelVisible: unread > 0,
            child: const Icon(Icons.notifications_outlined),
          ),
          selectedIcon: Badge(
            label: Text(unreadBadgeLabel(unread)),
            isLabelVisible: unread > 0,
            child: Icon(Icons.notifications, color: AppColors.accent),
          ),
          label: l10n.tabNotifications,
        ),
        NavigationDestination(
          icon: const Icon(Icons.person_outline),
          selectedIcon: const Icon(Icons.person),
          label: l10n.tabProfile,
        ),
      ],
    );
  }
}
