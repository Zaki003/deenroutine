import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/habit.dart';
import '../providers/habit_provider.dart';
import '../theme/deen_colors.dart';
import '../utils/duration_format.dart';
import 'habit_progress_ring.dart';

/// Dashboard control for a [HabitTrackingType.timer] habit: owns a local
/// ticker, shows a live mm:ss glyph while running and a play icon while
/// idle/paused, and checkpoints elapsed seconds via
/// [HabitProvider.logTimerProgress] on pause and on completion.
///
/// Foreground-only for now — there's no background service, so elapsed time
/// only persists at a checkpoint. If the app is killed while actively
/// running (not paused), the seconds since the last checkpoint are lost.
class HabitTimerControl extends StatefulWidget {
  final Habit habit;
  final bool dark;

  const HabitTimerControl({super.key, required this.habit, required this.dark});

  @override
  State<HabitTimerControl> createState() => _HabitTimerControlState();
}

class _HabitTimerControlState extends State<HabitTimerControl> {
  Timer? _ticker;
  late int _elapsedSeconds =
      widget.habit.hasProgressToday ? widget.habit.todayProgressValue : 0;
  bool _running = false;

  int get _targetSeconds => widget.habit.timerTargetMinutes * 60;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _toggleRunning() {
    if (widget.habit.isCompletedToday) {
      _undo();
      return;
    }
    _running ? _pause() : _start();
  }

  /// Rolls the local ticker back to just under target along with the
  /// provider write — [_elapsedSeconds] is this widget's own state, not
  /// derived from [widget.habit] on every build, so it wouldn't otherwise
  /// notice the undo until the next stream refresh. Left stale, the ring
  /// would still read as full after "done" turns false, and the very next
  /// tap would instantly re-complete it from the old cached value.
  void _undo() {
    setState(() => _elapsedSeconds = (_targetSeconds - 1).clamp(0, _targetSeconds));
    context.read<HabitProvider>().undoCompletion(widget.habit);
  }

  void _start() {
    setState(() => _running = true);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsedSeconds++);
      if (_elapsedSeconds >= _targetSeconds) {
        _ticker?.cancel();
        setState(() => _running = false);
        _checkpoint();
      }
    });
  }

  void _pause() {
    _ticker?.cancel();
    setState(() => _running = false);
    _checkpoint();
  }

  void _checkpoint() {
    context.read<HabitProvider>().logTimerProgress(
          widget.habit,
          elapsedSeconds: _elapsedSeconds,
        );
  }

  @override
  Widget build(BuildContext context) {
    final target = _targetSeconds;
    final remaining = (target - _elapsedSeconds).clamp(0, target);
    return HabitProgressRing(
      progress: target == 0 ? 0 : _elapsedSeconds / target,
      done: widget.habit.isCompletedToday,
      dark: widget.dark,
      onTap: _toggleRunning,
      centerGlyph: _running
          ? Text(
              formatMmSs(Duration(seconds: remaining)),
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.bold,
                color: DeenColors.primaryText(widget.dark),
              ),
            )
          : Icon(Icons.play_arrow, size: 16, color: DeenColors.primary),
    );
  }
}
