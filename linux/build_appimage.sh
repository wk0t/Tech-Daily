#!/usr/bin/env bash
# Builds TechCyberDaily-x86_64.AppImage. Run on a Linux machine.
set -e
cd "$(dirname "$0")"

APPDIR=AppDir
rm -rf "$APPDIR"
mkdir -p "$APPDIR"

cp AppRun                    "$APPDIR/AppRun"
chmod +x                    "$APPDIR/AppRun"
cp server.py                "$APPDIR/server.py"
cp ../android/assets/index.html "$APPDIR/index.html"
cp -r ../android/assets/fonts "$APPDIR/fonts"
cp tech-cyber-daily.desktop "$APPDIR/tech-cyber-daily.desktop"
cp tech-cyber-daily.png     "$APPDIR/tech-cyber-daily.png"

# Download appimagetool if missing
if [ ! -f appimagetool ]; then
  wget -q -O appimagetool \
    "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage"
  chmod +x appimagetool
fi

# --appimage-extract-and-run avoids needing FUSE (useful in CI)
export APPIMAGE_EXTRACT_AND_RUN=1
ARCH=x86_64 ./appimagetool "$APPDIR" TechCyberDaily-x86_64.AppImage

echo "OK -> $(pwd)/TechCyberDaily-x86_64.AppImage"
