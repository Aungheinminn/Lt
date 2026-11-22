import 'package:just_audio/just_audio.dart';
import 'package:material_ui/material_ui.dart';

String formatClock(int ms) {
  final s = ms ~/ 1000;
  final h = s ~/ 3600;
  final m = (s % 3600) ~/ 60;
  final sec = (s % 60).toString().padLeft(2, '0');
  return h > 0 ? '$h:${m.toString().padLeft(2, '0')}:$sec' : '$m:$sec';
}

class PlayerBar extends StatefulWidget {
  const PlayerBar({
    super.key,
    required this.player,
    required this.lineStartsMs,
    required this.onSkip,
    required this.onTogglePlay,
  });

  final AudioPlayer player;
  final List<int> lineStartsMs;
  final void Function(int ms) onSkip;
  final VoidCallback onTogglePlay;

  @override
  State<PlayerBar> createState() => _PlayerBarState();
}

class _PlayerBarState extends State<PlayerBar> {
  static const _speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

  /// Position under the thumb while dragging, so the thumb doesn't jump back
  /// to the playing position mid-drag.
  double? _dragMs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final player = widget.player;

    return Material(
      color: scheme.surfaceContainer,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
          child: StreamBuilder<Duration?>(
            stream: player.durationStream,
            builder: (context, durationSnap) {
              final durationMs = (durationSnap.data ?? Duration.zero).inMilliseconds.toDouble();
              return StreamBuilder<Duration>(
                stream: player.positionStream,
                builder: (context, positionSnap) {
                  final positionMs = (positionSnap.data ?? Duration.zero).inMilliseconds.toDouble();
                  final max = durationMs <= 0 ? 1.0 : durationMs;
                  final value = (_dragMs ?? positionMs).clamp(0.0, max);
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 36,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Positioned.fill(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                child: CustomPaint(
                                  painter: _LineMarks(
                                    startsMs: widget.lineStartsMs,
                                    durationMs: max,
                                    color: scheme.outline,
                                  ),
                                ),
                              ),
                            ),
                            Slider(
                              value: value,
                              max: max,
                              onChanged: (v) => setState(() => _dragMs = v),
                              onChangeEnd: (v) {
                                player.seek(Duration(milliseconds: v.round()));
                                setState(() => _dragMs = null);
                              },
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          const SizedBox(width: 12),
                          Text(
                            formatClock(value.round()),
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            tooltip: 'Back 10 seconds',
                            icon: const Icon(Icons.replay_10),
                            onPressed: () => widget.onSkip(-10000),
                          ),
                          StreamBuilder<PlayerState>(
                            stream: player.playerStateStream,
                            builder: (context, snap) {
                              final state = snap.data;
                              final completed = state?.processingState == ProcessingState.completed;
                              final playing = (state?.playing ?? false) && !completed;
                              return IconButton.filled(
                                iconSize: 32,
                                tooltip: playing ? 'Pause' : 'Play',
                                icon: Icon(playing ? Icons.pause : Icons.play_arrow),
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
                          IconButton(
                            tooltip: 'Forward 10 seconds',
                            icon: const Icon(Icons.forward_10),
                            onPressed: () => widget.onSkip(10000),
                          ),
                          const Spacer(),
                          StreamBuilder<double>(
                            stream: player.speedStream,
                            builder: (context, snap) {
                              final speed = snap.data ?? 1.0;
                              return PopupMenuButton<double>(
                                tooltip: 'Playback speed',
                                initialValue: speed,
                                onSelected: player.setSpeed,
                                itemBuilder: (_) => [
                                  for (final s in _speeds)
                                    PopupMenuItem(value: s, child: Text('${_fmtSpeed(s)}×')),
                                ],
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                  child: Text('${_fmtSpeed(speed)}×', style: theme.textTheme.labelLarge),
                                ),
                              );
                            },
                          ),
                          Text(
                            formatClock(durationMs.round()),
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: scheme.outline,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  static String _fmtSpeed(double s) =>
      s == s.roundToDouble() ? s.toStringAsFixed(0) : s.toString();
}

/// Small ticks above the slider track at the start of each line.
class _LineMarks extends CustomPainter {
  _LineMarks({required this.startsMs, required this.durationMs, required this.color});

  final List<int> startsMs;
  final double durationMs;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (durationMs <= 0) return;
    final paint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..strokeWidth = 1.5;
    final y = size.height / 2;
    for (final ms in startsMs) {
      final x = (ms / durationMs).clamp(0.0, 1.0) * size.width;
      canvas.drawLine(Offset(x, y - 10), Offset(x, y - 5), paint);
    }
  }

  @override
  bool shouldRepaint(_LineMarks old) =>
      old.startsMs != startsMs || old.durationMs != durationMs || old.color != color;
}
