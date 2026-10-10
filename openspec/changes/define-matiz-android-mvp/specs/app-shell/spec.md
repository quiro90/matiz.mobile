## Purpose

Define la estructura de la app móvil —tres pestañas inferiores (Crear, Generar, Paletas), una barra superior compacta, temas, idioma, ajustes y navegación con Atrás— para que Matiz se sienta pequeña, rápida y natural en una pantalla táctil.

## ADDED Requirements

### Requirement: Navegación por pestañas inferiores
La app SHALL organizarse en una barra de navegación inferior con tres destinos: **Crear** (rueda o imagen, barra Anterior | Actual, Recientes y vista previa del modo generado), **Generar** (paletas generadas y modo Personalizado) y **Paletas** (paleta activa y biblioteca). Cambiar de pestaña SHALL conservar el estado de cada una (scroll, modo, imagen). Ajustes, la cámara y las vistas previas de exportación SHALL abrirse como pantallas apiladas sobre las pestañas.

#### Scenario: Inicio
- **WHEN** el usuario abre la app
- **THEN** ve directamente la pestaña Crear con el último color de la sesión anterior, sin pantallas intermedias ni tutoriales obligatorios

#### Scenario: Estado conservado
- **WHEN** el usuario está en Generar → Armonías → Tetrádica, pasa a Paletas y vuelve
- **THEN** Generar sigue en Armonías → Tetrádica

### Requirement: Barra superior compacta
Sobre las pestañas SHALL existir una barra superior con el nombre de la app y los botones Deshacer, Rehacer, alternar tema claro/oscuro y Ajustes. En Crear la zona de contenido SHALL ofrecer además las acciones de entrada: Abrir imagen, Pegar, Cámara y (con imagen cargada) el conmutador Rueda | Imagen.

#### Scenario: Deshacer desde cualquier pestaña
- **WHEN** el usuario está en Generar y toca Deshacer
- **THEN** el color actual vuelve al anterior confirmado y las tarjetas se recalculan

### Requirement: Gesto Atrás predecible
El gesto o botón Atrás SHALL, en este orden de prioridad: cerrar la hoja o el menú abierto; cerrar la pantalla apilada; en Crear con modo Imagen, volver a modo Rueda; en Generar o Paletas, ir a Crear; en Crear (modo Rueda), salir de la app. SHALL ser compatible con la animación de "atrás predictivo" del sistema.

#### Scenario: Atrás desde Paletas
- **WHEN** el usuario está en Paletas sin hojas abiertas y usa Atrás
- **THEN** se muestra la pestaña Crear y la app no se cierra

### Requirement: Temas claro y oscuro neutros
La app SHALL ofrecer tema Sistema (por defecto), Claro y Oscuro, con superficies en grises neutros (sin tinte de color, incluso si el sistema ofrece color dinámico), aplicados al instante y persistentes. Las barras del sistema SHALL adaptarse al tema y la app SHALL dibujarse de borde a borde respetando los recortes y las barras.

#### Scenario: Cambiar tema
- **WHEN** el usuario toca el botón de tema en la barra superior estando en claro
- **THEN** toda la UI pasa a oscuro de inmediato y la preferencia persiste

### Requirement: Idioma español / inglés
La app SHALL estar disponible en español e inglés. Por defecto SHALL usar el idioma del sistema (español si el sistema está en cualquier variante de español, inglés en otro caso); en Ajustes SHALL poder elegirse Sistema, Español o English, aplicándose al instante sin reiniciar, y SHALL integrarse con la preferencia de idioma por app del sistema (Android 13+). Todos los textos visibles, avisos y descripciones de accesibilidad SHALL estar traducidos.

#### Scenario: Cambiar idioma
- **WHEN** el usuario elige "English" en Ajustes
- **THEN** todas las pantallas pasan a inglés de inmediato (por ejemplo "Crear" pasa a "Create") y la preferencia persiste

### Requirement: Ajustes
La pantalla Ajustes SHALL contener: Idioma; Tema; Formato principal; HEX en mayúsculas; Incluir `#`; Copiar al tomar color (por defecto desactivado); Ancla de la escala (Base en 500 / Automático); Burbuja flotante (ver `floating-bubble`) con "¿Cómo funciona?"; Créditos "Matiz <versión> by Juan Quiroga - @juanquirogaart" (el @ abre Instagram en el navegador); Apoyar el proyecto con los botones Cafecito y PayPal (abren el navegador externo); Política de privacidad (enlace); y Licencias de código abierto.

#### Scenario: Enlace de donación
- **WHEN** el usuario toca "Cafecito"
- **THEN** se abre el navegador del sistema en la página de Cafecito del autor, fuera de la app

### Requirement: Diseño táctil y adaptable
Todos los controles interactivos SHALL tener un área táctil mínima de 48×48 dp (40 dp en acciones secundarias dentro de tarjetas) y los botones solo con ícono SHALL tener descripción para TalkBack y tooltip al mantenerlos. La app SHALL funcionar sin recortes ni desbordes desde 360×640 dp en vertical con tamaño de texto del sistema hasta 130%. En anchos ≥ 600 dp (tablets, plegables, horizontal) Crear SHALL mostrar el selector y el panel del color lado a lado.

#### Scenario: Pantalla pequeña
- **WHEN** la app corre en una pantalla de 360×640 dp con texto al 130%
- **THEN** la rueda, la barra Anterior | Actual y la navegación son visibles y usables sin desbordes

#### Scenario: TalkBack
- **WHEN** TalkBack está activo y el foco llega al botón de copiar de la barra del color actual
- **THEN** se anuncia "Copiar color #5246BC"

### Requirement: Arranque rápido
La pestaña Crear SHALL ser interactiva en menos de 2 segundos en arranque en frío en un dispositivo de gama media, mostrando la pantalla de inicio del sistema con el ícono de Matiz mientras carga.

#### Scenario: Arranque en frío
- **WHEN** el usuario abre la app tras reiniciar el teléfono
- **THEN** la pestaña Crear responde al toque en menos de 2 segundos
