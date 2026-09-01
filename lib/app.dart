import 'package:flutter/material.dart';
import 'package:vwish_ui_kit/vwish_ui_kit.dart';
import 'router/app_router.dart';

class VwishApp extends StatelessWidget {
  const VwishApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Vwish Player',
      debugShowCheckedModeBanner: false,
      theme: VwishTheme.darkTheme,
      routerConfig: appRouter,
    );
  }
}
