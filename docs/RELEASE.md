# Release guide

## Tests first
```bash
godot --headless --path . res://tests/test_runner.tscn   # must end with "TESTS: N passed, 0 failed"
```

## Android (signed AAB + APK)
Keystore lives outside the repo: `~/Documents/frogpop-keys/frogpop-release.keystore` (alias `frogpop`, CN=Poyraz Yazilim, C=TR), passwords in chmod-600 text files next to it. **Back the keystore up** - Play App Signing upload key loss is painful.
```bash
tools/build_android.sh     # -> build/android/FrogPop.aab, FrogPop-release.apk, FrogPop-debug.apk (+ temporary gl_compat emulator APK)
```
Verify: `apksigner verify --print-certs build/android/FrogPop-release.apk` and `jarsigner -verify build/android/FrogPop.aab`.
Preset notes: AAB = gradle build (min SDK 24, target 35, arm64-v8a); APK = template build (no gradle). `android/build/` is the unpacked `android_source.zip` of the 4.7.2 templates (`android/.build_version` = `4.7.2.stable`); it is git-ignored.
Upload `FrogPop.aab` to Play Console (internal testing first). Store texts: `docs/STORE_LISTING.md`, graphics: `store/` and `assets/branding/` (512 icon, 1024x500 feature graphic, 5 screenshots per language).

## Emulator smoke test
`tools/adb.sh` targets `emulator-5594` (AVD `frogpop_pixel`). The emulator has no Vulkan, so `tools/build_android.sh` also makes `FrogPop-emu.apk` with the gl_compatibility renderer (project.godot is backed up and restored automatically).

## iOS
`godot --headless --path . --export-release "iOS" build/ios/FrogPop.ipa` generates `build/ios/FrogPop.xcodeproj` (preset has `export_project_only=true`). Replace `application/app_store_team_id="XXXXXXXXXX"` with your Apple Team ID, open the project in Xcode, set signing, archive. An unsigned device build was verified with
`xcodebuild -project build/ios/FrogPop.xcodeproj -scheme FrogPop -sdk iphoneos -configuration Release CODE_SIGNING_ALLOWED=NO build`.
Add the IAP / AdMob native plugins for iOS first (see MONETIZATION.md). App icon set: `assets/branding/ios_appicon/`.

## GitHub + Pages (to be done by the owner)
1. `gh auth login`, then `gh repo create omer-poyraz/frogpop-bubble-quest --public --source=. --push` (name must match the Pages URL).
2. Settings > Pages > Source: **GitHub Actions** (workflow `.github/workflows/pages.yml` deploys `site/`).
3. Result: https://omer-poyraz.github.io/frogpop-bubble-quest/privacy-policy/ - use this URL in Play Console / App Store Connect. Verify before claiming it is live.
4. Custom domain later: rename `site/CNAME.example` to `site/CNAME` (one line: your domain) and set DNS; all links in `site/` are relative so both work.

## Videos
`store/video/` holds the trailer / shorts metadata. Rendered MP4s are git-ignored (large); regenerate with `tools/make_videos.sh`.
