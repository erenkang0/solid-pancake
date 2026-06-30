import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import '../widgets/empty_state.dart';
import '../widgets/gradient_background.dart';
import '../widgets/kalip_card.dart';
import 'detail_screen.dart';
import 'edit_screen.dart';

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
    // Ekran açılınca önceki arama metnini geri yükle.
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

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: const Text('Tüm Kalıplar')),
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
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
              Expanded(
                child: liste.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Hata: $e')),
                  data: (kaliplar) {
                    if (kaliplar.isEmpty) {
                      return EmptyState(
                        ikon: Icons.search_off_rounded,
                        baslik: ref.read(aramaSorguProvider).isEmpty
                            ? 'Kayıt yok'
                            : 'Sonuç bulunamadı',
                        aciklama: ref.read(aramaSorguProvider).isEmpty
                            ? 'Sağ alttaki + ile ilk kalıbını ekle.'
                            : 'Farklı bir numara veya kod deneyin.',
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
}
