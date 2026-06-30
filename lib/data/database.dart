import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// Uygulamanın yerel SQLite veritabanı (tamamen offline).
class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  static const _dbName = 'kalip_takip.db';
  static const _dbVersion = 2;
  static const tableKalip = 'kalip';

  Database? _db;

  Future<Database> get database async {
    return _db ??= await _open();
  }

  Future<Database> _open() async {
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = join(dir.path, _dbName);
    return openDatabase(
      dbPath,
      version: _dbVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $tableKalip(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            numara TEXT NOT NULL,
            kod TEXT NOT NULL,
            reyon TEXT NOT NULL,
            ad TEXT,
            notlar TEXT,
            fotoYolu TEXT,
            favori INTEGER NOT NULL DEFAULT 0,
            olusturma INTEGER NOT NULL,
            guncelleme INTEGER NOT NULL
          )
        ''');
        await db
            .execute('CREATE INDEX idx_kalip_numara ON $tableKalip(numara)');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'ALTER TABLE $tableKalip ADD COLUMN favori INTEGER NOT NULL DEFAULT 0',
          );
        }
      },
    );
  }
}
