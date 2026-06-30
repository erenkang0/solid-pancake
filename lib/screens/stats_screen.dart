import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_background.dart';

/// Veritabanı özeti: toplam kalıp, reyon ve favori sayıları (animasyonlu).
class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toplam = ref.watch(kalipSayisiProvider).valueOrNull ?? 0;
    final reyon = ref.watch(reyonSayisiProvider).valueOrNull ?? 0;
    final favori = ref.watch(favoriSayisiProvider).valueOrNull ?? 0;
    final gruplar = ref.watch(reyonGruplariProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: const Text('İstatistikler')),
      body: GradientBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
            children: [
              Row(
                children: [
                  Expanded(
                    child: _SayacKart(
                      ikon: Icons.inventory_2_rounded,
                      renk: AppColors.morAcik,
                      etiket: 'Toplam Kalıp',
                      deger: toplam,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SayacKart(
                      ikon: Icons.grid_view_rounded,
                      renk: AppColors.camgobegi,
                      etiket: 'Reyon',
                      deger: reyon,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _SayacKart(
                ikon: Icons.star_rounded,
                renk: AppColors.amber,
                etiket: 'Favori Kalıp',
                deger: favori,
                genis: true,
              ),
              const SizedBox(height: 24),
              Text(
                'Reyon Dağılımı',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              gruplar.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Hata: $e'),
                data: (harita) {
                  if (harita.isEmpty) {
                    return const Text('Henüz veri yok.');
                  }
                  final enFazla = harita.values
                      .map((e) => e.length)
                      .fold<int>(1, (a, b) => a > b ? a : b);
                  final girisler = harita.entries.toList()
                    ..sort((a, b) => b.value.length.compareTo(a.value.length));
                  return Column(
                    children: [
                      for (var i = 0; i < girisler.length; i++)
                        _ReyonCubuk(
                          ad: girisler[i].key,
                          adet: girisler[i].value.length,
                          oran: girisler[i].value.length / enFazla,
                        )
                            .animate()
                            .fadeIn(delay: (60 * i).ms)
                            .moveX(begin: 16, end: 0),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SayacKart extends StatelessWidget {
  const _SayacKart({
    required this.ikon,
    required this.renk,
    required this.etiket,
    required this.deger,
    this.genis = false,
  });

  final IconData ikon;
  final Color renk;
  final String etiket;
  final int deger;
  final bool genis;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          mainAxisAlignment:
              genis ? MainAxisAlignment.start : MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: renk.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(ikon, color: renk, size: 28),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                TweenAnimationBuilder<int>(
                  tween: IntTween(begin: 0, end: deger),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutCubic,
                  builder: (context, v, _) => Text(
                    '$v',
                    style: const TextStyle(
                        fontSize: 30, fontWeight: FontWeight.w900),
                  ),
                ),
                Text(
                  etiket,
                  style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ReyonCubuk extends StatelessWidget {
  const _ReyonCubuk(
      {required this.ad, required this.adet, required this.oran});

  final String ad;
  final int adet;
  final double oran;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(ad, style: const TextStyle(fontWeight: FontWeight.w700)),
              Text('$adet'),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: oran.clamp(0.04, 1.0)),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOut,
              builder: (context, v, _) => LinearProgressIndicator(
                value: v,
                minHeight: 10,
                backgroundColor:
                    Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
                valueColor:
                    const AlwaysStoppedAnimation(AppColors.morAcik),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
