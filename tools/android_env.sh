# source this: Android build environment (secrets stay outside the repo)
export JAVA_HOME=/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home
export ANDROID_HOME=$HOME/Library/Android/sdk ANDROID_SDK_ROOT=$HOME/Library/Android/sdk
KEYS=$HOME/Documents/frogpop-keys
export GODOT_ANDROID_KEYSTORE_DEBUG_PATH=$KEYS/frogpop-debug.keystore GODOT_ANDROID_KEYSTORE_DEBUG_USER=frogpopdebug
export GODOT_ANDROID_KEYSTORE_DEBUG_PASSWORD=$(cat $KEYS/debug_password.txt)
export GODOT_ANDROID_KEYSTORE_RELEASE_PATH=$KEYS/frogpop-release.keystore GODOT_ANDROID_KEYSTORE_RELEASE_USER=frogpop
export GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD=$(cat $KEYS/release_password.txt)
export GODOT=/Applications/Godot.app/Contents/MacOS/Godot
