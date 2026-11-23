import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import 'package:material_ui/material_ui.dart';

import '../../audio/audio_file_sink.dart';
import '../../audio/line_sync.dart';
import '../../data/db/app_database.dart';
import '../../data/providers.dart';
import '../../session/session_storage.dart';
import '../../ui/basics.dart';
import '../../ui/player_dock.dart';
import '../../ui/tokens.dart';
import '../../ui/transcript_line.dart';

class SessionScreen extends ConsumerStatefulWidget {
  const SessionScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  ConsumerState<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends ConsumerState<SessionScreen> {
  final _player = AudioPlayer();
  final _scroll = ScrollController();
  final _focus = FocusNode();
  final _lineKeys = <String, GlobalKey>{};
  StreamSubscription<Duration>? _positionSub;

  String? _loadedAudio;
  bool _audioReady = false;
  bool _audioMissing = false;
  bool _follow = true;
  int _current = -1;
  List<int> _starts = const [];
  List<Line> _lines = const [];
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _positionSub = _player.positionStream.listen(_onPosition);
    _lifecycle = AppLifecycleListener(onPause: _player.pause);
  }

  // The shell keeps inactive tabs mounted under a disabled TickerMode, so this
  // is how the screen learns it was switched away from.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!TickerMode.valuesOf(context).enabled && _player.playing) _player.pause();
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _positionSub?.cancel();
    _player.dispose();
    _scroll.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _loadAudio(String? relativePath) async {
    if (relativePath == _loadedAudio) return;
    _loadedAudio = relativePath;
    setState(() {
      _audioReady = false;
      _audioMissing = false;
    });
    if (relativePath == null) {
      await _player.stop();
      return;
    }
    final path = await resolveAudioPath(relativePath);
    if (path == null || !mounted) return;
    try {
      await _player.setFilePath(path);
      if (mounted) setState(() => _audioReady = true);
    } catch (_) {
      if (mounted) setState(() => _audioMissing = true);
    }
  }

  void _onPosition(Duration position) {
    final index = lineIndexAt(_starts, position.inMilliseconds);
    if (index == _current) return;
    setState(() => _current = index);
    if (_follow && index >= 0 && _player.playing) _scrollToLine(index);
  }

  void _scrollToLine(int index) {
    final key = _lineKeys[_lines[index].itemId];
    final ctx = key?.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      alignment: 0.35,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> _playLine(Line line) async {
    if (!_audioReady) return;
    setState(() => _follow = true);
    await _player.seek(Duration(milliseconds: line.startMs));
    unawaited(_player.play());
  }

  void _backToCurrent() {
    setState(() => _follow = true);
    if (_current >= 0) _scrollToLine(_current);
  }

  void _skip(int ms) {
    final duration = _player.duration ?? Duration.zero;
    var target = _player.position + Duration(milliseconds: ms);
    if (target < Duration.zero) target = Duration.zero;
    if (target > duration) target = duration;
    _player.seek(target);
  }

  void _togglePlay() => _player.playing ? _player.pause() : _player.play();

  Future<void> _confirmDelete(Session session) async {
    final ok = await _confirm(
      title: 'Delete this session?',
      body: 'The transcript and audio will be removed from this device.',
      action: 'Delete',
    );
    if (ok != true || !mounted) return;
    await _player.stop();
    await deleteSessionWithAudio(ref.read(databaseProvider), session);
    if (mounted) context.go('/history');
  }

  Future<void> _confirmDeleteAudio(Session session) async {
    final ok = await _confirm(
      title: 'Delete the audio?',
      body: 'The transcript is kept. You won\'t be able to play this session.',
      action: 'Delete audio',
    );
    if (ok != true || !mounted) return;
    await _player.stop();
    final db = ref.read(databaseProvider);
    final audio = session.audioPath;
    await db.updateSession(
      session.id,
      const SessionsCompanion(audioPath: Value(null), audioBytes: Value(0)),
    );
    if (audio != null) await deleteAudioFile(audio);
  }

  Future<bool?> _confirm({required String title, required String body, required String action}) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: context.lt.rec, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: Text(action),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider(widget.sessionId)).value;
    final linesAsync = ref.watch(linesProvider(widget.sessionId));
    final db = ref.read(databaseProvider);
    final c = context.lt;

