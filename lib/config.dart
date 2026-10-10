// Configuración de compilación.

/// Plan B ante la política de pagos de Google Play: `--dart-define=DONATIONS=false` oculta las donaciones.
const bool donationsEnabled = bool.fromEnvironment('DONATIONS', defaultValue: true);

const String cafecitoUrl = 'https://cafecito.app/juanquiroga';
const String paypalUrl = 'https://www.paypal.com/ncp/payment/PJXDUSBHSE8DE';

/// URL pública de la política de privacidad (PRIVACY.md). PROVISIONAL: confirmar el repo/ruta definitivos antes de publicar.
const String privacyPolicyUrl = 'https://github.com/quiro90/matiz/blob/main/android/PRIVACY.md';
