import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

/// App-wide state, persisted locally on the device (no server, no account).
class AppState extends ChangeNotifier {
  static const _kPresets = 'presets_v1';
  static const _kHistory = 'history_v1';
  static const _kSettings = 'settings_v1';
  static const _kSeeded = 'seeded_v1';
  static const _maxHistory = 500;

  late SharedPreferences _prefs;
  List<Preset> presets = [];
  List<HistoryEntry> history = [];
  Settings settings = Settings();

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    presets = _readList(_kPresets).map(Preset.fromJson).toList();
    history = _readList(_kHistory).map(HistoryEntry.fromJson).toList();
    final s = _prefs.getString(_kSettings);
    if (s != null) {
      try {
        settings = Settings.fromJson(
            Map<String, dynamic>.from(jsonDecode(s) as Map));
      } catch (_) {}
    }
    if (!(_prefs.getBool(_kSeeded) ?? false)) {
      presets.add(Preset(
        id: newId(),
        name: 'Example: Full body',
        changeSec: 180,
        exercises: [
          Exercise(name: 'Squats', sets: 4, workSec: 60, restSec: 60),
          Exercise(name: 'Push-ups', sets: 4, workSec: 45, restSec: 60),
          Exercise(name: 'Rows', sets: 3, workSec: 60, restSec: 60),
        ],
      ));
      await _prefs.setBool(_kSeeded, true);
      await _savePresets();
    }
    notifyListeners();
  }

  List<Map<String, dynamic>> _readList(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _savePresets() => _prefs.setString(
      _kPresets, jsonEncode(presets.map((p) => p.toJson()).toList()));

  Future<void> _saveHistory() => _prefs.setString(
      _kHistory, jsonEncode(history.map((h) => h.toJson()).toList()));

  Future<void> savePreset(Preset p) async {
    final i = presets.indexWhere((x) => x.id == p.id);
    if (i >= 0) {
      presets[i] = p;
    } else {
      presets.add(p);
    }
    notifyListeners();
    await _savePresets();
  }

  Future<void> deletePreset(String id) async {
    presets.removeWhere((p) => p.id == id);
    notifyListeners();
    await _savePresets();
  }

  Future<void> addHistory(HistoryEntry e) async {
    history.insert(0, e);
    if (history.length > _maxHistory) {
      history = history.sublist(0, _maxHistory);
    }
    notifyListeners();
    await _saveHistory();
  }

  Future<void> clearHistory() async {
    history.clear();
    notifyListeners();
    await _saveHistory();
  }

  Future<void> updateSettings(Settings s) async {
    settings = s;
    notifyListeners();
    await _prefs.setString(_kSettings, jsonEncode(s.toJson()));
  }
}

final app = AppState();
