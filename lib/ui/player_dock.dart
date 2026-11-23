import 'package:just_audio/just_audio.dart';
import 'package:material_ui/material_ui.dart';

import 'basics.dart';
import 'tokens.dart';

class PlayerDock extends StatefulWidget {
  const PlayerDock({
    super.key,
    required this.player,
    required this.spans,
    required this.onSkip,
    required this.onTogglePlay,
  });

  final AudioPlayer player;

  /// Start and end of each line in ms; end is null if it was never closed.
  final List<(int, int?)> spans;
  final void Function(int ms) onSkip;
  final VoidCallback onTogglePlay;

  @override
  State<PlayerDock> createState() => _PlayerDockState();
}

class _PlayerDockState extends State<PlayerDock> {
  static const _speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

  /// Position under the finger while dragging, so the playhead doesn't jump
  /// back to the playing position mid-drag.
  double? _dragMs;

  void _seekTo(double dx, double width, double max, {required bool commit}) {
    final ms = (dx / width).clamp(0.0, 1.0) * max;
    if (commit) {
      widget.player.seek(Duration(milliseconds: ms.round()));
      setState(() => _dragMs = null);
    } else {
      setState(() => _dragMs = ms);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    final player = widget.player;
    final timeStyle = LtText.label.copyWith(letterSpacing: 0, fontSize: 11.5, color: c.faint, fontFeatures: LtText.tabular);

    return LtCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      child: StreamBuilder<Duration?>(
        stream: player.durationStream,
        builder: (context, durationSnap) {
          final durationMs = (durationSnap.data ?? Duration.zero).inMilliseconds.toDouble();
          final max = durationMs <= 0 ? 1.0 : durationMs;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              StreamBuilder<Duration>(
                stream: player.positionStream,
                builder: (context, positionSnap) {
                  final positionMs = (positionSnap.data ?? Duration.zero).inMilliseconds.toDouble();
                  final value = (_dragMs ?? positionMs).clamp(0.0, max);
                  return Column(
                    children: [
                      LayoutBuilder(
                        builder: (context, box) {
                          final w = box.maxWidth;
                          return Semantics(
                            slider: true,
                            label: 'Playback position',
                            value: formatClock(value.round()),
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTapUp: (d) => _seekTo(d.localPosition.dx, w, max, commit: true),
                              onHorizontalDragUpdate: (d) => _seekTo(d.localPosition.dx, w, max, commit: false),
                              onHorizontalDragEnd: (_) {
                                if (_dragMs != null) _seekTo(_dragMs! / max * w, w, max, commit: true);
                              },
                              child: SizedBox(
                                height: 28,
                                width: w,
                                child: CustomPaint(
                                  painter: _SentenceTrack(
                                    spans: widget.spans,
                                    durationMs: max,
                                    positionMs: value,
                                    played: c.brand,
                                    unplayed: c.line,
                                    gapColor: c.surface2,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(formatClock(value.round()), style: timeStyle),
                          const Spacer(),
                          Text(formatClock(durationMs.round()), style: timeStyle),
                        ],
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  StreamBuilder<double>(
                    stream: player.speedStream,
                    builder: (context, snap) {
                      final speed = snap.data ?? 1.0;
                      return PopupMenuButton<double>(
                        tooltip: 'Playback speed',
                        initialValue: speed,
                        onSelected: player.setSpeed,
                        itemBuilder: (_) => [
                          for (final s in _speeds) PopupMenuItem(value: s, child: Text('${_fmtSpeed(s)}×')),
                        ],
                        child: Container(
                          width: 48,
                          height: 32,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(LtRadius.sm)),
                          child: Text('${_fmtSpeed(speed)}×', style: LtText.chip.copyWith(color: c.ink, fontSize: 13, fontWeight: FontWeight.w600)),
                        ),
                      );
                    },
                  ),
                  RoundIconButton(
                    icon: Icons.replay_10_rounded,
                    tooltip: 'Back 10 seconds',
                    onPressed: () => widget.onSkip(-10000),
                  ),
                  StreamBuilder<PlayerState>(
                    stream: player.playerStateStream,
                    builder: (context, snap) {
                      final state = snap.data;
                      final completed = state?.processingState == ProcessingState.completed;
                      final playing = (state?.playing ?? false) && !completed;
                      return IconButton.filled(
                        tooltip: playing ? 'Pause (Space)' : 'Play (Space)',
                        style: IconButton.styleFrom(
                          backgroundColor: c.brand,
                          foregroundColor: c.onBrand,
                          fixedSize: const Size.square(52),
                        ),
                        icon: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 30),
                        onPressed: () {
                          if (completed) {
                            player.seek(Duration.zero);
                            player.play();
                          } else {
                            widget.onTogglePlay();
                          }
                        },
                      );
                    },
                  ),
                  RoundIconButton(
                    icon: Icons.forward_10_rounded,
                    tooltip: 'Forward 10 seconds',
                    onPressed: () => widget.onSkip(10000),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  static String _fmtSpeed(double s) => s == s.roundToDouble() ? s.toStringAsFixed(0) : s.toString();
}

/// The timeline drawn as one pill per sentence, so you can see where speech
/// is and jump between lines.
class _SentenceTrack extends CustomPainter {
  _SentenceTrack({
    required this.spans,
    required this.durationMs,
    required this.positionMs,
    required this.played,
    required this.unplayed,
    required this.gapColor,
  });

  final List<(int, int?)> spans;
  final double durationMs;
  final double positionMs;
  final Color played;
  final Color unplayed;
  final Color gapColor;

  @override
  void paint(Canvas canvas, Size size) {
    final midY = size.height / 2;
    double x(num ms) => (ms / durationMs).clamp(0.0, 1.0) * size.width;
    final px = x(positionMs);

    final base = Paint()..color = gapColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, midY - 2, size.width, 4), const Radius.circular(2)),
      base,
    );

    for (var i = 0; i < spans.length; i++) {
      final (start, end) = spans[i];
      final next = i + 1 < spans.length ? spans[i + 1].$1 : durationMs.round();
      final x0 = x(start);
      final x1 = (x(end ?? next) - 2).clamp(x0 + 3, size.width);
      final r = RRect.fromRectAndRadius(Rect.fromLTRB(x0, midY - 6, x1, midY + 6), const Radius.circular(4));
      canvas.drawRRect(r, Paint()..color = unplayed);
      if (px > x0) {
        canvas.save();
        canvas.clipRect(Rect.fromLTRB(x0, 0, px, size.height));
        canvas.drawRRect(r, Paint()..color = played);
        canvas.restore();
      }
    }

    final head = Paint()..color = played;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(px - 1.5, 0, 3, size.height), const Radius.circular(1.5)),
      head,
    );
  }

  @override
  bool shouldRepaint(_SentenceTrack old) =>
      old.positionMs != positionMs ||
      old.durationMs != durationMs ||
      old.spans != spans ||
      old.played != played ||
      old.unplayed != unplayed;
}
