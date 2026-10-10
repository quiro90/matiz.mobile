import 'package:flutter/material.dart';

/// Logo de Matiz (el mismo ícono de la app desktop, regenerado en alta resolución).
class MatizLogo extends StatelessWidget {
  const MatizLogo({super.key, this.size = 24});

  final double size;

  @override
  Widget build(BuildContext context) => Image.asset(
        'assets/branding/matiz_logo.png',
        width: size,
        height: size,
        filterQuality: FilterQuality.medium,
        semanticLabel: 'Matiz',
      );
}
