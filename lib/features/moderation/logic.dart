/// F15 saf kuralları: şikayet nedenleri ve not uzunluğu.
library;

/// Adlar `report_reason` enum değerleriyle aynıdır.
enum ReportReason { spam, harassment, spoiler, inappropriate, other }

/// Adlar `report_target` enum değerleriyle aynıdır.
enum ReportTarget { comment, profile }

const maxReportNoteLength = 300;

/// Not isteğe bağlıdır; boşsa gönderilmez.
bool isValidReportNote(String note) =>
    note.trim().runes.length <= maxReportNoteLength;

/// Boş not null olarak saklanır.
String? normalizeReportNote(String note) {
  final trimmed = note.trim();
  return trimmed.isEmpty ? null : trimmed;
}
