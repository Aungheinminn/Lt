import 'package:material_ui/material_ui.dart';

import 'tokens.dart';

class LtCard extends StatelessWidget {
  const LtCard({super.key, required this.child, this.padding, this.color, this.radius = LtRadius.xl});

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color ?? c.surface,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: color == null ? c.shadow : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Material(
          type: MaterialType.transparency,
          child: padding == null ? child : Padding(padding: padding!, child: child),
        ),
      ),
    );
  }
}

enum ChipTone { neutral, brand, rec, warn, selected }

class LtChip extends StatelessWidget {
  const LtChip({
    super.key,
    required this.label,
    this.icon,
    this.tone = ChipTone.neutral,
    this.pulse = false,
    this.onTap,
    this.height = 28,
  });

  final String label;
  final IconData? icon;
  final ChipTone tone;
  final bool pulse;
  final VoidCallback? onTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    final (bg, fg) = switch (tone) {
      ChipTone.neutral => (c.surface2, c.muted),
      ChipTone.brand => (c.brandSoft, c.brandText),
      ChipTone.rec => (c.recSoft, c.rec),
      ChipTone.warn => (c.warnSoft, c.warn),
      ChipTone.selected => (c.ink, c.bg),
    };
    final chip = Container(
      height: height,
      padding: EdgeInsets.symmetric(horizontal: height > 30 ? 14 : 10),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (pulse) ...[PulseDot(color: fg), const SizedBox(width: 7)],
          if (icon != null) ...[Icon(icon, size: 16, color: fg), const SizedBox(width: 5)],
          Text(
            label,
            maxLines: 1,
            style: LtText.chip.copyWith(color: fg, fontSize: height > 30 ? 13 : 12),
          ),
        ],
      ),
    );
    if (onTap == null) return chip;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: chip,
      ),
    );
  }
}

class PulseDot extends StatefulWidget {
  const PulseDot({super.key, required this.color, this.size = 8});

  final Color color;
  final double size;

  @override
  State<PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<PulseDot> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.stop();
      _c.value = 1;
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.35, end: 1.0).animate(_c),
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      ),
    );
  }
}

/// Three pulsing dots with a label, for text that's still on its way.
class TypingDots extends StatelessWidget {
  const TypingDots({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 3; i++) ...[
          PulseDot(color: c.brandText, size: 5),
          const SizedBox(width: 4),
        ],
        const SizedBox(width: 2),
        Text(label, style: LtText.chip.copyWith(color: c.brandText)),
      ],
    );
  }
}

class LtBanner extends StatelessWidget {
  const LtBanner({
    super.key,
    required this.icon,
    required this.title,
    this.body,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? body;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    return Material(
      color: c.warnSoft,
      borderRadius: BorderRadius.circular(LtRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(LtRadius.lg),
        onTap: onAction,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Row(
            children: [
              Icon(icon, color: c.warn, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: LtText.body.copyWith(fontWeight: FontWeight.w600, color: c.ink, fontSize: 13.5)),
                    if (body != null) Text(body!, style: LtText.meta.copyWith(color: c.muted)),
                  ],
                ),
              ),
              if (actionLabel != null) ...[
                const SizedBox(width: 8),
                Text(actionLabel!, style: LtText.body.copyWith(color: c.warn, fontWeight: FontWeight.w600, fontSize: 13.5)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class InlineNote extends StatelessWidget {
  const InlineNote({super.key, required this.icon, required this.text, this.busy = false});

  final IconData icon;
  final String text;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(color: c.warnSoft, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          if (busy)
            SizedBox.square(
              dimension: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: c.warn),
            )
          else
            Icon(icon, size: 16, color: c.warn),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: LtText.meta.copyWith(color: c.warn))),
        ],
      ),
    );
  }
}

class LtSegmented<T> extends StatelessWidget {
  const LtSegmented({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
  });

  final List<(T value, String label, IconData? icon)> segments;
  final T selected;
  final ValueChanged<T>? onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          for (final (value, label, icon) in segments)
            Expanded(
              child: Semantics(
                selected: value == selected,
                button: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onChanged == null ? null : () => onChanged!(value),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    height: 34,
                    decoration: BoxDecoration(
                      color: value == selected ? c.surface : Colors.transparent,
                      borderRadius: BorderRadius.circular(9),
                      boxShadow: value == selected ? c.shadow : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, size: 17, color: value == selected ? c.ink : c.muted),
                          const SizedBox(width: 6),
                        ],
                        Flexible(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: LtText.chip.copyWith(
                              fontSize: 13,
                              color: value == selected ? c.ink : c.muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.filled = false,
    this.color,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool filled;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: filled ? c.surface2 : null,
        foregroundColor: color ?? c.ink,
        fixedSize: const Size.square(40),
      ),
      icon: Icon(icon, size: 21),
    );
  }
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.padding = const EdgeInsets.fromLTRB(6, 18, 6, 8)});

  final String text;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Text(text.toUpperCase(), style: LtText.label.copyWith(color: context.lt.faint)),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(color: c.brandSoft, shape: BoxShape.circle),
              child: Icon(icon, color: c.brandText, size: 28),
            ),
            const SizedBox(height: 16),
            Text(title, style: LtText.rowTitle.copyWith(fontSize: 17, color: c.ink)),
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: Text(body, textAlign: TextAlign.center, style: LtText.original.copyWith(color: c.muted)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Centers page content in a readable column on wide windows.
class ReadingColumn extends StatelessWidget {
  const ReadingColumn({super.key, required this.child, this.maxWidth = 720});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

String formatClock(int ms) {
  final s = ms ~/ 1000;
  final h = s ~/ 3600;
  final m = (s % 3600) ~/ 60;
  final sec = (s % 60).toString().padLeft(2, '0');
  return h > 0 ? '$h:${m.toString().padLeft(2, '0')}:$sec' : '$m:$sec';
}
