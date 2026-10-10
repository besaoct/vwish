// OWNER: CORE-09
//
// `CompositeCommand` (ARCH §7.1, domain.md §6.1): applies its children in sequence as one atomic
// command (one history entry). Each child runs on the normalized result of the previous one; if
// any child is refused the whole command is refused with that rejection and nothing changes.
// Limits and validation run once, on the final result. Apply-to-all, Cut (copy + delete), Freeze
// and the AI caption commands are built from it.

part of '../edit_command.dart';

/// Several commands applied atomically as one.
final class CompositeCommand extends EditCommand {
  /// Creates a composite labelled [label] running [commands] in order.
  CompositeCommand(this.label, List<EditCommand> commands) : commands = List.unmodifiable(commands);

  @override
  final String label;

  /// The children, in order.
  final List<EditCommand> commands;

  @override
  void _apply(_Draft d) {
    for (final c in commands) {
      final child = _Draft(d.snapshot(), d.ctx);
      c._apply(child);
      d.absorb(child, child.finish());
    }
  }

  @override
  String toString() => 'CompositeCommand($label, $commands)';
}
