import 'package:flutter/material.dart';

import '../models.dart';
import '../storage.dart';
import '../xp/xp.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  String _date(DateTime d) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
  }

  Future<void> _clear(BuildContext context) async {
    final r = await showXpDialog(
      context,
      title: 'Clear history',
      message: 'Delete all workout history?',
      buttons: const ['Cancel', 'Clear'],
      icon: Icons.warning_amber_rounded,
      dangerIndex: 1,
    );
    if (r == 1) await app.clearHistory();
  }

  @override
  Widget build(BuildContext context) {
    return XpDesktop(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: XpWindow(
          title: 'Workout history',
          icon: Icons.history,
          expand: true,
          onClose: () => Navigator.pop(context),
          child: ListenableBuilder(
            listenable: app,
            builder: (context, _) {
              final h = app.history;
              final done = h.where((e) => e.completed).length;
              final totalSec = h.fold<int>(0, (a, e) => a + e.elapsedSec);
              final sets = h.fold<int>(0, (a, e) => a + e.setsDone);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  XpGroupBox(
                    label: 'Totals',
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _Stat('Workouts', '${h.length}'),
                        _Stat('Completed', '$done'),
                        _Stat('Sets', '$sets'),
                        _Stat('Time', fmt(totalSec)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: XpSunken(
                      child: h.isEmpty
                          ? const Center(
                              child: Text('No workouts yet.',
                                  style: TextStyle(fontSize: 15)))
                          : ListView.separated(
                              itemCount: h.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, i) {
                                final e = h[i];
                                return ListTile(
                                  leading: Icon(
                                    e.completed
                                        ? Icons.check_circle
                                        : Icons.cancel,
                                    color: e.completed
                                        ? const Color(0xFF21A121)
                                        : const Color(0xFFC6401C),
                                  ),
                                  title: Text(e.presetName,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  subtitle: Text(
                                    '${_date(e.startedAt)}\n'
                                    '${fmt(e.elapsedSec)} · sets ${e.setsDone}/${e.setsTotal}'
                                    '${e.completed ? '' : ' · stopped early'}',
                                  ),
                                  isThreeLine: true,
                                );
                              },
                            ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  XpButton(
                    label: 'Clear history',
                    icon: Icons.delete_sweep_outlined,
                    onPressed: h.isEmpty ? null : () => _clear(context),
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

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value);
  final String label, value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.black54)),
      ],
    );
  }
}
