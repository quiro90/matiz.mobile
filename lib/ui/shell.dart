import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:matiz_core/matiz_core.dart';
import 'package:provider/provider.dart';

import '../l10n/generated/app_localizations.dart';
import '../platform/platform_bridge.dart';
import '../state/app_controller.dart';
import '../widgets/matiz_logo.dart';
import 'create_page.dart';
import 'generate_page.dart';
import 'palettes_page.dart';
import 'settings_page.dart';

/// Estructura principal: barra superior compacta, tres pestañas inferiores (Crear, Generar, Paletas),
/// avisos (SnackBar), gesto Atrás y recepción de contenido compartido.
class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> with WidgetsBindingObserver {
  final _messenger = GlobalKey<ScaffoldMessengerState>();
  StreamSubscription<Toast>? _toastSub;
  StreamSubscription<IncomingContent>? _incomingSub;
  final Set<String> _handled = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final c = context.read<AppController>();
    _toastSub = c.toasts.listen(_showToast);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      c.showStartupNotices();
      final initial = await c.platform.initialContent();
      if (initial != null) await _handleIncoming(initial);
      _incomingSub = c.platform.incoming.listen(_handleIncoming);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _toastSub?.cancel();
    _incomingSub?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final c = context.read<AppController>();
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive || state == AppLifecycleState.detached) {
      c.flush();
    } else if (state == AppLifecycleState.resumed && c.settings.bubbleEnabled) {
      // La burbuja pudo descartarse arrastrándola a la ✕ o desde la notificación.
      c.platform.isBubbleRunning().then((running) {
        if (!running) c.setBubbleEnabled(false);
      });
    }
  }

  Future<void> _handleIncoming(IncomingContent content) async {
    // Un contenido recibido se procesa una sola vez (rotaciones, reanudaciones).
    if (!_handled.add('${content.kind}:${content.path}')) return;
    final c = context.read<AppController>();
    final file = File(content.path);
    if (!await file.exists()) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    Navigator.of(context).popUntil((r) => r.isFirst);
    await c.handleIncoming(content, bytes);
  }

  void _showToast(Toast t) {
    final m = _messenger.currentState;
    if (m == null) return;
    m.hideCurrentSnackBar();
    m.showSnackBar(SnackBar(
      content: Text(t.message),
      duration: t.duration,
      persist: false,
      action: t.actionLabel != null && t.onAction != null ? SnackBarAction(label: t.actionLabel!, onPressed: t.onAction!) : null,
    ));
  }

  void _toggleTheme(AppController c) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    c.setTheme(dark ? ThemePreference.light : ThemePreference.dark);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<AppController>();
    final t = AppLocalizations.of(context);
    c.t = t;
    final canPop = c.tab == Tabs.create && !c.showImage;
    return ScaffoldMessenger(
      key: _messenger,
      child: PopScope(
        canPop: canPop,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          if (c.tab != Tabs.create) {
            c.setTab(Tabs.create);
          } else if (c.showImage) {
            c.setShowImage(false);
          }
        },
        child: Scaffold(
          appBar: AppBar(
            titleSpacing: 16,
            title: Row(children: [
              const MatizLogo(size: 24),
              const SizedBox(width: 10),
              Text(t.appName),
            ]),
            actions: [
              IconButton(tooltip: t.undo, icon: const Icon(Icons.undo_rounded), onPressed: c.session.canUndo ? c.undo : null),
              IconButton(tooltip: t.redo, icon: const Icon(Icons.redo_rounded), onPressed: c.session.canRedo ? c.redo : null),
              IconButton(
                tooltip: t.toggleTheme,
                icon: Icon(Theme.of(context).brightness == Brightness.dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
                onPressed: () => _toggleTheme(c),
              ),
              IconButton(
                tooltip: t.settings,
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsPage())),
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: SafeArea(
            top: false,
            bottom: false,
            child: IndexedStack(index: c.tab, children: const [
              CreatePage(),
              GeneratePage(),
              PalettesPage(),
            ]),
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: c.tab,
            onDestinationSelected: c.setTab,
            destinations: [
              NavigationDestination(icon: const Icon(Icons.colorize_outlined), selectedIcon: const Icon(Icons.colorize), label: t.tabCreate),
              NavigationDestination(icon: const Icon(Icons.auto_awesome_outlined), selectedIcon: const Icon(Icons.auto_awesome), label: t.tabGenerate),
              NavigationDestination(icon: const Icon(Icons.palette_outlined), selectedIcon: const Icon(Icons.palette), label: t.tabPalettes),
            ],
          ),
        ),
      ),
    );
  }
}
