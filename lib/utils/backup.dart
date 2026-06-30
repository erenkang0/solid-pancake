import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart' as fs;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/kalip.dart';

/// Kalıp verisini JSON dosyası olarak dışa/içe aktarma.
class BackupService {
  static const _imza = 'kalip_takip';

  /// Tüm kayıtları geçici bir JSON dosyasına yazar ve dosyayı döndürür.
  static Future<File> dosyaOlustur(List<Kalip> kayitlar) async {
    final data = <String, Object?>{
      'uygulama': _imza,
      'surum': 1,
      'tarih': DateTime.now().toIso8601String(),
      'adet': kayitlar.length,
      'kaliplar': kayitlar.map((e) => e.toJson()).toList(),
    };
    final dir = await getTemporaryDirectory();
    final damga = DateTime.now()
        .toIso8601String()
        .replaceAll(RegExp(r'[:.]'), '-')
        .split('T')
        .join('_')
        .substring(0, 16);
    final file = File(p.join(dir.path, 'kalip_yedek_$damga.json'));
    await file
        .writeAsString(const JsonEncoder.withIndent('  ').convert(data));
    return file;
  }

  /// Kayıtları CSV (Excel uyumlu) dosyasına yazar ve dosyayı döndürür.
  static Future<File> csvDosyasiOlustur(String csv) async {
    final dir = await getTemporaryDirectory();
    final file = File(p.join(dir.path, 'kaliplar.csv'));
    // Excel'in Türkçe karakterleri doğru okuması için UTF-8 BOM eklenir.
    await file.writeAsString('﻿$csv');
    return file;
  }

  /// Yedek dosyasını paylaşım menüsüyle dışa aktarır.
  static Future<void> paylas(File file) async {
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Kalıp Takip Yedeği',
      text: 'Kalıp Takip yedek dosyası',
    );
  }

  /// Kullanıcıdan bir JSON yedeği seçtirir ve kayıtları çözümler.
  /// Geçerli bir dosya seçilmezse `null` döner.
  static Future<List<Kalip>?> dosyadanOku() async {
    const typeGroup = fs.XTypeGroup(
      label: 'JSON',
      extensions: ['json'],
      mimeTypes: ['application/json'],
    );
    final secilen = await fs.openFile(acceptedTypeGroups: [typeGroup]);
    if (secilen == null) return null;

    final content = await secilen.readAsString();
    final decoded = jsonDecode(content);
    if (decoded is! Map || decoded['kaliplar'] is! List) {
      throw const FormatException('Geçersiz yedek dosyası.');
    }
    final list = (decoded['kaliplar'] as List)
        .whereType<Map>()
        .map((e) => Kalip.fromJson(e.cast<String, Object?>()))
        .where((k) => k.numara.isNotEmpty)
        .toList();
    return list;
  }
}
