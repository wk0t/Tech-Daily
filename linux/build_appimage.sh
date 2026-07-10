#!/usr/bin/env bash
# Construit TechCyberDaily-x86_64.AppImage. À lancer sur une machine Linux.
set -e
cd "$(dirname "$0")"

APPDIR=AppDir
rm -rf "$APPDIR"
mkdir -p "$APPDIR"

cp AppRun                    "$APPDIR/AppRun"
chmod +x                    "$APPDIR/AppRun"
cp server.py                "$APPDIR/server.py"
cp ../android/assets/index.html "$APPDIR/index.html"
cp tech-cyber-daily.desktop "$APPDIR/tech-cyber-daily.desktop"
cp tech-cyber-daily.png     "$APPDIR/tech-cyber-daily.png"

# Récupère appimagetool si absent
if [ ! -f appimagetool ]; then
  wget -q -O appimagetool \
    "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage"
  chmod +x appimagetool
fi

# --appimage-extract-and-run évite d'avoir besoin de FUSE (utile en CI)
export APPIMAGE_EXTRACT_AND_RUN=1
ARCH=x86_64 ./appimagetool "$APPDIR" TechCyberDaily-x86_64.AppImage

echo "OK -> $(pwd)/TechCyberDaily-x86_64.AppImage"
