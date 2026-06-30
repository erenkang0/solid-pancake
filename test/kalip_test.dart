import 'package:flutter_test/flutter_test.dart';
import 'package:kalip_takip/data/kalip_repository.dart';
import 'package:kalip_takip/models/kalip.dart';

void main() {
  group('Kalip modeli', () {
    final ornek = Kalip(
      id: 7,
      numara: 'K-204',
      kod: 'ABC123',
      reyon: 'B12',
      ad: 'Ön kapak kalıbı',
      notlar: 'Kenarda çapak var',
      olusturma: DateTime.fromMillisecondsSinceEpoch(1000),
      guncelleme: DateTime.fromMillisecondsSinceEpoch(2000),
    );

    test('toMap / fromMap gidiş-dönüş tutarlı', () {
      final geri = Kalip.fromMap(ornek.toMap());
      expect(geri.id, 7);
      expect(geri.numara, 'K-204');
      expect(geri.kod, 'ABC123');
      expect(geri.reyon, 'B12');
      expect(geri.ad, 'Ön kapak kalıbı');
      expect(geri.olusturma, ornek.olusturma);
      expect(geri.guncelleme, ornek.guncelleme);
    });

    test('toJson fotoğraf yolunu dahil etmez', () {
      final j = ornek.copyWith(fotoYolu: '/data/foto.jpg').toJson();
      expect(j.containsKey('fotoYolu'), isFalse);
      expect(j['numara'], 'K-204');
    });

    test('fromJson alanları kırpar', () {
      final k = Kalip.fromJson({
        'numara': '  555  ',
        'kod': ' X1 ',
        'reyon': ' A3 ',
      });
      expect(k.numara, '555');
      expect(k.kod, 'X1');
      expect(k.reyon, 'A3');
    });

    test('copyWith ile fotoğraf temizlenebilir', () {
      final fotolu = ornek.copyWith(fotoYolu: '/x.jpg');
      expect(fotolu.fotoYolu, '/x.jpg');
      final temiz = fotolu.copyWith(fotoYoluTemizle: true);
      expect(temiz.fotoYolu, isNull);
    });
  });

  group('numara normalizasyonu', () {
    test('boşluk ve büyük/küçük harf yok sayılır', () {
      expect(KalipRepository.normalize('  K 204 '), 'k204');
      expect(KalipRepository.normalize('AbC 12'), 'abc12');
    });

    test('aynı numara farklı yazımda eşit normalize olur', () {
      expect(
        KalipRepository.normalize('12 34'),
        KalipRepository.normalize('1234'),
      );
    });
  });
}
