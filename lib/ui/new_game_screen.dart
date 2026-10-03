/// New Game setup screen: 2-4 players, names, human/AI per seat.
library;

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../state/game_controller.dart';

class NewGameScreen extends StatefulWidget {
  const NewGameScreen({super.key});
  @override
  State<NewGameScreen> createState() => _NewGameScreenState();
}

class _NewGameScreenState extends State<NewGameScreen> {
  int playerCount = 2;
  int aiCount = 0;
  final names = ['Player 1', 'Player 2', 'Player 3', 'Player 4'];
  final seedController = TextEditingController();

  @override
  void dispose() {
    seedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.newGameTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.newGamePlayers,
                  style: Theme.of(context).textTheme.titleMedium),
              Wrap(
                spacing: 8,
                children: [
                  for (var n in [2, 3, 4])
                    ChoiceChip(
                      label: Text('$n'),
                      selected: playerCount == n,
                      onSelected: (sel) {
                        if (sel) {
                          setState(() {
                            playerCount = n;
                            if (aiCount > n - 1) aiCount = n - 1;
                          });
                        }
                      },
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(l10n.newGameAiOpponents,
                  style: Theme.of(context).textTheme.titleMedium),
              Wrap(
                spacing: 8,
                children: [
                  for (var n in List.generate(playerCount, (i) => i))
                    ChoiceChip(
                      label: Text('$n'),
                      selected: aiCount == n,
                      onSelected: (sel) =>
                          sel ? setState(() => aiCount = n) : null,
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(l10n.newGameNames,
                  style: Theme.of(context).textTheme.titleMedium),
              for (var i = 0; i < playerCount; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Player ${i + 1}',
                      prefixIcon: Icon(i >= playerCount - aiCount
                          ? Icons.smart_toy
                          : Icons.person),
                    ),
                    onChanged: (v) => names[i] = v,
                    controller: TextEditingController(
                        text: names[i] == 'Player ${i + 1}'
                            ? null
                            : names[i]),
                  ),
                ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _startGame,
                icon: const Icon(Icons.play_arrow),
                label: Text(l10n.newGameStart),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _startGame() async {
    final seed = DateTime.now().millisecondsSinceEpoch;
    final players = List.generate(playerCount, (i) {
      return PlayerSeed(
        id: i,
        name: names[i].isEmpty ? 'Player ${i + 1}' : names[i],
        isAI: i >= playerCount - aiCount,
      );
    });
    final prefs = await SharedPreferences.getInstance();
    final stateJson = GameController.createInitialStateJson(
      seed: seed,
      players: players,
    );
    await prefs.setString('saved_game', stateJson);
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/game');
    }
  }
}
