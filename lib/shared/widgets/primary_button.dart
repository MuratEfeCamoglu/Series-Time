import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';

/// Sarı birincil düğme. [onPressed] null ise pasiftir; [loading] sırasında da basılamaz.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AppSpacing.buttonHeight,
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        child: loading
            ? const SizedBox.square(
                dimension: AppSpacing.progressIndicatorSize,
                child: CircularProgressIndicator(
                  strokeWidth: AppSpacing.progressIndicatorStroke,
                ),
              )
            : Text(label),
      ),
    );
  }
}
