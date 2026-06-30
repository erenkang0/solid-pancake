import 'package:sqflite/sqflite.dart';

import '../models/kalip.dart';
import 'database.dart';

/// Listeleme sıralama seçenekleri.
enum SiralamaTuru { yeniEklenen, eskiEklenen, numara, kod, reyon }

/// Kalıp kayıtları için tüm veritabanı işlemleri.
class KalipRepository {
  KalipRepository(this._appDb);

  final AppDatabase _appDb;

  Future<Database> get _db => _appDb.database;

  /// Numarayı arama/karşılaştırma için sadeleştirir (boşluk ve büyük/küçük
  /// harf farklarını yok sayar).
  static String normalize(String s) =>
      s.replaceAll(RegExp(r'\s+'), '').toLowerCase();

  static String _orderBy(SiralamaTuru s) {
    switch (s) {
      case SiralamaTuru.yeniEklenen:
        return 'guncelleme DESC';
      case SiralamaTuru.eskiEklenen:
        return 'guncelleme ASC';
      case SiralamaTuru.numara:
        return 'numara COLLATE NOCASE ASC';
      case SiralamaTuru.kod:
        return 'kod COLLATE NOCASE ASC';
      case SiralamaTuru.reyon:
        return 'reyon COLLATE NOCASE ASC';
    }
  }

  Future<List<Kalip>> tumu({
    SiralamaTuru sirala = SiralamaTuru.yeniEklenen,
  }) async {
    final db = await _db;
    final rows = await db.query(
      AppDatabase.tableKalip,
      orderBy: 'favori DESC, ${_orderBy(sirala)}',
    );
    return rows.map(Kalip.fromMap).toList();
  }

  Future<int> sayi() async {
    final db = await _db;
    final r = await db
        .rawQuery('SELECT COUNT(*) AS c FROM ${AppDatabase.tableKalip}');
    return Sqflite.firstIntValue(r) ?? 0;
  }

  Future<int> favoriSayi() async {
    final db = await _db;
    final r = await db.rawQuery(
        'SELECT COUNT(*) AS c FROM ${AppDatabase.tableKalip} WHERE favori = 1');
    return Sqflite.firstIntValue(r) ?? 0;
  }

  /// Boş olmayan, benzersiz reyon sayısı.
  Future<int> reyonSayi() async {
    final db = await _db;
    final r = await db.rawQuery(
      "SELECT COUNT(DISTINCT reyon) AS c FROM ${AppDatabase.tableKalip} "
      "WHERE TRIM(reyon) <> ''",
    );
    return Sqflite.firstIntValue(r) ?? 0;
  }

  Future<Kalip?> getir(int id) async {
    final db = await _db;
    final rows = await db.query(
      AppDatabase.tableKalip,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Kalip.fromMap(rows.first);
  }

  /// Serbest metin araması + sıralama + (isteğe bağlı) favori/reyon süzgeci.
  Future<List<Kalip>> ara(
    String sorgu, {
    SiralamaTuru sirala = SiralamaTuru.yeniEklenen,
    bool sadeceFavori = false,
    String? reyon,
  }) async {
    final db = await _db;
    final kosullar = <String>[];
    final args = <Object?>[];

    final q = sorgu.trim();
    if (q.isNotEmpty) {
      final like = '%$q%';
      kosullar.add('(numara LIKE ? OR kod LIKE ? OR reyon LIKE ? OR ad LIKE ?)');
      args.addAll([like, like, like, like]);
    }
    if (sadeceFavori) kosullar.add('favori = 1');
    if (reyon != null) {
      kosullar.add('reyon = ?');
      args.add(reyon);
    }

    final rows = await db.query(
      AppDatabase.tableKalip,
      where: kosullar.isEmpty ? null : kosullar.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'favori DESC, ${_orderBy(sirala)}',
    );
    return rows.map(Kalip.fromMap).toList();
  }

  /// Okunan numaraya göre kalıp bulur. Önce tam (normalize) eşleşme, yoksa
  /// kısmi eşleşme denenir. Birden çok aday dönebilir.
  Future<List<Kalip>> numarayaGoreBul(String numara) async {
    final n = normalize(numara);
    if (n.isEmpty) return [];
    final hepsi = await tumu();

    final tam = hepsi.where((k) => normalize(k.numara) == n).toList();
    if (tam.isNotEmpty) return tam;

    return hepsi
        .where((k) =>
            normalize(k.numara).contains(n) || n.contains(normalize(k.numara)))
        .toList();
  }

  /// Kalıpları reyona göre gruplar. Boş reyon "Reyonsuz" altında toplanır.
  /// Anahtarlar alfabetik sıralı döner.
  Future<Map<String, List<Kalip>>> reyonlar() async {
    final hepsi = await tumu(sirala: SiralamaTuru.numara);
    final harita = <String, List<Kalip>>{};
    for (final k in hepsi) {
      final anahtar = k.reyon.trim().isEmpty ? 'Reyonsuz' : k.reyon.trim();
      harita.putIfAbsent(anahtar, () => []).add(k);
    }
    final siraliAnahtarlar = harita.keys.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return {for (final a in siraliAnahtarlar) a: harita[a]!};
  }

  Future<Kalip> ekle(Kalip k) async {
    final db = await _db;
    final id = await db.insert(AppDatabase.tableKalip, k.toMap());
    return k.copyWith(id: id);
  }

  Future<void> guncelle(Kalip k) async {
    final db = await _db;
    await db.update(
      AppDatabase.tableKalip,
      k.toMap(),
      where: 'id = ?',
      whereArgs: [k.id],
    );
  }

  Future<void> favoriDegistir(int id, bool favori) async {
    final db = await _db;
    await db.update(
      AppDatabase.tableKalip,
      {'favori': favori ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> sil(int id) async {
    final db = await _db;
    await db.delete(AppDatabase.tableKalip, where: 'id = ?', whereArgs: [id]);
  }

  /// Yedekten içe aktarır. [temizle] true ise mevcut kayıtlar silinir.
  Future<int> iceAktar(List<Kalip> kayitlar, {bool temizle = false}) async {
    final db = await _db;
    int eklenen = 0;
    await db.transaction((txn) async {
      if (temizle) {
        await txn.delete(AppDatabase.tableKalip);
      }
      for (final k in kayitlar) {
        await txn.insert(AppDatabase.tableKalip, k.toMap());
        eklenen++;
      }
    });
    return eklenen;
  }

  /// Tüm kayıtları CSV metnine dönüştürür (Excel uyumlu).
  Future<String> csv() async {
    final hepsi = await tumu(sirala: SiralamaTuru.numara);
    final sb = StringBuffer()..writeln(Kalip.csvBaslik());
    for (final k in hepsi) {
      sb.writeln(k.csvSatir());
    }
    return sb.toString();
  }
}
