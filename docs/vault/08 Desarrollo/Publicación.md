---
tags: [desarrollo, play]
---
# Publicación (diferida)
Pendiente por decisión del autor.

**Ya listo**: `applicationId com.juanquiroga.matiz`, `minSdk 29`/`targetSdk 36`, R8, íconos adaptativos y monocromáticos, [[Permisos]] mínimos y la bandera `DONATIONS=false`.

**Falta**:
- `android/key.properties` y el keystore de subida (sin ellos, el release se firma con la clave de depuración);
- `flutter build appbundle`;
- la ficha de la tienda (es/en);
- el formulario de seguridad de datos ("no se recopilan datos");
- la justificación y el video de los FGS `specialUse`/`mediaProjection`;
- la política de privacidad publicada (la URL en `lib/config.dart` es provisional);
- para cuentas personales nuevas, la prueba cerrada con 12 testers durante 14 días.
