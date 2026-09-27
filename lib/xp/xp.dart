/// Retro XP-inspired widgets, drawn from scratch (no Microsoft assets).
library;

import 'dart:async';

import 'package:flutter/material.dart';

class Xp {
  static const face = Color(0xFFECE9D8); // window body
  static const frame = Color(0xFF0831D9); // window border
  static const titleA = Color(0xFF3D95FF);
  static const titleB = Color(0xFF0A5BE0);
  static const titleC = Color(0xFF0050E0);
  static const titleD = Color(0xFF1A6CF0);
  static const buttonBorder = Color(0xFF003C74);
  static const fieldBorder = Color(0xFF7F9DB9);
  static const groupBorder = Color(0xFFD0D0BF);
  static const groupLabel = Color(0xFF0046D5);
  static const green = Color(0xFF3C9A3C);
  static const greenLight = Color(0xFF7ED36E);
  static const workColor = Color(0xFF2E9A2E);
  static const restColor = Color(0xFF1E62D8);
  static const changeColor = Color(0xFFE07A10);
  static const prepColor = Color(0xFF7A5BC8);

  static const titleGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [titleA, titleB, titleC, titleD],
    stops: [0, 0.12, 0.8, 1],
  );

  static const titleText = TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.bold,
    fontSize: 15,
    shadows: [Shadow(color: Color(0xFF0A1A6A), offset: Offset(1, 1))],
  );
}

/// A window with a blue gradient title bar and a beige body.
class XpWindow extends StatelessWidget {
  const XpWindow({
    super.key,
    required this.title,
    required this.child,
    this.icon = Icons.timer_outlined,
    this.onClose,
    this.expand = false,
    this.padding = const EdgeInsets.all(10),
  });

  final String title;
  final Widget child;
  final IconData icon;
  final VoidCallback? onClose;
  final bool expand;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final body = Container(
      margin: const EdgeInsets.fromLTRB(3, 0, 3, 3),
      color: Xp.face,
      padding: padding,
      child: child,
    );
    return Container(
      decoration: BoxDecoration(
        color: Xp.titleD,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
        border: Border.all(color: Xp.frame),
        boxShadow: const [
          BoxShadow(color: Colors.black38, blurRadius: 8, offset: Offset(2, 3)),
        ],
      ),
      child: Column(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 32,
            decoration: const BoxDecoration(
              gradient: Xp.titleGradient,
              borderRadius: BorderRadius.vertical(top: Radius.circular(7)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(title,
                      style: Xp.titleText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
                if (onClose != null) _CloseButton(onTap: onClose!),
              ],
            ),
          ),
          if (expand) Expanded(child: body) else body,
        ],
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: Colors.white, width: 1),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE88A6C), Color(0xFFC6401C)],
          ),
        ),
        child: const Icon(Icons.close, color: Colors.white, size: 18),
      ),
    );
  }
}

enum XpButtonKind { normal, green, red }

/// Beveled, rounded push button.
class XpButton extends StatefulWidget {
  const XpButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.kind = XpButtonKind.normal,
    this.big = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final XpButtonKind kind;
  final bool big;

  @override
  State<XpButton> createState() => _XpButtonState();
}

class _XpButtonState extends State<XpButton> {
  bool _down = false;

