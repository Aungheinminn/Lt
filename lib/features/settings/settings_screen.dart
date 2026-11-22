import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              const _SectionHeader('OpenAI'),
              const _ApiKeyField(),
              const _SectionHeader('Recording'),
              SwitchListTile(
                title: const Text('Save audio'),
                subtitle: const Text('Keep a recording of each session for playback'),
                value: settings.saveAudio,
                onChanged: controller.setSaveAudio,
              ),
              ListTile(
                title: const Text('Delete audio after'),
                subtitle: const Text('Transcripts are kept'),
                trailing: DropdownButton<int>(
                  value: settings.audioRetentionDays,
                  onChanged: settings.saveAudio
                      ? (v) => controller.setAudioRetentionDays(v ?? 0)
                      : null,
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('Never')),
                    DropdownMenuItem(value: 7, child: Text('7 days')),
                    DropdownMenuItem(value: 30, child: Text('30 days')),
                    DropdownMenuItem(value: 90, child: Text('90 days')),
                  ],
                ),
              ),
              SwitchListTile(
                title: const Text('Speak translation'),
                subtitle: const Text(
                  'Captions mode: read each translated line out loud. The mic pauses while it speaks; '
                  'use headphones to keep talking over it.',
                ),
                value: settings.speakTranslation,
                onChanged: controller.setSpeakTranslation,
              ),
              const _SectionHeader('Appearance'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(value: ThemeMode.system, label: Text('System')),
                    ButtonSegment(value: ThemeMode.light, label: Text('Light')),
                    ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
                  ],
                  selected: {settings.themeMode},
                  onSelectionChanged: (s) => controller.setThemeMode(s.first),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        text,
        style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary),
      ),
    );
  }
}

class _ApiKeyField extends ConsumerStatefulWidget {
  const _ApiKeyField();

  @override
  ConsumerState<_ApiKeyField> createState() => _ApiKeyFieldState();
}

class _ApiKeyFieldState extends ConsumerState<_ApiKeyField> {
  final _controller = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _mask(String key) =>
      key.length <= 8 ? '••••' : '${key.substring(0, 3)}••••${key.substring(key.length - 4)}';

  Future<void> _save() async {
    final value = _controller.text.trim();
    if (value.isEmpty) return;
    await ref.read(apiKeyProvider.notifier).save(value);
    _controller.clear();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API key saved on this device')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final saved = ref.watch(apiKeyProvider).value;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (saved != null && saved.isNotEmpty)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.check_circle_outline),
              title: Text('Saved key: ${_mask(saved)}'),
              trailing: TextButton(
                onPressed: () => ref.read(apiKeyProvider.notifier).clear(),
                child: const Text('Remove'),
              ),
            ),
          TextField(
            controller: _controller,
            obscureText: _obscure,
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(
              labelText: saved == null ? 'API key' : 'Replace API key',
              hintText: 'sk-...',
              helperText: 'Stored in this device\'s secure storage. It is only sent to OpenAI.',
              suffixIcon: IconButton(
                tooltip: _obscure ? 'Show' : 'Hide',
                icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 8),
          FilledButton.tonal(onPressed: _save, child: const Text('Save key')),
        ],
      ),
    );
  }
}
