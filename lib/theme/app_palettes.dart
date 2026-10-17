import 'package:flutter/painting.dart';

/// F21(a) hazır koyu paletler (ISKELET.md §3.7). Metin, durum ve uyarı renkleri paletten
/// bağımsızdır; burada yalnızca vurgu ve zemin tonları değişir.
enum AppPalette {
  yellow(
    accent: Color(0xFFFFCC00),
    background: Color(0xFF000000),
    surface: Color(0xFF141414),
    surfaceAlt: Color(0xFF1F1F1F),
    border: Color(0xFF2A2A2A),
  ),
  purple(
    accent: Color(0xFFB388FF),
    background: Color(0xFF07050C),
    surface: Color(0xFF15111F),
    surfaceAlt: Color(0xFF201A2E),
    border: Color(0xFF2E2640),
  ),
  blue(
    accent: Color(0xFF4FC3F7),
    background: Color(0xFF03080C),
    surface: Color(0xFF0F1820),
    surfaceAlt: Color(0xFF18242F),
    border: Color(0xFF24323F),
  ),
  green(
    accent: Color(0xFF34C759),
    background: Color(0xFF030A05),
    surface: Color(0xFF0F1A12),
    surfaceAlt: Color(0xFF18261B),
    border: Color(0xFF243627),
  ),
  red(
    accent: Color(0xFFFF6B6B),
    background: Color(0xFF0C0404),
    surface: Color(0xFF1C1010),
    surfaceAlt: Color(0xFF281818),
    border: Color(0xFF3A2424),
  ),
  orange(
    accent: Color(0xFFFF9F0A),
    background: Color(0xFF0B0703),
    surface: Color(0xFF1C140C),
    surfaceAlt: Color(0xFF281D12),
    border: Color(0xFF3A2A1A),
  );

  const AppPalette({
    required this.accent,
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.border,
  });

  final Color accent;
  final Color background;
  final Color surface;
  final Color surfaceAlt;
  final Color border;
}
