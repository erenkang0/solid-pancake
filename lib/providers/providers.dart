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

/// Favori kalıp sayısı (istatistik).
final favoriSayisiProvider = FutureProvider<int>((ref) async {
  return ref.watch(repositoryProvider).favoriSayi();
});

/// Benzersiz reyon sayısı (istatistik).
final reyonSayisiProvider = FutureProvider<int>((ref) async {
  return ref.watch(repositoryProvider).reyonSayi();
});

/// Reyona göre gruplanmış kalıplar.
final reyonGruplariProvider =
    FutureProvider<Map<String, List<Kalip>>>((ref) async {
  return ref.watch(repositoryProvider).reyonlar();
});

/// Liste ekranındaki arama metni.
final aramaSorguProvider = StateProvider<String>((ref) => '');

/// Liste sıralaması.
final siralamaProvider =
    StateProvider<SiralamaTuru>((ref) => SiralamaTuru.yeniEklenen);

/// "Sadece favoriler" süzgeci.
final sadeceFavoriProvider = StateProvider<bool>((ref) => false);

/// Reyona göre süzgeç (null = hepsi).
final reyonFiltreProvider = StateProvider<String?>((ref) => null);

/// Arama + sıralama + süzgeçlere göre filtrelenmiş liste.
final aranmisListeProvider = FutureProvider<List<Kalip>>((ref) async {
  final sorgu = ref.watch(aramaSorguProvider);
  final sirala = ref.watch(siralamaProvider);
  final sadeceFavori = ref.watch(sadeceFavoriProvider);
  final reyon = ref.watch(reyonFiltreProvider);
  return ref.watch(repositoryProvider).ara(
        sorgu,
        sirala: sirala,
        sadeceFavori: sadeceFavori,
        reyon: reyon,
      );
});

/// Açık/koyu tema tercihi (oturum süresince bellekte tutulur).
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.dark);

/// Bir mutasyondan sonra tüm liste/say/grup sağlayıcılarını tazeler.
void kalipVerisiniYenile(WidgetRef ref) {
  ref.invalidate(kalipListProvider);
  ref.invalidate(kalipSayisiProvider);
  ref.invalidate(favoriSayisiProvider);
  ref.invalidate(reyonSayisiProvider);
  ref.invalidate(reyonGruplariProvider);
  ref.invalidate(aranmisListeProvider);
}
