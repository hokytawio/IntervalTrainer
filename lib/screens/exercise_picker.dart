import 'dart:async';

import 'package:flutter/material.dart';

import '../catalog.dart';
import '../storage.dart';
import '../xp/xp.dart';

/// Plays an exercise's start/end photos in a loop, like a GIF.
class ExerciseAnimation extends StatefulWidget {
  const ExerciseAnimation({
    super.key,
    required this.frames,
    this.interval = const Duration(milliseconds: 900),
  });

  final List<String> frames;
  final Duration interval;

  @override
  State<ExerciseAnimation> createState() => _ExerciseAnimationState();
}

class _ExerciseAnimationState extends State<ExerciseAnimation> {
  Timer? _timer;
  int _i = 0;
  bool _playing = true;
  bool _precached = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_precached) {
      _precached = true;
      for (final f in widget.frames) {
        precacheImage(AssetImage(f), context);
      }
    }
  }

  @override
  void didUpdateWidget(covariant ExerciseAnimation old) {
    super.didUpdateWidget(old);
    if (old.frames.join() != widget.frames.join()) {
      _i = 0;
      _precached = false;
    }
  }

  void _start() {
    _timer?.cancel();
    if (widget.frames.length < 2) return;
    _timer = Timer.periodic(widget.interval, (_) {
      if (mounted) setState(() => _i = (_i + 1) % widget.frames.length);
    });
  }

  void _toggle() {
    setState(() => _playing = !_playing);
    if (_playing) {
      _start();
    } else {
      _timer?.cancel();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.frames.isEmpty) return const SizedBox.shrink();
    final frame = widget.frames[_i % widget.frames.length];
    return GestureDetector(
      onTap: _toggle,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(color: Colors.white),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Image.asset(
              frame,
              key: ValueKey(frame),
              fit: BoxFit.contain,
              gaplessPlayback: true,
            ),
          ),
          if (!_playing)
            const Center(
              child: Icon(Icons.play_circle_fill, size: 56, color: Colors.white70),
            ),
        ],
      ),
    );
  }
}

/// Step 1: exercise family (e.g. Supino). Step 2: variant (e.g. Supino
/// inclinado). Returns the chosen [CatalogExercise].
class ExercisePickerScreen extends StatefulWidget {
  const ExercisePickerScreen({super.key});

  @override
  State<ExercisePickerScreen> createState() => _ExercisePickerScreenState();
}

class _ExercisePickerScreenState extends State<ExercisePickerScreen> {
  ExerciseCatalog? _catalog;
  CatalogFamily? _family;
  final _search = TextEditingController();

  String get _lang => app.settings.voiceLang;

