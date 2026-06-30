import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/gradient_background.dart';
import '../widgets/kalip_card.dart';
import 'detail_screen.dart';

/// Kalıpları reyona (rafa) göre gruplayıp gösterir — hangi rafta neler var?
class ReyonScreen extends ConsumerWidget {
  const ReyonScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gruplar = ref.watch(reyonGruplariProvider);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: const Text('Reyonlar')),
      body: GradientBackground(
        child: SafeArea(
          child: gruplar.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Hata: $e')),
            data: (harita) {
              if (harita.isEmpty) {
                return const EmptyState(
                  ikon: Icons.grid_view_rounded,
                  baslik: 'Reyon yok',
                  aciklama: 'Kalıp ekledikçe raflar burada listelenir.',
                );
              }
              final anahtarlar = harita.keys.toList();
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 40),
                itemCount: anahtarlar.length,
                itemBuilder: (context, i) {
                  final reyon = anahtarlar[i];
                  final kaliplar = harita[reyon]!;
                  return Card(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 6),
                    child: Theme(
                      data: Theme.of(context)
                          .copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        initiallyExpanded: i == 0,
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.camgobegi.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.grid_view_rounded,
                              color: AppColors.camgobegi),
                        ),
                        title: Text(
                          reyon,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 17),
                        ),
                        subtitle: Text('${kaliplar.length} kalıp'),
                        childrenPadding: const EdgeInsets.only(bottom: 8),
                        children: [
                          for (final k in kaliplar)
                            KalipCard(
                              kalip: k,
                              onTap: () async {
                                await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        DetailScreen(kalipId: k.id!),
                                  ),
                                );
                                kalipVerisiniYenile(ref);
                              },
                            ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: (50 * (i % 10)).ms).moveY(
                        begin: 12,
                        end: 0,
                      );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
