/// Public API surface of the Realita +62 Life Board engine package.
///
/// All gameplay logic lives here. The Flutter UI imports only this package
/// and never reaches into `src/` directly.
library realita_engine;

export 'src/balance_config.dart';
export 'src/board.dart';
export 'src/card_def.dart';
export 'src/card_deck.dart';
export 'src/card_resolver.dart';
export 'src/game_engine.dart';
export 'src/game_event.dart';
export 'src/game_orchestrator.dart';
export 'src/game_state.dart';
export 'src/models.dart';
export 'src/seeded_rng.dart';
