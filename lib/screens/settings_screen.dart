import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../utils/backup.dart';
import '../widgets/gradient_background.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _disaAktar(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(repositoryProvider);
    final kayitlar = await repo.tumu();
    if (kayitlar.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dışa aktarılacak kayıt yok.')),
        );
      }
      return;
    }
    try {
      final dosya = await BackupService.dosyaOlustur(kayitlar);
      await BackupService.paylas(dosya);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Dışa aktarılamadı: $e')),
        );
      }
    }
  }

  Future<void> _iceAktar(BuildContext context, WidgetRef ref) async {
    try {
      final kayitlar = await BackupService.dosyadanOku();
      if (kayitlar == null) return;
      if (!context.mounted) return;
      if (kayitlar.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dosyada kayıt bulunamadı.')),
        );
        return;
      }
      final secim = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('${kayitlar.length} kayıt bulundu'),
          content: const Text(
              'Mevcut kayıtlarla birleştirilsin mi, yoksa hepsi silinip '
              'yedekle değiştirilsin mi?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, 'iptal'),
              child: const Text('Vazgeç'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'degistir'),
              child: const Text('Hepsini Değiştir'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, 'birlestir'),
              child: const Text('Birleştir'),
            ),
          ],
        ),
      );
      if (secim == null || secim == 'iptal') return;

      final eklenen = await ref.read(repositoryProvider).iceAktar(
            kayitlar,
            temizle: secim == 'degistir',
          );
      kalipVerisiniYenile(ref);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$eklenen kayıt içe aktarıldı.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('İçe aktarılamadı: $e')),
        );
      }
    }
  }

  Future<void> _csvAktar(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(repositoryProvider);
    if (await repo.sayi() == 0) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dışa aktarılacak kayıt yok.')),
        );
      }
      return;
    }
    try {
      final csv = await repo.csv();
      final dosya = await BackupService.csvDosyasiOlustur(csv);
      await BackupService.paylas(dosya);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('CSV aktarılamadı: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: const Text('Ayarlar')),
      body: GradientBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
            children: [
              _baslik(context, 'Görünüm'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Tema',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      SegmentedButton<ThemeMode>(
                        segments: const [
                          ButtonSegment(
                            value: ThemeMode.light,
                            icon: Icon(Icons.light_mode_rounded),
                            label: Text('Açık'),
                          ),
                          ButtonSegment(
                            value: ThemeMode.dark,
                            icon: Icon(Icons.dark_mode_rounded),
                            label: Text('Koyu'),
                          ),
                          ButtonSegment(
                            value: ThemeMode.system,
                            icon: Icon(Icons.smartphone_rounded),
                            label: Text('Sistem'),
                          ),
                        ],
                        selected: {mode},
                        onSelectionChanged: (s) => ref
                            .read(themeModeProvider.notifier)
                            .state = s.first,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _baslik(context, 'Yedekleme'),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.upload_file_rounded,
                          color: AppColors.morAcik),
                      title: const Text('Dışa aktar (yedek al)'),
                      subtitle: const Text(
                          'Tüm kalıpları JSON dosyası olarak paylaş'),
                      onTap: () => _disaAktar(context, ref),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.download_rounded,
                          color: AppColors.camgobegi),
                      title: const Text('İçe aktar (yedeği yükle)'),
                      subtitle:
                          const Text('JSON yedeğinden kayıtları geri yükle'),
                      onTap: () => _iceAktar(context, ref),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.table_chart_rounded,
                          color: AppColors.yesil),
                      title: const Text('CSV olarak dışa aktar'),
                      subtitle:
                          const Text('Excel/Sheets için tablo dosyası'),
                      onTap: () => _csvAktar(context, ref),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _baslik(context, 'Hakkında'),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Kalıp Takip',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w800)),
                      SizedBox(height: 6),
                      Text(
                        'Kalıp numarasını kameradan (OCR) veya QR/barkoddan '
                        'okuyup kod ve reyon bilgisini gösteren, tamamen '
                        'çevrimdışı çalışan veritabanı uygulaması.',
                      ),
                      SizedBox(height: 10),
                      Text('Sürüm 1.0.0',
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _baslik(BuildContext context, String metin) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
      child: Text(
        metin,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.w800),
      ),
    );
  }
}
