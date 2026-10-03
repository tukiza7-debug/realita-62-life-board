/// Deterministic, seedable RNG — single source of all randomness in the game.
///
/// Uses an xorshift64* algorithm so that two games seeded with the same seed
/// produce identical outcomes (verifiable in tests and 5000-game simulations).
///
/// PORTED EXACTLY from the legacy Kotlin implementation (legacy-kotlin/
/// app/src/main/java/id/realita62/lifeboard/engine/SeededRng.kt). The
/// arithmetic is identical bit-for-bit; parity tests in test/parity_test.dart
/// verify that dice sequences, deck shuffles, and full game logs reproduce
/// the Kotlin reference output for the same seed.
library;

class SeededRng {
  /// Internal 64-bit state.
  int _state;

  SeededRng(int seed)
      : _state = seed == 0
            ? 0x9E3779B97F4A7C15 // avoid degenerate all-zero state
            : seed;

  /// Next raw 64-bit value. Mirrors Kotlin's `nextLong()` exactly.
  ///
  /// Dart's `>>>` (unsigned right shift) and `*` (which wraps on 64-bit)
  /// give the same bit pattern as Kotlin's `ushr` and `Long * Long`.
  int nextLong() {
    var x = _state;
    x = x ^ (x >>> 12);
    x = x ^ ((x << 25) & 0xFFFFFFFFFFFFFFFF); // mask off bits > 64
    x = x ^ (x >>> 27);
    _state = x;
    // Multiply by 0x2545F4914F6CDD1D; Dart's int*int wraps on 64 bits on the VM.
    return (x * 0x2545F4914F6CDD1D) & 0xFFFFFFFFFFFFFFFF;
  }

  /// Uniform int in [0, upper). Mirrors Kotlin's `nextInt(upper)`.
  int nextInt(int upper) {
    if (upper <= 0) {
      throw ArgumentError('upper must be > 0, was $upper');
    }
    // (nextLong() and Long.MAX_VALUE) % upper — exactly like Kotlin.
    final masked = nextLong() & 0x7FFFFFFFFFFFFFFF; // Long.MAX_VALUE
    return (masked % upper).toInt();
  }

  /// Uniform int in [lower, upper).
  int nextIntRange(int lower, int upper) {
    if (upper <= lower) {
      throw ArgumentError('upper must be > lower');
    }
    return lower + nextInt(upper - lower);
  }

  /// Double in [0.0, 1.0).
  double nextDouble() {
    final masked = nextLong() & 0x7FFFFFFFFFFFFFFF;
    return masked.toDouble() / 9223372036854775807.0; // 2^63 - 1
  }

  /// True with probability [p] (0..1).
  bool chance(double p) => nextDouble() < p;

  /// Pick a random element from a non-empty list.
  T pick<T>(List<T> list) {
    if (list.isEmpty) {
      throw StateError('Cannot pick from empty list');
    }
    return list[nextInt(list.length)];
  }

  /// Shuffle a list in place (Fisher–Yates), deterministically.
  void shuffle<T>(List<T> list) {
    for (var i = list.length - 1; i > 0; i--) {
      final j = nextInt(i + 1);
      final tmp = list[i];
      list[i] = list[j];
      list[j] = tmp;
    }
  }

  /// Roll two six-sided dice and return the sum + individual values.
  DiceRoll rollDice() {
    final d1 = nextIntRange(1, 7);
    final d2 = nextIntRange(1, 7);
    return DiceRoll(d1, d2, d1 + d2);
  }

  /// Re-derive a child RNG for a sub-system (e.g. a card deck) so that
  /// different sub-streams do not interfere with each other.
  SeededRng fork(int salt) => SeededRng(nextLong() ^ salt);

  /// Hash a string seed (e.g. "game-2026-10-03-A") into an int.
  static SeededRng fromStringSeed(String s) {
    var h = 1125899906842597; // FNV offset basis
    for (final c in s.codeUnits) {
      h = (h ^ c) & 0xFFFFFFFFFFFFFFFF;
      h = (h * 1099511628211) & 0xFFFFFFFFFFFFFFFF;
    }
    return SeededRng(h.abs());
  }
}

class DiceRoll {
  final int die1;
  final int die2;
  final int total;
  const DiceRoll(this.die1, this.die2, this.total);

  bool get isDouble => die1 == die2;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiceRoll &&
          die1 == other.die1 &&
          die2 == other.die2 &&
          total == other.total;

  @override
  int get hashCode => Object.hash(die1, die2, total);

  @override
  String toString() => 'DiceRoll($die1,$die2=$total)';
}
