---
tags: [adr]
---
# ADR-M01 Flutter y port del core
**Decisión**: app Flutter + port del core C# a Dart (en un paquete aparte), verificado con una tabla dorada.

**Por qué**: UI táctil moderna, y Android e iOS con un solo código. El core son unas 2.000 líneas de lógica pura: portarlo es más simple y robusto que usar FFI/NativeAOT o MAUI. La paridad se garantiza con [[Paridad con desktop]].
