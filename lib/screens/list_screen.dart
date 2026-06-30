import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/kalip_repository.dart';
import '../providers/providers.dart';
import '../widgets/empty_state.dart';
import '../widgets/gradient_background.dart';
import '../widgets/kalip_card.dart';
import 'detail_screen.dart';
import 'edit_screen.dart';

const _siralamaEtiket = {
  SiralamaTuru.yeniEklenen: 'Yeni → Eski',
  SiralamaTuru.eskiEklenen: 'Eski → Yeni',
  SiralamaTuru.numara: 'Numara (A-Z)',
  SiralamaTuru.kod: 'Kod (A-Z)',
  SiralamaTuru.reyon: 'Reyon (A-Z)',
};

class ListScreen extends ConsumerStatefulWidget {
  const ListScreen({super.key});

  @override
  ConsumerState<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends ConsumerState<ListScreen> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.text = ref.read(aramaSorguProvider);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final liste = ref.watch(aranmisListeProvider);
    final sirala = ref.watch(siralamaProvider);
    final sadeceFavori = ref.watch(sadeceFavoriProvider);
    final reyonFiltre = ref.watch(reyonFiltreProvider);
    final gruplar = ref.watch(reyonGruplariProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Tüm Kalıplar'),
        actions: [
          IconButton(
            tooltip: 'Sadece favoriler',
            isSelected: sadeceFavori,
            onPressed: () => ref.read(sadeceFavoriProvider.notifier).state =
                !sadeceFavori,
            icon: Icon(sadeceFavori
                ? Icons.star_rounded
                : Icons.star_outline_rounded),
          ),
          PopupMenuButton<SiralamaTuru>(
            tooltip: 'Sırala',
            icon: const Icon(Icons.sort_rounded),
            initialValue: sirala,
            onSelected: (v) =>
                ref.read(siralamaProvider.notifier).state = v,
            itemBuilder: (context) => [
              for (final e in _siralamaEtiket.entries)
                PopupMenuItem(value: e.key, child: Text(e.value)),
            ],
          ),
        ],
      ),
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: TextField(
                  controller: _controller,
                  onChanged: (v) =>
                      ref.read(aramaSorguProvider.notifier).state = v,
                  decoration: InputDecoration(
                    hintText: 'Numara, kod veya reyon ara…',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _controller.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              _controller.clear();
                              ref.read(aramaSorguProvider.notifier).state = '';
                              setState(() {});
                            },
                          ),
                  ),
                ),
              ),
              // Reyon filtre çipleri
              gruplar.maybeWhen(
                data: (harita) {
                  final reyonlar = harita.keys
                      .where((k) => k != 'Reyonsuz')
                      .toList();
                  if (reyonlar.isEmpty) return const SizedBox.shrink();
                  return SizedBox(
                    height: 44,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      children: [
                        _filtreCipi(
                          etiket: 'Tümü',
                          secili: reyonFiltre == null,
                          onTap: () => ref
                              .read(reyonFiltreProvider.notifier)
                              .state = null,
                        ),
                        for (final r in reyonlar)
                          _filtreCipi(
                            etiket: r,
                            secili: reyonFiltre == r,
                            onTap: () => ref
                                .read(reyonFiltreProvider.notifier)
                                .state = (reyonFiltre == r ? null : r),
                          ),
                      ],
                    ),
                  );
                },
                orElse: () => const SizedBox.shrink(),
              ),
              Expanded(
                child: liste.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Hata: $e')),
                  data: (kaliplar) {
                    if (kaliplar.isEmpty) {
                      return const EmptyState(
                        ikon: Icons.search_off_rounded,
                        baslik: 'Sonuç yok',
                        aciklama:
                            'Arama/süzgeçleri değiştirin ya da + ile yeni kalıp ekleyin.',
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.only(bottom: 110, top: 4),
                      itemCount: kaliplar.length,
                      itemBuilder: (context, i) {
                        final k = kaliplar[i];
                        return KalipCard(
                          kalip: k,
                          onTap: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => DetailScreen(kalipId: k.id!),
                              ),
                            );
                            kalipVerisiniYenile(ref);
                          },
                        )
                            .animate()
                            .fadeIn(
                                delay: (35 * (i % 12)).ms, duration: 280.ms)
                            .moveY(begin: 14, end: 0);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const EditScreen()),
          );
          kalipVerisiniYenile(ref);
        },
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _filtreCipi({
    required String etiket,
    required bool secili,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(etiket),
        selected: secili,
        onSelected: (_) => onTap(),
      ),
    );
  }
}
