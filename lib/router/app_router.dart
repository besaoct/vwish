import 'package:go_router/go_router.dart';
import 'package:vwish_features/vwish_features.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'player',
      builder: (context, state) => const VwishPlayerScreen(),
    ),
  ],
);
