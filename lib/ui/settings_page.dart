import 'package:flutter/material.dart';
import 'package:matiz_core/matiz_core.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config.dart';
import '../l10n/generated/app_localizations.dart';
import '../state/app_controller.dart';
import '../widgets/matiz_logo.dart';

/// Versión leída del paquete compilado (single source: `pubspec.yaml`); se consulta una vez.
/// Sin canal de plataforma (tests) devuelve null y el título no muestra versión.
final Future<PackageInfo?> _packageInfo = () async {
  try {
    return await PackageInfo.fromPlatform();
  } catch (_) {
    return null;
  }
}();

String _aboutTitle(PackageInfo? info) {
  final v = info?.version ?? '';
  return v.isEmpty ? 'Matiz by Juan Quiroga' : 'Matiz $v by Juan Quiroga';
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<void> _open(String url) => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

  @override
  Widget build(BuildContext context) {
    final c = context.watch<AppController>();
    final t = AppLocalizations.of(context);
    final s = c.settings;
    final theme = Theme.of(context);
    Widget header(String text) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
          child: Text(text.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, letterSpacing: 0.8)),
        );
    Widget segmented<T>(List<(T, String)> options, T selected, ValueChanged<T> onChanged) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            width: double.infinity,
            child: SegmentedButton<T>(
              showSelectedIcon: false,
              segments: [for (final (v, l) in options) ButtonSegment(value: v, label: Text(l))],
              selected: {selected},
              onSelectionChanged: (x) => onChanged(x.first),
            ),
          ),
        );

    return Scaffold(
      appBar: AppBar(title: Text(t.settings)),
      body: ListView(children: [
        header(t.settingsLanguage),
        segmented([(AppLanguage.system, t.languageSystem), (AppLanguage.spanish, 'Español'), (AppLanguage.english, 'English')],
            s.language, c.setLanguage),
        header(t.settingsTheme),
        segmented([(ThemePreference.system, t.themeSystem), (ThemePreference.light, t.themeLight), (ThemePreference.dark, t.themeDark)],
            s.theme, c.setTheme),
        header(t.settingsCopy),
        ListTile(
          title: Text(t.settingsDefaultFormat),
          subtitle: Text(ColorFormatters.get(s.defaultFormatId).displayName),
          trailing: const Icon(Icons.chevron_right),
          onTap: () async {
            final id = await showModalBottomSheet<String>(
              context: context,
              isScrollControlled: true,
              builder: (ctx) => SafeArea(
                child: ListView(shrinkWrap: true, children: [
                  for (final f in ColorFormatters.all.where((f) => f.id != 'all'))
                    ListTile(
                      title: Text(f.displayName),
                      subtitle: Text(f.format(c.currentArgb, c.formatOptions)),
                      trailing: f.id == s.defaultFormatId ? const Icon(Icons.check) : null,
                      onTap: () => Navigator.pop(ctx, f.id),
                    ),
                ]),
              ),
            );
            if (id != null) c.setDefaultFormat(id);
          },
        ),
        SwitchListTile(title: Text(t.settingsHexUppercase), value: s.hexUppercase, onChanged: c.setHexUppercase),
        SwitchListTile(title: Text(t.settingsHexHash), value: s.hexHash, onChanged: c.setHexHash),
        SwitchListTile(
          title: Text(t.settingsCopyOnPick),
          subtitle: Text(t.settingsCopyOnPickHint),
          value: s.copyOnPick,
          onChanged: c.setCopyOnPick,
        ),
        header(t.settingsScale),
        ListTile(title: Text(t.settingsScaleAnchor)),
        segmented([(ScaleAnchorMode.fixed500, t.anchorFixed500), (ScaleAnchorMode.automatic, t.anchorAuto)], s.scaleAnchor, c.setAnchor),
        if (c.platform.bubbleSupported) ...[
          header(t.settingsBubble),
          SwitchListTile(
            title: Text(t.settingsBubble),
            subtitle: Text(t.settingsBubbleHint),
            value: s.bubbleEnabled,
            onChanged: (v) => _toggleBubble(context, v),
          ),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: Text(t.bubbleHowTitle),
            onTap: () => showDialog<void>(
              context: context,
              builder: (d) => AlertDialog(
                title: Text(t.bubbleHowTitle),
                content: SingleChildScrollView(child: Text(t.bubbleHowBody)),
                actions: [TextButton(onPressed: () => Navigator.pop(d), child: Text(t.ok))],
              ),
            ),
          ),
        ],
        header(t.settingsAbout),
        ListTile(
          leading: const MatizLogo(size: 36),
          title: FutureBuilder<PackageInfo?>(
            future: _packageInfo,
            builder: (context, snapshot) => Text(_aboutTitle(snapshot.data)),
          ),
          subtitle: const Text('@juanquirogaart'),
          onTap: () => _open('https://www.instagram.com/juanquirogaart/'),
        ),
        if (donationsEnabled) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Text(t.support, style: theme.textTheme.bodyMedium),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(spacing: 8, runSpacing: 8, children: [
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF00B0E1), foregroundColor: Colors.white),
                onPressed: () => _open(cafecitoUrl),
                icon: const Icon(Icons.coffee_rounded, size: 18),
                label: const Text('Cafecito'),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFFC439), foregroundColor: const Color(0xFF003087)),
                onPressed: () => _open(paypalUrl),
                icon: const Icon(Icons.favorite_rounded, size: 18),
                label: const Text('PayPal'),
              ),
            ]),
          ),
        ],
        ListTile(
          leading: const Icon(Icons.privacy_tip_outlined),
          title: Text(t.privacyPolicy),
          onTap: () => _open(privacyPolicyUrl),
        ),
        ListTile(
          leading: const Icon(Icons.article_outlined),
          title: Text(t.licenses),
          onTap: () async {
            final info = await _packageInfo;
            if (!context.mounted) return;
            showLicensePage(
              context: context,
              applicationName: 'Matiz',
              applicationVersion: info?.version ?? '',
              applicationIcon: const Padding(padding: EdgeInsets.all(12), child: MatizLogo(size: 56)),
            );
          },
        ),
        const SizedBox(height: 24),
      ]),
    );
  }

  Future<void> _toggleBubble(BuildContext context, bool enable) async {
    final c = context.read<AppController>();
    final t = AppLocalizations.of(context);
    final p = c.platform;
    if (!enable) {
      await p.stopBubble();
      c.setBubbleEnabled(false);
      return;
    }
    if (!await p.canDrawOverlays()) {
      final granted = await p.requestOverlayPermission();
      if (!granted) {
        c.showToast(t.bubblePermissionOverlay);
        return;
      }
    }
    if (!await p.requestNotificationPermission()) {
      c.showToast(t.bubblePermissionNotifications);
      return;
    }
    final ok = await p.startBubble();
    c.setBubbleEnabled(ok);
  }
}
