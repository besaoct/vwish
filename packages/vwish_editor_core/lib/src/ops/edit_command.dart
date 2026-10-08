// OWNER: CORE-09
//
// Placeholder (D-33). CORE-09 replaces the body of this library with the command framework of
// ARCH §7.1. Commands are self-dispatching: every `EditCommand` subclass implements its own
// `applyTo`/`previewOn` inside its group's `part` file below, so command tickets never edit this
// file (BUILD_PLAN §2). The part list is fixed.

part 'commands/composite.dart';
part 'commands/clip_commands.dart';
part 'commands/ripple.dart';
part 'commands/clipboard_commands.dart';
part 'commands/speed_commands.dart';
part 'commands/property_commands.dart';
part 'commands/keyframe_commands.dart';
part 'commands/text_commands.dart';
part 'commands/subtitle_commands.dart';
part 'commands/caption_commands.dart';
part 'commands/transition_commands.dart';
part 'commands/track_commands.dart';
part 'commands/marker_commands.dart';
part 'commands/project_commands.dart';

/// An editing command (ARCH §7.1). Sealed: every command lives in one of this library's parts.
sealed class EditCommand {
  const EditCommand();

  /// History label ("Split", "Move clip", …).
  String get label;
}
