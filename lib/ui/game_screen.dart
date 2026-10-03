/// In-game screen: HUD strip + board track + actions + dialogs.
///
/// Per master-prompt section 6.x: this screen must show, for every player,
/// the persistent HUD with cash, debt, happiness, career, route, etc.
/// Plus: education/career picker, marriage/asset/mahar/retirement dialogs,
/// card reveal overlay for Event/Luck, results dialog.
// ignore_for_file: unnecessary_cast

library;

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:realita_engine/realita_engine.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../state/game_controller.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  GameController? _controller;

  @override
  void initState() {
    super.initState();
    _loadGame();
  }

  Future<void> _loadGame() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('saved_game');
    if (saved == null) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/new_game');
      }
      return;
    }
    final c = await GameController.loadSaved(saved);
    if (!mounted) return;
    if (c == null) {
      // Corrupted save — fall back to New Game screen.
      await prefs.remove('saved_game');
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/new_game');
      return;
    }
    setState(() => _controller = c);
  }

  Future<void> _autosave() async {
    if (_controller == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_game', _controller!.serialize());
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return ChangeNotifierProvider.value(
      value: _controller!,
      child: Consumer<GameController>(
        builder: (context, controller, _) {
          return _GameBody(
            controller: controller,
            onAutosave: _autosave,
          );
        },
      ),
    );
  }
}

