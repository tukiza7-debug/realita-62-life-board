/// Main menu screen — redesigned around the new logo. Per master prompt
/// section 6.2, the menu is NOT five identical pills; it centres the logo
/// and a continue-game card.
library;

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../settings/settings_repository.dart';
import 'main_menu_screen_imports.dart' as menu;

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 600;
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo lockup (vector).
                    Hero(
                      tag: 'app_logo',
                      child: SizedBox(
                        height: 96,
                        child: CustomPaint(
                          painter: menu.LogoPainter(),
                          size: const Size(96, 96),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.appTitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.menuSubtitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.tertiary,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.menuTagline,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 32),
                    _ContinueCard(),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        _MenuButton(
                          icon: Icons.play_arrow,
                          label: l10n.menuNewGame,
                          primary: true,
                          onTap: () => Navigator.pushNamed(context, '/new_game'),
                        ),
                        _MenuButton(
                          icon: Icons.school,
                          label: l10n.menuTutorial,
                          onTap: () => Navigator.pushNamed(context, '/tutorial'),
                        ),
                        _MenuButton(
                          icon: Icons.menu_book,
                          label: l10n.menuGlossary,
                          onTap: () => Navigator.pushNamed(context, '/glossary'),
                        ),
                        _MenuButton(
                          icon: Icons.settings,
                          label: l10n.menuSettings,
                          onTap: () => Navigator.pushNamed(context, '/settings'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ContinueCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        final hasSave = snap.data!.containsKey('saved_game');
        if (!hasSave) return const SizedBox.shrink();
        return Card(
          child: ListTile(
            leading: const Icon(Icons.history, color: Colors.green),
            title: Text(l10n.menuContinue),
            subtitle: Text(l10n.settingsDataSavedGame),
            onTap: () => Navigator.pushNamed(context, '/game'),
            trailing: const Icon(Icons.chevron_right),
          ),
        );
      },
    );
  }
}

class _MenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool primary;
  final VoidCallback onTap;
  const _MenuButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = primary ? const Size(180, 56) : const Size(140, 48);
    return SizedBox(
      width: size.width,
      height: size.height,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(label),
        style: primary
            ? null
            : ElevatedButton.styleFrom(
                backgroundColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                foregroundColor: Theme.of(context).colorScheme.onSurface,
              ),
      ),
    );
  }
}
