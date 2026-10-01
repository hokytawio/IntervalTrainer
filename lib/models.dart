/// Data models: exercises, presets (saved workouts), history and settings.
library;

String newId() => DateTime.now().microsecondsSinceEpoch.toString();

/// Formats seconds as m:ss (or h:mm:ss for long totals).
String fmt(int totalSec) {
  if (totalSec < 0) totalSec = 0;
  final h = totalSec ~/ 3600;
  final m = (totalSec % 3600) ~/ 60;
  final s = totalSec % 60;
  final ss = s.toString().padLeft(2, '0');
  if (h > 0) return '$h:${m.toString().padLeft(2, '0')}:$ss';
  return '$m:$ss';
}

class Exercise {
  String name;
  int sets;
  int workSec;
  int restSec;

  /// Id in the built-in catalog (enables "How to do it"), or null for a
  /// free-text exercise.
  String? catalogId;

  Exercise({
    required this.name,
    this.sets = 4,
    this.workSec = 60,
    this.restSec = 60,
    this.catalogId,
  });

  Exercise copy() => Exercise(
      name: name,
      sets: sets,
      workSec: workSec,
      restSec: restSec,
      catalogId: catalogId);

  Map<String, dynamic> toJson() => {
        'name': name,
        'sets': sets,
        'workSec': workSec,
        'restSec': restSec,
        if (catalogId != null) 'catalogId': catalogId,
      };

  factory Exercise.fromJson(Map<String, dynamic> j) => Exercise(
        name: j['name'] as String? ?? 'Exercise',
        sets: j['sets'] as int? ?? 4,
        workSec: j['workSec'] as int? ?? 60,
        restSec: j['restSec'] as int? ?? 60,
        catalogId: j['catalogId'] as String?,
      );
}

class Preset {
  String id;
  String name;
  List<Exercise> exercises;

  /// Time to change exercise. Replaces the normal rest after the last set.
  int changeSec;

  Preset({
    required this.id,
    required this.name,
    required this.exercises,
    this.changeSec = 180,
  });

  int get totalSets => exercises.fold(0, (a, e) => a + e.sets);

  /// Planned duration (without the "get ready" countdown).
  int get plannedSec {
    var t = 0;
    for (var i = 0; i < exercises.length; i++) {
      final e = exercises[i];
      t += e.sets * e.workSec + (e.sets - 1) * e.restSec;
      if (i < exercises.length - 1) t += changeSec;
    }
    return t;
  }

  Preset copy() => Preset(
        id: id,
        name: name,
        exercises: exercises.map((e) => e.copy()).toList(),
        changeSec: changeSec,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'changeSec': changeSec,
        'exercises': exercises.map((e) => e.toJson()).toList(),
      };

  factory Preset.fromJson(Map<String, dynamic> j) => Preset(
        id: j['id'] as String? ?? newId(),
        name: j['name'] as String? ?? 'Workout',
        changeSec: j['changeSec'] as int? ?? 180,
        exercises: ((j['exercises'] as List?) ?? [])
            .map((e) => Exercise.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
}

class HistoryEntry {
  final DateTime startedAt;
  final String presetName;
  final int plannedSec;
  final int elapsedSec;
  final int setsDone;
  final int setsTotal;
  final bool completed;

  HistoryEntry({
    required this.startedAt,
    required this.presetName,
    required this.plannedSec,
    required this.elapsedSec,
    required this.setsDone,
    required this.setsTotal,
    required this.completed,
  });

  Map<String, dynamic> toJson() => {
        'startedAt': startedAt.toIso8601String(),
        'presetName': presetName,
        'plannedSec': plannedSec,
        'elapsedSec': elapsedSec,
        'setsDone': setsDone,
        'setsTotal': setsTotal,
        'completed': completed,
      };

  factory HistoryEntry.fromJson(Map<String, dynamic> j) => HistoryEntry(
        startedAt:
            DateTime.tryParse(j['startedAt'] as String? ?? '') ?? DateTime.now(),
        presetName: j['presetName'] as String? ?? '',
        plannedSec: j['plannedSec'] as int? ?? 0,
        elapsedSec: j['elapsedSec'] as int? ?? 0,
        setsDone: j['setsDone'] as int? ?? 0,
        setsTotal: j['setsTotal'] as int? ?? 0,
        completed: j['completed'] as bool? ?? false,
      );
}

class Settings {
  /// 'en' or 'pt'
  String voiceLang;
  bool vibration;
  bool keepScreenOn;

  /// "Get ready" countdown before the first set.
  int prepSec;

  Settings({
    this.voiceLang = 'en',
    this.vibration = true,
    this.keepScreenOn = true,
    this.prepSec = 10,
  });

  Map<String, dynamic> toJson() => {
        'voiceLang': voiceLang,
        'vibration': vibration,
        'keepScreenOn': keepScreenOn,
        'prepSec': prepSec,
      };

  factory Settings.fromJson(Map<String, dynamic> j) => Settings(
        voiceLang: j['voiceLang'] as String? ?? 'en',
        vibration: j['vibration'] as bool? ?? true,
        keepScreenOn: j['keepScreenOn'] as bool? ?? true,
        prepSec: j['prepSec'] as int? ?? 10,
      );
}
