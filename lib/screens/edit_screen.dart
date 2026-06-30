import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/kalip.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_background.dart';
import '../widgets/success_check.dart';

class EditScreen extends ConsumerStatefulWidget {
  const EditScreen({super.key, this.mevcut, this.baslangicNumara});

  /// Düzenleme modunda mevcut kayıt; ekleme modunda `null`.
  final Kalip? mevcut;

  /// Taramadan gelen, önceden doldurulacak numara.
  final String? baslangicNumara;

  @override
  ConsumerState<EditScreen> createState() => _EditScreenState();
}

class _EditScreenState extends ConsumerState<EditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _numara;
  late final TextEditingController _kod;
  late final TextEditingController _reyon;
  late final TextEditingController _ad;
  late final TextEditingController _notlar;

  String? _fotoYolu;
  bool _favori = false;
  bool _kaydediliyor = false;

  bool get _duzenleme => widget.mevcut != null;

  @override
  void initState() {
    super.initState();
    final m = widget.mevcut;
    _numara = TextEditingController(text: m?.numara ?? widget.baslangicNumara ?? '');
    _kod = TextEditingController(text: m?.kod ?? '');
    _reyon = TextEditingController(text: m?.reyon ?? '');
    _ad = TextEditingController(text: m?.ad ?? '');
    _notlar = TextEditingController(text: m?.notlar ?? '');
    _fotoYolu = m?.fotoYolu;
    _favori = m?.favori ?? false;
  }

  @override
  void dispose() {
    _numara.dispose();
    _kod.dispose();
    _reyon.dispose();
    _ad.dispose();
    _notlar.dispose();
    super.dispose();
  }

  Future<void> _fotografSec(ImageSource kaynak) async {
    try {
      final secilen = await ImagePicker()
          .pickImage(source: kaynak, maxWidth: 1280, imageQuality: 85);
      if (secilen == null) return;
      final dir = await getApplicationDocumentsDirectory();
      final klasor = Directory(p.join(dir.path, 'fotograflar'));
      if (!klasor.existsSync()) klasor.createSync(recursive: true);
      final hedef = p.join(
          klasor.path, '${DateTime.now().millisecondsSinceEpoch}.jpg');
      await File(secilen.path).copy(hedef);
      if (mounted) setState(() => _fotoYolu = hedef);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fotoğraf seçilemedi.')),
        );
      }
    }
  }

  void _fotoKaynakSec() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.koyuArkaplan.first,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded),
              title: const Text('Kamera ile çek'),
              onTap: () {
                Navigator.pop(context);
                _fotografSec(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Galeriden seç'),
              onTap: () {
                Navigator.pop(context);
                _fotografSec(ImageSource.gallery);
              },
            ),
            if (_fotoYolu != null)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded,
                    color: AppColors.kirmizi),
                title: const Text('Fotoğrafı kaldır'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _fotoYolu = null);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _kaydet() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _kaydediliyor = true);

    final repo = ref.read(repositoryProvider);
    final simdi = DateTime.now();
    final temel = Kalip(
      id: widget.mevcut?.id,
      numara: _numara.text.trim(),
      kod: _kod.text.trim(),
      reyon: _reyon.text.trim(),
      ad: _ad.text.trim().isEmpty ? null : _ad.text.trim(),
      notlar: _notlar.text.trim().isEmpty ? null : _notlar.text.trim(),
      fotoYolu: _fotoYolu,
      favori: _favori,
      olusturma: widget.mevcut?.olusturma ?? simdi,
      guncelleme: simdi,
    );

    try {
      if (_duzenleme) {
        await repo.guncelle(temel);
      } else {
        await repo.ekle(temel);
      }
      kalipVerisiniYenile(ref);
      if (!mounted) return;
      await _basariGoster();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _kaydediliyor = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kaydedilemedi: $e')),
        );
      }
    }
  }

  Future<void> _basariGoster() async {
    HapticFeedback.mediumImpact();
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (context, anim, __, ___) => Center(
        child: ScaleTransition(
          scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.koyuArkaplan[1],
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SuccessCheck(),
                const SizedBox(height: 12),
                Text(_duzenleme ? 'Güncellendi' : 'Kaydedildi',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 1000));
    if (mounted) Navigator.of(context, rootNavigator: true).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(_duzenleme ? 'Kalıbı Düzenle' : 'Yeni Kalıp'),
      ),
      body: GradientBackground(
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
              children: [
                Center(child: _fotoSecici()),
                const SizedBox(height: 22),
                _alan(
                  controller: _numara,
                  etiket: 'Numara *',
                  ikon: Icons.numbers_rounded,
                  zorunlu: true,
                ),
                const SizedBox(height: 14),
                _alan(
                  controller: _kod,
                  etiket: 'Kod',
                  ikon: Icons.tag_rounded,
                ),
                const SizedBox(height: 14),
                _alan(
                  controller: _reyon,
                  etiket: 'Reyon (raf)',
                  ikon: Icons.grid_view_rounded,
                ),
                const SizedBox(height: 14),
                _alan(
                  controller: _ad,
                  etiket: 'Ad / açıklama',
                  ikon: Icons.label_outline_rounded,
                ),
                const SizedBox(height: 14),
                _alan(
                  controller: _notlar,
                  etiket: 'Notlar',
                  ikon: Icons.sticky_note_2_outlined,
                  satir: 3,
                ),
                const SizedBox(height: 14),
                Card(
                  child: SwitchListTile(
                    value: _favori,
                    onChanged: (v) => setState(() => _favori = v),
                    secondary: Icon(
                      _favori
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: _favori ? AppColors.amber : null,
                    ),
                    title: const Text('Favori'),
                    subtitle: const Text('Sık kullanılanlarda öne çıksın'),
                  ),
                ),
                const SizedBox(height: 26),
                FilledButton.icon(
                  onPressed: _kaydediliyor ? null : _kaydet,
                  icon: _kaydediliyor
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save_rounded),
                  label: Text(_duzenleme ? 'Kaydet' : 'Kalıbı Ekle'),
                ),
              ]
                  .animate(interval: 60.ms)
                  .fadeIn(duration: 320.ms)
                  .moveY(begin: 12, end: 0),
            ),
          ),
        ),
      ),
    );
  }

  Widget _fotoSecici() {
    final varMi = _fotoYolu != null && File(_fotoYolu!).existsSync();
    return GestureDetector(
      onTap: _fotoKaynakSec,
      child: Container(
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: const LinearGradient(
            colors: [AppColors.mor, AppColors.camgobegi],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: varMi
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(File(_fotoYolu!), fit: BoxFit.cover),
                  const Positioned(
                    right: 8,
                    bottom: 8,
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.black54,
                      child: Icon(Icons.edit_rounded,
                          size: 16, color: Colors.white),
                    ),
                  ),
                ],
              )
            : const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo_rounded,
                      color: Colors.white, size: 38),
                  SizedBox(height: 8),
                  Text('Fotoğraf ekle',
                      style: TextStyle(color: Colors.white)),
                ],
              ),
      ),
    );
  }

  Widget _alan({
    required TextEditingController controller,
    required String etiket,
    required IconData ikon,
    bool zorunlu = false,
    int satir = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: satir,
      textInputAction:
          satir > 1 ? TextInputAction.newline : TextInputAction.next,
      decoration: InputDecoration(
        labelText: etiket,
        prefixIcon: Icon(ikon),
      ),
      validator: zorunlu
          ? (v) =>
              (v == null || v.trim().isEmpty) ? 'Bu alan gerekli' : null
          : null,
    );
  }
}
