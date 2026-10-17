import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_motion.dart';

/// F22(c): yerel açılış ekranındaki simge ortadan büyüyüp solarak ilk ekrana geçer.
/// Uygulama alttan hemen kurulur; animasyon bitince katman kaldırılır.
class LaunchOverlay extends StatefulWidget {
  const LaunchOverlay({super.key, required this.child});

  final Widget child;

  @override
  State<LaunchOverlay> createState() => _LaunchOverlayState();
}

class _LaunchOverlayState extends State<LaunchOverlay>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: AppMotion.launch,
  );
  late final _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeInCubic,
  );
  bool _done = false;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.of(context).disableAnimations) {
      _done = true;
      return;
    }
    _controller.forward().whenComplete(() {
      if (mounted) setState(() => _done = true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_done) return widget.child;
    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: FadeTransition(
            opacity: ReverseAnimation(_curve),
            child: ColoredBox(
              key: const Key('launch.overlay'),
              color: AppColors.background,
              child: Center(
                child: ScaleTransition(
                  scale: Tween(
                    begin: 1.0,
                    end: AppMotion.launchIconScale,
                  ).animate(_curve),
                  child: Image.asset(
                    'assets/icon/app_icon_foreground.png',
                    width: AppMotion.launchIconSize,
                    height: AppMotion.launchIconSize,
                    excludeFromSemantics: true,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
