#!/bin/sh


out=$(pwd)
src=$(pwd)
APP="Besprited"
ARCH="$(uname -m)"

chmod +x besprited

mkdir -p Besprited/usr/bin

mv ../../desktop/besprited.desktop Besprited/
cp ../../desktop/icons/hicolor/256x256/apps/besprited.png Besprited/besprited.png

mv *.so* Besprited/usr/lib

# Create AppImage with lib4bin and Sharun
(
export ARCH="$(uname -m)" # Just to be double sure
cd Besprited
wget "https://raw.githubusercontent.com/VHSgunzo/sharun/refs/heads/main/lib4bin" -O ./lib4bin
chmod +x ./lib4bin
xvfb-run -a -- ./lib4bin -p -v -e -k -w \
  ../besprited \
  /usr/lib/libpthread.so* \
  /usr/lib/librt.so* \
  /usr/lib/libstdc++.so* 
ln ./sharun ./AppRun 
./sharun -g
)

# Maybe the data folder is being read during initial run
# This lets the run complete with expected original locations and then
# copies it over afterwards using the below command
mv "$out"/data "$out"/Besprited/bin

wget "https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-$ARCH.AppImage" -O appimagetool
chmod +x ./appimagetool
./appimagetool --comp zstd \
	--mksquashfs-opt -Xcompression-level --mksquashfs-opt 22 \
	-n "$out"/Besprited "$out"/"$APP"-anylinux-"$ARCH".AppImage
