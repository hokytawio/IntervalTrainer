import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import 'models.dart';

enum PhaseType { prep, work, rest, change }

class Phase {
  final PhaseType type;
  final int seconds;

  /// For work/rest: the current exercise. For change: the NEXT exercise.
  final int exercise;

  /// Set index (0-based) within the exercise.
  final int set;

  const Phase(this.type, this.seconds, this.exercise, this.set);

  @override
  String toString() => '$type(${seconds}s, ex $exercise, set $set)';
}

/// Builds the full sequence of phases for a preset.
/// After the last set of an exercise the change time REPLACES the rest.
List<Phase> buildTimeline(Preset p, {int prepSec = 10}) {
  final out = <Phase>[];
  if (p.exercises.isEmpty) return out;
  if (prepSec > 0) out.add(Phase(PhaseType.prep, prepSec, 0, 0));
  for (var e = 0; e < p.exercises.length; e++) {
    final ex = p.exercises[e];
    for (var s = 0; s < ex.sets; s++) {
      out.add(Phase(PhaseType.work, ex.workSec, e, s));
      final lastSet = s == ex.sets - 1;
      final lastEx = e == p.exercises.length - 1;
      if (!lastSet) {
        if (ex.restSec > 0) out.add(Phase(PhaseType.rest, ex.restSec, e, s));
      } else if (!lastEx && p.changeSec > 0) {
        out.add(Phase(PhaseType.change, p.changeSec, e + 1, 0));
      }
    }
  }
  return out;
}

enum CueKind { phaseStart, secondsLeft, countdown, finished }

class Cue {
  final CueKind kind;
  final Phase? phase;
  final int value;
  const Cue(this.kind, this.phase, this.value);
}

/// Clock-based timer: remaining time is computed from a monotonic stopwatch,
/// so it never drifts, even if a UI frame or tick is late.
class WorkoutEngine extends ChangeNotifier {
  WorkoutEngine(
    this.phases, {
    required this.onCue,
    this.tick = const Duration(milliseconds: 100),
  });

  final List<Phase> phases;
  final void Function(Cue cue) onCue;
  final Duration tick;

  int index = 0;
  bool paused = false;
  bool finished = false;
  bool started = false;

  final Stopwatch _phaseWatch = Stopwatch();
  final Stopwatch _totalWatch = Stopwatch();
  int _offsetMs = 0; // overflow carried from the previous phase
  int _lastWhole = -1;
  Timer? _timer;

  Phase get current => phases[min(index, phases.length - 1)];

  int get _elapsedMs => _phaseWatch.elapsedMilliseconds + _offsetMs;

  int get remainingMs =>
      finished ? 0 : max(0, current.seconds * 1000 - _elapsedMs);

  /// Seconds shown on screen (rounded up, like a real countdown).
  int get remainingWhole => (remainingMs / 1000).ceil();

  double get phaseProgress {
    if (finished) return 1;
    if (current.seconds <= 0) return 1;
    return (1 - remainingMs / (current.seconds * 1000)).clamp(0.0, 1.0);
  }

  int get totalElapsedSec => _totalWatch.elapsed.inSeconds;

  int get setsTotal => phases.where((p) => p.type == PhaseType.work).length;

  int get setsDone =>
      phases.take(index).where((p) => p.type == PhaseType.work).length;

  double get overallProgress {
    final total = phases.fold<int>(0, (a, p) => a + p.seconds);
    if (total == 0) return 1;
    if (finished) return 1;
    final done = phases.take(index).fold<int>(0, (a, p) => a + p.seconds) +
        (current.seconds - remainingMs / 1000);
    return (done / total).clamp(0.0, 1.0);
  }

  /// The next phase after the current one, if any.
  Phase? get nextPhase => index + 1 < phases.length ? phases[index + 1] : null;

  void start() {
    if (started) return;
    started = true;
    if (phases.isEmpty) {
      _finish();
      return;
    }
    _totalWatch.start();
    _enter(0, 0);
    _timer = Timer.periodic(tick, (_) => _tick());
  }

  void _enter(int i, int offsetMs) {
    index = i;
    _offsetMs = offsetMs;
    _phaseWatch
      ..reset()
      ..start();
    if (paused) _phaseWatch.stop();
    _lastWhole = current.seconds;
    onCue(Cue(CueKind.phaseStart, current, current.seconds));
    notifyListeners();
  }

  void _advance({required int carryMs}) {
    if (index + 1 >= phases.length) {
      _finish();
    } else {
      _enter(index + 1, carryMs);
    }
  }

  void _tick() {
    if (paused || finished) return;
    // A late tick may cover the end of one (or more) phases.
    while (!finished && remainingMs <= 0) {
      final carry = _elapsedMs - current.seconds * 1000;
      _advance(carryMs: max(0, carry));
    }
    if (finished) return;
    final w = remainingWhole;
    if (w != _lastWhole) {
      _lastWhole = w;
      if (w < current.seconds) {
        if (w == 30 || w == 10) {
          onCue(Cue(CueKind.secondsLeft, current, w));
        } else if (w >= 1 && w <= 5) {
          onCue(Cue(CueKind.countdown, current, w));
        }
      }
    }
    notifyListeners();
  }

  void pause() {
    if (finished || paused) return;
    paused = true;
    _phaseWatch.stop();
    _totalWatch.stop();
    notifyListeners();
  }

  void resume() {
    if (finished || !paused) return;
    paused = false;
    _phaseWatch.start();
    _totalWatch.start();
    notifyListeners();
  }

  void togglePause() => paused ? resume() : pause();

  void skip() {
    if (finished || !started) return;
    _advance(carryMs: 0);
  }

  /// Stops without firing the "finished" cue (user aborted).
  void stop() {
    _timer?.cancel();
    _phaseWatch.stop();
    _totalWatch.stop();
  }

  void _finish() {
    finished = true;
    index = phases.length;
    _timer?.cancel();
    _phaseWatch.stop();
    _totalWatch.stop();
    onCue(const Cue(CueKind.finished, null, 0));
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
