import 'package:intl/intl.dart';

import 'app_locale.dart';

/// Postgres `date` değeri ("2011-04-17") saat dilimi kaymasın diye UTC gece yarısı olarak okunur.
/// "Yayınlanmış bölüm" kuralı (CLAUDE.md) da UTC tarihle karşılaştırır.
DateTime? parseDbDate(Object? value) {
  if (value is! String || value.isEmpty) return null;
  final date = DateTime.parse(value);
  return DateTime.utc(date.year, date.month, date.day);
}

/// "17 Ekim 2026" / "17 October 2026". Tarih verisi MaterialApp yerelleştirmesiyle yüklenir.
String formatLongDate(DateTime date) =>
    DateFormat('d MMMM y', AppLocale.code).format(date);

/// Yaklaşan başlığı: "17 Ekim Cuma" (F7).
String formatDayMonthWeekday(DateTime date) =>
    DateFormat('d MMMM EEEE', AppLocale.code).format(date);

/// Afiş görünümü Yaklaşan satırı: "20 Eki Sal" (F6k).
String formatShortDayMonthWeekday(DateTime date) =>
    DateFormat('d MMM EEE', AppLocale.code).format(date);
