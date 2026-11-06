# Blockers / things that need the owner

| # | Item | Status | What is needed |
|---|---|---|---|
| 1 | Real AdMob ads | Layer done, plugin not bundled | Install the AdMob Godot plugin, create AdMob app + ad units, replace TEST ids in `data/config/monetization.json` (docs/MONETIZATION.md) |
| 2 | Real in-app purchases | Layer done, plugin not bundled | Install billing plugin, create 4 products in Play Console / App Store Connect with the listed ids |
| 3 | iOS signing / IPA | Xcode project exported, unsigned device build OK | Apple Developer account + Team ID (`application/app_store_team_id` currently `XXXXXXXXXX` placeholder) |
| 4 | GitHub repo + Pages | Files ready, NOT published (by instruction) | `gh auth login`, create repo `frogpop-bubble-quest`, enable Pages (Actions) - see docs/RELEASE.md |
| 5 | YouTube upload | Videos + metadata ready in `store/video/`, NOT uploaded (by instruction) | Owner uploads |
| 6 | Play Console assets | Icon 512, feature graphic, 5 screenshots TR/EN, texts ready | Owner creates the store listing; Data-safety form from `docs/DATA_SAFETY.md` |
| 7 | Keystore backup | Release keystore in `~/Documents/frogpop-keys/` | Back it up (not in repo) |
| 8 | Physical device test | Tested on Android emulator (gl_compat build) | Test the Vulkan (mobile renderer) build on a real device |
| 9 | Native speech / Gemini / Flow | Not used | Videos use game footage + synthesised music; no AI-generated footage |
