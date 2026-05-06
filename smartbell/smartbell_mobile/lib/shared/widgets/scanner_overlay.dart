import 'package:flutter/material.dart';

const _kAmber    = Color(0xFFEF9F27);
const _kScanRed  = Color(0xFFE24B4A);
const _kSquare   = 250.0;
const _kCorner   = 28.0;
const _kStroke   = 3.5;

class ScannerOverlay extends StatefulWidget {
  const ScannerOverlay({super.key});

  @override
  State<ScannerOverlay> createState() => _ScannerOverlayState();
}

class _ScannerOverlayState extends State<ScannerOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _lineCtrl;
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _lineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _lineCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_lineCtrl, _pulseCtrl]),
      builder: (_, __) => CustomPaint(
        painter: _OverlayPainter(
          scanProgress: _lineCtrl.value,
          pulse:        _pulseCtrl.value,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _OverlayPainter extends CustomPainter {
  final double scanProgress;
  final double pulse;

  const _OverlayPainter({required this.scanProgress, required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    final cx   = size.width / 2;
    final cy   = size.height / 2;
    const half = _kSquare / 2;
    final l = cx - half;
    final t = cy - half;
    final r = cx + half;
    final b = cy + half;

    // ── Dark overlay (4 rectangles leave a transparent square) ──
    final dark = Paint()..color = Colors.black.withValues(alpha: 0.72);
    canvas.drawRect(Rect.fromLTRB(0, 0, size.width, t), dark);
    canvas.drawRect(Rect.fromLTRB(0, b, size.width, size.height), dark);
    canvas.drawRect(Rect.fromLTRB(0, t, l, b), dark);
    canvas.drawRect(Rect.fromLTRB(r, t, size.width, b), dark);

    // Subtle outline on the transparent square
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTRB(l, t, r, b), const Radius.circular(4)),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // ── Corner L-shapes with pulse glow ──
    final alpha  = 0.55 + 0.45 * pulse;
    final corner = Paint()
      ..color     = _kAmber.withValues(alpha: alpha)
      ..style     = PaintingStyle.stroke
      ..strokeWidth = _kStroke
      ..strokeCap = StrokeCap.square;

    // Glow layer when pulse is strong
    if (pulse > 0.25) {
      final glow = Paint()
        ..color      = _kAmber.withValues(alpha: pulse * 0.30)
        ..style      = PaintingStyle.stroke
        ..strokeWidth = _kStroke + 5
        ..strokeCap  = StrokeCap.square
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
      _corners(canvas, l, t, r, b, glow);
    }
    _corners(canvas, l, t, r, b, corner);

    // ── Animated scan line (top → bottom, loops) ──
    final scanY = t + _kSquare * scanProgress;
    if (scanY >= t && scanY <= b) {
      // Main line with gradient fade on the edges
      final lineShader = LinearGradient(
        colors: [
          _kScanRed.withValues(alpha: 0),
          _kScanRed.withValues(alpha: 0.95),
          _kScanRed,
          _kScanRed.withValues(alpha: 0.95),
          _kScanRed.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromLTRB(l, scanY, r, scanY + 2));

      canvas.drawLine(
        Offset(l, scanY),
        Offset(r, scanY),
        Paint()
          ..shader     = lineShader
          ..strokeWidth = 1.8,
      );

      // Soft glow beneath
      final glowShader = LinearGradient(
        colors: [
          _kScanRed.withValues(alpha: 0),
          _kScanRed.withValues(alpha: 0.18),
          _kScanRed.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromLTRB(l, scanY, r, scanY + 10));

      canvas.drawLine(
        Offset(l, scanY + 4),
        Offset(r, scanY + 4),
        Paint()
          ..shader     = glowShader
          ..strokeWidth = 10
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
    }
  }

  void _corners(Canvas c, double l, double t, double r, double b, Paint p) {
    // Top-left
    c.drawPath(
      Path()..moveTo(l, t + _kCorner)..lineTo(l, t)..lineTo(l + _kCorner, t),
      p,
    );
    // Top-right
    c.drawPath(
      Path()..moveTo(r - _kCorner, t)..lineTo(r, t)..lineTo(r, t + _kCorner),
      p,
    );
    // Bottom-left
    c.drawPath(
      Path()..moveTo(l, b - _kCorner)..lineTo(l, b)..lineTo(l + _kCorner, b),
      p,
    );
    // Bottom-right
    c.drawPath(
      Path()..moveTo(r - _kCorner, b)..lineTo(r, b)..lineTo(r, b - _kCorner),
      p,
    );
  }

  @override
  bool shouldRepaint(_OverlayPainter old) =>
      old.scanProgress != scanProgress || old.pulse != pulse;
}
