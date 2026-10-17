import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/notifications/logic.dart';
import '../features/notifications/providers.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';

/// Bildirimler sekmesinin dizini (F13f).
const _notificationsIndex = 2;

/// Alt menü kabuğu: Diziler · Keşfet · Bildirimler · Profil.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final unread = ref.watch(unreadCountProvider).value ?? 0;
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          // Sekme açık kalır; her girişte liste yenilenip okundu işaretlenir (F13c).
          if (index == _notificationsIndex) {
            ref.invalidate(notificationsProvider);
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
      ),
    );
  }
}