    if (session != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadAudio(session.audioPath));
    }
    _lines = linesAsync.value ?? const [];
    _starts = [for (final l in _lines) l.startMs];

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.space): _togglePlay,
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () => _skip(-5000),
        const SingleActivator(LogicalKeyboardKey.arrowRight): () => _skip(5000),
      },
      child: Focus(
        focusNode: _focus,
        autofocus: true,
        child: Scaffold(
          body: SafeArea(
            child: ReadingColumn(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 8, 0),
                    child: Row(
                      children: [
                        RoundIconButton(
                          icon: Icons.arrow_back_rounded,
                          tooltip: 'Back to History',
                          filled: true,
                          onPressed: () => context.go('/history'),
                        ),
                        const Spacer(),
                        if (session != null) ...[
                          RoundIconButton(
                            icon: session.starred ? Icons.star_rounded : Icons.star_outline_rounded,
                            tooltip: session.starred ? 'Unstar' : 'Star',
                            color: session.starred ? c.star : null,
                            onPressed: () => db.updateSession(
                              session.id,
                              SessionsCompanion(starred: Value(!session.starred)),
                            ),
                          ),
                          PopupMenuButton<String>(
                            tooltip: 'More',
                            icon: const Icon(Icons.more_horiz_rounded),
                            onSelected: (v) {
                              if (v == 'delete') _confirmDelete(session);
                              if (v == 'delete_audio') _confirmDeleteAudio(session);
                            },
                            itemBuilder: (_) => [
                              if (session.audioPath != null)
                                const PopupMenuItem(value: 'delete_audio', child: Text('Delete audio only')),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete session', style: TextStyle(color: c.rec)),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (session != null) _Header(session: session),
                  if (session?.status == SessionStatus.interrupted)
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: InlineNote(
                        icon: Icons.info_outline_rounded,
                        text: 'Interrupted. Everything up to that point was saved.',
                      ),
                    ),
                  if (_audioMissing)
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: InlineNote(
                        icon: Icons.music_off_rounded,
                        text: 'The audio file for this session could not be opened.',
                      ),
                    ),
                  Expanded(
                    child: linesAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => EmptyState(
                        icon: Icons.error_outline_rounded,
                        title: 'Could not load transcript',
                        body: '$e',
                      ),
                      data: _transcript,
                    ),
                  ),
                  if (_audioReady)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                      child: PlayerDock(
                        player: _player,
                        spans: [for (final l in _lines) (l.startMs, l.endMs)],
                        onSkip: _skip,
                        onTogglePlay: _togglePlay,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _transcript(List<Line> lines) {
    if (lines.isEmpty) {
      return const EmptyState(
        icon: Icons.notes_rounded,
        title: 'No lines',
        body: 'Nothing was transcribed in this session.',
      );
    }
    return Stack(
      children: [
        NotificationListener<UserScrollNotification>(
          onNotification: (n) {
            if (_player.playing && _follow) setState(() => _follow = false);
            return false;
          },
          child: SingleChildScrollView(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 64),
            child: Column(
              children: [
                for (var i = 0; i < lines.length; i++)
                  Padding(
                    key: _lineKeys.putIfAbsent(lines[i].itemId, GlobalKey.new),
                    padding: const EdgeInsets.only(bottom: 2),
                    child: PlaybackLine(
                      startMs: lines[i].startMs,
                      original: lines[i].originalText,
                      translation: lines[i].translatedText,
                      active: i == _current && _audioReady,
                      onTap: _audioReady ? () => _playLine(lines[i]) : null,
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (!_follow && _audioReady)
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Center(
              child: FilledButton.icon(
                onPressed: _backToCurrent,
                style: FilledButton.styleFrom(
                  shape: const StadiumBorder(),
                  minimumSize: const Size(0, 36),
                  elevation: 2,
                ),
                icon: const Icon(Icons.my_location_rounded, size: 17),
                label: const Text('Back to current'),
              ),
            ),
          ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.session});

  final Session session;

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    final s = session;
    final minutes = (s.durationMs / 60000).ceil();
    final created = s.createdAt.toLocal();
    final now = DateTime.now();
    final date = (created.year == now.year ? DateFormat.MMMd() : DateFormat.yMMMd()).add_jm().format(created);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.title, style: LtText.heading.copyWith(color: c.ink)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              LtChip(
                label: '${s.sourceLang.toUpperCase()} → ${s.targetLang.toUpperCase()}',
                tone: ChipTone.brand,
              ),
              LtChip(label: date),
              LtChip(label: '$minutes min'),
              if (s.mode == SessionMode.interpreter)
                const LtChip(label: 'Interpreter', icon: Icons.record_voice_over_rounded),
            ],
          ),
        ],
      ),
    );
  }
}
