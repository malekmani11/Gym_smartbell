import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import 'circular_countdown_timer.dart';

class WorkoutRestTimer extends StatefulWidget {
  final int restSeconds;
  final String? nextExerciseName;
  final VoidCallback onComplete;
  final VoidCallback onSkip;

  const WorkoutRestTimer({
    super.key,
    required this.restSeconds,
    this.nextExerciseName,
    required this.onComplete,
    required this.onSkip,
  });

  @override
  State<WorkoutRestTimer> createState() => _WorkoutRestTimerState();
}

class _WorkoutRestTimerState extends State<WorkoutRestTimer> {
  final _controller = CircularCountdownTimerController();
  bool _paused = false;

  void _onTick(int remaining) {
    if (remaining > 0 && remaining <= 4) {
      SystemSound.play(SystemSoundType.click);
    }
  }

  void _onComplete() {
    HapticFeedback.heavyImpact();
    widget.onComplete();
  }

  void _togglePause() {
    setState(() => _paused = !_paused);
    if (_paused) {
      _controller.pause();
    } else {
      _controller.resume();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),

            // Header
            const Text(
              'Temps de repos',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (widget.nextExerciseName != null) ...[
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Exercice suivant : ',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                  ),
                  Flexible(
                    child: Text(
                      widget.nextExerciseName!,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 28),

            // Circular timer
            CircularCountdownTimer(
              duration: widget.restSeconds,
              onComplete: _onComplete,
              label: 'REPOS',
              controller: _controller,
              onTick: _onTick,
            ),
            const SizedBox(height: 32),

            // Controls row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _AdjustButton(
                  label: '-15s',
                  icon: Icons.remove,
                  onTap: () => _controller.addSeconds(-15),
                ),
                const SizedBox(width: 20),
                GestureDetector(
                  onTap: _togglePause,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                      color: Colors.black,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                _AdjustButton(
                  label: '+15s',
                  icon: Icons.add,
                  onTap: () => _controller.addSeconds(15),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Skip
            TextButton.icon(
              onPressed: widget.onSkip,
              icon: const Icon(Icons.skip_next_rounded, size: 18),
              label: const Text('Passer le repos'),
              style: TextButton.styleFrom(foregroundColor: AppTheme.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdjustButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _AdjustButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppTheme.primary, size: 15),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      );
}
