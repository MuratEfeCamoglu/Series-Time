import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../moderation/logic.dart';
import '../../moderation/providers.dart';
import '../../moderation/widgets/report_sheet.dart';
import '../../profile/providers.dart';
import '../../profile/widgets/profile_avatar.dart';
import '../data/models.dart';
import '../logic.dart';
import '../providers.dart';

/// F11 yorum yazma alanı. Sunucu hatası (hız sınırı, yasaklı kelime) alanın altında gösterilir.
class CommentComposer extends ConsumerStatefulWidget {
  const CommentComposer({super.key, required this.episodeId});

  final int episodeId;

  @override
  ConsumerState<CommentComposer> createState() => _CommentComposerState();
}

class _CommentComposerState extends ConsumerState<CommentComposer> {
  final _body = TextEditingController();
  bool _spoiler = false;
  bool _sending = false;
  Object? _error;

  @override
  void dispose() {
    _body.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final l10n = AppLocalizations.of(context);
    if (!isValidCommentBody(_body.text)) {
      setState(() => _error = l10n.commentTooLong);
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await ref
          .read(commentsProvider(widget.episodeId).notifier)
          .post(body: _body.text, isSpoiler: _spoiler);
      _body.clear();
      if (mounted) setState(() => _spoiler = false);
    } catch (error) {
      if (mounted) setState(() => _error = failureMessage(l10n, error));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final error = _error;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const Key('comment.body'),
          controller: _body,
          maxLength: maxCommentLength,
          minLines: 1,
          maxLines: 5,
          decoration: InputDecoration(hintText: l10n.commentHint),
        ),
        Row(
          children: [
            Expanded(
              child: SwitchListTile(
                key: const Key('comment.spoiler'),
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.commentSpoilerSwitch),
                value: _spoiler,
                onChanged: _sending
                    ? null
                    : (value) => setState(() => _spoiler = value),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            FilledButton(
              key: const Key('comment.send'),
              onPressed: _sending ? null : _send,
              child: Text(l10n.commentSend),
            ),
          ],
        ),
        if (error != null)
          Text(
            '$error',
            key: const Key('comment.error'),
            style: AppTextStyles.error,
          ),
      ],
    );
  }
}

/// F11 yorum listesi; spoiler kapısı (F11c) ekranda tutulur ve buraya [gateClosed] olarak gelir.
class CommentsList extends ConsumerWidget {
  const CommentsList({
    super.key,
    required this.episodeId,
    required this.gateClosed,
    required this.onShowAnyway,
  });

  final int episodeId;
  final bool gateClosed;
  final VoidCallback onShowAnyway;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    if (gateClosed) {
      return Card(
        key: const Key('comments.gate'),
        color: AppColors.surfaceAlt,
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              const Icon(Icons.visibility_off, color: AppColors.textSecondary),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.commentsSpoilerGate,
                style: AppTextStyles.body,
                textAlign: TextAlign.center,
              ),
              TextButton(
                key: const Key('comments.showAnyway'),
                onPressed: onShowAnyway,
                child: Text(l10n.commentsShowAnyway),
              ),
            ],
          ),
        ),
      );
    }
    return ref
        .watch(commentsProvider(episodeId))
        .when(
          data: (state) {
            if (state.comments.isEmpty) {
              return Text(
                l10n.commentsEmpty,
                style: AppTextStyles.bodySecondary,
              );
            }
            return Column(
              children: [
                for (final comment in state.comments)
                  CommentTile(
                    key: ValueKey(comment.id),
                    episodeId: episodeId,
                    comment: comment,
                  ),
                if (state.hasMore)
                  state.loadingMore
                      ? const Padding(
                          padding: EdgeInsets.all(AppSpacing.md),
                          child: CircularProgressIndicator(),
                        )
                      : TextButton(
                          key: const Key('comments.loadMore'),
                          onPressed: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            try {
                              await ref
                                  .read(commentsProvider(episodeId).notifier)
                                  .loadMore();
                            } catch (_) {
                              messenger.showSnackBar(
                                SnackBar(content: Text(l10n.saveFailed)),
                              );
                            }
                          },
                          child: Text(l10n.commentsLoadMore),
                        ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ErrorView(
            error: error,
            onRetry: () => ref.invalidate(commentsProvider(episodeId)),
          ),
        );
  }
}

void _showFailed(BuildContext context) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(AppLocalizations.of(context).saveFailed)),
  );
}

enum _CommentAction { delete, report, block }

class CommentTile extends ConsumerStatefulWidget {
  const CommentTile({
    super.key,
    required this.episodeId,
    required this.comment,
  });

