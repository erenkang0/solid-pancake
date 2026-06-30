import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Yavaşça hareket eden, animasyonlu degrade arka plan.
class GradientBackground extends StatefulWidget {
  const GradientBackground({super.key, required this.child});

  final Widget child;

  @override
  State<GradientBackground> createState() => _GradientBackgroundState();
}

class _GradientBackgroundState extends State<GradientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? AppColors.koyuArkaplan : AppColors.acikArkaplan;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = _c.value;
        final begin = Alignment(
          math.sin(t * math.pi * 2) * 0.6,
          -1 + t * 0.4,
        );
        final end = Alignment(
          -math.sin(t * math.pi * 2) * 0.6,
          1 - t * 0.4,
        );
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: colors,
              begin: begin,
              end: end,
            ),
          ),
          child: child,
        );
      },
      child: Stack(
        children: [
          // Renkli ışıltı lekeleri
          Positioned(
            top: -80,
            left: -60,
            child: _blob(AppColors.mor.withValues(alpha: isDark ? 0.40 : 0.25)),
          ),
          Positioned(
            bottom: -100,
            right: -70,
            child: _blob(
                AppColors.camgobegi.withValues(alpha: isDark ? 0.30 : 0.20)),
          ),
          widget.child,
        ],
      ),
    );
  }

  Widget _blob(Color color) {
    return Container(
      width: 260,
      height: 260,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
        ),
      ),
    );
  }
}
