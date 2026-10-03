package id.realita62.lifeboard.engine

import kotlin.math.absoluteValue
import kotlin.math.log10
import kotlin.math.pow

/**
 * Deterministic, seedable RNG — single source of all randomness in the game.
 * Uses an xorshift64* algorithm so that two games seeded with the same seed
 * produce identical outcomes (verifiable in tests and 1000-game simulations).
 *
 * The engine never reads Math.random() or System.currentTimeMillis() for
 * gameplay decisions — all randomness goes through this class.
 */
class SeededRng(seed: Long) {
    private var state: Long

    init {
        // Avoid the degenerate all-zero state.
        state = if (seed == 0L) 0x9E3779B97F4A7C15uL.toLong() else seed
    }

    /** Next raw 64-bit value. */
    fun nextLong(): Long {
        var x = state
        x = x xor (x ushr 12)
        x = x xor (x shl 25)
        x = x xor (x ushr 27)
        state = x
        return (x * 0x2545F4914F6CDD1DuL.toLong())
    }

    /** Uniform int in [0, upper) — Java Random-compatible but xorshift-backed. */
    fun nextInt(upper: Int): Int {
        require(upper > 0) { "upper must be > 0, was $upper" }
        return (nextLong() and Long.MAX_VALUE).rem(upper.toLong()).toInt()
    }

    /** Uniform int in [lower, upper]. */
    fun nextInt(lower: Int, upper: Int): Int {
        require(upper > lower) { "upper must be > lower" }
        return lower + nextInt(upper - lower)
    }

    /** Float in [0.0, 1.0). */
    fun nextFloat(): Float = (nextLong() and Long.MAX_VALUE).toFloat() / Long.MAX_VALUE.toFloat()

    /** True with probability `p` (0..1). */
    fun chance(p: Float): Boolean = nextFloat() < p

    /** Pick a random element from a non-empty list. */
    fun <T> pick(list: List<T>): T {
        require(list.isNotEmpty()) { "Cannot pick from empty list" }
        return list[nextInt(list.size)]
    }

    /** Shuffle a list in place deterministically. */
    fun <T> shuffle(list: MutableList<T>) {
        // Fisher–Yates
        for (i in list.size - 1 downTo 1) {
            val j = nextInt(i + 1)
            val tmp = list[i]
            list[i] = list[j]
            list[j] = tmp
        }
    }

    /** Roll two six-sided dice and return the sum + individual values (for animation). */
    fun rollDice(): DiceRoll {
        val d1 = nextInt(1, 7)
        val d2 = nextInt(1, 7)
        return DiceRoll(d1, d2, d1 + d2)
    }

    /** Re-derive a child RNG for a sub-system (e.g. a card deck) so that
     *  different sub-streams do not interfere with each other. */
    fun fork(salt: Long): SeededRng = SeededRng(nextLong() xor salt)

    companion object {
        /** Hash a string seed (e.g. "game-2026-10-03-A") into a Long. */
        fun fromStringSeed(s: String): SeededRng {
            var h: Long = 1125899906842597L // FNV offset basis
            for (c in s) {
                h = h xor c.code.toLong()
                h *= 1099511628211L
            }
            return SeededRng(h.absoluteValue)
        }
    }
}

@Serializable
data class DiceRoll(val die1: Int, val die2: Int, val total: Int) {
    val isDouble get() = die1 == die2
}

/** Tiny utility: round to a number of decimals without floating-point noise. */
fun Double.roundTo(decimals: Int): Double {
    val factor = 10.0.pow(decimals)
    return (this * factor).let { Math.round(it).toDouble() / factor }
}

fun Double.abs(): Double = if (this < 0) -this else this
