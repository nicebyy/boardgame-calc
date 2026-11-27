import 'package:material_ui/material_ui.dart';

import '../theme/boardgame_theme.dart';

class BoardgameCalcAvatar extends StatelessWidget {
  const BoardgameCalcAvatar({
    super.key,
    required this.nickname,
    this.avatarUrl,
    this.avatarColor,
    this.size = 40,
    this.isOnline = true,
    this.showOnlineDot = false,
    this.ringColor,
  });

  final String nickname;
  final String? avatarUrl;
  final String? avatarColor;
  final double size;
  final bool isOnline;
  final bool showOnlineDot;
  final Color? ringColor;

  @override
  Widget build(BuildContext context) {
    final theme = getPlayerTheme(avatarColor);
    final initial = getPlayerInitial(nickname);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.color,
              border: ringColor != null
                  ? Border.all(color: ringColor!, width: 2)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: (avatarUrl != null && avatarUrl!.isNotEmpty)
                ? Image.network(
                    avatarUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Center(
                      child: Text(
                        initial,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: size * 0.4,
                        ),
                      ),
                    ),
                  )
                : Center(
                    child: Text(
                      initial,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: size * 0.4,
                      ),
                    ),
                  ),
          ),
          if (showOnlineDot && !isOnline)
            Positioned(
              right: -1,
              bottom: -1,
              child: Container(
                width: size * 0.3,
                height: size * 0.3,
                decoration: BoxDecoration(
                  color: const Color(0xFF64748B),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
