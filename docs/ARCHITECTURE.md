# Architecture map (spec names -> code)

| Spec system | Implementation |
|---|---|
| GameManager / GameStateManager / UIManager | `scripts/core/game_manager.gd` (flow, run config), `core/main.gd` (screens, fade, toasts), `GameCore.State` (INTRO / PLAYING / WAVE_CLEAR / LOST / ENDED) |
| BubbleChainManager / BubbleMatchSystem / PathFollower | `scripts/gameplay/bubble_chain_manager.gd`, `bubble_match_system.gd` (arc-length `s` per ball, `PathData.pos_at(s)` = follower) |
| BubbleSpawner / BubbleProjectile | `Difficulty.make_sequence` (chain contents), `GameCore.projectiles` + `GameView` sprites |
| PathGenerator | `scripts/gameplay/path_generator.gd` + `path_data.gd` (parametric routes, validation) |
| ScoreManager / ComboManager | `score_manager.gd`, streak in `game_core.gd` |
| PowerUpManager | `power_up_manager.gd` + `GameCore.use_power` |
| FrogController / FrogAnimationController | `scripts/frog/frog.gd` (layered node tree + AnimationPlayer, eye tracking) |
| EffectManager / ParticlePool | `scripts/effects/fx_layer.gd` (fixed pool, struct-of-arrays), `floating_text.gd` |
| AudioManager | `scripts/audio/audio_manager.gd` |
| ThemeManager | `scripts/world/theme_manager.gd`, `theme_background.gd`, `data/themes/*.json` |
| ProgressionManager / DailyRewardManager / AchievementManager | `scripts/progression/progression_manager.gd`, `data/progression/*.json`, `data/missions/*.json` |
| SaveManager / SettingsManager / LocalizationManager | `scripts/save/`, `scripts/core/` (autoloads), `localization/strings.csv` |
| AdsManager / PurchaseManager | `scripts/ads/`, `scripts/purchases/`, config `data/config/monetization.json` |

Rules: simulation (`scripts/gameplay/*`) is pure `RefCounted` code with a fixed 1/120 s step and signals; rendering reads state, never writes it. Visual-only smoothing (insert animation, squash) lives in `GameView`.
