import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class CountdownTimer extends StatefulWidget {
  final int seconds;
  final VoidCallback onFinished;
  final double fontSize;

  const CountdownTimer({
    super.key,
    required this.seconds,
    required this.onFinished,
    this.fontSize = 36,
  });

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  late int _remaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remaining = widget.seconds;
    _start();
  }

  @override
  void didUpdateWidget(CountdownTimer old) {
    super.didUpdateWidget(old);
    if (old.seconds != widget.seconds) {
      _timer?.cancel();
      _remaining = widget.seconds;
      _start();
    }
  }

  void _start() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remaining <= 0) {
        _timer?.cancel();
        widget.onFinished();
      } else {
        setState(() => _remaining--);
      }
    });
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  String get _display {
    final m = _remaining ~/ 60;
    final s = _remaining % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Color get _color {
    if (_remaining > 30) return AppTheme.primary;
    if (_remaining > 10) return AppTheme.warning;
    return AppTheme.error;
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        _display,
        style: TextStyle(
          color: _color,
          fontSize: widget.fontSize,
          fontWeight: FontWeight.bold,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
      const SizedBox(height: 6),
      Text(
        _remaining == 0 ? 'Repos terminé !' : 'Temps de repos',
        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
      ),
    ],
  );
}
