import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:vwish_features/vwish_features.dart';

String folderLocation(String path) => '/folder?path=${Uri.encodeQueryComponent(path)}';

String playlistLocation(String name) => '/playlist/${Uri.encodeComponent(name)}';

String settingsLocation(SettingsDestination destination) => '/settings/${destination.path}';

void _back(BuildContext context) => context.canPop() ? context.pop() : context.go('/');

Widget _settingsPage(BuildContext context, SettingsDestination destination) {
  void back() => _back(context);
  return switch (destination) {
    SettingsDestination.profile => VwishProfileScreen(onBack: back),
    SettingsDestination.speedTest => VwishSpeedTestScreen(onBack: back),
    SettingsDestination.streamCheck => VwishStreamCheckScreen(onBack: back, onOpenPlayer: () => context.push('/player')),
    SettingsDestination.mediaInfo => VwishMediaInfoScreen(onBack: back),
    SettingsDestination.dataUsage => VwishDataUsageScreen(onBack: back),
    SettingsDestination.storage => VwishStorageScreen(onBack: back),
    SettingsDestination.about => VwishAboutScreen(
        onBack: back,
        onOpenPrivacy: () => context.push(settingsLocation(SettingsDestination.privacy)),
        onOpenTerms: () => context.push(settingsLocation(SettingsDestination.terms)),
      ),
    SettingsDestination.privacy => VwishLegalScreen(document: LegalDocument.privacy, onBack: back),
    SettingsDestination.terms => VwishLegalScreen(document: LegalDocument.terms, onBack: back),
  };
}

/// Pages are nested under Home so Back always has somewhere to go, even after a deep link.
GoRouter createAppRouter() => GoRouter(
      initialLocation: '/',
      // Unknown locations (e.g. a file URL the OS handed over) land on Home instead of an error page.
      onException: (context, state, router) => router.go('/'),
      routes: [
        GoRoute(
          path: '/',
          name: 'home',
          builder: (context, state) => VwishHomeScreen(
            onOpenPlayer: () => context.push('/player'),
            onOpenFolder: (path) => context.push(folderLocation(path)),
            onOpenPlaylist: (name) => context.push(playlistLocation(name)),
            onOpenSettings: () => context.push('/settings'),
          ),
          routes: [
            GoRoute(
              path: 'settings',
              name: 'settings',
              builder: (context, state) => VwishSettingsScreen(
                onBack: () => _back(context),
                onNavigate: (destination) => context.push(settingsLocation(destination)),
              ),
              routes: [
                for (final destination in SettingsDestination.values)
                  GoRoute(
                    path: destination.path,
                    builder: (context, state) => _settingsPage(context, destination),
                  ),
              ],
            ),
            GoRoute(
              path: 'player',
              name: 'player',
              builder: (context, state) => VwishPlayerScreen(onBack: () => _back(context)),
            ),
            GoRoute(
              path: 'folder',
              name: 'folder',
              redirect: (context, state) => (state.uri.queryParameters['path'] ?? '').isEmpty ? '/' : null,
              builder: (context, state) {
                final path = state.uri.queryParameters['path']!;
                return VwishFolderScreen(
                  key: ValueKey(path),
                  path: path,
                  onBack: () => _back(context),
                  onOpenFolder: (child) => context.push(folderLocation(child)),
                  onJumpToFolder: (ancestor) => context.go(folderLocation(ancestor)),
                  onOpenPlayer: () => context.push('/player'),
                );
              },
            ),
            GoRoute(
              path: 'playlist/:name',
              name: 'playlist',
              builder: (context, state) {
                final name = state.pathParameters['name']!;
                return VwishPlaylistScreen(
                  key: ValueKey(name),
                  name: name,
                  onBack: () => _back(context),
                  onOpenPlayer: () => context.push('/player'),
                  onRenamed: (newName) => context.replace(playlistLocation(newName)),
                );
              },
            ),
          ],
        ),
      ],
    );