  @override
  void initState() {
    super.initState();
    ExerciseCatalog.load().then((c) {
      if (mounted) setState(() => _catalog = c);
    });
    _search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _howTo(CatalogExercise ex) async {
    final chosen = await Navigator.push<CatalogExercise>(
      context,
      MaterialPageRoute(
          builder: (_) => ExerciseHowToScreen(exercise: ex, canChoose: true)),
    );
    if (chosen != null && mounted) Navigator.pop(context, chosen);
  }

  List<CatalogExercise> _matches(String q) {
    q = q.toLowerCase();
    return [
      for (final f in _catalog!.families)
        for (final v in f.variants)
          if (v.pt.toLowerCase().contains(q) ||
              v.en.toLowerCase().contains(q) ||
              f.pt.toLowerCase().contains(q) ||
              f.en.toLowerCase().contains(q))
            v
    ];
  }

  @override
  Widget build(BuildContext context) {
    final fam = _family;
    return PopScope(
      canPop: fam == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && fam != null) setState(() => _family = null);
      },
      child: XpDesktop(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: XpWindow(
            title: fam == null ? 'Choose exercise' : fam.name(_lang),
            icon: Icons.fitness_center,
            expand: true,
            onClose: () => Navigator.pop(context),
            child: _catalog == null
                ? const Center(child: Text('Loading…'))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (fam == null) ...[
                        XpTextField(
                            controller: _search, hint: 'Search (e.g. supino)'),
                        const SizedBox(height: 8),
                      ],
                      Expanded(
                        child: XpSunken(
                          child: fam != null
                              ? _variantList(fam.variants)
                              : _search.text.trim().isNotEmpty
                                  ? _variantList(_matches(_search.text.trim()),
                                      showFamily: true)
                                  : _familyList(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          if (fam != null) ...[
                            Expanded(
                              child: XpButton(
                                label: 'Back',
                                icon: Icons.arrow_back,
                                onPressed: () => setState(() => _family = null),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Expanded(
                            child: XpButton(
                              label: 'Cancel',
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Exercise data and photos: free-exercise-db (public domain)',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11, color: Colors.black45),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _familyList() {
    final fams = _catalog!.families;
    if (fams.isEmpty) {
      return const Center(child: Text('Exercise list not available.'));
    }
    return ListView.separated(
      itemCount: fams.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final f = fams[i];
        return ListTile(
          leading: SizedBox(
            width: 54,
            height: 36,
            child: Image.asset(f.variants.first.frames.first, fit: BoxFit.cover),
          ),
          title: Text(f.name(_lang),
              style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('${f.altName(_lang)} · ${f.variants.length}'),
          trailing: const Icon(Icons.chevron_right, color: Xp.titleB),
          onTap: () => setState(() => _family = f),
        );
      },
    );
  }

  Widget _variantList(List<CatalogExercise> items, {bool showFamily = false}) {
    if (items.isEmpty) {
      return const Center(child: Text('No exercises found.'));
    }
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final v = items[i];
        return ListTile(
          contentPadding: const EdgeInsets.only(left: 10, right: 4),
          leading: SizedBox(
            width: 66,
            height: 44,
            child: Image.asset(v.frames.first, fit: BoxFit.cover),
          ),
          title: Text(v.name(_lang),
              style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(showFamily
              ? '${v.family.name(_lang)} · ${v.altName(_lang)}'
              : v.altName(_lang)),
          trailing: IconButton(
            tooltip: 'How to do it',
            icon: const Icon(Icons.play_circle_outline, color: Xp.titleB),
            onPressed: () => _howTo(v),
          ),
          onTap: () => Navigator.pop(context, v),
        );
      },
    );
  }
}

/// "How to do it": looping animation, muscles, equipment and steps.
class ExerciseHowToScreen extends StatelessWidget {
  const ExerciseHowToScreen({
    super.key,
    required this.exercise,
    this.canChoose = false,
  });

  final CatalogExercise exercise;

  /// Shows a "Choose this exercise" button that returns [exercise].
  final bool canChoose;

  @override
  Widget build(BuildContext context) {
    final lang = app.settings.voiceLang;
    final ex = exercise;
    String muscles(List<String> m) => m.map((x) => catalogLabel(x, lang)).join(', ');

    return XpDesktop(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: XpWindow(
          title: 'How to do it',
          icon: Icons.help_outline,
          expand: true,
          onClose: () => Navigator.pop(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ListView(
                  children: [
                    XpSunken(
                      child: AspectRatio(
                        aspectRatio: 3 / 2,
                        child: ExerciseAnimation(frames: ex.frames),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text('Tap the picture to pause',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.black45)),
                    const SizedBox(height: 8),
                    Text(ex.name(lang),
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    Text(ex.altName(lang),
                        style: const TextStyle(color: Colors.black54)),
                    const SizedBox(height: 8),
                    XpGroupBox(
                      label: 'Details',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (ex.primary.isNotEmpty)
                            _kv('Main muscles', muscles(ex.primary)),
                          if (ex.secondary.isNotEmpty)
                            _kv('Also works', muscles(ex.secondary)),
                          if (ex.equipment.isNotEmpty)
                            _kv('Equipment', catalogLabel(ex.equipment, lang)),
                          if (ex.level.isNotEmpty)
                            _kv('Level', catalogLabel(ex.level, lang)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    XpGroupBox(
                      label: 'Steps',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (var i = 0; i < ex.instructions.length; i++)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 22,
                                    height: 22,
                                    alignment: Alignment.center,
                                    margin: const EdgeInsets.only(right: 8),
                                    decoration: const BoxDecoration(
                                        color: Xp.titleB,
                                        shape: BoxShape.circle),
                                    child: Text('${i + 1}',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                  Expanded(
                                    child: Text(ex.instructions[i],
                                        style: const TextStyle(fontSize: 14)),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Source: free-exercise-db (public domain). '
                      'Not medical advice: stop if you feel pain.',
                      style: TextStyle(fontSize: 11, color: Colors.black45),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: XpButton(
                      label: 'Back',
                      icon: Icons.arrow_back,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  if (canChoose) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: XpButton(
                        label: 'Choose',
                        icon: Icons.check,
                        kind: XpButtonKind.green,
                        onPressed: () => Navigator.pop(context, exercise),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: RichText(
          text: TextSpan(
            style: const TextStyle(color: Colors.black, fontSize: 14),
            children: [
              TextSpan(
                  text: '$k: ',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              TextSpan(text: v),
            ],
          ),
        ),
      );
}
