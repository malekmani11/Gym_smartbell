import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

const _kAmber = Color(0xFFEF9F27);
const _kRed   = Color(0xFFE24B4A);
const _kTrack = Color(0xFF2A2A2A);

// ─── Controller ───────────────────────────────────────────────────────────────

class CircularCountdownTimerController {
  _CircularCountdownTimerState? _state;

  void pause()           => _state?._pause();
  void resume()          => _state?._resume();
  void addSeconds(int s) => _state?._addSeconds(s);
  void skip()            => _state?._skip();
  bool get isPaused      => _state?._paused ?? false;
}

// ─── Widget ───────────────────────────────────────────────────────────────────

class CircularCountdownTimer extends StatefulWidget {
  final int duration;
  final VoidCallback onComplete;
  final bool autoStart;
  final String label;
  final CircularCountdownTimerController? controller;
  final ValueChanged<int>? onTick;

  const CircularCountdownTimer({
    super.key,
    required this.duration,
    required this.onComplete,
    this.autoStart = true,
    this.label = 'REPOS',
    this.controller,
    this.onTick,
  });

  @override
  State<CircularCountdownTimer> createState() => _CircularCountdownTimerState();
}

class _CircularCountdownTimerState extends State<CircularCountdownTimer>
    with SingleTickerProviderStateMixin {
  // AnimationController drives the smooth arc (value: 1.0 → 0.0)
  late AnimationController _animCtrl;
  late int _totalSeconds;
  int _remaining = 0;
  Timer? _tickTimer;
  bool _paused = false;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _totalSeconds = widget.duration.clamp(1, 9999);
    _remaining = _totalSeconds;
    widget.controller?._state = this;

    _animCtrl = AnimationController(vsync: this, value: 1.0);
    _animCtrl.addStatusListener(_onAnimStatus);

    if (widget.autoStart) _run();
  }

  // Fires when animation reaches 0.0 (dismissed = lowerBound reached)
  void _onAnimStatus(AnimationStatus status) {
    if (status == AnimationStatus.dismissed && !_done && !_paused) {
      _done = true;
      _tickTimer?.cancel();
      widget.onComplete();
    }
  }

  // Start or resume the animation + second tick
  void _run() {
    _done = false;

    // Smooth arc: animate from current value → 0.0 over _remaining seconds
    _animCtrl.animateTo(
      0.0,
      duration: Duration(seconds: _remaining),
      curve: Curves.linear,
    );

    // Tick timer: updates the displayed countdown and fires onTick callbacks
    _tickTimer?.cancel();
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _paused) return;
      if (_remaining <= 1) {
        _tickTimer?.cancel();
        if (mounted) setState(() => _remaining = 0);
        return;
      }
      setState(() => _remaining--);
      widget.onTick?.call(_remaining);
    });
  }

  void _pause() {
    if (_paused) return;
    _tickTimer?.cancel();
    _animCtrl.stop();
    setState(() => _paused = true);
  }

  void _resume() {
    if (!_paused) return;
    if (_remaining <= 0) {
      widget.onComplete();
      return;
    }
    setState(() => _paused = false);
    _run();
  }

  void _addSeconds(int seconds) {
    final wasRunning = !_paused;
    _tickTimer?.cancel();
    _animCtrl.stop();

    _remaining = (_remaining + seconds).clamp(1, 9999);
    if (seconds > 0) _totalSeconds += seconds;

    // Reposition the arc to reflect the new remaining/total ratio
    _animCtrl.value = (_remaining / _totalSeconds).clamp(0.0, 1.0);
    if (mounted) setState(() {});

    if (wasRunning) _run();
  }

  void _skip() {
    _done = true;
    _tickTimer?.cancel();
    _animCtrl.stop();
    widget.onComplete();
  }

  @override
  void dispose() {
    widget.controller?._state = null;
    _animCtrl.removeStatusListener(_onAnimStatus);
    _animCtrl.dispose();
    _tickTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // AnimatedBuilder repaints the arc at 60 fps; _remaining updates each second
    return AnimatedBuilder(
      animation: _animCtrl,
      builder: (_, __) {
        final color = _remaining <= 5 ? _kRed : _kAmber;
        return SizedBox(
          width: 180,
          height: 180,
          child: CustomPaint(
            painter: _ArcPainter(ratio: _animCtrl.value, color: color),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$_remaining',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.label,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── CustomPainter ────────────────────────────────────────────────────────────

class _ArcPainter extends CustomPainter {
  final double ratio;
  final Color color;

  const _ArcPainter({required this.ratio, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 - 10;

    // Background track
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = _kTrack
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round,
    );

    // Active arc — starts at top (-π/2), sweeps clockwise, shrinks as ratio → 0
    if (ratio > 0.001) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        2 * pi * ratio,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_ArcPainter old) =>
      old.ratio != ratio || old.color != color;
}
