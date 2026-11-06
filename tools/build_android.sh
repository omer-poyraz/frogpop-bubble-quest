#!/bin/bash
# Builds signed release APK + AAB, debug APK, and a temporary gl_compatibility APK for the emulator.
set -e
cd "$(dirname "$0")/.."
source tools/android_env.sh
mkdir -p build/android
$GODOT --headless --path . --import >/dev/null 2>&1
$GODOT --headless --path . --export-debug "Android APK" build/android/FrogPop-debug.apk 2>&1 | grep -E "^ERROR" || true
$GODOT --headless --path . --export-release "Android APK" build/android/FrogPop-release.apk 2>&1 | grep -E "^ERROR" || true
$GODOT --headless --path . --export-release "Android AAB" build/android/FrogPop.aab 2>&1 | grep -E "^ERROR" || true
# emulator build (emulator cannot do Vulkan): temporary renderer switch, then restore
cp project.godot build/project.godot.bak
sed -i '' 's/renderer\/rendering_method="mobile"/renderer\/rendering_method="gl_compatibility"/; s/renderer\/rendering_method.mobile="mobile"/renderer\/rendering_method.mobile="gl_compatibility"/' project.godot
$GODOT --headless --path . --import >/dev/null 2>&1
$GODOT --headless --path . --export-debug "Android APK" build/android/FrogPop-emu.apk 2>&1 | grep -E "^ERROR" || true
cp build/project.godot.bak project.godot
$GODOT --headless --path . --import >/dev/null 2>&1
$ANDROID_HOME/build-tools/36.0.0/apksigner verify --print-certs build/android/FrogPop-release.apk | head -3
$JAVA_HOME/bin/jarsigner -verify build/android/FrogPop.aab | head -2
ls -la build/android
