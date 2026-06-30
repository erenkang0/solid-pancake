import 'package:sqflite/sqflite.dart';

import '../models/kalip.dart';
import 'database.dart';

/// Kalıp kayıtları için tüm veritabanı işlemleri.
class KalipRepository {
  KalipRepository(this._appDb);

  final AppDatabase _appDb;

  Future<Database> get _db => _appDb.database;

  /// Numarayı arama/karşılaştırma için sadeleştirir (boşluk ve büyük/küçük
  /// harf farklarını yok sayar).
  static String normalize(String s) =>
      s.replaceAll(RegExp(r'\s+'), '').toLowerCase();

  Future<List<Kalip>> tumu() async {
    final db = await _db;
    final rows = await db.query(
      AppDatabase.tableKalip,
      orderBy: 'guncelleme DESC',
    );
    return rows.map(Kalip.fromMap).toList();
  }

  Future<int> sayi() async {
    final db = await _db;
    final r = await db
        .rawQuery('SELECT COUNT(*) AS c FROM ${AppDatabase.tableKalip}');
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

  /// Serbest metin araması: numara, kod, reyon ve ad alanlarında geçer.
  Future<List<Kalip>> ara(String sorgu) async {
    final q = sorgu.trim();
    if (q.isEmpty) return tumu();
    final db = await _db;
    final like = '%$q%';
    final rows = await db.query(
      AppDatabase.tableKalip,
      where: 'numara LIKE ? OR kod LIKE ? OR reyon LIKE ? OR ad LIKE ?',
      whereArgs: [like, like, like, like],
      orderBy: 'guncelleme DESC',
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
}
