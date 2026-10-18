import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';

enum SocialPlatform { letterboxd, instagram }

/// F8(i): Letterboxd veya Instagram logolu yuvarlak düğme; dokununca kişinin sayfası açılır.
/// Logolar paket ve indirilen dosya olmadan, platformların kendi renkleriyle çizilir.
class SocialLinkButton extends StatelessWidget {
  const SocialLinkButton({
    super.key,
    required this.platform,
    required this.username,
    required this.url,
  });

  final SocialPlatform platform;
  final String username;
  final String url;

  Future<void> _open(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final message = AppLocalizations.of(context).errorLinkOpen;
    final opened = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!opened) messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final label = switch (platform) {
      SocialPlatform.letterboxd => l10n.socialLetterboxdLabel(username),
      SocialPlatform.instagram => l10n.socialInstagramLabel(username),
    };
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Tooltip(
        message: label,
        child: InkResponse(
          onTap: () => _open(context),
          radius: AppSpacing.minTapTarget / 2,
          child: SizedBox.square(
            dimension: AppSpacing.minTapTarget,
            child: Center(
              child: SizedBox.square(
                dimension: AppSpacing.socialIconSize,
                child: CustomPaint(
                  painter: switch (platform) {
                    SocialPlatform.letterboxd => const _LetterboxdPainter(),
                    SocialPlatform.instagram => const _InstagramPainter(),
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Koyu daire üstünde yan yana, kesişen turuncu, yeşil ve mavi üç nokta.
class _LetterboxdPainter extends CustomPainter {
  const _LetterboxdPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.shortestSide / 2;
    final center = size.center(Offset.zero);
    canvas.drawCircle(
      center,
      r,
      Paint()..color = AppColors.letterboxdBackground,
    );
    final dot = r * 0.3;
    final step = dot * 1.45;
    final colors = [
      AppColors.letterboxdOrange,
      AppColors.letterboxdGreen,
      AppColors.letterboxdBlue,
    ];
    for (var i = 0; i < colors.length; i++) {
      canvas.drawCircle(
        center.translate((i - 1) * step, 0),
        dot,
        Paint()..color = colors[i],
      );
    }
    // Kesişimler logodaki gibi açık tonla gösterilir.
    final overlap = Paint()
      ..color = AppColors.textPrimary.withValues(alpha: 0.35)
      ..blendMode = BlendMode.srcATop;
    for (var i = 0; i < colors.length - 1; i++) {
      final left = Path()
        ..addOval(
          Rect.fromCircle(
            center: center.translate((i - 1) * step, 0),
            radius: dot,
          ),
        );
      final right = Path()
        ..addOval(
          Rect.fromCircle(center: center.translate(i * step, 0), radius: dot),
        );
      canvas.drawPath(
        Path.combine(PathOperation.intersect, left, right),
        overlap,
      );
    }
  }

  @override
  bool shouldRepaint(_LetterboxdPainter oldDelegate) => false;
}

/// Renk geçişli daire üstünde beyaz kamera glifi: yuvarlak kare, daire ve köşede nokta.
class _InstagramPainter extends CustomPainter {
  const _InstagramPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.shortestSide / 2;
    final center = size.center(Offset.zero);
    final bounds = Rect.fromCircle(center: center, radius: r);
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
          colors: AppColors.instagramGradient,
        ).createShader(bounds),
    );
    final stroke = r * 0.13;
    final glyph = Paint()
      ..color = AppColors.textPrimary
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    final half = r * 0.52;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCircle(center: center, radius: half),
        Radius.circular(half * 0.55),
      ),
      glyph,
    );
    canvas.drawCircle(center, half * 0.48, glyph);
    canvas.drawCircle(
      center.translate(half * 0.58, -half * 0.58),
      stroke * 0.7,
      Paint()..color = AppColors.textPrimary,
    );
  }

  @override
  bool shouldRepaint(_InstagramPainter oldDelegate) => false;
}
