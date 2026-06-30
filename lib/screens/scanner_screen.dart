import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../models/kalip.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/scan_overlay.dart';
import '../widgets/success_check.dart';
import 'detail_screen.dart';
import 'edit_screen.dart';

enum ScanMode { ocr, barkod }

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen>
    with WidgetsBindingObserver {
  ScanMode _mod = ScanMode.ocr;

  CameraController? _camera;
  MobileScannerController? _scanner;
  final TextRecognizer _recognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  bool _kameraHazir = false;
  bool _kameraHata = false;
  bool _islemde = false;
  bool _isikAcik = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ocrBaslat();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _camera?.dispose();
    _scanner?.dispose();
    _recognizer.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_mod != ScanMode.ocr) return;
    final cam = _camera;
    if (cam == null || !cam.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      cam.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _ocrBaslat();
    }
  }

  // ---- Mod yönetimi ----

  Future<void> _ocrBaslat() async {
    await _scanner?.dispose();
    _scanner = null;
    setState(() {
      _kameraHazir = false;
      _kameraHata = false;
    });
    try {
      final kameralar = await availableCameras();
      if (kameralar.isEmpty) {
        setState(() => _kameraHata = true);
        return;
      }
      final arka = kameralar.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => kameralar.first,
      );
      final controller = CameraController(
        arka,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      _camera = controller;
      setState(() => _kameraHazir = true);
    } catch (_) {
      if (mounted) setState(() => _kameraHata = true);
    }
  }

  Future<void> _barkodBaslat() async {
    await _camera?.dispose();
    _camera = null;
    setState(() {
      _kameraHazir = false;
      _kameraHata = false;
      _isikAcik = false;
    });
    try {
      _scanner = MobileScannerController(
        detectionSpeed: DetectionSpeed.noDuplicates,
      );
      await _scanner!.start();
      if (mounted) setState(() => _kameraHazir = true);
    } catch (_) {
      if (mounted) setState(() => _kameraHata = true);
    }
  }

  Future<void> _moduDegistir(ScanMode yeni) async {
    if (yeni == _mod) return;
    setState(() => _mod = yeni);
    if (yeni == ScanMode.ocr) {
      await _ocrBaslat();
    } else {
      await _barkodBaslat();
    }
  }

  // ---- Okuma ----

  Future<void> _fotograftanOku() async {
    final cam = _camera;
    if (cam == null || !cam.value.isInitialized || _islemde) return;
    setState(() => _islemde = true);
    try {
      final dosya = await cam.takePicture();
      final girdi = InputImage.fromFilePath(dosya.path);
      final sonuc = await _recognizer.processImage(girdi);
      final adaylar = _adaylariCikar(sonuc);
      if (!mounted) return;
      setState(() => _islemde = false);
      if (adaylar.isEmpty) {
        _uyari('Numara okunamadı. Daha yakından deneyin veya elle girin.');
        return;
      }
      final secilen = await _adaySectir(adaylar);
      if (secilen != null) await _numarayiIsle(secilen);
    } catch (_) {
      if (mounted) {
        setState(() => _islemde = false);
        _uyari('Okuma sırasında bir hata oluştu.');
      }
    }
  }

  void _barkodYakalandi(BarcodeCapture capture) {
    if (_islemde) return;
    final deger = capture.barcodes
        .map((b) => b.rawValue)
        .firstWhere((v) => v != null && v.trim().isNotEmpty, orElse: () => null);
    if (deger == null) return;
    setState(() => _islemde = true);
    _numarayiIsle(deger.trim());
  }

  /// Tanınan metinden numaraya benzeyen adayları çıkarır.
  List<String> _adaylariCikar(RecognizedText t) {
    final adaylar = <String>[];

    void ekle(String s) {
      final temiz = s.trim();
      if (temiz.length < 2) return;
      if (!RegExp(r'[0-9]').hasMatch(temiz)) return;
      if (!adaylar.contains(temiz)) adaylar.add(temiz);
    }

    for (final blok in t.blocks) {
      for (final satir in blok.lines) {
        ekle(satir.text);
        for (final eleman in satir.elements) {
          ekle(eleman.text);
        }
      }
    }
    // Önce daha çok rakam içerenler
    adaylar.sort((a, b) {
      int rakam(String s) => RegExp(r'[0-9]').allMatches(s).length;
      final r = rakam(b).compareTo(rakam(a));
      return r != 0 ? r : b.length.compareTo(a.length);
    });
    return adaylar.take(8).toList();
  }

  Future<void> _numarayiIsle(String numara) async {
    final repo = ref.read(repositoryProvider);
    final bulunan = await repo.numarayaGoreBul(numara);
    if (!mounted) return;

    if (bulunan.length == 1) {
      await _basariAnimasyonu();
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => DetailScreen(kalipId: bulunan.first.id!),
        ),
      );
    } else if (bulunan.length > 1) {
      await _cokluSecim(numara, bulunan);
    } else {
      await _bulunamadi(numara);
    }
    if (mounted) setState(() => _islemde = false);
  }

  // ---- Sonuç diyalogları ----

  Future<String?> _adaySectir(List<String> adaylar) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.koyuArkaplan.first,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Okunan numarayı seçin',
                  style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              const Text('Yanlışsa düzeltebilirsiniz.',
                  style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final a in adaylar)
                    ActionChip(
                      label: Text(a,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                      onPressed: () => Navigator.pop(context, a),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Center(
                child: TextButton.icon(
                  onPressed: () async {
                    final elle = await _elleGirDiyalog(onceki: adaylar.first);
                    if (context.mounted) Navigator.pop(context, elle);
                  },
                  icon: const Icon(Icons.edit_rounded),
                  label: const Text('Elle düzelt / gir'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _cokluSecim(String numara, List<Kalip> liste) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.koyuArkaplan.first,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Birden fazla eşleşme bulundu',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              ),
              for (final k in liste)
                ListTile(
                  leading: const Icon(Icons.inventory_2_rounded),
                  title: Text(k.numara,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text('Kod: ${k.kod} • Reyon: ${k.reyon}'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => DetailScreen(kalipId: k.id!),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _bulunamadi(String numara) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.koyuArkaplan.first,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.help_outline_rounded,
                    size: 48, color: AppColors.amber),
                const SizedBox(height: 12),
                Text('"$numara" kayıtlı değil',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                const Text(
                  'Bu numarayı yeni bir kalıp olarak ekleyebilirsiniz.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Tekrar Dene'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) =>
                                  EditScreen(baslangicNumara: numara),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Ekle'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<String?> _elleGirDiyalog({String? onceki}) {
    final controller = TextEditingController(text: onceki ?? '');
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Numarayı elle gir'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Örn. 12345 / K-204'),
            onSubmitted: (v) => Navigator.pop(context, v.trim()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Ara'),
            ),
          ],
        );
      },
    ).then((v) => (v != null && v.isNotEmpty) ? v : null);
  }

  Future<void> _basariAnimasyonu() async {
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (context, anim, __, ___) {
        return Center(
          child: ScaleTransition(
            scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColors.koyuArkaplan[1],
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SuccessCheck(),
                  SizedBox(height: 12),
                  Text('Kalıp bulundu!',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ),
        );
      },
    );
    await Future<void>.delayed(const Duration(milliseconds: 950));
    if (mounted) Navigator.of(context, rootNavigator: true).pop();
  }

  void _uyari(String mesaj) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mesaj)));
  }

  Future<void> _isikDegistir() async {
    try {
      if (_mod == ScanMode.barkod) {
        await _scanner?.toggleTorch();
      } else {
        await _camera?.setFlashMode(
            _isikAcik ? FlashMode.off : FlashMode.torch);
      }
      setState(() => _isikAcik = !_isikAcik);
    } catch (_) {}
  }

  // ---- Görsel ----

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(child: _onizleme()),
          const Positioned.fill(child: IgnorePointer(child: ScanOverlay())),
          _ustBar(),
          _altPanel(),
          if (_islemde)
            Positioned.fill(
              child: Container(
                color: Colors.black38,
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }

  Widget _onizleme() {
    if (_kameraHata) {
      return _hataGorunumu();
    }
    if (!_kameraHazir) {
      return const ColoredBox(
        color: Colors.black,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_mod == ScanMode.ocr) {
      final cam = _camera;
      if (cam == null) return const SizedBox.shrink();
      return FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: cam.value.previewSize?.height ?? 1080,
          height: cam.value.previewSize?.width ?? 1920,
          child: CameraPreview(cam),
        ),
      );
    }
    final sc = _scanner;
    if (sc == null) return const SizedBox.shrink();
    return MobileScanner(controller: sc, onDetect: _barkodYakalandi);
  }

  Widget _hataGorunumu() {
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.no_photography_rounded,
                  color: Colors.white70, size: 56),
              const SizedBox(height: 16),
              const Text(
                'Kameraya erişilemedi',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'Kamera izni verildiğinden emin olun veya numarayı elle girin.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white60),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                children: [
                  OutlinedButton.icon(
                    onPressed: () =>
                        _mod == ScanMode.ocr ? _ocrBaslat() : _barkodBaslat(),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Tekrar Dene'),
                  ),
                  FilledButton.icon(
                    onPressed: () async {
                      final v = await _elleGirDiyalog();
                      if (v != null) await _numarayiIsle(v);
                    },
                    icon: const Icon(Icons.keyboard_rounded),
                    label: const Text('Elle Gir'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ustBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            _yuvarlakButon(
              icon: Icons.close_rounded,
              onTap: () => Navigator.of(context).maybePop(),
            ),
            const Spacer(),
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.all(4),
              child: SegmentedButton<ScanMode>(
                style: ButtonStyle(
                  side: WidgetStateProperty.all(BorderSide.none),
                  backgroundColor: WidgetStateProperty.resolveWith((s) =>
                      s.contains(WidgetState.selected)
                          ? AppColors.mor
                          : Colors.transparent),
                  foregroundColor: WidgetStateProperty.all(Colors.white),
                ),
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: ScanMode.ocr,
                    icon: Icon(Icons.text_fields_rounded),
                    label: Text('Rakam'),
                  ),
                  ButtonSegment(
                    value: ScanMode.barkod,
                    icon: Icon(Icons.qr_code_rounded),
                    label: Text('QR/Barkod'),
                  ),
                ],
                selected: {_mod},
                onSelectionChanged: (s) => _moduDegistir(s.first),
              ),
            ),
            const Spacer(),
            _yuvarlakButon(
              icon: _isikAcik
                  ? Icons.flash_on_rounded
                  : Icons.flash_off_rounded,
              onTap: _isikDegistir,
            ),
          ],
        ),
      ),
    );
  }

  Widget _altPanel() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _mod == ScanMode.ocr
                      ? 'Numarayı çerçeveye al ve butona bas'
                      : 'QR/barkodu çerçeveye getir, otomatik okur',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _yuvarlakButon(
                    icon: Icons.keyboard_rounded,
                    onTap: () async {
                      final v = await _elleGirDiyalog();
                      if (v != null) await _numarayiIsle(v);
                    },
                  ),
                  const SizedBox(width: 28),
                  if (_mod == ScanMode.ocr)
                    GestureDetector(
                      onTap: _fotograftanOku,
                      child: Container(
                        width: 78,
                        height: 78,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: AppColors.markaGradyan,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.mor.withValues(alpha: 0.6),
                              blurRadius: 22,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.camera_alt_rounded,
                            color: Colors.white, size: 34),
                      ),
                    )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .scaleXY(begin: 1, end: 1.06, duration: 1000.ms)
                  else
                    const SizedBox(
                      width: 78,
                      height: 78,
                      child: Icon(Icons.qr_code_scanner_rounded,
                          color: Colors.white70, size: 44),
                    ),
                  const SizedBox(width: 28),
                  const SizedBox(width: 48), // simetri için boşluk
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _yuvarlakButon({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: Colors.black.withValues(alpha: 0.45),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(icon, color: Colors.white),
        ),
      ),
    );
  }
}
