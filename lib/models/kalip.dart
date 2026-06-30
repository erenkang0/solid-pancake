/// Bir kalıp kaydını temsil eder.
///
/// Kullanıcı kalıbın [numara]sını kameradan okutur; uygulama bu numarayı
/// veritabanında arar ve eşleşen kalıbın [kod] ve [reyon] bilgisini gösterir.
class Kalip {
  final int? id;
  final String numara;
  final String kod;
  final String reyon;
  final String? ad;
  final String? notlar;
  final String? fotoYolu;
  final bool favori;
  final DateTime olusturma;
  final DateTime guncelleme;

  const Kalip({
    this.id,
    required this.numara,
    required this.kod,
    required this.reyon,
    this.ad,
    this.notlar,
    this.fotoYolu,
    this.favori = false,
    required this.olusturma,
    required this.guncelleme,
  });

  Kalip copyWith({
    int? id,
    String? numara,
    String? kod,
    String? reyon,
    String? ad,
    String? notlar,
    String? fotoYolu,
    bool? favori,
    DateTime? olusturma,
    DateTime? guncelleme,
    bool fotoYoluTemizle = false,
  }) {
    return Kalip(
      id: id ?? this.id,
      numara: numara ?? this.numara,
      kod: kod ?? this.kod,
      reyon: reyon ?? this.reyon,
      ad: ad ?? this.ad,
      notlar: notlar ?? this.notlar,
      fotoYolu: fotoYoluTemizle ? null : (fotoYolu ?? this.fotoYolu),
      favori: favori ?? this.favori,
      olusturma: olusturma ?? this.olusturma,
      guncelleme: guncelleme ?? this.guncelleme,
    );
  }

  /// sqflite satırına dönüştürür.
  Map<String, Object?> toMap() {
    return {
      'id': id,
      'numara': numara,
      'kod': kod,
      'reyon': reyon,
      'ad': ad,
      'notlar': notlar,
      'fotoYolu': fotoYolu,
      'favori': favori ? 1 : 0,
      'olusturma': olusturma.millisecondsSinceEpoch,
      'guncelleme': guncelleme.millisecondsSinceEpoch,
    };
  }

  factory Kalip.fromMap(Map<String, Object?> m) {
    return Kalip(
      id: m['id'] as int?,
      numara: (m['numara'] as String?) ?? '',
      kod: (m['kod'] as String?) ?? '',
      reyon: (m['reyon'] as String?) ?? '',
      ad: m['ad'] as String?,
      notlar: m['notlar'] as String?,
      fotoYolu: m['fotoYolu'] as String?,
      favori: ((m['favori'] as int?) ?? 0) == 1,
      olusturma:
          DateTime.fromMillisecondsSinceEpoch((m['olusturma'] as int?) ?? 0),
      guncelleme:
          DateTime.fromMillisecondsSinceEpoch((m['guncelleme'] as int?) ?? 0),
    );
  }

  /// Yedekleme (JSON) için. Fotoğraf yolu cihaza özgü olduğundan yedeğe dahil
  /// edilmez.
  Map<String, Object?> toJson() {
    return {
      'numara': numara,
      'kod': kod,
      'reyon': reyon,
      'ad': ad,
      'notlar': notlar,
      'favori': favori,
      'olusturma': olusturma.millisecondsSinceEpoch,
      'guncelleme': guncelleme.millisecondsSinceEpoch,
    };
  }

  factory Kalip.fromJson(Map<String, Object?> j) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return Kalip(
      numara: (j['numara'] as String?)?.trim() ?? '',
      kod: (j['kod'] as String?)?.trim() ?? '',
      reyon: (j['reyon'] as String?)?.trim() ?? '',
      ad: (j['ad'] as String?)?.trim(),
      notlar: (j['notlar'] as String?)?.trim(),
      favori: (j['favori'] as bool?) ?? false,
      olusturma:
          DateTime.fromMillisecondsSinceEpoch((j['olusturma'] as int?) ?? now),
      guncelleme:
          DateTime.fromMillisecondsSinceEpoch((j['guncelleme'] as int?) ?? now),
    );
  }

  /// CSV satırı (numara,kod,reyon,ad,favori).
  static String csvBaslik() => 'numara,kod,reyon,ad,favori';

  String csvSatir() {
    String q(String? s) {
      final v = (s ?? '').replaceAll('"', '""');
      return '"$v"';
    }

    return '${q(numara)},${q(kod)},${q(reyon)},${q(ad)},${favori ? 'evet' : 'hayır'}';
  }
}
