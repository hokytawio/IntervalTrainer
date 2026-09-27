import 'package:flutter/material.dart';

import '../models.dart';
import '../storage.dart';
import '../xp/xp.dart';

/// Create or edit a saved workout (preset).
class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key, this.preset});
  final Preset? preset;

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late final Preset _p;
  late final TextEditingController _name;
  final List<TextEditingController> _exNames = [];

  @override
  void initState() {
    super.initState();
    _p = widget.preset?.copy() ??
        Preset(
          id: newId(),
          name: '',
          exercises: [Exercise(name: 'Exercise 1')],
          changeSec: 180,
        );
    _name = TextEditingController(text: _p.name);
    for (final e in _p.exercises) {
      _exNames.add(TextEditingController(text: e.name));
    }
  }

  @override
  void dispose() {
    _name.dispose();
    for (final c in _exNames) {
      c.dispose();
    }
    super.dispose();
  }

  void _setExerciseCount(int n) {
    setState(() {
      while (_p.exercises.length < n) {
        final prev = _p.exercises.isNotEmpty ? _p.exercises.last : null;
        final name = 'Exercise ${_p.exercises.length + 1}';
        _p.exercises.add(Exercise(
          name: name,
          sets: prev?.sets ?? 4,
          workSec: prev?.workSec ?? 60,
          restSec: prev?.restSec ?? 60,
        ));
        _exNames.add(TextEditingController(text: name));
      }
      while (_p.exercises.length > n) {
        _p.exercises.removeLast();
        _exNames.removeLast().dispose();
      }
    });
  }

  Future<void> _save() async {
    _p.name = _name.text.trim().isEmpty ? 'My workout' : _name.text.trim();
    for (var i = 0; i < _p.exercises.length; i++) {
      final t = _exNames[i].text.trim();
      _p.exercises[i].name = t.isEmpty ? 'Exercise ${i + 1}' : t;
    }
    await app.savePreset(_p);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final lowChange = _p.exercises.length > 1 && _p.changeSec < 180;
    return XpDesktop(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: XpWindow(
          title: widget.preset == null ? 'New workout' : 'Edit workout',
          icon: Icons.edit_note,
          expand: true,
          onClose: () => Navigator.pop(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ListView(
                  children: [
                    XpGroupBox(
                      label: 'Workout',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Name'),
                          const SizedBox(height: 4),
                          XpTextField(controller: _name, hint: 'e.g. Leg day'),
                          const SizedBox(height: 12),
                          _Line(
                            label: 'How many exercises?',
                            child: XpSpinner(
                              value: _p.exercises.length,
                              min: 1,
                              max: 20,
                              onChanged: _setExerciseCount,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (var i = 0; i < _p.exercises.length; i++) ...[
                      _ExerciseBox(
                        index: i,
                        exercise: _p.exercises[i],
                        nameController: _exNames[i],
                        onChanged: () => setState(() {}),
                      ),
                      const SizedBox(height: 8),
                    ],
                    XpGroupBox(
                      label: 'Change exercise',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Line(
                            label: 'Time to change exercise',
                            child: XpSpinner(
                              value: _p.changeSec,
                              min: 0,
                              max: 900,
                              step: 15,
                              format: fmt,
                              onChanged: (v) =>
                                  setState(() => _p.changeSec = v),
                            ),
                          ),
                          const SizedBox(height: 8),
                          _Balloon(
                            warning: lowChange,
                            text: lowChange
                                ? 'Recommended: 3–5 min. Less than 3 min may not '
                                    'let you fully recover for the next exercise.'
                                : 'Recommended: 3–5 min, so you fully recover '
                                    'before the next exercise. This replaces the '
                                    'rest after the last set.',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Total: ${_p.totalSets} sets · about ${fmt(_p.plannedSec)}',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: XpButton(
                        label: 'Cancel',
                        onPressed: () => Navigator.pop(context)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: XpButton(
                      label: 'Save',
                      icon: Icons.save,
                      kind: XpButtonKind.green,
                      onPressed: _save,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExerciseBox extends StatelessWidget {
  const _ExerciseBox({
    required this.index,
    required this.exercise,
    required this.nameController,
    required this.onChanged,
  });

  final int index;
  final Exercise exercise;
  final TextEditingController nameController;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final e = exercise;
    return XpGroupBox(
      label: 'Exercise ${index + 1}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          XpTextField(controller: nameController, hint: 'e.g. Squats'),
          const SizedBox(height: 10),
          _Line(
            label: 'Sets (series)',
            child: XpSpinner(
              value: e.sets,
              min: 1,
              max: 20,
              onChanged: (v) {
                e.sets = v;
                onChanged();
              },
            ),
          ),
          _Line(
            label: 'Set time',
            child: XpSpinner(
              value: e.workSec,
              min: 5,
              max: 900,
              step: 5,
              format: fmt,
              onChanged: (v) {
                e.workSec = v;
                onChanged();
              },
            ),
          ),
          _Line(
            label: 'Rest between sets',
            child: XpSpinner(
              value: e.restSec,
              min: 0,
              max: 600,
              step: 5,
              format: fmt,
              onChanged: (v) {
                e.restSec = v;
                onChanged();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 15))),
          child,
        ],
      ),
    );
  }
}

/// Yellow tooltip "balloon" for tips and warnings.
class _Balloon extends StatelessWidget {
  const _Balloon({required this.text, this.warning = false});
  final String text;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFE1),
        border: Border.all(color: Colors.black54),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(warning ? Icons.warning_amber_rounded : Icons.lightbulb_outline,
              size: 20,
              color: warning ? const Color(0xFFD08A00) : Xp.titleB),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}
