import 'package:flutter/material.dart';

/// Hand-rolled shimmer primitive — no `shimmer` package dependency.
///
/// Wrap any widget tree to apply a sweeping linear gradient animation.
/// Respects [MediaQuery.disableAnimations] so flutter_test goldens are
/// deterministic. Wraps content in `Semantics(label: 'Loading')` so
/// screen readers announce loading instead of empty boxes.
///
/// Also wraps its animating subtree in a [RepaintBoundary] — the shimmer
/// gradient repaints every frame; without the boundary, the whole parent
/// tree repaints with it. See `references/performance.md` for the
/// RepaintBoundary placement rules.
class Shimmer extends StatefulWidget {
  const Shimmer({
    required this.child,
    this.duration = const Duration(milliseconds: 1500),
    super.key,
  });

  final Widget child;
  final Duration duration;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final disableAnimations = MediaQuery.of(context).disableAnimations;
    final base = theme.colorScheme.surfaceContainerHighest;
    final highlight = theme.colorScheme.surfaceContainerLow;

    return Semantics(
      label: 'Loading',
      excludeSemantics: true,
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _controller,
          // The static child is built once and reused on every animation
          // tick — only the ShaderMask + builder closure runs at 60fps.
          child: widget.child,
          builder: (context, child) {
            if (disableAnimations) return child!;
            return ShaderMask(
              blendMode: BlendMode.srcATop,
              shaderCallback: (bounds) => LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [base, highlight, base],
                stops: const [0.0, 0.5, 1.0],
                transform: _SlidingGradientTransform(_controller.value),
              ).createShader(bounds),
              child: child,
            );
          },
        ),
      ),
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform(this.t);

  final double t;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * (t * 2 - 1), 0, 0);
  }
}
