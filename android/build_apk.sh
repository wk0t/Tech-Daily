#!/usr/bin/env bash
# Compile l'APK sans Gradle (aapt + javac + d8 + zipalign + apksigner), version Linux de build_apk.ps1.
# Prerequisites: JDK 17 (d8 breaks with Debian's JDK 21) and the Android SDK (build-tools 34.0.0, platforms;android-34).
#   ANDROID_SDK_ROOT : default ~/android-sdk
#   JDK17_HOME       : default ~/jdk17
#   KEYSTORE_DIR     : default ~/.android-keys (outside the repo; never put the .jks in git)
set -euo pipefail
NAME="TechCyberDaily"          # nom du fichier .apk
KS_BASENAME="techcyber"     # nom du keystore
ALIAS="tcd"
DN="CN=Tech Cyber Daily"

export JAVA_HOME="${JDK17_HOME:-$HOME/jdk17}"; export PATH="$JAVA_HOME/bin:$PATH"
SDK="${ANDROID_SDK_ROOT:-$HOME/android-sdk}"
BT="$SDK/build-tools/34.0.0"
PLATFORM="$SDK/platforms/android-34/android.jar"
PROJ="$(cd "$(dirname "$0")" && pwd)"
OUT="$PROJ/build"
APK="$(dirname "$PROJ")/$NAME.apk"
KDIR="${KEYSTORE_DIR:-$HOME/.android-keys}"
KS="$KDIR/$KS_BASENAME.jks"
KPASS_FILE="$KDIR/$KS_BASENAME.pass"

rm -rf "$OUT"; mkdir -p "$OUT/obj" "$OUT/dex" "$OUT/gen" "$KDIR"; chmod 700 "$KDIR"

echo "[0/6] R.java";      "$BT/aapt" package -f -m -J "$OUT/gen" -M "$PROJ/AndroidManifest.xml" -S "$PROJ/res" -I "$PLATFORM"
echo "[1/6] javac";       find "$PROJ/src" "$OUT/gen" -name '*.java' > "$OUT/srcs.txt"
javac -encoding UTF-8 --release 8 -Xlint:-options -classpath "$PLATFORM" -d "$OUT/obj" @"$OUT/srcs.txt"
echo "[2/6] d8";          mapfile -t CLASSES < <(find "$OUT/obj" -name '*.class')
"$BT/d8" --release --lib "$PLATFORM" --min-api 24 --output "$OUT/dex" "${CLASSES[@]}"
echo "[3/6] aapt package"; "$BT/aapt" package -f -M "$PROJ/AndroidManifest.xml" -S "$PROJ/res" -A "$PROJ/assets" -I "$PLATFORM" -F "$OUT/app.unsigned.apk"
echo "[4/6] classes.dex";  (cd "$OUT/dex" && "$BT/aapt" add "$OUT/app.unsigned.apk" classes.dex >/dev/null)
echo "[5/6] zipalign";     "$BT/zipalign" -f 4 "$OUT/app.unsigned.apk" "$OUT/app.aligned.apk"
echo "[6/6] apksigner"
if [ ! -f "$KS" ]; then
  umask 077; head -c 24 /dev/urandom | base64 | tr -d '/+=' > "$KPASS_FILE"
  keytool -genkeypair -keystore "$KS" -storepass "$(cat "$KPASS_FILE")" -keypass "$(cat "$KPASS_FILE")" \
    -alias "$ALIAS" -keyalg RSA -keysize 2048 -validity 10000 -dname "$DN"
fi
KS_PASS="$(cat "$KPASS_FILE")" "$BT/apksigner" sign --ks "$KS" --ks-pass env:KS_PASS --key-pass env:KS_PASS --out "$APK" "$OUT/app.aligned.apk"

echo; echo "=== Check ==="
"$BT/apksigner" verify --print-certs "$APK" | head -3
"$BT/aapt" dump badging "$APK" | head -3
echo "APK built: $APK ($(( $(stat -c%s "$APK") / 1024 )) KB)"
