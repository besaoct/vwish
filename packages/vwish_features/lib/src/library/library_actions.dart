import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vwish_data/vwish_data.dart';
import 'package:vwish_domain/vwish_domain.dart';
import 'package:vwish_ui_kit/vwish_ui_kit.dart';

import '../controllers/providers.dart';
import 'library_providers.dart';
import 'media_picker.dart';

/// Replaces the queue with [items] and starts playing. [shuffle] starts at a random item and
/// shuffles the rest, keeping the original order to restore when shuffle is turned off.
void vwishPlayItems(WidgetRef ref, List<MediaRef> items, {int startIndex = 0, bool shuffle = false}) {
  if (items.isEmpty) return;
  final queue = ref.read(queueControllerProvider.notifier);
  final start = shuffle ? math.Random().nextInt(items.length) : startIndex;
  queue.playFrom(items, startIndex: start).catchError((Object e) {
    debugPrint('[Library] playFrom failed: $e');
  });
  if (shuffle) queue.setShuffle(true);
}

String vwishErrorMessage(Object error) => switch (error) {
      MediaPickerException(:final message) => message,
      PlaylistException(:final message) => message,
      _ => 'Something went wrong. Please try again.',
    };

void showVwishError(BuildContext context, Object error) {
  if (error is! MediaPickerException && error is! PlaylistException) debugPrint('[Library] $error');
  VwishToast.show(context, vwishErrorMessage(error), kind: VwishToastKind.error, icon: Icons.error_outline_rounded);
}

void showVwishSuccess(BuildContext context, String message) {
  VwishToast.show(context, message, kind: VwishToastKind.success, icon: Icons.check_circle_rounded);
}

/// Asks for a name and creates the playlist; returns its stored name, or null when cancelled.
Future<String?> promptNewPlaylist(BuildContext context, WidgetRef ref) async {
  final library = ref.read(libraryControllerProvider.notifier);
  final name = await showVwishPrompt(
    context,
    title: 'New playlist',
    hint: 'Playlist name',
    confirmLabel: 'Create',
    prefixIcon: Icons.queue_music_rounded,
    validator: (value) => library.validatePlaylistName(value),
  );
  if (name == null) return null;
  try {
    return await library.createPlaylist(name);
  } on PlaylistException catch (e) {
    if (context.mounted) showVwishError(context, e);
    return null;
  }
}

/// Returns the new name, or null when cancelled or unchanged.
Future<String?> promptRenamePlaylist(BuildContext context, WidgetRef ref, String name) async {
  final library = ref.read(libraryControllerProvider.notifier);
  final newName = await showVwishPrompt(
    context,
    title: 'Rename playlist',
    initialValue: name,
    hint: 'Playlist name',
    confirmLabel: 'Rename',
    prefixIcon: Icons.queue_music_rounded,
    validator: (value) => library.validatePlaylistName(value, renaming: name),
  );
  if (newName == null || newName == name) return null;
  try {
    return await library.renamePlaylist(name, newName);
  } on PlaylistException catch (e) {
    if (context.mounted) showVwishError(context, e);
    return null;
  }
}

/// Asks before deleting a playlist; deleting never touches its videos.
Future<bool> confirmDeletePlaylist(BuildContext context, String name) {
  return showVwishConfirm(
    context,
    title: 'Delete playlist',
    message: '"$name" will be deleted. The videos stay on disk.',
    confirmLabel: 'Delete',
    destructive: true,
    icon: Icons.delete_outline_rounded,
  );
}

/// Adds [items] to [playlist] and reports the result as a toast.
Future<void> addToPlaylistWithFeedback(
  BuildContext context,
  WidgetRef ref,
  String playlist,
  List<MediaRef> items,
) async {
  try {
    final added = await ref.read(libraryControllerProvider.notifier).addToPlaylist(playlist, items);
    if (!context.mounted) return;
    if (added == 0) {
      VwishToast.show(
        context,
        items.length == 1 ? 'Already in $playlist' : 'These videos are already in $playlist',
        icon: Icons.info_outline_rounded,
      );
    } else {
      showVwishSuccess(
        context,
        items.length == 1 ? 'Added to $playlist' : 'Added ${added == 1 ? '1 video' : '$added videos'} to $playlist',
      );
    }
  } on PlaylistException catch (e) {
    if (context.mounted) showVwishError(context, e);
  }
}
