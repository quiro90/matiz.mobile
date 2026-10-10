/// HSV/HSB. Hue en grados [0,360), Saturation y Value en [0,1].
class Hsv {
  final double h, s, v;
  const Hsv(this.h, this.s, this.v);
}

/// HSL. Hue en grados [0,360), Saturation y Lightness en [0,1].
class Hsl {
  final double h, s, l;
  const Hsl(this.h, this.s, this.l);
}

/// CMYK aproximado sin perfil. Todos los componentes en [0,1].
class Cmyk {
  final double c, m, y, k;
  const Cmyk(this.c, this.m, this.y, this.k);
}

/// Oklab (Björn Ottosson). L en [0,1].
class Oklab {
  final double l, a, b;
  const Oklab(this.l, this.a, this.b);
}

/// OKLCH: forma polar de Oklab. Hue en grados [0,360).
class Oklch {
  final double l, c, h;
  const Oklch(this.l, this.c, this.h);

  Oklch withC(double chroma) => Oklch(l, chroma, h);
}

/// sRGB lineal (sin función de transferencia), canales nominalmente en [0,1].
class LinearRgb {
  final double r, g, b;
  const LinearRgb(this.r, this.g, this.b);
}

/// Terna de canales en [0,1].
typedef Rgb3 = ({double r, double g, double b});
