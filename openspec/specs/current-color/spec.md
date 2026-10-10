# current-color Specification

## Purpose

Garantiza un único "Color Actual" como fuente de verdad, presentado de forma compacta (Anterior | Actual) con sus acciones principales a un toque y el detalle completo en una hoja deslizable, con deshacer/rehacer.

## Requirements

### Requirement: Fuente única de verdad
El sistema SHALL mantener un único color actual. La rueda, el brillo, los campos, los formatos, las paletas generadas y las vistas previas SHALL derivarse de él y actualizarse cuando cambie, cualquiera sea su origen (rueda, brillo, entrada manual, imagen, cámara, burbuja, historial, paleta, grises, tarjetas generadas, deshacer/rehacer).

#### Scenario: Entrada manual sincroniza el selector
- **WHEN** el usuario introduce `#5246BC` en el campo de color
- **THEN** el marcador queda en hue 246° y saturación 63%, el brillo en 74% y se recalculan formatos y paletas generadas

### Requirement: Actualización en tiempo real
El sistema SHALL actualizar la muestra, el HEX y las paletas generadas visibles mientras el usuario arrastra, sin botón "Aplicar".

#### Scenario: Arrastre continuo
- **WHEN** el usuario arrastra el marcador por la rueda
- **THEN** el HEX y la vista previa cambian de forma continua durante el arrastre

### Requirement: Preservación de coordenadas del selector
El sistema SHALL conservar el hue cuando la saturación o el brillo llegan a 0, y la saturación cuando el brillo llega a 0, si el cambio proviene del selector o de entradas HSV. Si el color proviene de una entrada RGB/HEX/imagen acromática, SHALL conservarse el hue anterior.

#### Scenario: Oscurecer hasta negro y volver
- **WHEN** el color es hue 246°, S 63%, B 74% y el usuario baja el brillo a 0% y lo sube de nuevo a 74%
- **THEN** el color vuelve a `#5246BC`

### Requirement: Barra compacta Anterior | Actual
La pestaña Crear SHALL mostrar bajo la rueda (o la imagen) una barra compacta con dos muestras contiguas, "Anterior" (estrecha) y "Actual" (ancha, con su HEX legible sobre el color), de altura no mayor a 64 dp, y junto a ellas dos acciones siempre visibles: "Copiar" (formato principal) y "Añadir a paleta" (paleta activa). Tocar "Anterior" SHALL restaurar ese color como cambio confirmado. Tocar "Actual" SHALL abrir la hoja de detalle del color. El color anterior SHALL ser el actual previo al último cambio confirmado (fin de arrastre, confirmación de campo, imagen/cámara/burbuja, historial, paleta, tarjeta, grises, deshacer/rehacer).

#### Scenario: Comparar tras arrastre
- **WHEN** el color es `#5246BC`, el usuario arrastra hasta `#675BCE` y suelta
- **THEN** "Anterior" muestra `#5246BC` y "Actual" muestra `#675BCE`

#### Scenario: Volver al anterior
- **WHEN** el usuario toca la muestra "Anterior"
- **THEN** el color actual pasa a ser `#5246BC` y "Anterior" pasa a ser `#675BCE`

#### Scenario: Añadir a la paleta activa
- **WHEN** la paleta activa es "PuchiApp" y el usuario toca "Añadir a paleta"
- **THEN** el color actual se añade al final de "PuchiApp" y un aviso breve confirma "Añadido a PuchiApp"

### Requirement: Hoja de detalle del color
Tocar la muestra "Actual" SHALL abrir una hoja inferior deslizable con: campo de texto que acepta cualquier formato de `color-model` (con "Pegar" que lee el portapapeles), campos R/G/B (0–255), campos H/S/B y enfoque (ver `visual-picker`), "Gris equivalente", la lista de formatos con copiar (ver `color-clipboard`), "Copiar todo", "Exportar superpuestos" (dupla Anterior/Actual, ver `palette-export`) y los Recientes (ver `color-history`). La hoja SHALL cerrarse deslizando hacia abajo o con el gesto Atrás, sin perder cambios ya confirmados.

#### Scenario: Abrir el detalle
- **WHEN** el usuario toca la muestra "Actual" con `#5246BC`
- **THEN** se abre la hoja con HEX `#5246BC`, R 82, G 70, B 188, H 246, S 63, B 74 y los formatos listados

#### Scenario: Valor RGB inválido
- **WHEN** el usuario escribe `256` en el campo R
- **THEN** el campo se marca como inválido y el color actual no cambia

#### Scenario: Pegar un color
- **WHEN** el portapapeles contiene `rgb(82, 70, 188)` y el usuario toca "Pegar"
- **THEN** el color actual pasa a ser `#5246BC` como cambio confirmado

### Requirement: Deshacer y rehacer
El sistema SHALL mantener una pila de deshacer de al menos 50 cambios confirmados del color actual, accesible con los botones Deshacer/Rehacer de la barra superior (deshabilitados cuando no aplica). Un nuevo cambio confirmado SHALL descartar la pila de rehacer. Los pasos intermedios de un arrastre no SHALL generar entradas.

#### Scenario: Deshacer un arrastre completo
- **WHEN** el usuario arrastra la rueda pasando por muchos colores intermedios, suelta y toca Deshacer
- **THEN** el color actual vuelve al que había antes de empezar el arrastre

### Requirement: Restaurar el último color
Al abrir la app SHALL mostrarse el último color actual de la sesión anterior (con su hue/saturación del selector) en la pestaña Crear.

#### Scenario: Reabrir la app
- **WHEN** el usuario cierra la app con `#5246BC` y la vuelve a abrir
- **THEN** la pestaña Crear muestra `#5246BC` con el marcador en su posición
