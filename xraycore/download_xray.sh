#!/bin/bash
# Downloads the prebuilt AndroidLibXrayLite aar and unpacks it into this module.
# Usage: ./download_xray.sh [version]   (default: v26.8.20)
set -e

VERSION="${1:-v26.8.20}"
URL="https://github.com/2dust/AndroidLibXrayLite/releases/download/${VERSION}/libv2ray.aar"
DIR="$(cd "$(dirname "$0")" && pwd)"

cd "$DIR"
echo "Downloading $URL"
curl -L -o libv2ray.aar "$URL"

rm -rf _tmp libs src/main/jniLibs src/main/assets
mkdir -p _tmp libs src/main/jniLibs src/main/assets
unzip -q libv2ray.aar -d _tmp
cp _tmp/classes.jar libs/libv2ray-classes.jar
cp -r _tmp/jni/* src/main/jniLibs/
cp _tmp/assets/geoip.dat _tmp/assets/geosite.dat src/main/assets/
cp _tmp/proguard.txt ./proguard-libv2ray.txt
rm -rf _tmp libv2ray.aar

echo "Done. Xray-core ${VERSION} unpacked into $DIR"
