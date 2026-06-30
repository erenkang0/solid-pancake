import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import '../data/kalip_repository.dart';
import '../models/kalip.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase.instance;
});

final repositoryProvider = Provider<KalipRepository>((ref) {
  return KalipRepository(ref.watch(appDatabaseProvider));
});

/// Tüm kalıpların listesi. Mutasyonlardan sonra `ref.invalidate` ile yenilenir.
final kalipListProvider = FutureProvider<List<Kalip>>((ref) async {
  return ref.watch(repositoryProvider).tumu();
});

/// Toplam kalıp sayısı (ana ekrandaki rozet).
final kalipSayisiProvider = FutureProvider<int>((ref) async {
  return ref.watch(repositoryProvider).sayi();
});

/// Liste ekranındaki arama metni.
final aramaSorguProvider = StateProvider<String>((ref) => '');

/// Arama metnine göre filtrelenmiş liste.
final aranmisListeProvider = FutureProvider<List<Kalip>>((ref) async {
  final sorgu = ref.watch(aramaSorguProvider);
  return ref.watch(repositoryProvider).ara(sorgu);
});

/// Açık/koyu tema tercihi (oturum süresince bellekte tutulur).
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.dark);

/// Bir mutasyondan sonra tüm liste/say sağlayıcılarını tazeler.
void kalipVerisiniYenile(WidgetRef ref) {
  ref.invalidate(kalipListProvider);
  ref.invalidate(kalipSayisiProvider);
  ref.invalidate(aranmisListeProvider);
}
