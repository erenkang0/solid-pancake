import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../models/kalip.dart';
import '../theme/app_theme.dart';

/// Bir kalıbın numarasını yazdırılabilir/paylaşılabilir QR etiketi olarak
/// üretir. Etiketi yapıştırıp daha sonra QR moduyla güvenilir okursunuz.
class QrScreen extends StatelessWidget {
  QrScreen({super.key, required this.kalip});

  final Kalip kalip;
  final GlobalKey _etiketKey = GlobalKey();

  Future<void> _paylas(BuildContext context) async {
    try {
      final boundary = _etiketKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final bytes = byteData.buffer.asUint8List();

      final dir = await getTemporaryDirectory();
      final dosya = File(p.join(dir.path,
          'kalip_etiket_${kalip.numara.replaceAll(RegExp(r'[^A-Za-z0-9]'), '_')}.png'));
      await dosya.writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(dosya.path)],
        subject: 'Kalıp ${kalip.numara} etiketi',
        text: 'Kalıp ${kalip.numara} • Kod: ${kalip.kod} • Reyon: ${kalip.reyon}',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Etiket paylaşılamadı: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QR Etiket')),
      backgroundColor: AppColors.koyuArkaplan.first,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Bu etiketi yazdırıp kalıba yapıştırın.\nSonra "QR/Barkod" moduyla okuyun.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 20),
            RepaintBoundary(
              key: _etiketKey,
              child: Container(
                width: 280,
                padding: const EdgeInsets.all(22),
                color: Colors.white,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    QrImageView(
                      data: kalip.numara,
                      version: QrVersions.auto,
                      size: 220,
                      gapless: true,
                      backgroundColor: Colors.white,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      kalip.numara,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                    if (kalip.kod.isNotEmpty || kalip.reyon.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          [
                            if (kalip.kod.isNotEmpty) 'Kod: ${kalip.kod}',
                            if (kalip.reyon.isNotEmpty) 'Reyon: ${kalip.reyon}',
                          ].join('   •   '),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.black54, fontSize: 13),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: () => _paylas(context),
              icon: const Icon(Icons.ios_share_rounded),
              label: const Text('Etiketi Paylaş / Yazdır'),
            ),
          ],
        ),
      ),
    );
  }
}
