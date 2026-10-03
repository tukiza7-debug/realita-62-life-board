# Motion — Animation System

## 1. Iron rule

Animation is **presentation only**. The engine (`GameController.takeTurn()`)
resolves the full event list for a turn synchronously BEFORE any animation
plays. Dice value, card draw, and money change never depend on animation
timing, frame rate, or skipping.

This means: tapping anywhere on the screen during an animation
**fast-forwards** the UI to the final state, with no desync from the
engine's actual result.

## 2. Motion tokens (one file: `lib/theme/app_theme.dart`)

### Durations

| Token | Duration | Use |
|---|---|---|
| `AppMotionDurations.instant` | 0 ms | No transition (instant state change) |
| `AppMotionDurations.fast` | 120 ms | Cross-fade, micro-interaction |
| `AppMotionDurations.base` | 220 ms | Standard screen transition, card slide |
| `AppMotionDurations.slow` | 400 ms | Token hop, dice settle |
| `AppMotionDurations.emphasis` | 700 ms | Score tally count-up, podium rise |

### Curves

| Token | Curve | Use |
|---|---|---|
| `AppMotionCurves.standard` | `Curves.easeOut` | Default ease |
| `AppMotionCurves.emphasized` | `Curves.easeInOutCubicEmphasized` | Page transitions |
| `AppMotionCurves.springTokenLanding` | `Curves.elasticOut` | Token landing squash |

No inline magic numbers anywhere else. If a duration or curve is needed, it
lives in `app_theme.dart`.

## 3. AnimationDirector (v2.1 — UNVERIFIED in v2.0.0)

A future `AnimationDirector` (in `lib/motion/animation_director.dart`) will
queue engine events as a sequential list of presentation steps. Each step
knows its duration and the curve used. Tapping anywhere (or Settings →
Instant) fast-forwards the queue to the final state.

For v2.0.0, the UI renders engine events as a Game Log list (in
`lib/ui/game_screen.dart` `_LogPanel`) — the underlying invariant (animation
is presentation only) is already enforced because `takeTurn()` runs
synchronously and the log is appended AFTER the engine resolves.

## 4. Catalogue (master prompt section 8.2)

Each animation below is implemented as a Flutter built-in (`ImplicitlyAnimatedWidget`,
`TweenAnimationBuilder`, `CustomPainter` + `AnimationController`, `Transform`).
NO Lottie / Rive files — keeps the APK small and avoids external asset
licensing headaches.

| # | Animation | v2.0 status |
|---|---|---|
| 1 | Screen transitions (fade-through) | ✅ `_fade()` in `screens_router.dart` |
| 2 | Main menu logo entrance + subtle background drift | UNVERIFIED (basic logo painter; no entrance animation yet) |
| 3 | Dice tumble + settle | UNVERIFIED (no dice animation; v2.1) |
| 4 | Token hop tile-by-tile | UNVERIFIED (board painter shows positions; v2.1) |
| 5 | Turn change active-player indicator slide | ✅ HUD highlights current player via `colorScheme.primary` |
| 6 | Card reveal 3D Y-axis flip | UNVERIFIED (Game Log list shows the card text; v2.1) |
| 7 | Money count-up/down + floating delta chip | UNVERIFIED (raw number displayed; v2.1) |
| 8 | Happiness meter change + icon state change | ✅ HUD shows `H {value}` text (UNVERIFIED: animated meter) |
| 9 | Asset purchase "SOLD" stamp | UNVERIFIED (v2.1) |
| 10 | Bad Luck / KPK sting / bankruptcy colour wash | UNVERIFIED (v2.1) |
| 11 | Retirement + Results sunrise gradient + tally + podium | UNVERIFIED (results screen shows scores; v2.1) |
| 12 | Micro-interactions (button press, toggle, list item appear) | ✅ Material 3 default (ripple, animated switch) |

## 5. Motion levels (Settings → Animation)

| Level | Behaviour |
|---|---|
| Full | Everything above. Default from the system "remove animations" flag — UNVERIFIED wiring (v2.1). |
| Reduced | No large movement, parallax, shake, or loops. Short cross-fades ≤ 120 ms. Essential feedback (dice result, money change) stays visible. |
| Off | No animation; instant state changes. |

The `AppSettings.motionLevel` setting is wired through `SettingsRepository`
and persisted; the UI reads it via `Consumer<AppSettingsNotifier>` and the
`buildAppTheme` function uses it. The actual filtering of individual
animations to the motion level is UNVERIFIED in v2.0.0 (v2.1 task).

## 6. Photosensitivity safety

No animation flashes more than 3 times per second. No full-screen strobing.
The KPK sting emphasis uses a single colour wash, not a strobe. The "Bad
Luck" card reveal uses a desaturation, not a flash.

## 7. Performance

- `RepaintBoundary` around the board (master prompt section 8.4).
- Correct `shouldRepaint` on `BoardPainter` — only repaints when positions
  change, not when the theme changes.
- No per-frame allocations in painters.
- No `setState` on large trees per frame.

**UNVERIFIED** — these rules are written but not measured with
`flutter run --profile`. v2.1 task.

## 8. Leak prevention

Every `AnimationController` is disposed (master prompt section 8.1). v2.0.0
uses mostly implicit animations (`AnimatedSwitcher`, `TweenAnimationBuilder`,
`Hero`) which the framework disposes automatically. v2.1 will add a leak
test or lint check before introducing custom `AnimationController`s.
