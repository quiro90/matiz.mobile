## Purpose

Define cómo se empaqueta, firma y publica Matiz Android en Google Play cumpliendo sus políticas vigentes (nivel de API, permisos, servicios en primer plano, seguridad de datos y privacidad), con un build reproducible.

## ADDED Requirements

### Requirement: Build de publicación firmado
El proyecto SHALL generar con un único comando documentado un Android App Bundle (`.aab`) de release firmado con la clave de subida del autor (fuera del código fuente, referenciada por un archivo de propiedades local no versionado), con ofuscación/minimización habilitadas sin romper la funcionalidad, `versionName` semántico y `versionCode` creciente. También SHALL poder generarse un APK de release para pruebas locales.

#### Scenario: Generar el bundle
- **WHEN** el autor ejecuta el comando de release documentado con `key.properties` configurado
- **THEN** se genera `build/app/outputs/bundle/release/app-release.aab` firmado y aceptado por Play Console

#### Scenario: Sin clave configurada
- **WHEN** se ejecuta el comando de release sin `key.properties`
- **THEN** el build falla con un mensaje claro y no produce un bundle firmado con la clave de depuración

### Requirement: Niveles de API y compatibilidad de plataforma
La app SHALL compilar y apuntar (`targetSdk`) al nivel de API exigido por Google Play para apps nuevas al momento del envío (a octubre de 2026: API 36), con `minSdk` 29 (Android 10). SHALL soportar páginas de memoria de 16 KB, pantalla de borde a borde, atrás predictivo y la preferencia de idioma por app.

#### Scenario: Revisión previa al lanzamiento
- **WHEN** se sube el bundle a la pista de pruebas internas
- **THEN** Play Console no informa errores de nivel de API, de compatibilidad con 16 KB ni de permisos no declarados

### Requirement: Permisos mínimos y justificados
La app SHALL declarar solo: `CAMERA` (en tiempo de ejecución, para `camera-picker`); y para `floating-bubble`: `SYSTEM_ALERT_WINDOW`, `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_SPECIAL_USE` (burbuja en reposo), `FOREGROUND_SERVICE_MEDIA_PROJECTION` (solo durante la captura) y `POST_NOTIFICATIONS`. NO SHALL declarar permisos de almacenamiento, de medios (`READ_MEDIA_*`), de ubicación, de contactos, `QUERY_ALL_PACKAGES` ni `INTERNET` (los enlaces externos se abren en el navegador). La cámara SHALL declararse como característica no obligatoria para que la app se instale en dispositivos sin cámara.

#### Scenario: Manifiesto final
- **WHEN** se inspecciona el manifiesto combinado del bundle de release
- **THEN** solo contiene los permisos listados y `android.hardware.camera` con `required="false"`

### Requirement: Declaraciones de Google Play
El proyecto SHALL incluir en `docs/` el material para Play Console: descripción corta y completa (es/en), notas de versión, capturas guía, justificación de los servicios en primer plano de tipo "special use" y "media projection" (con guion del video de demostración), respuestas del formulario de seguridad de datos ("no se recopilan ni comparten datos"; procesamiento solo en el dispositivo), clasificación de contenido y una política de privacidad publicable. SHALL documentar el riesgo de rechazo por los enlaces de donación externos (política de pagos de Play) y el plan alternativo (ocultarlos con una bandera de compilación).

#### Scenario: Formulario de seguridad de datos
- **WHEN** el autor completa el formulario de seguridad de datos con `docs/play-store/`
- **THEN** cada respuesta tiene su justificación y coincide con los permisos y el comportamiento real de la app

#### Scenario: Plan B de donaciones
- **WHEN** Play rechaza la app por los enlaces de donación
- **THEN** compilar con la bandera documentada (por ejemplo `--dart-define=DONATIONS=false`) oculta la sección de donaciones sin otros cambios

### Requirement: Identidad visual
La app SHALL usar el ícono de Matiz (copiado del proyecto desktop) como ícono adaptativo de Android (con capa monocromática para íconos temáticos), ícono de 512×512 para Play y gráfico destacado de 1024×500, y una pantalla de inicio del sistema con ese ícono sobre fondo neutro.

#### Scenario: Ícono temático
- **WHEN** el usuario activa íconos temáticos en Android 13+
- **THEN** el ícono de Matiz se muestra en su versión monocromática

### Requirement: Preparada para iOS
La lógica (`matiz_core`) y la UI SHALL no depender de APIs de Android fuera de servicios de plataforma aislados detrás de interfaces (compartir/recibir, burbuja, guardar en galería), de modo que agregar iOS en el futuro solo requiera implementar esos servicios; las funciones sin equivalente (burbuja) SHALL ocultarse en plataformas que no las soporten.

#### Scenario: Plataforma sin burbuja
- **WHEN** la app se ejecuta en una plataforma donde el servicio de burbuja no está disponible
- **THEN** el ajuste "Burbuja flotante" no aparece y el resto de la app funciona igual