  List<Color> get _colors {
    switch (widget.kind) {
      case XpButtonKind.green:
        return _down
            ? const [Color(0xFF2F7F2F), Color(0xFF4FAF4F)]
            : const [Color(0xFF6CCB5F), Color(0xFF2F8F2F)];
      case XpButtonKind.red:
        return _down
            ? const [Color(0xFFA0301C), Color(0xFFD65A3C)]
            : const [Color(0xFFEA7B5C), Color(0xFFB8361A)];
      case XpButtonKind.normal:
        return _down
            ? const [Color(0xFFCDCAC3), Color(0xFFF2F2F1)]
            : const [Color(0xFFFFFFFF), Color(0xFFE3E3DB)];
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final colored = widget.kind != XpButtonKind.normal;
    final textColor = colored ? Colors.white : Colors.black;
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapUp: enabled ? (_) => setState(() => _down = false) : null,
        onTapCancel: enabled ? () => setState(() => _down = false) : null,
        onTap: widget.onPressed,
        child: Container(
          constraints: BoxConstraints(minHeight: widget.big ? 52 : 36),
          padding: EdgeInsets.symmetric(
              horizontal: widget.big ? 18 : 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Xp.buttonBorder),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: _colors,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: widget.big ? 24 : 18, color: textColor),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  widget.label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor,
                    fontSize: widget.big ? 18 : 14,
                    fontWeight: colored ? FontWeight.bold : FontWeight.normal,
                    shadows: colored
                        ? const [
                            Shadow(color: Colors.black38, offset: Offset(1, 1))
                          ]
                        : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Labeled frame (like a classic "group box").
class XpGroupBox extends StatelessWidget {
  const XpGroupBox({super.key, required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.only(top: 9),
          padding: const EdgeInsets.fromLTRB(10, 16, 10, 10),
          decoration: BoxDecoration(
            border: Border.all(color: Xp.groupBorder),
            borderRadius: BorderRadius.circular(4),
          ),
          child: child,
        ),
        Positioned(
          left: 8,
          top: 0,
          child: Container(
            color: Xp.face,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(label,
                style: const TextStyle(
                    color: Xp.groupLabel,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }
}

/// Sunken white panel (for lists and displays).
class XpSunken extends StatelessWidget {
  const XpSunken({super.key, required this.child, this.padding});
  final Widget child;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Xp.fieldBorder),
      ),
      child: child,
    );
  }
}

class XpTextField extends StatelessWidget {
  const XpTextField({super.key, required this.controller, this.hint});
  final TextEditingController controller;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    const border = OutlineInputBorder(
      borderRadius: BorderRadius.zero,
      borderSide: BorderSide(color: Xp.fieldBorder),
    );
    return TextField(
      controller: controller,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
            borderSide: const BorderSide(color: Xp.titleB, width: 1.5)),
      ),
    );
  }
}

/// Number box with ▲▼ arrows. Hold an arrow to repeat.
class XpSpinner extends StatelessWidget {
  const XpSpinner({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 999,
    this.step = 1,
    this.format,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final int min, max, step;
  final String Function(int v)? format;

  void _bump(int dir) {
    final v = (value + dir * step).clamp(min, max);
    if (v != value) onChanged(v);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Arrow(icon: Icons.remove, onStep: () => _bump(-1)),
        Container(
          width: 72,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Xp.fieldBorder),
          ),
          child: Text(format?.call(value) ?? '$value',
              style: const TextStyle(fontSize: 16)),
        ),
        _Arrow(icon: Icons.add, onStep: () => _bump(1)),
      ],
    );
  }
}

class _Arrow extends StatefulWidget {
  const _Arrow({required this.icon, required this.onStep});
  final IconData icon;
  final VoidCallback onStep;

  @override
  State<_Arrow> createState() => _ArrowState();
}

class _ArrowState extends State<_Arrow> {
  Timer? _repeat;
  bool _down = false;

  void _start() {
    setState(() => _down = true);
    widget.onStep();
    _repeat = Timer(const Duration(milliseconds: 400), () {
      _repeat = Timer.periodic(
          const Duration(milliseconds: 90), (_) => widget.onStep());
    });
  }

  void _end() {
    _repeat?.cancel();
    _repeat = null;
    if (mounted) setState(() => _down = false);
  }

  @override
  void dispose() {
    _repeat?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _start(),
      onPointerUp: (_) => _end(),
      onPointerCancel: (_) => _end(),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          border: Border.all(color: Xp.buttonBorder),
          borderRadius: BorderRadius.circular(3),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _down
                ? const [Color(0xFFCDCAC3), Color(0xFFF2F2F1)]
                : const [Color(0xFFFFFFFF), Color(0xFFD6DDF5)],
          ),
        ),
        child: Icon(widget.icon, size: 18, color: Xp.buttonBorder),
      ),
    );
  }
}

class XpCheckbox extends StatelessWidget {
  const XpCheckbox(
      {super.key,
      required this.value,
      required this.onChanged,
      required this.label});
  final bool value;
  final ValueChanged<bool> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFF1C5180)),
              ),
              child: value
                  ? const Icon(Icons.check, size: 16, color: Color(0xFF21A121))
                  : null,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 15))),
          ],
        ),
      ),
    );
  }
}

class XpRadio<T> extends StatelessWidget {
  const XpRadio({
    super.key,
    required this.value,
    required this.group,
    required this.onChanged,
    required this.label,
  });
  final T value;
  final T group;
  final ValueChanged<T> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    final selected = value == group;
    return InkWell(
      onTap: () => onChanged(value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: const Color(0xFF1C5180)),
              ),
              alignment: Alignment.center,
              child: selected
                  ? Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                          shape: BoxShape.circle, color: Color(0xFF21A121)),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 15)),
          ],
        ),
      ),
    );
  }
}

