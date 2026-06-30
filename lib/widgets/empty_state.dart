import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Liste boşken gösterilen, hafif animasyonlu bilgilendirme.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.ikon,
    required this.baslik,
    required this.aciklama,
    this.aksiyon,
  });

  final IconData ikon;
  final String baslik;
  final String aciklama;
  final Widget? aksiyon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.primary.withValues(alpha: 0.15),
              ),
              child: Icon(ikon, size: 54, color: scheme.primary),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scaleXY(begin: 1, end: 1.06, duration: 1600.ms)
                .then()
                .shimmer(duration: 1200.ms, color: scheme.primary),
            const SizedBox(height: 22),
            Text(
              baslik,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              aciklama,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
                  ),
            ),
            if (aksiyon != null) ...[
              const SizedBox(height: 24),
              aksiyon!,
            ],
          ],
        ).animate().fadeIn(duration: 500.ms).moveY(begin: 12, end: 0),
      ),
    );
  }
}
