import 'package:flutter/material.dart';

import '../models.dart';
import '../storage.dart';
import '../xp/xp.dart';
import 'editor_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';
import 'workout_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _push(BuildContext context, Widget screen) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    return XpDesktop(
      menu: [
        XpMenuItem('New workout', Icons.add_box_outlined,
            () => _push(context, const EditorScreen())),
        XpMenuItem('History', Icons.history,
            () => _push(context, const HistoryScreen())),
        XpMenuItem('Settings', Icons.settings,
            () => _push(context, const SettingsScreen())),
      ],
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: XpWindow(
          title: 'Interval Trainer — My workouts',
          icon: Icons.fitness_center,
          expand: true,
          child: ListenableBuilder(
            listenable: app,
            builder: (context, _) {
              final presets = app.presets;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: XpSunken(
                      child: presets.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(24),
                                child: Text(
                                  'No workouts yet.\nTap "New workout" to create one.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 15),
                                ),
                              ),
                            )
                          : ListView.separated(
                              itemCount: presets.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, i) =>
                                  _PresetRow(preset: presets[i]),
                            ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  XpButton(
                    label: 'New workout',
                    icon: Icons.add,
                    onPressed: () => _push(context, const EditorScreen()),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PresetRow extends StatelessWidget {
  const _PresetRow({required this.preset});
  final Preset preset;

  Future<void> _delete(BuildContext context) async {
    final r = await showXpDialog(
      context,
      title: 'Delete workout',
      message: 'Delete "${preset.name}"? This cannot be undone.',
      buttons: const ['Cancel', 'Delete'],
      icon: Icons.warning_amber_rounded,
      dangerIndex: 1,
    );
    if (r == 1) await app.deletePreset(preset.id);
  }

  @override
  Widget build(BuildContext context) {
    final p = preset;
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(p.name,
              style:
                  const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(
            '${p.exercises.length} exercises · ${p.totalSets} sets · ~${fmt(p.plannedSec)}',
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              XpButton(
                label: 'Start',
                icon: Icons.play_arrow,
                kind: XpButtonKind.green,
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => WorkoutScreen(preset: p.copy())),
                ),
              ),
              const SizedBox(width: 8),
              XpButton(
                label: 'Edit',
                icon: Icons.edit,
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => EditorScreen(preset: p)),
                ),
              ),
              const Spacer(),
              XpButton(
                label: '',
                icon: Icons.delete_outline,
                onPressed: () => _delete(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
