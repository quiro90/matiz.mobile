---
tags: [funcionalidad, formato]
---
# Archivo .mpalette
JSON idéntico al de desktop (`schemaVersion`, nombre, descripción, fechas, `grayPercent` opcional 0–100 — omitido si 0 — y colores con `hex`, más `alpha` si ≠ 255). Lee fechas con los 7 decimales de .NET. Los colores del archivo son siempre los originales (la mezcla de escala de grises no se hornea; ver [[Paletas]]).
- Exportar: **Guardar en…** (diálogo del sistema) o **Compartir**.
- Importar: selector de archivos, [[Compartir hacia Matiz]] o Abrir con. Siempre crea una paleta nueva (sufijo " 2" si el nombre existe) y restaura el `grayPercent` guardado al activarla; una versión futura o un JSON inválido muestran un aviso sin cambiar nada.
