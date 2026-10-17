import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/preferences.dart';
import '../../theme/app_palettes.dart';

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
