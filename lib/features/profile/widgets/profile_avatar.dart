import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';

/// Yuvarlak avatar. Öncelik: henüz yüklenmemiş seçim ([bytes]) → [url] → boş simge.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    this.url,
    this.bytes,
    this.size = AppSpacing.avatarLarge,
  });

  final String? url;
  final Uint8List? bytes;
  final double size;

  @override
  Widget build(BuildContext context) {
    final placeholder = ColoredBox(
      color: AppColors.surfaceAlt,
      child: Icon(Icons.person, size: size / 2, color: AppColors.textSecondary),
    );
    final picked = bytes;
    final remote = url;
    final Widget image;
    if (picked != null) {
      image = Image.memory(picked, fit: BoxFit.cover);
    } else if (remote != null) {
      image = CachedNetworkImage(
        imageUrl: remote,
        fit: BoxFit.cover,
        placeholder: (_, _) => placeholder,
        errorWidget: (_, _, _) => placeholder,
      );
    } else {
      image = placeholder;
    }
    return SizedBox.square(
      dimension: size,
      child: ClipOval(child: image),
    );
  }
}
