import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/providers.dart';
import '../../ui/basics.dart';
import '../../ui/settings_group.dart';
import '../../ui/tokens.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const _retention = [(0, 'Never'), (7, '7 days'), (30, '30 days'), (90, '90 days')];

  Future<void> _pickRetention(BuildContext context, WidgetRef ref, int current) async {
    final c = context.lt;
    final picked = await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Delete audio after'),
        children: [
          for (final (days, label) in _retention)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, days),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                children: [
                  Expanded(child: Text(label, style: LtText.body.copyWith(color: c.ink))),
                  if (days == current) Icon(Icons.check_rounded, color: c.brand, size: 20),
                ],
              ),
            ),
        ],
      ),
    );
    if (picked != null) ref.read(settingsProvider.notifier).setAudioRetentionDays(picked);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);
    final c = context.lt;
    final retentionLabel = _retention
        .firstWhere((r) => r.$1 == settings.audioRetentionDays, orElse: () => (0, '${settings.audioRetentionDays} days'))
        .$2;

    return Scaffold(
      body: SafeArea(
        child: ReadingColumn(
          maxWidth: 600,
          child: ListView(
            padding: EdgeInsets.fromLTRB(16, context.isWide ? 24 : 8, 16, 24),
            children: [
              Text('Settings', style: LtText.title.copyWith(color: c.ink)),
              const SizedBox(height: 4),
              const SettingsGroup(label: 'OpenAI', children: [_ApiKeyRow()]),
              SettingsGroup(
                label: 'Recording',
                children: [
                  SettingsRow(
                    icon: Icons.save_rounded,
                    title: 'Save audio',
                    subtitle: 'Replay sessions later',
                    onTap: () => controller.setSaveAudio(!settings.saveAudio),
                    trailing: Switch(value: settings.saveAudio, onChanged: controller.setSaveAudio),
                  ),
                  SettingsRow(
                    icon: Icons.auto_delete_rounded,
                    title: 'Delete audio after',
                    subtitle: 'Transcripts are always kept',
                    enabled: settings.saveAudio,
                    onTap: () => _pickRetention(context, ref, settings.audioRetentionDays),
                    trailing: SettingsValue(retentionLabel),
                  ),
                  SettingsRow(
                    icon: Icons.volume_up_rounded,
                    title: 'Speak translation',
                    subtitle: 'Reads each line aloud. The mic pauses while it speaks, so use headphones to keep talking.',
                    onTap: () => controller.setSpeakTranslation(!settings.speakTranslation),
                    trailing: Switch(value: settings.speakTranslation, onChanged: controller.setSpeakTranslation),
                  ),
                ],
              ),
              const SectionLabel('Appearance'),
              LtCard(
                padding: const EdgeInsets.all(4),
                child: LtSegmented<ThemeMode>(
                  segments: const [
                    (ThemeMode.system, 'System', Icons.contrast_rounded),
                    (ThemeMode.light, 'Light', Icons.light_mode_rounded),
                    (ThemeMode.dark, 'Dark', Icons.dark_mode_rounded),
                  ],
                  selected: settings.themeMode,
                  onChanged: controller.setThemeMode,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Text(
                  'Your key is only ever sent to OpenAI.',
                  textAlign: TextAlign.center,
                  style: LtText.meta.copyWith(color: c.faint, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ApiKeyRow extends ConsumerWidget {
  const _ApiKeyRow();

  static String _mask(String key) =>
      key.length <= 8 ? '••••' : '${key.substring(0, 3)}••••••••${key.substring(key.length - 4)}';

  Future<void> _edit(BuildContext context, WidgetRef ref, {required bool replacing}) async {
    final key = await showDialog<String>(
      context: context,
      builder: (_) => _ApiKeyDialog(replacing: replacing),
    );
    if (key == null || key.isEmpty) return;
    await ref.read(apiKeyProvider.notifier).save(key);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API key saved on this device')),
      );
    }
  }

  Future<void> _remove(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove API key?'),
        content: const Text('Lt can’t transcribe or translate until you add a key again.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: context.lt.rec, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok == true) await ref.read(apiKeyProvider.notifier).clear();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.lt;
    final saved = ref.watch(apiKeyProvider).value;
    final hasKey = saved != null && saved.isNotEmpty;

    if (!hasKey) {
      return SettingsRow(
        icon: Icons.key_rounded,
        title: 'No key yet',
        subtitle: 'Needed to transcribe and translate',
        onTap: () => _edit(context, ref, replacing: false),
        trailing: FilledButton(
          onPressed: () => _edit(context, ref, replacing: false),
          child: const Text('Add key'),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: c.brandSoft, borderRadius: BorderRadius.circular(9)),
            child: Icon(Icons.check_circle_rounded, size: 18, color: c.brandText),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Key connected', style: LtText.body.copyWith(color: c.ink, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  _mask(saved),
                  style: LtText.meta.copyWith(color: c.muted, fontSize: 12, fontFamily: 'monospace'),
                ),
              ],
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(backgroundColor: c.surface2, foregroundColor: c.ink),
            onPressed: () => _edit(context, ref, replacing: true),
            child: const Text('Replace'),
          ),
          const SizedBox(width: 4),
          RoundIconButton(
            icon: Icons.delete_outline_rounded,
            tooltip: 'Remove key',
            color: c.muted,
            onPressed: () => _remove(context, ref),
          ),
        ],
      ),
    );
  }
}

class _ApiKeyDialog extends StatefulWidget {
  const _ApiKeyDialog({required this.replacing});

  final bool replacing;

  @override
  State<_ApiKeyDialog> createState() => _ApiKeyDialogState();
}

class _ApiKeyDialogState extends State<_ApiKeyDialog> {
  final _controller = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() => Navigator.pop(context, _controller.text.trim());

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    return AlertDialog(
      title: Text(widget.replacing ? 'Replace API key' : 'Add your OpenAI key'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              obscureText: _obscure,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(
                hintText: 'sk-...',
                suffixIcon: IconButton(
                  tooltip: _obscure ? 'Show' : 'Hide',
                  icon: Icon(_obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded, size: 20),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 10),
            Text(
              'Stored in this device’s secure storage. It is only sent to OpenAI.',
              style: LtText.meta.copyWith(color: c.muted, fontSize: 12),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ListenableBuilder(
          listenable: _controller,
          builder: (context, _) => FilledButton(
            onPressed: _controller.text.trim().isEmpty ? null : _save,
            child: const Text('Save key'),
          ),
        ),
      ],
    );
  }
}
