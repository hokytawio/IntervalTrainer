import 'package:flutter_test/flutter_test.dart';
import 'package:interval_trainer/engine.dart';
import 'package:interval_trainer/models.dart';

Preset _preset() => Preset(
      id: 't',
      name: 'Test',
      changeSec: 180,
      exercises: [
        Exercise(name: 'A', sets: 3, workSec: 60, restSec: 60),
        Exercise(name: 'B', sets: 2, workSec: 45, restSec: 30),
      ],
    );

void main() {
  test('change time replaces rest after the last set', () {
    final t = buildTimeline(_preset(), prepSec: 10);
    final types = t.map((p) => p.type).toList();
    expect(types, [
      PhaseType.prep,
      PhaseType.work, PhaseType.rest, // A1
      PhaseType.work, PhaseType.rest, // A2
      PhaseType.work, PhaseType.change, // A3 -> change to B
      PhaseType.work, PhaseType.rest, // B1
      PhaseType.work, // B2 (end, no rest)
    ]);
    expect(t[6].exercise, 1); // change phase points at the next exercise
    expect(t[6].seconds, 180);
  });

  test('planned duration', () {
    // A: 3*60 + 2*60 = 300, change 180, B: 2*45 + 1*30 = 120
    expect(_preset().plannedSec, 600);
  });

  test('no prep phase when prepSec is 0', () {
    final t = buildTimeline(_preset(), prepSec: 0);
    expect(t.first.type, PhaseType.work);
  });

  test('fmt', () {
    expect(fmt(5), '0:05');
    expect(fmt(180), '3:00');
    expect(fmt(3725), '1:02:05');
  });

  test('catalogId survives save/load and is optional', () {
    final e = Exercise(name: 'Supino inclinado', catalogId: 'Incline_Dumbbell_Press');
    final back = Exercise.fromJson(e.toJson());
    expect(back.catalogId, 'Incline_Dumbbell_Press');
    expect(back.copy().catalogId, 'Incline_Dumbbell_Press');
    // Presets saved before this feature have no catalogId.
    final old = Exercise.fromJson({'name': 'Squats', 'sets': 3, 'workSec': 60, 'restSec': 60});
    expect(old.catalogId, isNull);
    expect(old.toJson().containsKey('catalogId'), isFalse);
  });
}
