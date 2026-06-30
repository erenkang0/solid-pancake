import 'package:flutter/material.dart';

/// Çizilerek beliren animasyonlu onay (✓) işareti. Eşleşme/kayıt başarısında
/// gösterilir.
class SuccessCheck extends StatefulWidget {
  const SuccessCheck({
    super.key,
    this.boyut = 96,
    this.renk = const Color(0xFF34D399),
  });

  final double boyut;
  final Color renk;

  @override
  State<SuccessCheck> createState() => _SuccessCheckState();
}

class _SuccessCheckState extends State<SuccessCheck>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.boyut,
      height: widget.boyut,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          return CustomPaint(
            painter: _CheckPainter(progress: _c.value, renk: widget.renk),
          );
        },
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  _CheckPainter({required this.progress, required this.renk});

  final double progress;
  final Color renk;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;

    // Halka: 0.0 - 0.6 arası çizilir
    final ringP = (progress / 0.6).clamp(0.0, 1.0);
    final ringPaint = Paint()
      ..color = renk
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 4),
      -1.57,
      6.283 * ringP,
      false,
      ringPaint,
    );

    // Onay işareti: 0.55 - 1.0 arası çizilir
    final tickP = ((progress - 0.55) / 0.45).clamp(0.0, 1.0);
    final p1 = Offset(size.width * 0.30, size.height * 0.52);
    final p2 = Offset(size.width * 0.44, size.height * 0.66);
    final p3 = Offset(size.width * 0.72, size.height * 0.36);

    final tickPaint = Paint()
      ..color = renk
      ..strokeWidth = 7
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()..moveTo(p1.dx, p1.dy);
    if (tickP <= 0.5) {
      final f = tickP / 0.5;
      path.lineTo(
          p1.dx + (p2.dx - p1.dx) * f, p1.dy + (p2.dy - p1.dy) * f);
    } else {
      path.lineTo(p2.dx, p2.dy);
      final f = (tickP - 0.5) / 0.5;
      path.lineTo(
          p2.dx + (p3.dx - p2.dx) * f, p2.dy + (p3.dy - p2.dy) * f);
    }
    canvas.drawPath(path, tickPaint);
  }

  @override
  bool shouldRepaint(covariant _CheckPainter old) =>
      old.progress != progress || old.renk != renk;
}
