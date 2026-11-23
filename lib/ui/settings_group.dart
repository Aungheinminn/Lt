import 'package:material_ui/material_ui.dart';

import 'basics.dart';
import 'tokens.dart';

class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, required this.label, required this.children});

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionLabel(label),
        LtCard(
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const Divider(indent: 58),
                children[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.enabled = true,
    this.iconTone = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool enabled;

  /// Brand-tinted icon tile, for a row that shows a good state.
  final bool iconTone;

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconTone ? c.brandSoft : c.surface2,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 18, color: iconTone ? c.brandText : c.muted),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: LtText.body.copyWith(color: c.ink)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!, style: LtText.meta.copyWith(color: c.muted, fontSize: 12)),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 12), trailing!],
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsValue extends StatelessWidget {
  const SettingsValue(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(text, style: LtText.body.copyWith(color: c.muted, fontWeight: FontWeight.w400, fontSize: 13.5)),
        Icon(Icons.chevron_right_rounded, size: 20, color: c.faint),
      ],
    );
  }
}
