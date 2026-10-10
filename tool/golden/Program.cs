using System.Text.Json;
using System.Text.Json.Nodes;
using Matiz.Core.Colors;
using Matiz.Core.Export;
using Matiz.Core.Formatting;
using Matiz.Core.Generation;

// Tabla dorada de paridad Android ↔ desktop. Valores generados con Matiz.Core (C#).
var root = new JsonObject();

// 1) System.Random(1234): primeras salidas (Next(1000) y NextDouble()).
var rnd = new Random(1234);
var nexts = new JsonArray();
for (var i = 0; i < 10; i++) nexts.Add(rnd.Next(1000));
var doubles = new JsonArray();
for (var i = 0; i < 10; i++) doubles.Add(rnd.NextDouble());
root["random1234"] = new JsonObject { ["next1000"] = nexts, ["nextDouble"] = doubles };

// 2) Colores: conversiones, escala, armonías, tints/shades, neutros, gris equivalente.
var colorRnd = new Random(42);
var colors = new JsonArray();
var samples = new List<Argb>
{
    Argb.FromRgb(82, 70, 188), Argb.FromRgb(250, 204, 21), Argb.FromRgb(0, 0, 0), Argb.FromRgb(255, 255, 255),
    Argb.FromRgb(128, 128, 128), Argb.FromRgb(255, 0, 0), Argb.FromRgb(0, 255, 0), Argb.FromRgb(0, 0, 255),
    Argb.FromRgb(1, 2, 3), Argb.FromRgb(254, 253, 252),
};
while (samples.Count < 2000) samples.Add(Argb.FromUInt32(0xFF000000u | (uint)colorRnd.Next(0, 1 << 24)));

static JsonArray Hexes(IEnumerable<GeneratedColor> g) => new(g.Select(x => (JsonNode)x.Color.ToHex()).ToArray());

foreach (var c in samples)
{
    var o = new JsonObject
    {
        ["hex"] = c.ToHex(),
        ["hsl"] = ColorFormats.Hsl(c),
        ["hsv"] = ColorFormats.Hsv(c),
        ["cmyk"] = ColorFormats.Cmyk(c),
        ["oklch"] = ColorFormats.Oklch(c),
        ["gray"] = ColorMath.GrayEquivalent(c).ToHex(),
        ["grayMix25"] = ColorMath.MixToGray(c, 0.25).ToHex(),
        ["grayMix50"] = ColorMath.MixToGray(c, 0.50).ToHex(),
        ["grayMix57"] = ColorMath.MixToGray(c, 0.57).ToHex(),
        ["grayMix100"] = ColorMath.MixToGray(c, 1.0).ToHex(),
        ["scale500"] = Hexes(DesignScale.Generate(c, ScaleAnchorMode.Fixed500)),
        ["scaleAuto"] = Hexes(DesignScale.Generate(c, ScaleAnchorMode.Automatic)),
        ["tintsShades"] = Hexes(PaletteGenerator.TintsAndShades(c)),
        ["neutrals"] = Hexes(PaletteGenerator.Neutrals(c)),
    };
    var harm = new JsonObject();
    foreach (var k in Enum.GetValues<HarmonyKind>())
    {
        harm[k.ToString()] = Hexes(PaletteGenerator.Harmony(c, k, ScaleAnchorMode.Fixed500, true));
        harm[k + "Raw"] = Hexes(PaletteGenerator.Harmony(c, k, ScaleAnchorMode.Fixed500, false));
    }
    o["harmony"] = harm;
    colors.Add(o);
}
root["colors"] = colors;

// 3) Puntos libres desde un estado continuo.
var st = new ColorState(246.1, 0.63, 0.74);
root["freePoints"] = Hexes(PaletteGenerator.FreePoints(st,
    [(120, 0, null), (180, -0.3, null), (-45, 0.2, null), (30, 0.1, -0.2), (200, 0.5, 0.3)], true));

// 4) Extracción de colores sobre imágenes sintéticas deterministas (BGRA).
var images = new JsonArray();
foreach (var (w, h, seed) in new[] { (64, 48, 1), (300, 200, 2), (37, 129, 3) })
{
    var r = new Random(seed);
    var px = new byte[w * h * 4];
    // Bloques de color con ruido: varios grupos para que k-means tenga estructura.
    var palette = Enumerable.Range(0, 7).Select(_ => (B: (byte)r.Next(256), G: (byte)r.Next(256), R: (byte)r.Next(256))).ToArray();
    for (var y = 0; y < h; y++)
    for (var x = 0; x < w; x++)
    {
        var p = palette[(x * 7 / w + y * 3 / h) % palette.Length];
        var o = (y * w + x) * 4;
        px[o] = (byte)Math.Clamp(p.B + r.Next(-12, 13), 0, 255);
        px[o + 1] = (byte)Math.Clamp(p.G + r.Next(-12, 13), 0, 255);
        px[o + 2] = (byte)Math.Clamp(p.R + r.Next(-12, 13), 0, 255);
        px[o + 3] = (byte)(r.Next(20) == 0 ? 0 : 255);
    }
    var res = new JsonObject();
    foreach (var count in new[] { 1, 6, 9, 64 })
        res[count.ToString()] = new JsonArray(DominantColors.Extract(px, w, h, w * 4, count).Select(a => (JsonNode)a.ToHex()).ToArray());
    images.Add(new JsonObject { ["w"] = w, ["h"] = h, ["bgra"] = Convert.ToBase64String(px), ["result"] = res });
}
root["extraction"] = images;

// 5) Exportación de código con nombres variados.
var model = new PaletteExportModel("Mi Paleta Bonita", [
    new("Primary", Argb.FromRgb(82, 70, 188)), new("Secondary", Argb.FromRgb(255, 138, 0)),
    new("Árbol Ñandú", Argb.FromRgb(1, 2, 3)), new(null, Argb.FromRgb(4, 5, 6)), new("primary", Argb.FromRgb(7, 8, 9)),
    new("UIColor", new Argb(128, 10, 20, 30)), new("3d shadow", Argb.FromRgb(11, 12, 13)), new("primaryDark", Argb.FromRgb(14, 15, 16)),
]);
var export = new JsonObject();
foreach (var f in PaletteFormatters.All) export[f.Id] = f.Format(model, FormatOptions.Default);
root["export"] = export;

var outPath = Path.GetFullPath(Path.Combine(AppContext.BaseDirectory, "../../../../../packages/matiz_core/test/fixtures/golden.json"));
Directory.CreateDirectory(Path.GetDirectoryName(outPath)!);
File.WriteAllText(outPath, root.ToJsonString(new JsonSerializerOptions { WriteIndented = false }));
Console.WriteLine($"OK → {outPath}");
