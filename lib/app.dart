import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/routing/route_names.dart';
import 'core/services/theme_music_controller.dart';
import 'core/theme/app_theme.dart';

class GradVisApp extends StatefulWidget {
  final GoRouter router;

  const GradVisApp({super.key, required this.router});

  @override
  State<GradVisApp> createState() => _GradVisAppState();
}

class _GradVisAppState extends State<GradVisApp> {
  final ThemeMusicController _themeMusic = ThemeMusicController();

  @override
  void initState() {
    super.initState();
    widget.router.routerDelegate.addListener(_handleRouteChange);
    _themeMusic.startLoop();
  }

  @override
  void dispose() {
    widget.router.routerDelegate.removeListener(_handleRouteChange);
    _themeMusic.dispose();
    super.dispose();
  }

  void _handleRouteChange() {
    final path = widget.router.routerDelegate.currentConfiguration.uri.path;
    if (path == RouteNames.home) {
      _themeMusic.fadeOutAndStop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'GradVis',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: widget.router,
    );
  }
}
