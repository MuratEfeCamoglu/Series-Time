import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Cihazda saklanan tercihler. Örnek `main.dart` içinde açılışta okunur ve bu sağlayıcı
/// override edilir; böylece tercihler ilk karede eşzamanlı okunabilir.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('main.dart içinde override edilir'),
);
