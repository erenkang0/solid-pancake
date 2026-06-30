# Kalıp Takip 📦📷

Kalıbın **numarasını telefon kamerasıyla okutup** (yazılı rakamı **OCR** ile veya
**QR/barkod** etiketinden), o kalıbın **kodunu** ve **hangi reyonda (rafta)** durduğunu
anında gösteren, **tamamen çevrimdışı** çalışan bir Android veritabanı uygulaması.

> Veriler yalnızca telefonunuzda saklanır; internet gerektirmez.

## ✨ Özellikler

- 📷 **Kameradan rakam okuma (OCR):** Kalıbın üzerindeki numarayı kameraya gösterip
  butona basın; uygulama numarayı tanır. Yanlış okursa aday listesinden seçer veya elle
  düzeltirsiniz.
- 🔳 **QR / barkod tarama:** Etiketli kalıplar için anında, güvenilir okuma.
- 🗂️ **Kalıp veritabanı:** Her kalıp için **numara, kod, reyon, ad, not ve fotoğraf**.
- ⚡ **Anında sorgu:** Okunan numara kayıtlıysa kod + reyon büyük puntoyla görünür;
  kayıtlı değilse tek dokunuşla yeni kalıp olarak eklersiniz.
- 🔎 **Arama:** Numara, kod veya reyona göre tüm kalıplarda arama.
- 💾 **Yedekleme:** Tüm kayıtları JSON dosyası olarak dışa/içe aktarma.
- 🎬 **Akıcı animasyonlar:** Geçişler, tarama efektleri, başarı animasyonları, koyu/açık tema.

### ✨ Ek özellikler

- ⭐ **Favoriler:** Sık kullanılan kalıpları yıldızlayın; listede öne çıkar.
- 🔳 **QR etiket üretici:** Her kalıp için yazdırılabilir/paylaşılabilir QR etiket oluşturun, yapıştırın ve sonra QR moduyla güvenle okuyun.
- 🗄️ **Reyon görünümü:** Kalıpları rafa (reyona) göre gruplayıp “hangi rafta ne var” görün.
- 📊 **İstatistik panosu:** Toplam kalıp, reyon ve favori sayıları + reyon dağılımı (animasyonlu).
- ↕️ **Sıralama & filtre:** Numara/kod/reyon/tarihe göre sıralama; reyona ve favoriye göre süzme.
- 📳 **Titreşimli geri bildirim:** Eşleşme/kayıt/bulunamadı durumlarında haptik.
- 📄 **CSV dışa aktarma** (Excel/Sheets) ve 📋 **panoya kopyalama** (kod/reyona dokununca).

## 📲 Uygulamayı telefona kurma (APK)

APK'yı sizin için **GitHub otomatik olarak derler** — bilgisayara hiçbir şey kurmanız
gerekmez.

1. Bu deponun **Actions** sekmesine girin → en üstteki **"APK Derle"** çalışmasını açın.
   - Çalışma yeşil (✓) olunca alttaki **Artifacts** bölümünden `kalip-takip-apk` dosyasını
     indirin **veya** deponun **Releases** sekmesinden en son `app-release.apk` dosyasını
     indirin (giriş yapmadan da indirilebilir, daha kolaydır).
2. İndirdiğiniz `app-release.apk` dosyasını telefona aktarın (ya da telefonun tarayıcısından
   indirin).
3. Dosyayı açın. Android **"bilinmeyen kaynaklara izin ver"** derse izin verin.
4. Kurulum bitince uygulamayı açın ve kamera iznini verin. Hazır! 🎉

> Not: APK kişisel kullanım için hata ayıklama (debug) anahtarıyla imzalanır; Play Store'a
> yüklemek için ayrı bir imzalama anahtarı gerekir.

## 🚀 Kullanım

1. Ana ekranda **"Numara Tara"**ya basın.
2. Üstten **Rakam (OCR)** veya **QR/Barkod** modunu seçin.
3. Numarayı çerçeveye alın:
   - OCR modunda alttaki **çekim** butonuna basın → okunan numarayı onaylayın.
   - QR/Barkod modunda kod otomatik okunur.
4. Kayıt varsa **kod + reyon** açılır; yoksa **"Ekle"** ile yeni kalıp oluşturursunuz.
5. **+** ile elle de kalıp ekleyebilir, **Ayarlar → Yedekleme** ile verinizi
   yedekleyebilirsiniz.

## 🛠️ Teknik

- **Flutter (Dart)** · Material 3 · Riverpod
- **sqflite** ile cihaz içi SQLite veritabanı (çevrimdışı)
- **google_mlkit_text_recognition** (OCR) + **mobile_scanner** (QR/barkod) + **camera**
- **flutter_animate** ile animasyonlar

### Yerelde çalıştırma (geliştirici)

```bash
flutter pub get
flutter run                 # bağlı bir Android cihaz/emülatörde
flutter build apk --release # build/app/outputs/flutter-apk/app-release.apk
```

Veri modeli `lib/models/kalip.dart`, veritabanı işlemleri `lib/data/`, ekranlar
`lib/screens/` altındadır.
