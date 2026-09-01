import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vwish_data/vwish_data.dart';
import 'package:vwish_domain/vwish_domain.dart';
import 'package:vwish_engine/vwish_engine.dart';
import 'player_controller.dart';
import 'queue_controller.dart';

final playbackEngineProvider = Provider<PlaybackEngine>((ref) {
  throw UnimplementedError('playbackEngineProvider must be overridden with a concrete engine');
});

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  throw UnimplementedError('sessionRepositoryProvider must be initialized');
});

final libraryRepositoryProvider = Provider<LibraryRepository>((ref) {
  throw UnimplementedError('libraryRepositoryProvider must be initialized');
});

final playerControllerProvider =
    StateNotifierProvider<PlayerController, PlayerState>((ref) {
  final engine = ref.watch(playbackEngineProvider);
  final sessionRepo = ref.watch(sessionRepositoryProvider);
  final libraryRepo = ref.watch(libraryRepositoryProvider);
  return PlayerController(engine, sessionRepo, libraryRepo, ref);
});

final queueControllerProvider =
    StateNotifierProvider<QueueController, QueueState>((ref) {
  final playerCtrl = ref.watch(playerControllerProvider.notifier);
  final libraryRepo = ref.watch(libraryRepositoryProvider);
  return QueueController(playerCtrl, libraryRepo);
});
