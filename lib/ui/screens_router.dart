/// Screens router (named routes for navigation).
library;

import 'package:flutter/material.dart';

import 'game_screen.dart';
import 'glossary_screen.dart';
import 'main_menu_screen.dart';
import 'new_game_screen.dart';
import 'settings_screen.dart';
import 'tutorial_screen.dart';

class ScreensRouter extends StatelessWidget {
  const ScreensRouter({super.key});

  @override
  Widget build(BuildContext context) {
    return Navigator(
      initialRoute: '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return _fade(const MainMenuScreen());
          case '/new_game':
            return _fade(const NewGameScreen());
          case '/game':
            return _fade(const GameScreen());
          case '/tutorial':
            return _fade(const TutorialScreen());
          case '/glossary':
            return _fade(const GlossaryScreen());
          case '/settings':
            return _fade(const SettingsScreen());
          default:
            return _fade(const MainMenuScreen());
        }
      },
    );
  }

  PageRoute _fade(Widget screen) {
    return PageRouteBuilder(
      pageBuilder: (context, anim, secondary) => screen,
      transitionsBuilder: (context, anim, secondary, child) {
        return FadeTransition(
          opacity: anim.drive(CurveTween(curve: Curves.easeOut)),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 220),
    );
  }
}
