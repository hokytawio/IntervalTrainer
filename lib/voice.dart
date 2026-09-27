import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

import 'engine.dart';
import 'models.dart';

/// Voice lines in English and Portuguese.
class VoiceLines {
  final String getReady, startWorkout, startRest, changeExercise, next,
      complete, seconds;
  const VoiceLines({
    required this.getReady,
    required this.startWorkout,
    required this.startRest,
    required this.changeExercise,
    required this.next,
    required this.complete,
    required this.seconds,
  });

  static const en = VoiceLines(
    getReady: 'Get ready',
    startWorkout: 'Start workout',
    startRest: 'Start rest',
    changeExercise: 'Change exercise',
    next: 'Next',
    complete: 'Workout complete. Great job!',
    seconds: 'seconds',
  );

  static const pt = VoiceLines(
    getReady: 'Prepara-te',
    startWorkout: 'Começar treino',
    startRest: 'Começar descanso',
    changeExercise: 'Troca de exercício',
    next: 'A seguir',
    complete: 'Treino concluído. Bom trabalho!',
    seconds: 'segundos',
  );

  static VoiceLines of(String lang) => lang == 'pt' ? pt : en;
}

/// Turns engine cues into speech and vibration.
class Announcer {
  /// Native Android text-to-speech (Speaker.kt). It takes audio focus with
  /// "duck" so music (YouTube, Spotify…) gets quieter while the voice speaks.
  static const _ch = MethodChannel('interval_trainer/voice');
  String _lang = 'en';
  bool vibrationOn = true;
  bool _hasVibrator = false;

  Future<void> init({required String lang, required bool vibration}) async {
    vibrationOn = vibration;
    try {
      _hasVibrator = await Vibration.hasVibrator() == true;
    } catch (_) {
      _hasVibrator = false;
    }
    await setLanguage(lang);
  }

  Future<void> _call(String method, [Object? args]) async {
    try {
      await _ch.invokeMethod(method, args);
    } on MissingPluginException {
      // Not on Android (e.g. tests): stay silent.
    } on PlatformException catch (_) {}
  }

  Future<void> setLanguage(String lang) async {
    _lang = lang;
    await _call('init', {'lang': lang});
  }

  Future<void> say(String text) => _call('speak', {'text': text});

  Future<void> _buzz({int ms = 500, List<int>? pattern}) async {
    if (!vibrationOn || !_hasVibrator) return;
    try {
      if (pattern != null) {
        await Vibration.vibrate(pattern: pattern);
      } else {
        await Vibration.vibrate(duration: ms);
      }
    } catch (_) {}
  }

  void handle(Cue cue, Preset preset) {
    final t = VoiceLines.of(_lang);
    switch (cue.kind) {
      case CueKind.phaseStart:
        final p = cue.phase!;
        switch (p.type) {
          case PhaseType.prep:
            say(t.getReady);
            break;
          case PhaseType.work:
            say(t.startWorkout);
            _buzz(ms: 600);
            break;
          case PhaseType.rest:
            say(t.startRest);
            _buzz(ms: 300);
            break;
          case PhaseType.change:
            final name = p.exercise < preset.exercises.length
                ? preset.exercises[p.exercise].name
                : '';
            say('${t.changeExercise}. ${t.next}: $name');
            _buzz(pattern: [0, 300, 150, 300]);
            break;
        }
        break;
      case CueKind.secondsLeft:
        say('${cue.value} ${t.seconds}');
        break;
      case CueKind.countdown:
        say('${cue.value}');
        break;
      case CueKind.finished:
        say(t.complete);
        _buzz(pattern: [0, 400, 200, 400, 200, 800]);
        break;
    }
  }

  Future<void> dispose() => _call('stop');
}
