/// Built-in exercise catalog (assets/exercises/catalog.json).
/// Data and images: free-exercise-db, public domain (Unlicense).
library;

import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

class CatalogExercise {
  final String id;
  final String pt;
  final String en;
  final List<String> frames;
  final String equipment;
  final String level;
  final List<String> primary;
  final List<String> secondary;
  final List<String> instructions;
  late final CatalogFamily family;

  CatalogExercise({
    required this.id,
    required this.pt,
    required this.en,
    required this.frames,
    required this.equipment,
    required this.level,
    required this.primary,
    required this.secondary,
    required this.instructions,
  });

  /// Name in the given language ('pt' or 'en').
  String name(String lang) => lang == 'pt' ? pt : en;

  /// Name in the other language (shown as a subtitle).
  String altName(String lang) => lang == 'pt' ? en : pt;

  factory CatalogExercise.fromJson(Map<String, dynamic> j) => CatalogExercise(
        id: j['id'] as String,
        pt: j['pt'] as String,
        en: j['en'] as String,
        frames: List<String>.from(j['frames'] as List),
        equipment: j['equipment'] as String? ?? '',
        level: j['level'] as String? ?? '',
        primary: List<String>.from(j['primary'] as List? ?? const []),
        secondary: List<String>.from(j['secondary'] as List? ?? const []),
        instructions: List<String>.from(j['instructions'] as List? ?? const []),
      );
}

class CatalogFamily {
  final String pt;
  final String en;
  final List<CatalogExercise> variants;

  CatalogFamily(this.pt, this.en, this.variants) {
    for (final v in variants) {
      v.family = this;
    }
  }

  String name(String lang) => lang == 'pt' ? pt : en;
  String altName(String lang) => lang == 'pt' ? en : pt;
}

class ExerciseCatalog {
  ExerciseCatalog._(this.families) {
    for (final f in families) {
      for (final v in f.variants) {
        _byId[v.id] = v;
      }
    }
  }

  final List<CatalogFamily> families;
  final Map<String, CatalogExercise> _byId = {};

  CatalogExercise? byId(String? id) => id == null ? null : _byId[id];

  static ExerciseCatalog? _instance;

  /// Loaded once and cached.
  static Future<ExerciseCatalog> load() async {
    if (_instance != null) return _instance!;
    try {
      final raw = await rootBundle.loadString('assets/exercises/catalog.json');
      final j = jsonDecode(raw) as Map<String, dynamic>;
      final fams = (j['families'] as List).map((f) {
        final m = f as Map<String, dynamic>;
        return CatalogFamily(
          m['pt'] as String,
          m['en'] as String,
          (m['variants'] as List)
              .map((v) => CatalogExercise.fromJson(v as Map<String, dynamic>))
              .toList(),
        );
      }).toList();
      _instance = ExerciseCatalog._(fams);
    } catch (_) {
      // Missing or broken asset: the app still works with free-text names.
      _instance = ExerciseCatalog._(const []);
    }
    return _instance!;
  }

  /// Already loaded instance, or null (non-blocking lookups in the UI).
  static ExerciseCatalog? get loaded => _instance;
}

/// Readable labels for the database's English muscle/equipment terms.
String catalogLabel(String raw, String lang) {
  const pt = {
    'abdominals': 'abdominais', 'abductors': 'abdutores', 'adductors': 'adutores',
    'biceps': 'bíceps', 'calves': 'gémeos', 'chest': 'peito', 'forearms': 'antebraços',
    'glutes': 'glúteos', 'hamstrings': 'isquiotibiais', 'lats': 'dorsais',
    'lower back': 'lombar', 'middle back': 'meio das costas', 'neck': 'pescoço',
    'quadriceps': 'quadríceps', 'shoulders': 'ombros', 'traps': 'trapézio',
    'triceps': 'tríceps',
    'barbell': 'barra', 'dumbbell': 'halteres', 'cable': 'polia', 'machine': 'máquina',
    'body only': 'peso corporal', 'bands': 'elásticos', 'kettlebells': 'kettlebell',
    'e-z curl bar': 'barra EZ', 'exercise ball': 'bola de exercício', 'other': 'outro',
    'beginner': 'iniciante', 'intermediate': 'intermédio', 'expert': 'avançado',
  };
  if (lang == 'pt') return pt[raw] ?? raw;
  return raw;
}
