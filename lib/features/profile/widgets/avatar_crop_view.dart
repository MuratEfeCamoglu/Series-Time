import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../logic.dart';

/// F2 kare kırpma: görsel kareyi kaplar, sürükleyip yakınlaştırarak ayarlanır; "Kullan" ile
/// görünen kare [avatarOutputSize] kenarlı PNG olarak döner.
Future<Uint8List?> showAvatarCrop(BuildContext context, ImageProvider image) =>
    showDialog<Uint8List>(
      context: context,
      builder: (_) => Dialog.fullscreen(child: AvatarCropView(image: image)),
    );

class AvatarCropView extends StatefulWidget {
  const AvatarCropView({super.key, required this.image});

  final ImageProvider image;

  @override
  State<AvatarCropView> createState() => _AvatarCropViewState();
}

class _AvatarCropViewState extends State<AvatarCropView> {
  final _boundary = GlobalKey();
  final _transform = TransformationController();
  ImageStream? _stream;
  late final _listener = ImageStreamListener(_onImage);
  double? _aspectRatio;
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _stream?.removeListener(_listener);
    _stream = widget.image.resolve(createLocalImageConfiguration(context))
      ..addListener(_listener);
  }

  void _onImage(ImageInfo info, bool _) {
    if (!mounted) return;
    setState(() => _aspectRatio = info.image.width / info.image.height);
  }

  @override
  void dispose() {
    _stream?.removeListener(_listener);
    _transform.dispose();
    super.dispose();
  }

  Future<void> _done() async {
    setState(() => _saving = true);
    final boundary =
        _boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(
      pixelRatio: avatarOutputSize / boundary.size.width,
    );
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (!mounted) return;
    Navigator.pop(context, data?.buffer.asUint8List());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final aspectRatio = _aspectRatio;
    return Scaffold(
      appBar: AppBar(
        leading: const CloseButton(),
        title: Text(l10n.cropTitle),
        actions: [
          TextButton(
            key: const Key('crop.done'),
            onPressed: aspectRatio == null || _saving ? null : _done,
            child: Text(l10n.cropDone),
          ),
        ],
      ),
      body: aspectRatio == null
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final side =
                    (constraints.biggest.shortestSide - AppSpacing.md * 2)
                        .clamp(0.0, double.infinity);
                // Kısa kenar kareye oturur; taşan kısım sürüklenerek seçilir.
                final width = aspectRatio >= 1 ? side * aspectRatio : side;
                final height = aspectRatio >= 1 ? side : side / aspectRatio;
                if (_transform.value.isIdentity()) {
                  _transform.value = Matrix4.translationValues(
                    -(width - side) / 2,
                    -(height - side) / 2,
                    0,
                  );
                }
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox.square(
                      dimension: side,
                      child: Stack(
                        children: [
                          RepaintBoundary(
                            key: _boundary,
                            child: ClipRect(
                              child: InteractiveViewer(
                                transformationController: _transform,
                                constrained: false,
                                minScale: 1,
                                maxScale: 5,
                                child: SizedBox(
                                  width: width,
                                  height: height,
                                  child: Image(
                                    image: widget.image,
                                    fit: BoxFit.fill,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Profilde avatar yuvarlak görünür; kare yine de kaydedilir.
                          IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.fromBorderSide(
                                  BorderSide(
                                    color: AppColors.accent,
                                    width: AppSpacing.avatarRing,
                                  ),
                                ),
                              ),
                              child: SizedBox.expand(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(l10n.cropHint, style: AppTextStyles.bodySecondary),
                  ],
                );
              },
            ),
    );
  }
}
