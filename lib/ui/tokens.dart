import 'package:material_ui/material_ui.dart';

const kFontFamily = 'Inter';

/// Burmese glyphs aren't in Inter, so text falls through to the bundled
/// Noto face instead of whatever the OS picks (which differs per platform).
const kFontFallback = ['NotoSansMyanmar'];

abstract final class LtRadius {
  static const sm = 10.0;
  static const md = 14.0;
  static const lg = 16.0;
  static const xl = 20.0;
}

@immutable
class LtColors extends ThemeExtension<LtColors> {
  const LtColors({
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.line,
    required this.ink,
    required this.muted,
    required this.faint,
    required this.brand,
    required this.onBrand,
    required this.brandSoft,
    required this.brandText,
    required this.rec,
    required this.recSoft,
    required this.warn,
    required this.warnSoft,
    required this.star,
    required this.ok,
    required this.shadow,
  });

  final Color bg;
  final Color surface;
  final Color surface2;
  final Color line;
  final Color ink;
  final Color muted;
  final Color faint;
  final Color brand;
  final Color onBrand;
  final Color brandSoft;
  final Color brandText;
  final Color rec;
  final Color recSoft;
  final Color warn;
  final Color warnSoft;
  final Color star;
  final Color ok;
  final List<BoxShadow> shadow;

  static const light = LtColors(
    bg: Color(0xFFF5F6F5),
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFEEF1F0),
    line: Color(0xFFE2E7E7),
    ink: Color(0xFF101819),
    muted: Color(0xFF5C6A6C),
    faint: Color(0xFF8C999B),
    brand: Color(0xFF0B7480),
    onBrand: Color(0xFFFFFFFF),
    brandSoft: Color(0xFFE0F0F1),
    brandText: Color(0xFF09626C),
    rec: Color(0xFFE5484D),
    recSoft: Color(0xFFFDE8E8),
    warn: Color(0xFFA15C07),
    warnSoft: Color(0xFFFDF1DC),
    star: Color(0xFFE0A100),
    ok: Color(0xFF2BA36B),
    shadow: [
      BoxShadow(color: Color(0x0F101819), blurRadius: 2, offset: Offset(0, 1)),
      BoxShadow(color: Color(0x1F101819), blurRadius: 16, spreadRadius: -6, offset: Offset(0, 4)),
    ],
  );

  static const dark = LtColors(
    bg: Color(0xFF0D1314),
    surface: Color(0xFF162021),
    surface2: Color(0xFF1D292A),
    line: Color(0xFF253233),
    ink: Color(0xFFE7EEEE),
    muted: Color(0xFF9AABAD),
    faint: Color(0xFF6B7C7E),
    brand: Color(0xFF2FB1BE),
    onBrand: Color(0xFF04282C),
    brandSoft: Color(0xFF13383C),
    brandText: Color(0xFF6FD3DD),
    rec: Color(0xFFFF6369),
    recSoft: Color(0xFF3B1D1F),
    warn: Color(0xFFF2B35B),
    warnSoft: Color(0xFF352816),
    star: Color(0xFFF2C14E),
    ok: Color(0xFF3CC384),
    shadow: [
      BoxShadow(color: Color(0x4D000000), blurRadius: 2, offset: Offset(0, 1)),
      BoxShadow(color: Color(0x99000000), blurRadius: 20, spreadRadius: -8, offset: Offset(0, 6)),
    ],
  );

  @override
  LtColors copyWith() => this;

  @override
  LtColors lerp(LtColors? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return LtColors(
      bg: l(bg, other.bg),
      surface: l(surface, other.surface),
      surface2: l(surface2, other.surface2),
      line: l(line, other.line),
      ink: l(ink, other.ink),
      muted: l(muted, other.muted),
      faint: l(faint, other.faint),
      brand: l(brand, other.brand),
      onBrand: l(onBrand, other.onBrand),
      brandSoft: l(brandSoft, other.brandSoft),
      brandText: l(brandText, other.brandText),
      rec: l(rec, other.rec),
      recSoft: l(recSoft, other.recSoft),
      warn: l(warn, other.warn),
      warnSoft: l(warnSoft, other.warnSoft),
      star: l(star, other.star),
      ok: l(ok, other.ok),
      shadow: t < 0.5 ? shadow : other.shadow,
    );
  }
}

abstract final class LtText {
  static const title = TextStyle(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.7, height: 1.2);
  static const heading = TextStyle(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.45, height: 1.25);
  static const translation = TextStyle(fontSize: 17, fontWeight: FontWeight.w500, height: 1.55);
  static const original = TextStyle(fontSize: 13.5, height: 1.45);
  static const body = TextStyle(fontSize: 14.5, fontWeight: FontWeight.w500, height: 1.35);
  static const rowTitle = TextStyle(fontSize: 15, fontWeight: FontWeight.w600, height: 1.3);
  static const meta = TextStyle(fontSize: 12.5, height: 1.35);
  static const chip = TextStyle(fontSize: 12, fontWeight: FontWeight.w500, height: 1.2);
  static const label = TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.7, height: 1.2);
  static const tabular = [FontFeature.tabularFigures()];
}

extension LtContext on BuildContext {
  LtColors get lt => Theme.of(this).extension<LtColors>()!;

  /// Sidebar layout instead of the bottom bar.
  bool get isWide => MediaQuery.sizeOf(this).width >= 720;
}
