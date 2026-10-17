import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../logic.dart';
import '../providers.dart';

String reportReasonLabel(AppLocalizations l10n, ReportReason reason) =>
    switch (reason) {
      ReportReason.spam => l10n.reportReasonSpam,
      ReportReason.harassment => l10n.reportReasonHarassment,
      ReportReason.spoiler => l10n.reportReasonSpoiler,
      ReportReason.inappropriate => l10n.reportReasonInappropriate,
      ReportReason.other => l10n.reportReasonOther,
    };

/// F15(a): şikayet nedeni ve isteğe bağlı not. Gönderilirse true döner.
class ReportSheet extends ConsumerStatefulWidget {
  const ReportSheet({super.key, required this.target, required this.targetId});

  final ReportTarget target;
  final String targetId;

  @override
  ConsumerState<ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends ConsumerState<ReportSheet> {
  final _note = TextEditingController();
  ReportReason? _reason;
  bool _sending = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final reason = _reason;
    if (reason == null || !isValidReportNote(_note.text)) return;
    setState(() => _sending = true);
    final messenger = ScaffoldMessenger.of(context);
    final failed = AppLocalizations.of(context).saveFailed;
    try {
      await ref
          .read(moderationRepositoryProvider)
          .report(
            target: widget.target,
            targetId: widget.targetId,
            reason: reason,
            note: normalizeReportNote(_note.text),
          );
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(failed)));
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.reportTitle, style: AppTextStyles.title),
              RadioGroup<ReportReason>(
                groupValue: _reason,
                onChanged: (value) => setState(() => _reason = value),
                child: Column(
                  children: [
                    for (final reason in ReportReason.values)
                      RadioListTile<ReportReason>(
                        key: Key('report.${reason.name}'),
                        value: reason,
                        title: Text(reportReasonLabel(l10n, reason)),
                      ),
                  ],
                ),
              ),
              TextField(
                controller: _note,
                maxLength: maxReportNoteLength,
                decoration: InputDecoration(hintText: l10n.reportNoteHint),
              ),
              const SizedBox(height: AppSpacing.sm),
              FilledButton(
                key: const Key('report.send'),
                onPressed: _reason == null || _sending ? null : _send,
                child: Text(l10n.reportSend),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
