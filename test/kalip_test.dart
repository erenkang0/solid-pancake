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
      favori: true,
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
      expect(geri.favori, isTrue);
      expect(geri.olusturma, ornek.olusturma);
      expect(geri.guncelleme, ornek.guncelleme);
    });

    test('favori SQLite tamsayısı (1/0) olarak saklanır', () {
      expect(ornek.toMap()['favori'], 1);
      expect(ornek.copyWith(favori: false).toMap()['favori'], 0);
    });

    test('CSV satırı alanları tırnaklar ve favoriyi içerir', () {
      final satir = ornek.csvSatir();
      expect(satir.startsWith('"K-204","ABC123","B12"'), isTrue);
      expect(satir.endsWith('evet'), isTrue);
      expect(Kalip.csvBaslik(), 'numara,kod,reyon,ad,favori');
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
