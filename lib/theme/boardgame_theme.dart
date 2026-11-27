import 'package:material_ui/material_ui.dart';

/// 원본 `pickban_smulator` 보드게임 계산기의 기본 Warm Walnut & Parchment Gold 단일 테마 토큰.
class BoardgameColors {
  BoardgameColors._();

  // Outer parchment / tabletop canvas
  static const Color canvasBg = Color(0xFFF4EBE1);
  static const Color canvasSurface = Color(0xFFFDFAF5);
  static const Color canvasSurfaceAlt = Color(0xFFFFFCF7);
  static const Color canvasChipBg = Color(0xFFE2CEB5);
  static const Color canvasBorder = Color(0xFFC4A685);
  static const Color canvasSubtleBorder = Color(0xFFE8D7C4);

  // Light wood-board tokens (BottomMe panel / thin wood tray)
  static const Color lightWoodTop = Color(0xFFF6EAD7);
  static const Color lightWoodMid = Color(0xFFEDE0CB);
  static const Color lightWoodEdge = Color(0xFFE5D2B5);
  static const Color lightWoodBorder = Color(0xFFC29B68);
  static const Color lightWoodDivider = Color(0x47A8804E);
  static const Color lightWoodChipBg = Color(0xE6FAF2E6);

  // Parchment text & walnut accents
  static const Color inkPrimary = Color(0xFF2C180D);
  static const Color inkSecondary = Color(0xFF5A3822);
  static const Color inkMuted = Color(0xFF6E462A);
  static const Color inkPlaceholder = Color(0xFF9E7D60);
  static const Color walnutPrimary = Color(0xFF8A5327);
  static const Color walnutHover = Color(0xFF72421C);

  // Dark walnut surfaces (Center tools, modals, drawer, header badges)
  static const Color walnutDeep = Color(0xFF140B06);
  static const Color walnutDarkest = Color(0xFF180D07);
  static const Color walnutPanel = Color(0xFF1A0E08);
  static const Color walnutCard = Color(0xFF24130A);
  static const Color walnutSurface = Color(0xFF2B160C);
  static const Color walnutElevated = Color(0xFF3A1F12);
  static const Color walnutSoft = Color(0xFF3D2011);
  static const Color walnutHeader = Color(0xFF3E2723);
  static const Color walnutBorder = Color(0xFF522B17);
  static const Color walnutMutedBorder = Color(0xFF8D5B4C);

  // Gold & parchment accents on dark walnut
  static const Color gold = Color(0xFFC5A059);
  static const Color goldBright = Color(0xFFD4AF37);
  static const Color goldLight = Color(0xFFF3E5AB);
  static const Color creamText = Color(0xFFF5E6CB);
  static const Color creamMuted = Color(0xFFD6B78D);
  static const Color creamSubtle = Color(0xFFB8956E);
  static const Color creamWarmWhite = Color(0xFFFFF7EE);

  // Semantic accents
  static const Color emeraldBg = Color(0xFF1E4835);
  static const Color emeraldText = Color(0xFFD8F3DC);
  static const Color emeraldBorder = Color(0xFF3B8764);
  static const Color emeraldBright = Color(0xFF10B981);

  static const Color crimsonBg = Color(0xFF6B2222);
  static const Color crimsonText = Color(0xFFFFCCD5);
  static const Color crimsonBorder = Color(0xFFA83232);
  static const Color crimsonBright = Color(0xFFEF4444);

  static const Color amberScoreText = Color(0xFF855307);
  static const Color amberBadgeBg = Color(0xFF5C3E10);
  static const Color amberBadgeText = Color(0xFFFDE047);
  static const Color amberBright = Color(0xFFF59E0B);
}

class PlayerThemeColor {
  const PlayerThemeColor({
    required this.id,
    required this.name,
    required this.hex,
    required this.color,
    required this.cardBg,
    required this.cardBorder,
    required this.innerBoxBg,
    required this.innerBoxBorder,
  });

  final String id;
  final String name;
  final String hex;
  final Color color;
  final Color cardBg;
  final Color cardBorder;
  final Color innerBoxBg;
  final Color innerBoxBorder;
}

