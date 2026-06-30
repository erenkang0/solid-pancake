import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/gradient_background.dart';
import '../widgets/kalip_card.dart';
import 'detail_screen.dart';
import 'edit_screen.dart';
import 'list_screen.dart';
import 'scanner_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liste = ref.watch(kalipListProvider);
    final sayi = ref.watch(kalipSayisiProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Kalıp Takip'),
        actions: [
          IconButton(
            tooltip: 'Ayarlar',
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: GradientBackground(
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async => kalipVerisiniYenile(ref),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
              children: [
                const SizedBox(height: 8),
                _Karsilama()
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .moveY(begin: -10, end: 0),
                const SizedBox(height: 18),
                _TaraButonu(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ScannerScreen()),
                  ),
                ).animate().fadeIn(delay: 120.ms).scale(
                      begin: const Offset(0.92, 0.92),
                      end: const Offset(1, 1),
                      curve: Curves.easeOutBack,
                      duration: 500.ms,
                    ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _IstatistikKart(
                        ikon: Icons.inventory_2_rounded,
                        renk: AppColors.morAcik,
                        baslik: 'Toplam Kalıp',
                        deger: sayi.maybeWhen(
                          data: (v) => '$v',
                          orElse: () => '—',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _HizliAksiyonKart(
                        ikon: Icons.add_rounded,
                        renk: AppColors.yesil,
                        baslik: 'Yeni Kalıp',
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const EditScreen()),
                          );
                          kalipVerisiniYenile(ref);
                        },
                      ),
                    ),
                  ],
                )
                    .animate()
                    .fadeIn(delay: 220.ms)
                    .moveY(begin: 14, end: 0),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Son Eklenenler',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    TextButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ListScreen()),
                      ),
                      icon: const Text('Tümü'),
                      label: const Icon(Icons.arrow_forward_rounded, size: 18),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                liste.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: Text('Hata: $e'),
                  ),
                  data: (kaliplar) {
                    if (kaliplar.isEmpty) {
                      return EmptyState(
                        ikon: Icons.qr_code_scanner_rounded,
                        baslik: 'Henüz kalıp yok',
                        aciklama:
                            'Numarayı kameradan okutarak veya elle ekleyerek '
                            'ilk kalıbınızı oluşturun.',
                        aksiyon: FilledButton.icon(
                          onPressed: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const EditScreen()),
                            );
                            kalipVerisiniYenile(ref);
                          },
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Kalıp Ekle'),
                        ),
                      );
                    }
                    final ilkler = kaliplar.take(5).toList();
                    return Column(
                      children: [
                        for (var i = 0; i < ilkler.length; i++)
                          KalipCard(
                            kalip: ilkler[i],
                            onTap: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      DetailScreen(kalipId: ilkler[i].id!),
                                ),
                              );
                              kalipVerisiniYenile(ref);
                            },
                          )
                              .animate()
                              .fadeIn(delay: (80 * i).ms, duration: 350.ms)
                              .moveX(begin: 18, end: 0),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ScannerScreen()),
        ),
        icon: const Icon(Icons.qr_code_scanner_rounded),
        label: const Text('Numara Tara'),
      ).animate().scale(
            delay: 400.ms,
            duration: 400.ms,
            curve: Curves.easeOutBack,
          ),
    );
  }
}

class _Karsilama extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Merhaba 👋',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color:
                    Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
        ),
        const SizedBox(height: 2),
        Text(
          'Kalıbın numarasını okut, kodunu ve reyonunu gör.',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.w800, height: 1.2),
        ),
      ],
    );
  }
}

class _TaraButonu extends StatelessWidget {
  const _TaraButonu({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(26),
      onTap: onTap,
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: const LinearGradient(
            colors: AppColors.markaGradyan,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.mor.withValues(alpha: 0.45),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -10,
              bottom: -16,
              child: Icon(
                Icons.qr_code_scanner_rounded,
                size: 150,
                color: Colors.white.withValues(alpha: 0.16),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.center_focus_strong_rounded,
                        color: Colors.white, size: 28),
                  )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .scaleXY(begin: 1, end: 1.12, duration: 1200.ms),
                  const Spacer(),
                  const Text(
                    'Numara Tara',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    'Kamerayla OCR veya QR/barkod',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 13.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IstatistikKart extends StatelessWidget {
  const _IstatistikKart({
    required this.ikon,
    required this.renk,
    required this.baslik,
    required this.deger,
  });

  final IconData ikon;
  final Color renk;
  final String baslik;
  final String deger;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(ikon, color: renk, size: 26),
            const SizedBox(height: 12),
            Text(
              deger,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
            ),
            Text(
              baslik,
              style: TextStyle(
                color:
                    Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HizliAksiyonKart extends StatelessWidget {
  const _HizliAksiyonKart({
    required this.ikon,
    required this.renk,
    required this.baslik,
    required this.onTap,
  });

  final IconData ikon;
  final Color renk;
  final String baslik;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: renk.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(ikon, color: renk, size: 26),
              ),
              const SizedBox(height: 14),
              Text(
                baslik,
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w800),
              ),
              Text(
                'Elle kayıt oluştur',
                style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
