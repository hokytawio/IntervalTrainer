import 'package:flutter/material.dart';

import '../models.dart';
import '../storage.dart';
import '../voice.dart';
import '../xp/xp.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final Announcer _voice = Announcer();
  bool _voiceReady = false;

  Settings get s => app.settings;

  @override
  void initState() {
    super.initState();
    _voice.init(lang: s.voiceLang, vibration: s.vibration).then((_) {
      if (mounted) setState(() => _voiceReady = true);
    });
  }

  @override
  void dispose() {
    _voice.dispose();
    super.dispose();
  }

  void _update(void Function(Settings n) change) {
    final n = Settings.fromJson(s.toJson());
    change(n);
    app.updateSettings(n);
    setState(() {});
  }

  Future<void> _test() async {
    await _voice.setLanguage(s.voiceLang);
    final t = VoiceLines.of(s.voiceLang);
    await _voice.say('${t.startWorkout}. 30 ${t.seconds}. 3, 2, 1. ${t.startRest}');
  }

  @override
  Widget build(BuildContext context) {
    return XpDesktop(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: XpWindow(
          title: 'Settings',
          icon: Icons.settings,
          expand: true,
          onClose: () => Navigator.pop(context),
          child: ListView(
            children: [
              XpGroupBox(
                label: 'Voice language',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    XpRadio<String>(
                      value: 'en',
                      group: s.voiceLang,
                      label: 'English',
                      onChanged: (v) => _update((n) => n.voiceLang = v),
                    ),
                    XpRadio<String>(
                      value: 'pt',
                      group: s.voiceLang,
                      label: 'Português',
                      onChanged: (v) => _update((n) => n.voiceLang = v),
                    ),
                    const SizedBox(height: 8),
                    XpButton(
                      label: 'Test voice',
                      icon: Icons.volume_up,
                      onPressed: _voiceReady ? _test : null,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Uses your phone\'s text-to-speech. If Portuguese sounds '
                      'wrong, install the Portuguese voice in Android settings '
                      '→ Text-to-speech.',
                      style: TextStyle(color: Colors.black54, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              XpGroupBox(
                label: 'During a workout',
                child: Column(
                  children: [
                    XpCheckbox(
                      value: s.vibration,
                      label: 'Vibrate on phase changes',
                      onChanged: (v) => _update((n) => n.vibration = v),
                    ),
                    XpCheckbox(
                      value: s.keepScreenOn,
                      label: 'Keep screen on',
                      onChanged: (v) => _update((n) => n.keepScreenOn = v),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          const Expanded(
                              child: Text('"Get ready" countdown',
                                  style: TextStyle(fontSize: 15))),
                          XpSpinner(
                            value: s.prepSec,
                            min: 0,
                            max: 60,
                            step: 5,
                            format: (v) => '${v}s',
                            onChanged: (v) => _update((n) => n.prepSec = v),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
