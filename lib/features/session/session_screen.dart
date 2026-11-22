import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:material_ui/material_ui.dart';

import '../../audio/audio_file_sink.dart';
import '../../audio/line_sync.dart';
import '../../data/db/app_database.dart';
import '../../data/providers.dart';
import '../../session/session_storage.dart';
import 'player_bar.dart';

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

  @override
  void initState() {
    super.initState();
    _positionSub = _player.positionStream.listen(_onPosition);
  }

  @override
  void dispose() {
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
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(action)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider(widget.sessionId)).value;
    final linesAsync = ref.watch(linesProvider(widget.sessionId));
    final db = ref.read(databaseProvider);

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
          appBar: AppBar(
            title: Text(session?.title ?? ''),
            actions: [
              if (session != null)
                IconButton(
                  tooltip: session.starred ? 'Unstar' : 'Star',
                  icon: Icon(session.starred ? Icons.star : Icons.star_border),
                  onPressed: () => db.updateSession(
                    session.id,
                    SessionsCompanion(starred: Value(!session.starred)),
                  ),
                ),
              if (session != null)
                PopupMenuButton<String>(
                  tooltip: 'More',
                  onSelected: (v) {
                    if (v == 'delete') _confirmDelete(session);
                    if (v == 'delete_audio') _confirmDeleteAudio(session);
                  },
                  itemBuilder: (_) => [
                    if (session.audioPath != null)
                      const PopupMenuItem(value: 'delete_audio', child: Text('Delete audio only')),
                    const PopupMenuItem(value: 'delete', child: Text('Delete session')),
                  ],
                ),
            ],
          ),
          body: linesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Could not load transcript: $e')),
            data: (lines) => Column(
              children: [
                if (session?.status == SessionStatus.interrupted)
                  const _Notice(
                    icon: Icons.warning_amber,
                    text: 'This session was interrupted. Everything up to that point was saved.',
                  ),
                if (_audioMissing)
                  const _Notice(
                    icon: Icons.music_off,
                    text: 'The audio file for this session could not be opened.',
                  ),
                Expanded(child: _transcript(lines)),
                if (_audioReady)
                  PlayerBar(
                    player: _player,
                    lineStartsMs: _starts,
                    onSkip: _skip,
                    onTogglePlay: _togglePlay,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _transcript(List<Line> lines) {
    if (lines.isEmpty) return const Center(child: Text('No lines in this session.'));
    return Stack(
      children: [
        NotificationListener<UserScrollNotification>(
          onNotification: (n) {
            if (_player.playing && _follow) setState(() => _follow = false);
            return false;
          },
          child: SingleChildScrollView(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 72),
            child: Column(
              children: [
                for (var i = 0; i < lines.length; i++)
                  _LineTile(
                    key: _lineKeys.putIfAbsent(lines[i].itemId, GlobalKey.new),
                    line: lines[i],
                    active: i == _current && _audioReady,
                    canPlay: _audioReady,
                    onTap: () => _playLine(lines[i]),
                  ),
              ],
            ),
          ),
        ),
        if (!_follow && _audioReady)
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Center(
              child: FilledButton.tonalIcon(
                onPressed: _backToCurrent,
                icon: const Icon(Icons.my_location, size: 18),
                label: const Text('Back to current'),
              ),
            ),
          ),
      ],
    );
  }
}

class _LineTile extends StatelessWidget {
  const _LineTile({
    super.key,
    required this.line,
    required this.active,
    required this.canPlay,
    required this.onTap,
  });

  final Line line;
  final bool active;
  final bool canPlay;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: active ? scheme.primaryContainer : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: canPlay ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 56,
                child: Row(
                  children: [
                    if (canPlay)
                      Icon(
                        active ? Icons.graphic_eq : Icons.play_arrow,
                        size: 16,
                        color: active ? scheme.primary : scheme.outline,
                      ),
                    const SizedBox(width: 2),
                    Text(
                      formatClock(line.startMs),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: active ? scheme.primary : scheme.outline,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      line.originalText ?? 'Not transcribed',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: line.originalText == null ? scheme.outline : null,
                        fontStyle: line.originalText == null ? FontStyle.italic : null,
                      ),
                    ),
                    if (line.translatedText != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        line.translatedText!,
                        style: theme.textTheme.bodyLarge?.copyWith(color: scheme.primary),
                      ),
                    ],
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

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      color: scheme.surfaceContainerHigh,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: scheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
