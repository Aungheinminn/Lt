import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/languages.dart';
import '../../data/db/app_database.dart';
import '../../data/providers.dart';
import '../../session/live_session.dart';
import '../../widgets/language_picker.dart';

class LiveScreen extends ConsumerWidget {
  const LiveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final live = ref.watch(liveSessionProvider);

    ref.listen(liveSessionProvider, (prev, next) {
      final messenger = ScaffoldMessenger.of(context);
      final saved = next.savedSessionId;
      if (saved != null && saved != prev?.savedSessionId) {
        messenger.showSnackBar(SnackBar(
          content: Text(next.error ?? 'Session saved to History'),
          action: SnackBarAction(
            label: 'Open',
            onPressed: () => context.go('/history/$saved'),
          ),
        ));
        ref.read(liveSessionProvider.notifier).clearMessage();
      } else if (next.error != null && next.error != prev?.error) {
        messenger.showSnackBar(SnackBar(content: Text(next.error!)));
        ref.read(liveSessionProvider.notifier).clearMessage();
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Live')),
      body: SafeArea(
        child: live.active && live.sessionId != null
            ? _LiveView(state: live)
            : _IdleView(connecting: live.phase == LivePhase.connecting),
      ),
    );
  }
}

class _IdleView extends ConsumerWidget {
  const _IdleView({required this.connecting});

  final bool connecting;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);
    final hasKey = ref.watch(apiKeyProvider).value?.isNotEmpty ?? false;
    final theme = Theme.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (!hasKey)
              Card(
                color: theme.colorScheme.errorContainer,
                child: ListTile(
                  leading: const Icon(Icons.key),
                  title: const Text('Add your OpenAI API key'),
                  subtitle: const Text('Lt needs it to transcribe and translate.'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('/settings'),
                ),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: LanguagePicker(
                    label: 'I speak',
                    value: settings.sourceLang,
                    onChanged: (v) => controller.setLanguages(source: v),
                  ),
                ),
                IconButton(
                  tooltip: 'Swap languages',
                  icon: const Icon(Icons.swap_horiz),
                  onPressed: controller.swapLanguages,
                ),
                Expanded(
                  child: LanguagePicker(
                    label: 'Translate to',
                    value: settings.targetLang,
                    onChanged: (v) => controller.setLanguages(target: v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 48),
            Center(
              child: SizedBox.square(
                dimension: 120,
                child: FilledButton(
                  style: FilledButton.styleFrom(shape: const CircleBorder()),
                  onPressed: hasKey && !connecting
                      ? () => ref.read(liveSessionProvider.notifier).start()
                      : null,
                  child: connecting
                      ? const SizedBox.square(
                          dimension: 36,
                          child: CircularProgressIndicator(strokeWidth: 3),
                        )
                      : const Icon(Icons.mic, size: 48),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              connecting ? 'Connecting…' : 'Tap to start',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              settings.saveAudio ? 'Audio will be saved' : 'Audio will not be saved',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveView extends ConsumerStatefulWidget {
  const _LiveView({required this.state});

  final LiveState state;

  @override
  ConsumerState<_LiveView> createState() => _LiveViewState();
}

class _LiveViewState extends ConsumerState<_LiveView> {
  final _scroll = ScrollController();
  int _lastCount = 0;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _followBottom(int count) {
    if (count == _lastCount) return;
    _lastCount = count;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final settings = ref.watch(settingsProvider);
    final lines = ref.watch(linesProvider(s.sessionId!)).value ?? const <Line>[];
    final theme = Theme.of(context);
    final stopping = s.phase == LivePhase.stopping;
    _followBottom(lines.length + s.partials.length);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              _StatusDot(speaking: s.speaking, stopping: stopping),
              const SizedBox(width: 8),
              Text(
                stopping ? 'Finishing…' : (s.speaking ? 'Hearing speech' : 'Listening'),
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(width: 12),
              Text(
                '${languageFor(settings.sourceLang).name} → ${languageFor(settings.targetLang).name}',
                style: theme.textTheme.bodySmall,
              ),
              const Spacer(),
              Text(
                _clock(s.elapsedMs),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
        LinearProgressIndicator(value: stopping ? null : s.level, minHeight: 3),
        Expanded(
          child: lines.isEmpty
              ? Center(
                  child: Text(
                    'Start speaking. Each sentence appears here with its translation.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
                  ),
                )
              : ListView.separated(
                  controller: _scroll,
                  padding: const EdgeInsets.all(16),
                  itemCount: lines.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 14),
                  itemBuilder: (context, i) {
                    final l = lines[i];
                    return _LiveLine(line: l, partial: s.partials[l.itemId]);
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: theme.colorScheme.onError,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: stopping ? null : () => ref.read(liveSessionProvider.notifier).stop(),
              icon: const Icon(Icons.stop),
              label: Text(stopping ? 'Saving…' : 'Stop'),
            ),
          ),
        ),
      ],
    );
  }
}

class _LiveLine extends StatelessWidget {
  const _LiveLine({required this.line, this.partial});

  final Line line;
  final String? partial;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final original = line.originalText ?? partial;
    final muted = theme.colorScheme.outline;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          original ?? (line.endMs == null ? 'Listening…' : 'Transcribing…'),
          style: theme.textTheme.bodyLarge?.copyWith(
            color: line.originalText == null ? muted : null,
          ),
        ),
        if (line.originalText != null) ...[
          const SizedBox(height: 2),
          Text(
            line.translatedText ?? 'Translating…',
            style: theme.textTheme.titleMedium?.copyWith(
              color: line.translatedText == null ? muted : theme.colorScheme.primary,
            ),
          ),
        ],
      ],
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.speaking, required this.stopping});

  final bool speaking;
  final bool stopping;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: stopping ? scheme.outline : (speaking ? scheme.error : scheme.primary),
      ),
    );
  }
}

String _clock(int ms) {
  final s = ms ~/ 1000;
  final h = s ~/ 3600;
  final m = (s % 3600) ~/ 60;
  final sec = (s % 60).toString().padLeft(2, '0');
  return h > 0 ? '$h:${m.toString().padLeft(2, '0')}:$sec' : '$m:$sec';
}
