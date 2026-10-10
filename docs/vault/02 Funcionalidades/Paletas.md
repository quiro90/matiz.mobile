---
tags: [funcionalidad, paletas]
---
# Paletas (pestaña)
- **Paleta activa**: nombre y descripción editables y lista de colores (tocar = usar; mantener y arrastrar = reordenar; mantener sin mover o ⋮ = menú: copiar, renombrar, reemplazar con el actual, mover, eliminar con Deshacer).
- **Escala de grises**: slider 0–100 % siempre visible bajo las acciones de la paleta activa; mezcla "en caliente" cada color hacia su gris equivalente (Oklab) solo a nivel de presentación, con % visible y botón para restablecer a 0. Cada paleta recuerda su % (`grayPercent`, restaurado al activar/importar; crear y duplicar arrancan en 0). Las exportaciones (código e imagen) salen tal como se ve; el `.mpalette` conserva los originales + el %.
- Acciones: Cargar en la rueda (→ [[Personalizado]], con aviso; respeta la vista vigente), Exportar imagen (paleta o superpuestos, ver [[Exportación]]), `.mpalette` (guardar o compartir, ver [[Archivo mpalette]]), Copiar o Compartir como código, Duplicar, Eliminar (con Deshacer).
- **Biblioteca**: todas las paletas con vista previa completa; tocar = activar; Nueva e Importar. Estado vacío explicativo.
- Límite de 64 colores al añadir (las importadas más grandes se conservan). Autoguardado: [[Flujo de persistencia]].
