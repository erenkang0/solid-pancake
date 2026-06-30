import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/kalip.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/gradient_background.dart';
import 'edit_screen.dart';

class DetailScreen extends ConsumerStatefulWidget {
  const DetailScreen({super.key, required this.kalipId});

  final int kalipId;

  @override
  ConsumerState<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends ConsumerState<DetailScreen> {
  Future<Kalip?> _yukle() => ref.read(repositoryProvider).getir(widget.kalipId);

  late Future<Kalip?> _future = _yukle();

  void _yenile() => setState(() => _future = _yukle());

  Future<void> _sil(Kalip k) async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kalıbı sil?'),
        content: Text(
            '"${k.numara}" numaralı kalıp kalıcı olarak silinecek.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            style:
                FilledButton.styleFrom(backgroundColor: AppColors.kirmizi),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (onay != true) return;
    await ref.read(repositoryProvider).sil(k.id!);
    kalipVerisiniYenile(ref);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Kalıp Detayı'),
      ),
      body: GradientBackground(
        child: SafeArea(
          child: FutureBuilder<Kalip?>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final k = snap.data;
              if (k == null) {
                return const Center(child: Text('Kayıt bulunamadı.'));
              }
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                children: [
                  _foto(k),
                  const SizedBox(height: 18),
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'NUMARA',
                          style: TextStyle(
                            letterSpacing: 2,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          k.numara,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                        if ((k.ad ?? '').isNotEmpty)
                          Text(
                            k.ad!,
                            style: TextStyle(
                              fontSize: 16,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.75),
                            ),
                          ),
                      ],
                    ),
                  ).animate().fadeIn().moveY(begin: 10, end: 0),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: _bilgiKart(
                          ikon: Icons.tag_rounded,
                          renk: AppColors.morAcik,
                          baslik: 'KOD',
                          deger: k.kod.isEmpty ? '—' : k.kod,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _bilgiKart(
                          ikon: Icons.grid_view_rounded,
                          renk: AppColors.camgobegi,
                          baslik: 'REYON',
                          deger: k.reyon.isEmpty ? '—' : k.reyon,
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 120.ms).moveY(begin: 14, end: 0),
                  if ((k.notlar ?? '').isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.sticky_note_2_rounded,
                                    size: 18),
                                const SizedBox(width: 8),
                                Text('Notlar',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                            fontWeight: FontWeight.w800)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(k.notlar!),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(delay: 200.ms),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    'Eklendi: ${tarihBicimle(k.olusturma)}\n'
                    'Güncellendi: ${tarihBicimle(k.guncelleme)}',
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.55),
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _sil(k),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.kirmizi,
                            side: const BorderSide(color: AppColors.kirmizi),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          icon: const Icon(Icons.delete_outline_rounded),
                          label: const Text('Sil'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: FilledButton.icon(
                          onPressed: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => EditScreen(mevcut: k),
                              ),
                            );
                            kalipVerisiniYenile(ref);
                            _yenile();
                          },
                          icon: const Icon(Icons.edit_rounded),
                          label: const Text('Düzenle'),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _foto(Kalip k) {
    final varMi = k.fotoYolu != null && File(k.fotoYolu!).existsSync();
    return Hero(
      tag: 'kalip-foto-${k.id}',
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: const LinearGradient(
            colors: [AppColors.mor, AppColors.camgobegi],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: varMi
            ? Image.file(File(k.fotoYolu!),
                fit: BoxFit.cover, width: double.infinity)
            : const Center(
                child: Icon(Icons.qr_code_2_rounded,
                    color: Colors.white, size: 90),
              ),
      ),
    );
  }

  Widget _bilgiKart({
    required IconData ikon,
    required Color renk,
    required String baslik,
    required String deger,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: renk.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(ikon, color: renk),
            ),
            const SizedBox(height: 12),
            Text(
              baslik,
              style: TextStyle(
                letterSpacing: 1.5,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              deger,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}
