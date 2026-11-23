import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../core/pricing.dart';
import '../data/db/app_database.dart';
import 'basics.dart';
import 'tokens.dart';

class SessionRow extends StatelessWidget {
  const SessionRow({super.key, required this.session, required this.onTap});

  final Session session;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    final s = session;
    final minutes = (s.durationMs / 60000).ceil();
    final cost = SessionCost.of(s);
    final meta = [
      '$minutes min',
      DateFormat.jm().format(s.createdAt.toLocal()),
      if (cost != null) formatUsd(cost.total),
    ].join(' · ');

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            LanguageBadge(source: s.sourceLang, target: s.targetLang),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: LtText.rowTitle.copyWith(color: c.ink),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (s.mode == SessionMode.interpreter) ...[
                        Icon(Icons.record_voice_over_rounded, size: 13, color: c.muted),
                        const SizedBox(width: 4),
                      ],
                      Flexible(
                        child: Text(meta, maxLines: 1, style: LtText.meta.copyWith(color: c.muted)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (s.status == SessionStatus.interrupted) ...[
              const SizedBox(width: 8),
              const LtChip(label: 'Interrupted', tone: ChipTone.warn, height: 22),
            ],
            if (s.starred) ...[
              const SizedBox(width: 8),
              Icon(Icons.star_rounded, size: 20, color: c.star),
            ],
          ],
        ),
      ),
    );
  }
}

class LanguageBadge extends StatelessWidget {
  const LanguageBadge({super.key, required this.source, required this.target});

  final String source;
  final String target;

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    final style = TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.3, height: 1.1, color: c.brandText);
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(color: c.brandSoft, borderRadius: BorderRadius.circular(12)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(source.toUpperCase(), style: style),
          Icon(Icons.arrow_drop_down_rounded, size: 12, color: c.brandText.withValues(alpha: 0.55)),
          Text(target.toUpperCase(), style: style),
        ],
      ),
    );
  }
}
