import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/launch_overlay.dart';
import 'app/router.dart';
import 'core/app_locale.dart';
import 'core/config.dart';
import 'core/preferences.dart';
import 'features/settings/logic.dart';
import 'features/settings/providers.dart';
import 'l10n/app_localizations.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    // Sessizce boş istemciyle açılmak yerine eksik yapılandırmayı hemen göster.
    throw StateError(
      'SUPABASE_URL / SUPABASE_ANON_KEY eksik. Uygulamayı '
      '--dart-define-from-file=env/dev.json ile çalıştır.',
    );
  }
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  // supabase_flutter anon anahtarını artık `publishableKey` adıyla alıyor; değer aynı.
  await Supabase.initialize(url: supabaseUrl, publishableKey: supabaseAnonKey);
  final preferences = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
      child: const SezonlukApp(),
    ),
  );
}

class SezonlukApp extends ConsumerWidget {
  const SezonlukApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // F21(a): palet değişince renkleri doğrudan okuyan widget'lar da yeniden çizilsin diye
    // uygulama ağacı palet anahtarıyla yeniden kurulur (rota yığını korunur).
    final palette = ref.watch(paletteProvider);
    AppColors.apply(palette);
    final language = ref.watch(languageProvider);
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      // F21(b): Sistem seçiliyse telefon dili Türkçe değilse İngilizce.
      locale: language == AppLanguage.system ? null : Locale(language.name),
      localeResolutionCallback: (device, supported) => Locale(
        resolveLanguageCode(
          choice: language.name,
          deviceLanguageCode: device?.languageCode,
        ),
      ),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) {
        // Bölüm kodu, ondalık ayırıcı ve TMDB dili çözülen dile göre (F21b).
        final code = Localizations.localeOf(context).languageCode;
        AppLocale.apply(code);
        return LaunchOverlay(
          child: KeyedSubtree(key: ValueKey((palette, code)), child: child!),
        );
      },
    );
  }
}
