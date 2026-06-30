/// Tarihi Türkçe ve kısa biçimde gösterir (ör. "30 Haz 2026, 14:05").
String tarihBicimle(DateTime d) {
  const aylar = [
    'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
    'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara',
  ];
  final saat = d.hour.toString().padLeft(2, '0');
  final dakika = d.minute.toString().padLeft(2, '0');
  return '${d.day} ${aylar[d.month - 1]} ${d.year}, $saat:$dakika';
}
