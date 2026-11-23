import 'package:material_ui/material_ui.dart';

import 'basics.dart';
import 'tokens.dart';

/// A sentence while recording: original small on top, translation large below.
class LiveLine extends StatelessWidget {
  const LiveLine({
    super.key,
    required this.original,
    required this.translation,
    required this.partial,
    required this.ended,
  });

  final String? original;
  final String? translation;
  final String? partial;

  /// Speech for this line has stopped, so it's waiting on the transcript.
  final bool ended;

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    final o = original;

    if (o == null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(14, 2, 14, 2),
        child: partial != null && partial!.isNotEmpty
            ? Text('$partial…', style: LtText.original.copyWith(color: c.faint, fontSize: 15))
            : TypingDots(label: ended ? 'Transcribing' : 'Listening'),
      );
    }

    final pending = translation == null;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: pending ? c.brandSoft : c.surface,
        borderRadius: BorderRadius.circular(LtRadius.lg),
        boxShadow: pending ? null : c.shadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            o,
            style: LtText.original.copyWith(color: pending ? c.ink : c.muted, fontSize: pending ? 15 : 13.5),
          ),
          const SizedBox(height: 6),
          if (pending)
            const TypingDots(label: 'Translating')
          else
            Text(translation!, style: LtText.translation.copyWith(color: c.ink)),
        ],
      ),
    );
  }
}

/// A sentence in a saved session, with a timestamp gutter. Tapping plays it.
class PlaybackLine extends StatelessWidget {
  const PlaybackLine({
    super.key,
    required this.startMs,
    required this.original,
    required this.translation,
    required this.active,
    required this.onTap,
  });

  final int startMs;
  final String? original;
  final String? translation;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    return Material(
      color: active ? c.brandSoft : Colors.transparent,
      borderRadius: BorderRadius.circular(LtRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(LtRadius.md),
        onTap: onTap,
        child: Stack(
          children: [
            if (active)
              Positioned(
                left: 0,
                top: 12,
                bottom: 12,
                child: Container(
                  width: 3,
                  decoration: BoxDecoration(color: c.brand, borderRadius: BorderRadius.circular(2)),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 44,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Text(
                        formatClock(startMs),
                        style: LtText.label.copyWith(
                          letterSpacing: 0,
                          fontSize: 11.5,
                          color: active ? c.brandText : c.faint,
                          fontFeatures: LtText.tabular,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          original ?? 'Not transcribed',
                          style: LtText.original.copyWith(
                            color: original == null ? c.faint : c.muted,
                            fontStyle: original == null ? FontStyle.italic : null,
                          ),
                        ),
                        if (translation != null) ...[
                          const SizedBox(height: 4),
                          Text(translation!, style: LtText.translation.copyWith(color: c.ink, fontSize: 16.5)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
