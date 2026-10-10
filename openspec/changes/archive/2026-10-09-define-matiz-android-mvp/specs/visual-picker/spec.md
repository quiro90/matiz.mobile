## Purpose

Selector visual principal en la pestaña Crear: una rueda hue/saturación táctil con control de brillo y ajustes finos accesibles, pensada para elegir colores con el dedo de forma rápida y precisa en pantallas pequeñas.

## ADDED Requirements

### Requirement: Rueda hue/saturación táctil
El sistema SHALL mostrar una rueda donde el ángulo representa el hue (0° rojo arriba, creciente en sentido horario) y la distancia al centro la saturación HSV (centro 0% = blanco, borde 100%), dibujada con brillo 100%. Tocar y soltar sin moverse (tap) SHALL establecer el color en ese punto como cambio confirmado; arrastrar SHALL mover el marcador en vivo y confirmar al soltar. Apoyar el dedo sin moverlo NO SHALL cambiar el color hasta soltar (tap) o hasta empezar a arrastrar, de modo que mantener pulsado pueda usarse para añadir secundarios (ver `free-points`). La rueda SHALL ocupar el máximo espacio disponible de su zona manteniéndose circular.

#### Scenario: Tap en el borde
- **WHEN** el usuario toca y suelta el borde de la rueda a 120° con brillo 100%
- **THEN** el color actual es `#00FF00`

#### Scenario: Tap en el centro
- **WHEN** el usuario toca y suelta el centro exacto con brillo 100%
- **THEN** el color actual es `#FFFFFF`

#### Scenario: Arrastre fuera de la rueda
- **WHEN** el usuario arrastra el dedo más allá del borde
- **THEN** la saturación se limita a 100% y el hue sigue el ángulo del dedo

#### Scenario: Mantener pulsado no mueve el principal
- **WHEN** el usuario mantiene el dedo quieto sobre la rueda más de 500 ms
- **THEN** el color actual no cambia (se dispara la acción de mantener pulsado)

### Requirement: Marcador visible bajo el dedo
El sistema SHALL mostrar un marcador en la posición (hue, saturación) del color actual con contraste sobre cualquier color, y SHALL moverlo cuando el color cambie por cualquier vía. Durante el arrastre el marcador SHALL agrandarse o mostrar una muestra desplazada por encima del dedo, para que el dedo no oculte el color elegido.

#### Scenario: Entrada externa
- **WHEN** el color actual pasa a ser `#5246BC` desde el historial
- **THEN** el marcador se ubica a 246° y al radio de saturación 63% según la distribución activa

#### Scenario: Muestra visible durante el arrastre
- **WHEN** el usuario arrastra el marcador
- **THEN** una muestra del color actual permanece visible por encima del punto de contacto

### Requirement: Control de brillo
El sistema SHALL mostrar junto a la rueda un control de brillo (HSV Value) vertical cuyo fondo sea un degradado del color actual desde brillo 100% hasta negro, con un área táctil de al menos 48 dp de ancho. Arrastrarlo SHALL modificar solo el brillo, en vivo, y confirmar al soltar.

#### Scenario: Oscurecer
- **WHEN** el color es `#5246BC` y el usuario lleva el brillo a 37%
- **THEN** el color actual pasa a ser `#29235E` y el marcador de la rueda no cambia de posición

### Requirement: Distribución radial de saturación (enfoque)
El sistema SHALL ofrecer un control "Enfoque" entre "Vivo" y "Pastel" (con acción de restablecer) que cambie cómo se distribuye la saturación en el radio sin cambiar el color actual (`S = r^γ`, lineal en la posición neutra). El ajuste SHALL persistir entre sesiones. El control SHALL estar en la hoja de ajuste fino del color, no en la vista principal.

#### Scenario: Cambiar enfoque no altera el color
- **WHEN** el color actual es `#5246BC` y el usuario mueve el enfoque hacia "Pastel"
- **THEN** el color actual sigue siendo `#5246BC` y el marcador se desplaza hacia el exterior

#### Scenario: Más espacio para pasteles
- **WHEN** el enfoque está en "Pastel"
- **THEN** el rango de saturación 0–30% ocupa más de la mitad del radio

### Requirement: Ajuste fino numérico
La hoja de detalle del color (ver `current-color`) SHALL ofrecer campos H (0–360, un decimal), S (0–100%) y B (0–100%) con teclado numérico, y botones −/+ (±1) que repitan al mantenerlos pulsados. Los valores fuera de rango SHALL marcarse como inválidos sin cambiar el color.

#### Scenario: Edición numérica
- **WHEN** el usuario escribe `200` en H y confirma
- **THEN** el marcador gira a 200° y el color actual se actualiza manteniendo saturación y brillo

#### Scenario: Valor fuera de rango
- **WHEN** el usuario escribe `120` en S
- **THEN** el campo se marca como inválido y el color no cambia

### Requirement: Grises
El sistema SHALL permitir seleccionar grises desde el centro de la rueda y SHALL ofrecer la acción "Gris equivalente" (gris de igual luminosidad OKLab L). El estado del selector SHALL conservar hue y saturación de origen cuando el color pasa a gris o negro.

#### Scenario: Gris equivalente
- **WHEN** el color actual es `#5246BC` y el usuario ejecuta "Gris equivalente"
- **THEN** el color actual es un gris neutro cuya L OKLab coincide con la de `#5246BC` (±0.005)

### Requirement: Rendimiento de la rueda
El mapa de la rueda SHALL generarse una vez y reutilizarse mientras no cambien su tamaño, la densidad de píxeles o el enfoque; mover el marcador o el brillo no SHALL regenerarlo. La interacción SHALL mantenerse a la tasa de refresco de la pantalla en un dispositivo de gama media.

#### Scenario: Arrastre sin regeneración
- **WHEN** el usuario arrastra el marcador o el brillo de forma continua
- **THEN** la imagen de la rueda no se regenera y no hay saltos de fotogramas perceptibles
