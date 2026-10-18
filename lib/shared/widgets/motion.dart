import 'package:flutter/material.dart';

import '../../theme/app_motion.dart';

/// Sistemde "animasyonları azalt" açıksa animasyonlar atlanır (F22c).
Duration motionDuration(BuildContext context, Duration duration) =>
    MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;

/// Basılı tutulurken hafifçe küçülen dokunma tepkisi (afiş, kart, tepki, yıldız).
/// Dokunuşu yakalamaz; altındaki InkWell/GestureDetector çalışmaya devam eder.
class PressScale extends StatefulWidget {
  const PressScale({super.key, required this.child, this.enabled = true});

  final Widget child;
  final bool enabled;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _pressed = false;

  void _set(bool pressed) {
    if (_pressed != pressed && mounted) setState(() => _pressed = pressed);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _pressed ? AppMotion.pressScale : 1,
        duration: motionDuration(context, AppMotion.press),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Liste ve ızgara öğelerinin ilk görünüşte sırayla solarak aşağıdan kayması.
/// [index] gecikmeyi belirler; ilk birkaç öğeden sonrası beklemeden gelir.
class EntranceAnimation extends StatefulWidget {
  const EntranceAnimation({
    super.key,
    required this.index,
    required this.child,
  });

  final int index;
  final Widget child;

  @override
  State<EntranceAnimation> createState() => _EntranceAnimationState();
}

class _EntranceAnimationState extends State<EntranceAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _curve;

  @override
  void initState() {
    super.initState();
    // Gecikme zamanlayıcıyla değil, aynı animasyonun ilk diliminde beklenerek verilir.
    final delay =
        AppMotion.stagger * widget.index.clamp(0, AppMotion.staggeredItems);
    final total = delay + AppMotion.entrance;
    _controller = AnimationController(vsync: this, duration: total);
    _curve = CurvedAnimation(
      parent: _controller,
      curve: Interval(
        delay.inMicroseconds / total.inMicroseconds,
        1,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller.isAnimating || _controller.isCompleted) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _curve,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, AppMotion.entranceOffset),
          end: Offset.zero,
        ).animate(_curve),
        child: widget.child,
      ),
    );
  }
}

/// Sayının sıfırdan hedefe sayarak gelmesi (istatistikler).
class CountUp extends StatelessWidget {
  const CountUp({super.key, required this.value, required this.builder});

  final int value;
  final Widget Function(BuildContext context, int value) builder;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: motionDuration(context, AppMotion.countUp),
      curve: Curves.easeOutCubic,
      builder: (context, current, _) => builder(context, current.round()),
    );
  }
}

/// Seçildiği anda kısa bir zıplama (tepki, yıldız, oy). [active] false'tan true'ya
/// geçince oynar; ilk çizimde ve seçim kalkarken oynamaz.
class SelectionBounce extends StatefulWidget {
  const SelectionBounce({super.key, required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  State<SelectionBounce> createState() => _SelectionBounceState();
}

class _SelectionBounceState extends State<SelectionBounce>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.bounce,
  );
  late final Animation<double> _scale = TweenSequence([
    TweenSequenceItem(
      tween: Tween(begin: 1.0, end: AppMotion.bounceScale),
      weight: 1,
    ),
    TweenSequenceItem(
      tween: Tween(begin: AppMotion.bounceScale, end: 1.0),
      weight: 1,
    ),
  ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

  @override
  void didUpdateWidget(SelectionBounce oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active &&
        !oldWidget.active &&
        !MediaQuery.disableAnimationsOf(context)) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      ScaleTransition(scale: _scale, child: widget.child);
}