const List<PlayerThemeColor> playerThemePalette = [
  PlayerThemeColor(
    id: 'blue',
    name: '블루',
    hex: '#3b82f6',
    color: Color(0xFF3B82F6),
    cardBg: Color(0xFFEEF5FF),
    cardBorder: Color(0xFF93C5FD),
    innerBoxBg: Color(0xE6FFFFFF),
    innerBoxBorder: Color(0xFFBFDBFE),
  ),
  PlayerThemeColor(
    id: 'red',
    name: '레드',
    hex: '#ef4444',
    color: Color(0xFFEF4444),
    cardBg: Color(0xFFFEF1F2),
    cardBorder: Color(0xFFFCA5A5),
    innerBoxBg: Color(0xE6FFFFFF),
    innerBoxBorder: Color(0xFFFECACA),
  ),
  PlayerThemeColor(
    id: 'green',
    name: '그린',
    hex: '#10b981',
    color: Color(0xFF10B981),
    cardBg: Color(0xFFEEFAF2),
    cardBorder: Color(0xFF86EFAC),
    innerBoxBg: Color(0xE6FFFFFF),
    innerBoxBorder: Color(0xFFBBF7D0),
  ),
  PlayerThemeColor(
    id: 'amber',
    name: '골드/앰버',
    hex: '#f59e0b',
    color: Color(0xFFF59E0B),
    cardBg: Color(0xFFFEF8EA),
    cardBorder: Color(0xFFFCD34D),
    innerBoxBg: Color(0xE6FFFFFF),
    innerBoxBorder: Color(0xFFFDE68A),
  ),
  PlayerThemeColor(
    id: 'purple',
    name: '퍼플',
    hex: '#8b5cf6',
    color: Color(0xFF8B5CF6),
    cardBg: Color(0xFFF4F0FE),
    cardBorder: Color(0xFFC4B5FD),
    innerBoxBg: Color(0xE6FFFFFF),
    innerBoxBorder: Color(0xFFDDD6FE),
  ),
  PlayerThemeColor(
    id: 'pink',
    name: '핑크',
    hex: '#ec4899',
    color: Color(0xFFEC4899),
    cardBg: Color(0xFFFDF0F7),
    cardBorder: Color(0xFFF9A8D4),
    innerBoxBg: Color(0xE6FFFFFF),
    innerBoxBorder: Color(0xFFFBCFE8),
  ),
  PlayerThemeColor(
    id: 'cyan',
    name: '시안',
    hex: '#06b6d4',
    color: Color(0xFF06B6D4),
    cardBg: Color(0xFFEAF9FC),
    cardBorder: Color(0xFF67E8F9),
    innerBoxBg: Color(0xE6FFFFFF),
    innerBoxBorder: Color(0xFFA5F3FC),
  ),
  PlayerThemeColor(
    id: 'orange',
    name: '오렌지',
    hex: '#f97316',
    color: Color(0xFFF97316),
    cardBg: Color(0xFFFFF3E8),
    cardBorder: Color(0xFFFDBA74),
    innerBoxBg: Color(0xE6FFFFFF),
    innerBoxBorder: Color(0xFFFED7AA),
  ),
];

Color parseHexColor(String? hex, {Color fallback = const Color(0xFF3B82F6)}) {
  if (hex == null || hex.isEmpty) return fallback;
  final clean = hex.trim().replaceFirst('#', '');
  if (clean.length == 6) {
    final parsed = int.tryParse('FF$clean', radix: 16);
    if (parsed != null) return Color(parsed);
  }
  return fallback;
}

PlayerThemeColor getPlayerTheme(String? colorHex) {
  if (colorHex == null || colorHex.trim().isEmpty) {
    return playerThemePalette.first;
  }
  final lower = colorHex.trim().toLowerCase();
  for (final theme in playerThemePalette) {
    if (theme.hex.toLowerCase() == lower) {
      return theme;
    }
  }
  final parsed = parseHexColor(colorHex);
  return PlayerThemeColor(
    id: 'custom',
    name: '사용자 지정',
    hex: colorHex,
    color: parsed,
    cardBg: parsed.withValues(alpha: 0.09),
    cardBorder: parsed.withValues(alpha: 0.4),
    innerBoxBg: const Color(0xE6FFFFFF),
    innerBoxBorder: parsed.withValues(alpha: 0.27),
  );
}

String getPlayerInitial(String? nickname) {
  if (nickname == null) return '?';
  final clean = nickname.trim();
  if (clean.isEmpty) return '?';
  return clean.substring(0, 1).toUpperCase();
}

ThemeData buildBoardgameTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: BoardgameColors.canvasBg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: BoardgameColors.walnutPrimary,
      surface: BoardgameColors.canvasSurface,
      primary: BoardgameColors.walnutPrimary,
      secondary: BoardgameColors.goldBright,
      error: BoardgameColors.crimsonBright,
    ),
    fontFamilyFallback: const [
      'Pretendard',
      'Noto Sans KR',
      'Malgun Gothic',
      'Apple SD Gothic Neo',
      'sans-serif',
    ],
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: BoardgameColors.canvasSurfaceAlt,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: BoardgameColors.canvasBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: BoardgameColors.canvasBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: BoardgameColors.walnutPrimary, width: 1.5),
      ),
    ),
  );
}
