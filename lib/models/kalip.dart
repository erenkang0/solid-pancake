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
      olusturma:
          DateTime.fromMillisecondsSinceEpoch((j['olusturma'] as int?) ?? now),
      guncelleme:
          DateTime.fromMillisecondsSinceEpoch((j['guncelleme'] as int?) ?? now),
    );
  }
}
