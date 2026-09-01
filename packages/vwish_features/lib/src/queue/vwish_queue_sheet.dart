import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vwish_domain/vwish_domain.dart';
import 'package:vwish_platform/vwish_platform.dart';
import 'package:vwish_ui_kit/vwish_ui_kit.dart';
import '../controllers/providers.dart';

class VwishQueueSheet extends ConsumerWidget {
  final VoidCallback onClose;

  const VwishQueueSheet({super.key, required this.onClose});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(queueControllerProvider);
    final queueCtrl = ref.read(queueControllerProvider.notifier);

    return Container(
      width: 380,
      margin: const EdgeInsets.only(bottom: 64, right: 16),
      child: VwishGlassCard(
        padding: EdgeInsets.zero,
        backgroundColor: VwishColors.surfaceElevated.withValues(alpha: 0.96),
        borderColor: VwishColors.borderBright,
        borderRadius: 14,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: VwishColors.border)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.queue_music_rounded, color: VwishColors.primaryLight, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Now Playing Queue (${queue.items.length})',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  // Shuffle Button
                  IconButton(
                    icon: Icon(
                      Icons.shuffle_rounded,
                      size: 18,
                      color: queue.isShuffled ? VwishColors.cyan : VwishColors.textMuted,
                    ),
                    splashRadius: 14,
                    onPressed: () => queueCtrl.setShuffle(!queue.isShuffled),
                    tooltip: 'Shuffle',
                  ),
                  // Repeat Button
                  IconButton(
                    icon: Icon(
                      queue.repeatMode == RepeatMode.one
                          ? Icons.repeat_one_rounded
                          : Icons.repeat_rounded,
                      size: 18,
                      color: queue.repeatMode != RepeatMode.off
                          ? VwishColors.cyan
                          : VwishColors.textMuted,
                    ),
                    splashRadius: 14,
                    onPressed: () => queueCtrl.cycleRepeatMode(),
                    tooltip: 'Repeat (${queue.repeatMode.name})',
                  ),
                  // Close Button
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18, color: VwishColors.textSecondary),
                    splashRadius: 14,
                    onPressed: onClose,
                  ),
                ],
              ),
            ),

            // Queue List (Reorderable)
            Expanded(
              child: queue.items.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.playlist_remove_rounded, size: 36, color: VwishColors.textMuted),
                          const SizedBox(height: 8),
                          const Text('Queue is empty', style: TextStyle(color: VwishColors.textSecondary, fontSize: 13)),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.add_rounded, size: 16),
                            label: const Text('Add Media'),
                            onPressed: () async {
                              final paths = await PlatformBridge.pickVideoFiles();
                              if (paths.isNotEmpty) {
                                final refs = paths
                                    .map((p) => MediaRef(
                                          id: p,
                                          title: p.split(RegExp(r'[/\\]')).last,
                                          pathOrUri: p,
                                        ))
                                    .toList();
                                queueCtrl.addToQueue(refs);
                              }
                            },
                          ),
                        ],
                      ),
                    )
                  : ReorderableListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      itemCount: queue.items.length,
                      // ignore: deprecated_member_use
                      onReorder: (oldIndex, newIndex) {
                        if (oldIndex < newIndex) {
                          newIndex -= 1;
                        }
                        queueCtrl.move(oldIndex, newIndex);
                      },
                      itemBuilder: (context, index) {
                        final item = queue.items[index];
                        final isCurrent = index == queue.currentIndex;

                        return Container(
                          key: ValueKey(item.id + index.toString()),
                          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? VwishColors.primary.withValues(alpha: 0.15)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isCurrent
                                  ? VwishColors.primary.withValues(alpha: 0.4)
                                  : Colors.transparent,
                            ),
                          ),
                          child: ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                            leading: isCurrent
                                ? const Icon(Icons.play_circle_fill_rounded, color: VwishColors.cyan, size: 18)
                                : Text(
                                    '${index + 1}',
                                    style: const TextStyle(fontSize: 12, color: VwishColors.textMuted),
                                  ),
                            title: Text(
                              item.title,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                                color: isCurrent ? Colors.white : VwishColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: item.duration > Duration.zero
                                ? Text(
                                    _formatDuration(item.duration),
                                    style: const TextStyle(fontSize: 11, color: VwishColors.textMuted),
                                  )
                                : null,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline_rounded, size: 16, color: VwishColors.textMuted),
                                  splashRadius: 12,
                                  onPressed: () => queueCtrl.remove(index),
                                  tooltip: 'Remove',
                                ),
                                ReorderableDragStartListener(
                                  index: index,
                                  child: const Icon(Icons.drag_handle_rounded, size: 18, color: VwishColors.textMuted),
                                ),
                              ],
                            ),
                            onTap: () => queueCtrl.jumpTo(index),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds.remainder(60);
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
