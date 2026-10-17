import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/router.dart';
import 'core/config.dart';
import 'core/preferences.dart';
import 'l10n/app_localizations.dart';
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
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      locale: const Locale('tr'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: ref.watch(routerProvider),
    );
  }
}
