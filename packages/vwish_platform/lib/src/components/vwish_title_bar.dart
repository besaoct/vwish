import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

class VwishTitleBar extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final bool isAlwaysOnTop;
  final VoidCallback? onToggleAlwaysOnTop;

  const VwishTitleBar({
    super.key,
    this.title = 'Vwish Player',
    this.trailing,
    this.isAlwaysOnTop = false,
    this.onToggleAlwaysOnTop,
  });

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || (!Platform.isMacOS && !Platform.isWindows && !Platform.isLinux)) {
      return const SizedBox.shrink();
    }

    final isMac = Platform.isMacOS;

    return Container(
      height: 38,
      padding: EdgeInsets.only(left: isMac ? 78 : 12, right: 12),
      decoration: const BoxDecoration(
        color: Color(0xD907080C),
        border: Border(
          bottom: BorderSide(color: Color(0xFF1E2230), width: 1),
        ),
      ),
      child: Stack(
        children: [
          // Drag Window Region
          const Positioned.fill(
            child: DragToMoveArea(
              child: SizedBox.expand(),
            ),
          ),

          // Content
          Row(
            children: [
              if (!isMac)
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Icon(Icons.play_circle_fill_rounded, color: Color(0xFF6366F1), size: 18),
                ),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFA0A6BC),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              if (onToggleAlwaysOnTop != null)
                IconButton(
                  icon: Icon(
                    isAlwaysOnTop ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                    size: 16,
                    color: isAlwaysOnTop ? const Color(0xFF6366F1) : const Color(0xFF6B728D),
                  ),
                  splashRadius: 14,
                  onPressed: onToggleAlwaysOnTop,
                  tooltip: isAlwaysOnTop ? 'Unpin window (T)' : 'Pin window on top (T)',
                ),
              if (trailing != null) trailing!,
              if (Platform.isWindows || Platform.isLinux) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.minimize_rounded, size: 16, color: Color(0xFFA0A6BC)),
                  splashRadius: 14,
                  onPressed: () => windowManager.minimize(),
                ),
                IconButton(
                  icon: const Icon(Icons.crop_square_rounded, size: 16, color: Color(0xFFA0A6BC)),
                  splashRadius: 14,
                  onPressed: () async {
                    if (await windowManager.isMaximized()) {
                      windowManager.unmaximize();
                    } else {
                      windowManager.maximize();
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 16, color: Color(0xFFA0A6BC)),
                  splashRadius: 14,
                  onPressed: () => windowManager.close(),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
