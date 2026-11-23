import 'package:material_ui/material_ui.dart';

import 'basics.dart';
import 'tokens.dart';

class RecordDock extends StatefulWidget {
  const RecordDock({
    super.key,
    required this.elapsedMs,
    required this.level,
    required this.stopping,
    required this.onStop,
  });

  final int elapsedMs;

  /// Mic level, 0..1.
  final double level;
  final bool stopping;
  final VoidCallback onStop;

  @override
  State<RecordDock> createState() => _RecordDockState();
}

class _RecordDockState extends State<RecordDock> {
  static const _bars = 40;
  final _levels = List<double>.filled(_bars, 0, growable: true);

  @override
  void didUpdateWidget(RecordDock old) {
    super.didUpdateWidget(old);
    if (widget.level != old.level || widget.elapsedMs != old.elapsedMs) {
      _levels
        ..removeAt(0)
        ..add(widget.stopping ? 0 : widget.level.clamp(0.0, 1.0));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    return LtCard(
      padding: const EdgeInsets.fromLTRB(18, 10, 10, 10),
      child: Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                formatClock(widget.elapsedMs),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.4,
                  color: c.ink,
                  fontFeatures: LtText.tabular,
                ),
              ),
              Text(
                widget.stopping ? 'Saving…' : 'Recording',
                style: LtText.chip.copyWith(color: c.muted, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: SizedBox(
              height: 36,
              child: CustomPaint(painter: _LevelBars(_levels, widget.stopping ? c.faint : c.brand)),
            ),
          ),
          const SizedBox(width: 14),
          Tooltip(
            message: 'Stop and save',
            child: Material(
              color: widget.stopping ? c.surface2 : c.rec,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: widget.stopping ? null : widget.onStop,
                child: SizedBox.square(
                  dimension: 52,
                  child: Center(
                    child: widget.stopping
                        ? SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: c.muted),
                          )
                        : Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
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

class _LevelBars extends CustomPainter {
  _LevelBars(List<double> levels, this.color) : levels = List.of(levels);

  final List<double> levels;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final n = levels.length;
    const gap = 2.0;
    final w = (size.width - gap * (n - 1)) / n;
    final paint = Paint()..color = color.withValues(alpha: 0.85);
    for (var i = 0; i < n; i++) {
      final h = (3 + levels[i] * (size.height - 3)).clamp(3.0, size.height);
      final x = i * (w + gap);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, (size.height - h) / 2, w, h),
          Radius.circular(w / 2),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_LevelBars old) => true;
}
