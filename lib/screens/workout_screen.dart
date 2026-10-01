import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../background.dart';
import '../catalog.dart';
import '../engine.dart';
import '../models.dart';
import '../storage.dart';
import '../voice.dart';
import '../xp/xp.dart';
import 'exercise_picker.dart';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key, required this.preset});
  final Preset preset;

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  late final WorkoutEngine _engine;
  final Announcer _voice = Announcer();
  final DateTime _startedAt = DateTime.now();
  bool _saved = false;
  bool _serviceOn = false;
  String _notifKey = '';

  @override
  void initState() {
    super.initState();
    final s = app.settings;
    _engine = WorkoutEngine(
      buildTimeline(widget.preset, prepSec: s.prepSec),
      onCue: (cue) {
        _voice.handle(cue, widget.preset);
        if (cue.kind == CueKind.finished) {
          _saveHistory(completed: true);
          _stopService();
        }
      },
    );
    _engine.addListener(_syncNotification);
    WorkoutNotification.onAction = _onNotificationAction;
    if (s.keepScreenOn) WakelockPlus.enable();
    ExerciseCatalog.load().then((_) {
      if (mounted) setState(() {});
    });
    _begin(s);
  }

  Future<void> _begin(Settings s) async {
    await WorkoutNotification.requestPermission();
    await _voice.init(lang: s.voiceLang, vibration: s.vibration);
    if (!mounted) return;
    _engine.start();
  }

  @override
  void dispose() {
    if (!_saved && _engine.started) _saveHistory(completed: false);
    _engine.removeListener(_syncNotification);
    if (WorkoutNotification.onAction == _onNotificationAction) {
      WorkoutNotification.onAction = null;
    }
    _stopService();
    _engine.stop();
    _engine.dispose();
    _voice.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  // ---- Foreground service / notification ----

  void _onNotificationAction(String action) {
    if (!mounted || _engine.finished) return;
    switch (action) {
      case 'pause':
        _engine.togglePause();
        break;
      case 'skip':
        _engine.skip();
        break;
      case 'stop':
        _engine.stop();
        _saveHistory(completed: false);
        _stopService();
        Navigator.pop(context);
        break;
    }
  }

  /// Updates the notification only when the phase or pause state changes;
  /// the notification's own countdown handles the seconds.
  void _syncNotification() {
    if (!_engine.started || _engine.finished) return;
    final key = '${_engine.index}|${_engine.paused}';
    if (key == _notifKey) return;
    _notifKey = key;
    final p = _engine.current;
    final title = _engine.paused
        ? '${_phaseLabel(p)} — PAUSED (${fmt(_engine.remainingWhole)})'
        : _phaseLabel(p);
    final text = _describe(p);
    final endAt =
        DateTime.now().millisecondsSinceEpoch + _engine.remainingMs;
    if (!_serviceOn) {
      _serviceOn = true;
      WorkoutNotification.start(
          title: title, text: text, endAt: endAt, paused: _engine.paused);
    } else {
      WorkoutNotification.update(
          title: title, text: text, endAt: endAt, paused: _engine.paused);
    }
  }

  void _stopService() {
    if (!_serviceOn) return;
    _serviceOn = false;
    WorkoutNotification.stop();
  }

  void _saveHistory({required bool completed}) {
    if (_saved) return;
    _saved = true;
    final entry = HistoryEntry(
      startedAt: _startedAt,
      presetName: widget.preset.name,
      plannedSec: widget.preset.plannedSec,
      elapsedSec: _engine.totalElapsedSec,
      setsDone: _engine.setsDone,
      setsTotal: _engine.setsTotal,
      completed: completed,
    );
    // Deferred so it never notifies listeners while the widget tree is locked.
    Future.microtask(() => app.addHistory(entry));
  }

  Future<void> _confirmStop() async {
    if (_engine.finished) {
      Navigator.pop(context);
      return;
    }
    final wasPaused = _engine.paused;
    _engine.pause();
    final r = await showXpDialog(
      context,
      title: 'Stop workout',
      message: 'Stop this workout? Your progress will be saved to history.',
      buttons: const ['Keep going', 'Stop'],
      icon: Icons.help_outline,
      dangerIndex: 1,
    );
    if (!mounted) return;
    if (r == 1) {
      _engine.stop();
      _saveHistory(completed: false);
      _stopService();
      Navigator.pop(context);
    } else if (!wasPaused) {
      _engine.resume();
    }
  }

  String _phaseLabel(Phase p) {
    switch (p.type) {
      case PhaseType.prep:
        return 'GET READY';
      case PhaseType.work:
        return 'WORK';
      case PhaseType.rest:
        return 'REST';
      case PhaseType.change:
        return 'CHANGE EXERCISE';
    }
  }

  Color _phaseColor(Phase p) {
    switch (p.type) {
      case PhaseType.prep:
        return Xp.prepColor;
      case PhaseType.work:
        return Xp.workColor;
      case PhaseType.rest:
        return Xp.restColor;
      case PhaseType.change:
        return Xp.changeColor;
    }
  }

  String _describe(Phase p) {
    final ex = widget.preset.exercises;
    final e = p.exercise < ex.length ? ex[p.exercise] : null;
    switch (p.type) {
      case PhaseType.prep:
        return 'First: ${e?.name ?? ''}';
      case PhaseType.work:
        return '${e?.name ?? ''} — set ${p.set + 1} of ${e?.sets ?? 0}';
      case PhaseType.rest:
        return 'Rest ${fmt(p.seconds)}';
      case PhaseType.change:
        return 'Change → ${e?.name ?? ''} (${fmt(p.seconds)})';
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmStop();
      },
      child: XpDesktop(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: XpWindow(
            title: widget.preset.name,
            icon: Icons.timer,
            expand: true,
            onClose: _confirmStop,
            child: ListenableBuilder(
              listenable: _engine,
              builder: (context, _) =>
                  _engine.finished ? _buildDone() : _buildRunning(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRunning() {
    if (!_engine.started) {
      return const Center(child: Text('Loading voice…'));
    }
    final p = _engine.current;
    final color = _phaseColor(p);
    final remaining = _engine.remainingWhole;
    final countdown = remaining <= 5 && remaining > 0 && p.seconds > 5;
    final ex = widget.preset.exercises;
    final exName = p.exercise < ex.length ? ex[p.exercise].name : '';
    final next = _engine.nextPhase;
    // During prep / change, p.exercise is the exercise that comes next.
    final catalogEx = p.exercise < ex.length
        ? ExerciseCatalog.loaded?.byId(ex[p.exercise].catalogId)
        : null;
    final upcoming = p.type == PhaseType.prep || p.type == PhaseType.change;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Phase banner
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color.lerp(color, Colors.white, 0.35)!, color],
            ),
            border: Border.all(color: Colors.black26),
          ),
          child: Text(
            _engine.paused ? '${_phaseLabel(p)} — PAUSED' : _phaseLabel(p),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              shadows: [Shadow(color: Colors.black45, offset: Offset(1, 1))],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(exName,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        if (p.type == PhaseType.work || p.type == PhaseType.rest)
          Text(
            'Exercise ${p.exercise + 1} of ${ex.length} · '
            'Set ${p.set + 1} of ${ex[p.exercise].sets}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54, fontSize: 14),
          ),
        if (catalogEx != null) ...[
          const SizedBox(height: 6),
          Center(
            child: XpButton(
              label: 'How to do it',
              icon: Icons.play_circle_outline,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => ExerciseHowToScreen(exercise: catalogEx)),
              ),
            ),
          ),
        ],
        if (catalogEx != null && upcoming) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 130,
            child: XpSunken(
              child: ExerciseAnimation(frames: catalogEx.frames),
            ),
          ),
        ],
        const SizedBox(height: 10),
        // Big time display
        Expanded(
          child: XpSunken(
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  transitionBuilder: (child, anim) =>
                      ScaleTransition(scale: anim, child: child),
                  child: Text(
                    countdown ? '$remaining' : fmt(remaining),
                    key: ValueKey(countdown ? 'c$remaining' : 't'),
                    style: TextStyle(
                      fontSize: countdown ? 200 : 110,
                      fontWeight: FontWeight.bold,
                      color: countdown ? const Color(0xFFD0301C) : color,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        XpProgressBar(value: _engine.phaseProgress, color: color),
        const SizedBox(height: 8),
        Text(next == null ? 'Up next: finish!' : 'Up next: ${_describe(next)}',
            style: const TextStyle(fontSize: 15)),
        const SizedBox(height: 6),
        Row(
          children: [
            Text('Total ${fmt(_engine.totalElapsedSec)}'),
            const Spacer(),
            Text('Sets done ${_engine.setsDone}/${_engine.setsTotal}'),
          ],
        ),
        const SizedBox(height: 4),
        XpProgressBar(value: _engine.overallProgress, height: 14),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: XpButton(
                big: true,
                label: _engine.paused ? 'Resume' : 'Pause',
                icon: _engine.paused ? Icons.play_arrow : Icons.pause,
                kind: _engine.paused ? XpButtonKind.green : XpButtonKind.normal,
                onPressed: _engine.togglePause,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: XpButton(
                big: true,
                label: 'Skip',
                icon: Icons.skip_next,
                onPressed: _engine.skip,
              ),
            ),
            const SizedBox(width: 8),
            XpButton(
              big: true,
              label: '',
              icon: Icons.stop,
              kind: XpButtonKind.red,
              onPressed: _confirmStop,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDone() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(),
        const Icon(Icons.emoji_events, size: 90, color: Color(0xFFE0A800)),
        const SizedBox(height: 10),
        const Text('Workout complete!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        XpGroupBox(
          label: 'Summary',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Workout: ${widget.preset.name}',
                  style: const TextStyle(fontSize: 15)),
              Text('Time: ${fmt(_engine.totalElapsedSec)}',
                  style: const TextStyle(fontSize: 15)),
              Text('Sets: ${_engine.setsDone}/${_engine.setsTotal}',
                  style: const TextStyle(fontSize: 15)),
            ],
          ),
        ),
        const Spacer(),
        XpButton(
          big: true,
          label: 'Done',
          icon: Icons.check,
          kind: XpButtonKind.green,
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }
}
