## Purpose

Permite que Matiz reciba contenido de otras apps a través del sistema: una captura de pantalla o foto compartida se abre lista para tomar colores, y un archivo `.mpalette` compartido o abierto se importa como paleta nueva.

## ADDED Requirements

### Requirement: Matiz como destino de "Compartir" para imágenes
La app SHALL registrarse como destino de la hoja "Compartir" del sistema para imágenes (`image/*`, una imagen). Al recibir una imagen SHALL abrir la pestaña Crear en modo Imagen con esa imagen cargada y su extracción automática (ver `image-picker`), reemplazando la imagen previa si la hubiera y conservando el color actual, las paletas y el conjunto Personalizado. Si se comparten varias imágenes SHALL cargarse la primera y avisar que se usó una.

#### Scenario: Compartir una captura con la app cerrada
- **WHEN** la app está cerrada y el usuario toma una captura de pantalla y elige Compartir → Matiz
- **THEN** Matiz abre directamente en Crear → Imagen con la captura y sus colores extraídos

#### Scenario: Compartir con la app abierta
- **WHEN** Matiz está abierta en segundo plano en la pestaña Paletas y el usuario comparte una foto hacia Matiz
- **THEN** Matiz pasa al frente en Crear → Imagen con esa foto, sin crear una segunda instancia ni perder las paletas

#### Scenario: Varias imágenes
- **WHEN** el usuario comparte 3 imágenes a la vez hacia Matiz
- **THEN** se carga la primera y un aviso indica "Se usó la primera imagen"

### Requirement: Recibir archivos `.mpalette`
La app SHALL aceptar archivos `.mpalette` recibidos por "Compartir" y por "Abrir con" (gestores de archivos, adjuntos de correo, mensajería) e importarlos como paleta nueva según `palette-file`, mostrando la pestaña Paletas con la paleta importada marcada. Dado que muchos orígenes no informan un tipo MIME específico, la app SHALL validar el contenido (JSON con `schemaVersion` y paleta) en lugar de confiar en la extensión o el MIME, y SHALL rechazar con aviso de error lo que no sea una paleta válida.

#### Scenario: Abrir un adjunto
- **WHEN** el usuario toca un adjunto "PuchiApp.mpalette" en el correo y elige Abrir con → Matiz
- **THEN** Matiz abre en la pestaña Paletas con la paleta "PuchiApp" importada como nueva y marcada

#### Scenario: Archivo inválido
- **WHEN** se comparte hacia Matiz un `.mpalette` corrupto
- **THEN** se muestra un aviso de error y la biblioteca no cambia

### Requirement: Recepción segura
El contenido recibido SHALL leerse una sola vez mediante el acceso temporal concedido por el sistema, sin solicitar permisos de almacenamiento, y la app SHALL copiar a su almacenamiento privado solo lo necesario para mantener la imagen activa en la sesión. Un contenido recibido no SHALL procesarse de nuevo al rotar la pantalla o volver a la app.

#### Scenario: Rotación tras recibir
- **WHEN** el usuario recibe una imagen compartida y luego rota el dispositivo
- **THEN** la imagen sigue cargada una sola vez y no se repite la extracción ni el aviso