  final int episodeId;
  final EpisodeComment comment;

  @override
  ConsumerState<CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends ConsumerState<CommentTile> {
  // F11(b): spoiler işaretli yorum dokununca açılır.
  bool _revealed = false;

  CommentsNotifier get _comments =>
      ref.read(commentsProvider(widget.episodeId).notifier);

  Future<void> _run(Future<void> mutation) async {
    try {
      await mutation;
    } catch (_) {
      if (mounted) _showFailed(context);
    }
  }

  Future<void> _onAction(_CommentAction action) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final comment = widget.comment;
    switch (action) {
      case _CommentAction.delete:
        final confirmed = await _confirm(
          l10n.commentDeleteConfirm,
          null,
          l10n.commentDelete,
        );
        if (confirmed) await _run(_comments.delete(comment.id));
      case _CommentAction.report:
        final sent = await showModalBottomSheet<bool>(
          context: context,
          isScrollControlled: true,
          builder: (_) =>
              ReportSheet(target: ReportTarget.comment, targetId: comment.id),
        );
        if (sent == true) {
          // F15(a): şikayet edilen içerik şikayet edene hemen gizlenir.
          _comments.hideLocally((c) => c.id == comment.id);
          messenger.showSnackBar(SnackBar(content: Text(l10n.reportSent)));
        }
      case _CommentAction.block:
        final confirmed = await _confirm(
          l10n.blockConfirmTitle(comment.displayName),
          l10n.blockConfirmBody,
          l10n.block,
        );
        if (!confirmed) return;
        try {
          await ref.read(blockedUsersProvider.notifier).block(comment.userId);
          messenger.showSnackBar(
            SnackBar(content: Text(l10n.blockDone(comment.displayName))),
          );
        } catch (_) {
          if (mounted) _showFailed(context);
        }
    }
  }

  Future<bool> _confirm(String title, String? body, String action) async {
    final l10n = AppLocalizations.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: body == null ? null : Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            key: const Key('confirm.ok'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(action),
          ),
        ],
      ),
    );
    return result == true;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final comment = widget.comment;
    final isMine =
        comment.userId ==
        ref.read(episodeFeedbackRepositoryProvider).currentUserId;
    final avatarPath = comment.avatarPath;
    final hidden = comment.isSpoiler && !_revealed;
    final body = Text(comment.body, style: AppTextStyles.body);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProfileAvatar(
            size: AppSpacing.avatarSmall,
            url: avatarPath == null
                ? null
                : ref.read(profileRepositoryProvider).avatarUrl(avatarPath),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${comment.displayName} · ${formatLongDate(comment.createdAt.toLocal())}',
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: AppSpacing.xs),
                if (hidden)
                  GestureDetector(
                    key: Key('comment.reveal.${comment.id}'),
                    onTap: () => setState(() => _revealed = true),
                    child: Stack(
                      children: [
                        ImageFiltered(
                          imageFilter: ImageFilter.blur(
                            sigmaX: AppSpacing.spoilerBlurSigma,
                            sigmaY: AppSpacing.spoilerBlurSigma,
                          ),
                          // Bulanık metin ekran okuyucuya da okunmaz.
                          child: ExcludeSemantics(child: body),
                        ),
                        Positioned.fill(
                          child: Center(
                            child: Text(
                              l10n.commentSpoilerHidden,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.accent,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  body,
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                key: Key('comment.like.${comment.id}'),
                tooltip: comment.likedByMe
                    ? l10n.commentUnlike
                    : l10n.commentLike,
                // F11(e): kendi yorumunu beğenemez.
                onPressed: isMine
                    ? null
                    : () => _run(_comments.toggleLike(comment)),
                icon: Icon(
                  comment.likedByMe ? Icons.favorite : Icons.favorite_border,
                  color: comment.likedByMe ? AppColors.accent : null,
                ),
              ),
              Text('${comment.likeCount}', style: AppTextStyles.caption),
            ],
          ),
          PopupMenuButton<_CommentAction>(
            key: Key('comment.menu.${comment.id}'),
            tooltip: l10n.commentMenu,
            onSelected: _onAction,
            itemBuilder: (_) => [
              if (isMine)
                PopupMenuItem(
                  value: _CommentAction.delete,
                  child: Text(l10n.commentDelete),
                )
              else ...[
                PopupMenuItem(
                  value: _CommentAction.report,
                  child: Text(l10n.report),
                ),
                PopupMenuItem(
                  value: _CommentAction.block,
                  child: Text(l10n.block),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