class _GameBody extends StatelessWidget {
  final GameController controller;
  final Future<void> Function() onAutosave;
  const _GameBody({required this.controller, required this.onAutosave});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = controller.orchestrator.state;
    final currentPlayer = state.players[state.currentPlayerIdx];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Realita +62'),
            Text(l10n.turnLabel(currentPlayer.name),
                style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.pause),
            onPressed: () => _showPauseMenu(context),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isLandscape = constraints.maxWidth > constraints.maxHeight;
            if (isLandscape) {
              return Row(
                children: [
                  Expanded(child: _BoardPanel(controller: controller)),
                  SizedBox(
                    width: 320,
                    child: _SidePanel(
                        controller: controller, onAutosave: onAutosave),
                  ),
                ],
              );
            }
            return Column(
              children: [
                _HudStrip(controller: controller),
                _BoardPanel(controller: controller),
                Expanded(
                  child: _LogPanel(controller: controller),
                ),
                _ActionBar(controller: controller, onAutosave: onAutosave),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showPauseMenu(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.play_arrow),
              title: Text(l10n.pauseResume),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.save),
              title: Text(l10n.pauseSaveQuit),
              onTap: () async {
                await onAutosave();
                if (context.mounted) {
                  Navigator.popUntil(context, (route) => route.isFirst);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: Text(l10n.pauseSettings),
              onTap: () => Navigator.pushNamed(context, '/settings'),
            ),
            ListTile(
              leading: const Icon(Icons.school),
              title: Text(l10n.pauseTutorial),
              onTap: () => Navigator.pushNamed(context, '/tutorial'),
            ),
            ListTile(
              leading: const Icon(Icons.restart_alt),
              title: Text(l10n.pauseRestart),
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('saved_game');
                if (context.mounted) {
                  Navigator.popUntil(context, (route) => route.isFirst);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _HudStrip extends StatelessWidget {
  final GameController controller;
  const _HudStrip({required this.controller});
  @override
  Widget build(BuildContext context) {
    final state = controller.orchestrator.state;
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: state.players.length,
        itemBuilder: (context, i) {
          final p = state.players[i];
          final isCurrent = i == state.currentPlayerIdx;
          return SizedBox(
            width: 160,
            child: Card(
              color: isCurrent ? Theme.of(context).colorScheme.primary : null,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(p.isAI ? Icons.smart_toy : Icons.person),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            p.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ),
                      ],
                    ),
                    Text('Rp ${p.cash.toStringAsFixed(1)}M',
                        style: Theme.of(context).textTheme.labelSmall),
                    Text('H ${p.happiness}',
                        style: Theme.of(context).textTheme.labelSmall),
                    Text(
                      p.career?.id ?? '-',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    if (p.children.isNotEmpty)
                      Text('👶 ${p.children.length}',
                          style: Theme.of(context).textTheme.labelSmall),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BoardPanel extends StatelessWidget {
  final GameController controller;
  const _BoardPanel({required this.controller});
  @override
  Widget build(BuildContext context) {
    final board = controller.orchestrator.board;
    final positions =
        controller.orchestrator.state.players.map((p) => p.position).toList();
    return SizedBox(
      height: 240,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: InteractiveViewer(
            boundaryMargin: const EdgeInsets.all(40),
            minScale: 0.6,
            maxScale: 2.5,
            child: CustomPaint(
              size: const Size(double.infinity, double.infinity),
              painter: BoardPainter(
                tiles: board,
                positions: positions,
                currentPlayerIdx:
                    controller.orchestrator.state.currentPlayerIdx,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LogPanel extends StatelessWidget {
  final GameController controller;
  const _LogPanel({required this.controller});
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final log = controller.orchestrator.state.log;
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.gameLog, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Expanded(
              child: log.isEmpty
                  ? const Center(child: Text('No events yet — roll the dice.'))
                  : ListView.builder(
                      reverse: true,
                      itemCount: log.length > 50 ? 50 : log.length,
                      itemBuilder: (context, i) {
                        final ev = log[log.length - 1 - i];
                        return Text(formatEvent(ev),
                            style: Theme.of(context).textTheme.bodyMedium);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  final GameController controller;
  final Future<void> Function() onAutosave;
  const _ActionBar({required this.controller, required this.onAutosave});
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = controller.orchestrator.state;
    final p = state.players[state.currentPlayerIdx];

    // Education pick
    if (p.education == null) {
      return Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => controller.setEducation(
                    state.currentPlayerIdx, EducationPath.college),
                child: const Text('PTN (College)'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: () => controller.setEducation(
                    state.currentPlayerIdx, EducationPath.smaSmk),
                child: const Text('SMA/SMK'),
              ),
            ),
          ],
        ),
      );
    }

    // Career pick
    if (p.career == null) {
      final options = p.education == EducationPath.college
          ? [Career.scbdEmployee, Career.pns, Career.contractor]
          : [Career.ojolDriver, Career.dailyWorker];
      return Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            for (final c in options) ...[
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ElevatedButton(
                    onPressed: () =>
                        controller.assignCareer(state.currentPlayerIdx, c),
                    child: Text(c.id),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(8),
      child: SizedBox(
        height: 56,
        child: FilledButton.icon(
          onPressed: controller.busy
              ? null
              : () async {
                  controller.takeTurn();
                  await onAutosave();
                },
          icon: const Icon(Icons.casino),
          label: Text(l10n.rollDice),
        ),
      ),
    );
  }
}

class _SidePanel extends StatelessWidget {
  final GameController controller;
  final Future<void> Function() onAutosave;
  const _SidePanel({required this.controller, required this.onAutosave});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _HudStrip(controller: controller),
        Expanded(child: _LogPanel(controller: controller)),
        _ActionBar(controller: controller, onAutosave: onAutosave),
      ],
    );
  }
}

// ----------------------- Board painter ----------------------------

class BoardPainter extends CustomPainter {
  final List<Tile> tiles;
  final List<int> positions;
  final int currentPlayerIdx;
  const BoardPainter({
    required this.tiles,
    required this.positions,
    required this.currentPlayerIdx,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rows = 6;
    final cols = 10;
    final cellW = size.width / cols;
    final cellH = size.height / rows;
    for (var i = 0; i < tiles.length && i < rows * cols; i++) {
      final row = i ~/ cols;
      final col = (row % 2 == 0) ? (i % cols) : (cols - 1 - (i % cols));
      final cx = col * cellW + cellW / 2;
      final cy = row * cellH + cellH / 2;
      final paint = Paint()..color = colorFor(tiles[i].type);
      canvas.drawCircle(Offset(cx, cy), cellW * 0.35, paint);
      // Icon-like overlay for colorblind safety
      final iconPaint = Paint()
        ..color = const Color(0xFFFFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      // Just draw a thin white inner ring for non-blank tiles
      if (tiles[i].type != TileType.blank) {
        canvas.drawCircle(Offset(cx, cy), cellW * 0.20, iconPaint);
      }
      // Player markers
      for (var p = 0; p < positions.length; p++) {
        if (positions[p] == i) {
          canvas.drawCircle(
            Offset(cx, cy + cellW * 0.05 * (p + 1)),
            cellW * 0.12,
            Paint()..color = playerColor(p),
          );
        }
      }
    }
  }

  Color colorFor(TileType t) {
    switch (t) {
      case TileType.start:
      case TileType.educationFork:
        return const Color(0xFFD4A23A);
      case TileType.payday:
        return const Color(0xFF4CAF50);
      case TileType.event_:
        return const Color(0xFFFFC107);
      case TileType.luck:
        return const Color(0xFF2196F3);
      case TileType.marriage:
        return const Color(0xFFE91E63);
      case TileType.child:
        return const Color(0xFF9C27B0);
      case TileType.assetShop:
        return const Color(0xFF795548);
      case TileType.maharPartaiGate:
        return const Color(0xFF607D8B);
      case TileType.tender:
        return const Color(0xFFFF9800);
      case TileType.retirementFork:
        return const Color(0xFFB31919);
      case TileType.blank:
        return const Color(0xFFE0E0E0);
    }
  }

  Color playerColor(int i) {
    const colors = [
      Color(0xFFE55353),
      Color(0xFF2196F3),
      Color(0xFF4CAF50),
      Color(0xFFFFC107),
    ];
    return colors[i % colors.length];
  }

  @override
  bool shouldRepaint(covariant BoardPainter oldDelegate) =>
      positions != oldDelegate.positions ||
      currentPlayerIdx != oldDelegate.currentPlayerIdx;
}

// ----------------------- Event formatting ----------------------------

String formatEvent(GameEvent e) {
  return switch (e) {
    Payday() => 'Payday +${(e as Payday).amount}M (TAPERA ${(e).tapera}M)',
    PaydaySkipped() => 'Payday skipped (layoff)',
    LivingCost() => 'Living cost -${(e as LivingCost).amount}M',
    UktInterest() => 'UKT +${(e as UktInterest).amount}M',
    KprInterest() => 'KPR +${(e as KprInterest).amount}M',
    PinjolInterest() => 'Pinjol +${(e as PinjolInterest).amount}M',
    SideBusinessPaid() => 'Side business +${(e as SideBusinessPaid).amount}M',
    SideBusinessEnded() => 'Side business ended',
    FuelSubsidyEnded() => 'Fuel subsidy recovered',
    LandlordRentEnded() => 'Rent stabilized',
    CheapRentEnded() => 'Cheap rent ended',
    StoleProjectFunds() =>
      'Stole funds +${(e as StoleProjectFunds).amount}M (heat ${(e).newHeat})',
    KpkStingMiss() => 'KPK missed',
    KpkStingCaught() => 'KPK OTT! cash -${(e as KpkStingCaught).cashLost}M',
    Married() => 'Married (${(e as Married).lavish ? "Lavish" : "Modest"})',
    ChildBorn() => 'Child born',
    SchoolFunded() =>
      'School ${(e as SchoolFunded).private ? "private" : "public"} -${(e).cost}M',
    EnteredPoliticianPath() =>
      'Entered politics (${(e as EnteredPoliticianPath).corrupt ? "Corrupt" : "Clean"})',
    PoliticianEntryFailed() => 'Politics entry failed',
    NepotismPerk() => 'Nepotism +${(e as NepotismPerk).gain}M',
    Retired() => 'Retired (${(e as Retired).choice.id}) score ${(e).score}M',
    CardDrawn() => 'Card ${(e as CardDrawn).cardId}',
    CashDelta() =>
      '${(e as CashDelta).amount >= 0 ? "+" : ""}${(e).amount}M — ${(e).reason}',
    HappinessDelta() =>
      'H ${(e as HappinessDelta).delta >= 0 ? "+" : ""}${(e).delta} — ${(e).reason}',
    SkipTurn() => 'Skip ${(e as SkipTurn).laps} turn(s)',
    Moved() => '${(e as Moved).fromTile}→${(e).toTile}',
    LapCompleted() => 'Lap ${(e as LapCompleted).laps}',
    AssetPurchased() => 'Bought ${(e as AssetPurchased).name}',
    TokenAwarded() => 'Token: ${(e as TokenAwarded).token}',
    LoanTaken() =>
      'Loan ${(e as LoanTaken).principal}M @${((e).interestPct * 100).toInt()}%',
    DebtFlagged() => '⚠ ${(e as DebtFlagged).flag}',
    EmptyEvent() => '',
  };
}
