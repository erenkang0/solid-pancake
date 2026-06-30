import 'package:flutter/material.dart';

/// Kamera önizlemesinin üzerine çizilen animasyonlu tarama çerçevesi:
/// köşe braketleri + aşağı yukarı süzülen tarama çizgisi.
class ScanOverlay extends StatefulWidget {
  const ScanOverlay({
    super.key,
    this.renk = const Color(0xFF22D3EE),
    this.cerceveOrani = 0.78,
    this.cerceveYukseklik = 150,
  });

  final Color renk;
  final double cerceveOrani;
  final double cerceveYukseklik;

  @override
  State<ScanOverlay> createState() => _ScanOverlayState();
}

class _ScanOverlayState extends State<ScanOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth * widget.cerceveOrani;
        final h = widget.cerceveYukseklik;
        return Stack(
          alignment: Alignment.center,
          children: [
            // Çerçeve dışını karart
            ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withValues(alpha: 0.55),
                BlendMode.srcOut,
              ),
              child: Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      backgroundBlendMode: BlendMode.dstOut,
                    ),
                  ),
                  Center(
                    child: Container(
                      width: w,
                      height: h,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Çerçeve + köşeler + tarama çizgisi
            SizedBox(
              width: w,
              height: h,
              child: AnimatedBuilder(
                animation: _c,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _FramePainter(
                      renk: widget.renk,
                      cizgiKonumu: _c.value,
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FramePainter extends CustomPainter {
  _FramePainter({required this.renk, required this.cizgiKonumu});

  final Color renk;
  final double cizgiKonumu;

  @override
  void paint(Canvas canvas, Size size) {
    const corner = 26.0;
    final p = Paint()
      ..color = renk
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Sol üst
    canvas.drawLine(const Offset(0, corner), const Offset(0, 0), p);
    canvas.drawLine(const Offset(0, 0), const Offset(corner, 0), p);
    // Sağ üst
    canvas.drawLine(Offset(size.width - corner, 0), Offset(size.width, 0), p);
    canvas.drawLine(
        Offset(size.width, 0), Offset(size.width, corner), p);
    // Sol alt
    canvas.drawLine(
        Offset(0, size.height - corner), Offset(0, size.height), p);
    canvas.drawLine(
        Offset(0, size.height), Offset(corner, size.height), p);
    // Sağ alt
    canvas.drawLine(Offset(size.width - corner, size.height),
        Offset(size.width, size.height), p);
    canvas.drawLine(Offset(size.width, size.height - corner),
        Offset(size.width, size.height), p);

    // Süzülen tarama çizgisi
    final y = size.height * cizgiKonumu;
    final shader = LinearGradient(
      colors: [
        renk.withValues(alpha: 0),
        renk,
        renk.withValues(alpha: 0),
      ],
    ).createShader(Rect.fromLTWH(0, 0, size.width, 1));
    final linePaint = Paint()
      ..shader = shader
      ..strokeWidth = 3;
    canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
  }

  @override
  bool shouldRepaint(covariant _FramePainter old) =>
      old.cizgiKonumu != cizgiKonumu || old.renk != renk;
}
