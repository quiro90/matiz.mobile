import 'dart:collection';

import '../colors/argb.dart';
import '../colors/color_state.dart';

enum ColorChangeKind {
  /// Cambio en curso (arrastre). No entra en la pila de deshacer.
  preview,

  /// Cambio confirmado.
  commit,
  undo,
  redo,
}

/// Origen de un cambio confirmado (para historial y otras reacciones).
enum ColorChangeSource {
  picker,
  manualInput,
  screenCapture,
  camera,
  image,
  history,
  palette,
  generated,
  gray,
  previous,
  undoRedo,
  startup,
}

class ColorChange {
  final ColorState state;
  final ColorChangeKind kind;
  final ColorChangeSource source;
  const ColorChange(this.state, this.kind, this.source);
}

/// Fuente única de verdad del Color Actual: color actual, color anterior y pilas de deshacer/rehacer
/// formadas solo por cambios confirmados.
class ColorSession {
  static const int undoLimit = 50;

  final ListQueue<ColorState> _undo = ListQueue();
  final List<ColorState> _redo = [];
  ColorState _committed;

  ColorState current;

  /// Color actual previo al último cambio confirmado.
  ColorState previous;

  void Function(ColorChange change)? onChanged;

  ColorSession(ColorState initial)
      : _committed = initial,
        current = initial,
        previous = initial;

  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;
  int get undoCount => _undo.length;

  void setPreview(ColorState state) {
    current = state;
    onChanged?.call(ColorChange(state, ColorChangeKind.preview, ColorChangeSource.picker));
  }

  void commit(ColorState state, [ColorChangeSource source = ColorChangeSource.picker]) {
    if (state.argb != _committed.argb) {
      _undo.addLast(_committed);
      if (_undo.length > undoLimit) _undo.removeFirst();
      _redo.clear();
      previous = _committed;
    }
    _committed = state;
    current = state;
    onChanged?.call(ColorChange(state, ColorChangeKind.commit, source));
  }

  /// Confirma un color canónico conservando hue/saturación si es acromático.
  void commitArgb(Argb color, ColorChangeSource source) => commit(ColorState.fromArgb(color, current), source);

  /// Restaura el color anterior (también es un cambio confirmado: anterior y actual se intercambian).
  void restorePrevious() => commit(previous, ColorChangeSource.previous);

  bool undo() {
    if (_undo.isEmpty) return false;
    final state = _undo.removeLast();
    _redo.add(_committed);
    previous = _committed;
    _committed = state;
    current = state;
    onChanged?.call(ColorChange(state, ColorChangeKind.undo, ColorChangeSource.undoRedo));
    return true;
  }

  bool redo() {
    if (_redo.isEmpty) return false;
    final state = _redo.removeLast();
    _undo.addLast(_committed);
    previous = _committed;
    _committed = state;
    current = state;
    onChanged?.call(ColorChange(state, ColorChangeKind.redo, ColorChangeSource.undoRedo));
    return true;
  }
}
