# Monetization setup / Para kazanma kurulumu

The game never fakes ads or purchases. `AdsManager` / `PurchaseManager` autoloads look for native plugins with `Engine.has_singleton(...)`:

| Service | Android singleton | iOS singleton |
|---|---|---|
| AdMob | `PoingGodotAdMob` | `PoingGodotAdMob` |
| Billing | `GodotGooglePlayBilling` | `InAppStore` |

Without a plugin: ads -> "unavailable" (continue / rewarded buttons hidden), store -> "Store unavailable on this device", PRO buttons disabled. Debug builds on desktop may show a full-screen **TEST AD** (clearly labelled, 3 s) - never in release builds.

## Steps (Android)
1. Install the AdMob plugin for Godot 4 (e.g. Poing Studios *godot-admob-android* v4 AAR) and the Google Play Billing plugin (*godot-google-play-billing*) into `android/plugins/` and enable them in the Android export preset (gradle build is already used for the AAB preset).
2. Create your AdMob app + ad units. Put the real ids into `data/config/monetization.json` (`admob.android.*`, currently Google's public **TEST** ids). Set `tag_for_child_directed_treatment` / `tag_for_under_age_of_consent` as required (the game is 13+, not child-directed).
3. Add `permissions/internet` and `access_network_state` in the preset (they are off in the plugin-less build) and the AdMob app id `<meta-data>` required by the plugin.
4. In Google Play Console create products `frogpop_pro_monthly`, `frogpop_pro_yearly` (subscriptions), `frogpop_pro_lifetime`, `frogpop_remove_ads` (one-time) with the same ids. The plugin callbacks must call `PurchaseManager.grant(product_id)` after the store confirmed the purchase.
5. Add Google's UMP consent flow for EEA/UK (plugin provides it) before the first ad request.
6. Update `docs/DATA_SAFETY.md` answers to match the final SDK set before submitting.

## Ad rules implemented (`data/config/monetization.json` -> `ad_rules`)
- Interstitial only on game-over / menu transitions, never during play (`AdsManager.in_gameplay`).
- Not in the first 3 games, every 3rd finished game, >= 150 s apart, max 6 per session, never for PRO / ad-free.
- Rewarded ads are always optional (continue once per run) and refused while a game is running.

## PRO
Monthly / yearly / lifetime + Remove Ads. Benefits are shown on the PRO screen before purchase: no ads, Galaxy Frog costume, pick any world (incl. Galaxy & Crystal), +50 % coins. Entitlement is stored locally; **no server-side verification** exists and none is claimed. `PurchaseManager.revoke_subscription()` exists for plugin expiry callbacks.

## Product ids
`frogpop_pro_monthly`, `frogpop_pro_yearly`, `frogpop_pro_lifetime`, `frogpop_remove_ads`
