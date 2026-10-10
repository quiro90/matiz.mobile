import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:matiz_core/matiz_core.dart';
import 'package:provider/provider.dart';

import 'l10n/generated/app_localizations.dart';
import 'state/app_controller.dart';
import 'ui/shell.dart';
import 'ui/theme.dart';

class MatizApp extends StatelessWidget {
  const MatizApp({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: controller,
      child: Builder(builder: (context) {
        final theme = context.select<AppController, ThemePreference>((c) => c.settings.theme);
        final language = context.select<AppController, AppLanguage>((c) => c.settings.language);
        return MaterialApp(
          title: 'Matiz',
          debugShowCheckedModeBanner: false,
          theme: MatizTheme.light(),
          darkTheme: MatizTheme.dark(),
          themeMode: switch (theme) {
            ThemePreference.light => ThemeMode.light,
            ThemePreference.dark => ThemeMode.dark,
            ThemePreference.system => ThemeMode.system,
          },
          locale: switch (language) {
            AppLanguage.spanish => const Locale('es'),
            AppLanguage.english => const Locale('en'),
            AppLanguage.system => null,
          },
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          localeResolutionCallback: (locale, supported) =>
              locale != null && locale.languageCode == 'es' ? const Locale('es') : const Locale('en'),
          home: const Shell(),
        );
      }),
    );
  }
}
