import 'package:matiz_core/matiz_core.dart';

import '../l10n/generated/app_localizations.dart';

String modeLabel(AppLocalizations t, GenerationMode m) => switch (m) {
      GenerationMode.scale => t.modeScale,
      GenerationMode.tintsShades => t.modeTintsShades,
      GenerationMode.neutrals => t.modeNeutrals,
      GenerationMode.harmony => t.modeHarmony,
      GenerationMode.custom => t.modeCustom,
      GenerationMode.extracted => t.modeExtracted,
    };

String harmonyLabel(AppLocalizations t, HarmonyKind k) => switch (k) {
      HarmonyKind.complementary => t.harmonyComplementary,
      HarmonyKind.analogous => t.harmonyAnalogous,
      HarmonyKind.splitComplementary => t.harmonySplit,
      HarmonyKind.triadic => t.harmonyTriadic,
      HarmonyKind.tetradic => t.harmonyTetradic,
      HarmonyKind.monochromatic => t.harmonyMonochromatic,
    };
