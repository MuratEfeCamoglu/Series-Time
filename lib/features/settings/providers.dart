import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/preferences.dart';
import '../../theme/app_palettes.dart';
import 'data/repository.dart';

const _paletteKey = 'appearance.palette';

/// F21(a): seçilen renk paleti cihazda saklanır.
class PaletteNotifier extends Notifier<AppPalette> {
  @override
  AppPalette build() {
    final stored = ref.watch(sharedPreferencesProvider).getString(_paletteKey);
    return AppPalette.values.asNameMap()[stored] ?? AppPalette.yellow;
  }

  Future<void> select(AppPalette palette) async {
    state = palette;
    await ref
        .read(sharedPreferencesProvider)
        .setString(_paletteKey, palette.name);
  }
}

final paletteProvider = NotifierProvider<PaletteNotifier, AppPalette>(
  PaletteNotifier.new,
);

final appIconRepositoryProvider = Provider<AppIconRepository>(
  (ref) => const AppIconRepository(),
);

/// F22: seçili uygulama simgesi; işletim sisteminden okunur, seçim iyimser uygulanır.
class AppIconNotifier extends AsyncNotifier<AppPalette> {
  @override
  Future<AppPalette> build() =>
      ref.read(appIconRepositoryProvider).currentIcon();

  /// Hata olursa önceki simgeye döner ve hatayı yeniden fırlatır (ekran SnackBar gösterir).
  Future<void> select(AppPalette icon) async {
    final previous = state;
    state = AsyncData(icon);
    try {
      await ref.read(appIconRepositoryProvider).setIcon(icon);
    } catch (_) {
      state = previous;
      rethrow;
    }
  }
}

final appIconProvider = AsyncNotifierProvider<AppIconNotifier, AppPalette>(
  AppIconNotifier.new,
);

const _languageKey = 'app.locale';

/// F21(b): Sistem, Türkçe veya İngilizce.
enum AppLanguage { system, tr, en }

class LanguageNotifier extends Notifier<AppLanguage> {
  @override
  AppLanguage build() {
    final stored = ref.watch(sharedPreferencesProvider).getString(_languageKey);
    return AppLanguage.values.asNameMap()[stored] ?? AppLanguage.system;
  }

  Future<void> select(AppLanguage language) async {
    state = language;
    await ref
        .read(sharedPreferencesProvider)
        .setString(_languageKey, language.name);
  }
}

final languageProvider = NotifierProvider<LanguageNotifier, AppLanguage>(
  LanguageNotifier.new,
);