/// Segmented "block" progress bar.
class XpProgressBar extends StatelessWidget {
  const XpProgressBar(
      {super.key, required this.value, this.color = Xp.green, this.height = 22});
  final double value;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFF686868)),
        borderRadius: BorderRadius.circular(3),
      ),
      child: LayoutBuilder(builder: (context, c) {
        const seg = 9.0, gap = 2.0;
        final count = (c.maxWidth / (seg + gap)).floor();
        final filled = (count * value.clamp(0.0, 1.0)).round();
        final light = Color.lerp(color, Colors.white, 0.45)!;
        return Row(
          children: List.generate(filled, (_) {
            return Container(
              width: seg,
              margin: const EdgeInsets.only(right: gap),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [light, color, light],
                ),
              ),
            );
          }),
        );
      }),
    );
  }
}

class XpMenuItem {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const XpMenuItem(this.label, this.icon, this.onTap);
}

/// Blue "desktop" background with an optional taskbar at the bottom.
class XpDesktop extends StatelessWidget {
  const XpDesktop({super.key, required this.child, this.menu});
  final Widget child;
  final List<XpMenuItem>? menu;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3A6EA5),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF5B9BE6), Color(0xFF2F6CC9), Color(0xFF1E4F9E)],
          ),
        ),
        child: Column(
          children: [
            // Without a taskbar, keep content clear of Android's navigation bar.
            Expanded(child: SafeArea(bottom: menu == null, child: child)),
            if (menu != null) _Taskbar(menu: menu!),
          ],
        ),
      ),
    );
  }
}

class _Taskbar extends StatelessWidget {
  const _Taskbar({required this.menu});
  final List<XpMenuItem> menu;

  void _openMenu(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        child: Align(
          alignment: Alignment.bottomLeft,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 42, left: 2),
            child: Material(
              color: Colors.transparent,
              child: SizedBox(
                width: 240,
                child: XpWindow(
                  title: 'Menu',
                  icon: Icons.apps,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final m in menu)
                        ListTile(
                          dense: true,
                          leading: Icon(m.icon, color: Xp.titleB),
                          title: Text(m.label,
                              style: const TextStyle(fontSize: 15)),
                          onTap: () {
                            Navigator.pop(ctx);
                            m.onTap();
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF3F8CF3), Color(0xFF245EDC), Color(0xFF1941A5)],
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 42,
          child: Row(
            children: [
              GestureDetector(
                onTap: () => _openMenu(context),
                child: Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    borderRadius:
                        BorderRadius.horizontal(right: Radius.circular(14)),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Xp.greenLight, Xp.green, Color(0xFF2A7A2A)],
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.fitness_center, color: Colors.white, size: 20),
                      SizedBox(width: 6),
                      Text('Menu',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              fontStyle: FontStyle.italic,
                              shadows: [
                                Shadow(
                                    color: Colors.black45, offset: Offset(1, 1))
                              ])),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              const _TrayClock(),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrayClock extends StatefulWidget {
  const _TrayClock();
  @override
  State<_TrayClock> createState() => _TrayClockState();
}

class _TrayClockState extends State<_TrayClock> {
  late Timer _t;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 15),
        (_) => setState(() => _now = DateTime.now()));
  }

  @override
  void dispose() {
    _t.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hh = _now.hour.toString().padLeft(2, '0');
    final mm = _now.minute.toString().padLeft(2, '0');
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1DA3F2), Color(0xFF0C7AD6)],
        ),
        border: Border(left: BorderSide(color: Color(0xFF0A4FB0))),
      ),
      child: Text('$hh:$mm',
          style: const TextStyle(color: Colors.white, fontSize: 15)),
    );
  }
}

/// Classic message box. Returns the index of the tapped button.
Future<int?> showXpDialog(
  BuildContext context, {
  required String title,
  required String message,
  List<String> buttons = const ['OK'],
  IconData icon = Icons.info_outline,
  int? dangerIndex,
}) {
  return showDialog<int>(
    context: context,
    builder: (ctx) => Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Material(
          color: Colors.transparent,
          child: XpWindow(
            title: title,
            icon: icon,
            onClose: () => Navigator.pop(ctx),
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, size: 36, color: Xp.titleB),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Text(message,
                            style: const TextStyle(fontSize: 15))),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var i = 0; i < buttons.length; i++)
                      XpButton(
                        label: buttons[i],
                        kind: i == dangerIndex
                            ? XpButtonKind.red
                            : XpButtonKind.normal,
                        onPressed: () => Navigator.pop(ctx, i),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
