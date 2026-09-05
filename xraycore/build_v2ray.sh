#!/bin/bash
# Builds the pure-Java v2ray core (../../v2ray, Maven multi-module) and copies
# the shaded fat jar into this module's libs/.
# Usage: ./build_v2ray.sh
set -e

DIR="$(cd "$(dirname "$0")" && pwd)"
SRC="$DIR/../../v2ray"

# javac 21+ compiles enums to the $values() pattern which crashes D8/R8;
# build with JDK 11 when available for maximum Android compatibility.
JDK11="/opt/homebrew/Cellar/openjdk@11/11.0.30/libexec/openjdk.jdk/Contents/Home"
if [ -d "$JDK11" ]; then
    export JAVA_HOME="$JDK11"
fi

cd "$SRC"
mvn -q clean package -DskipTests

mkdir -p "$DIR/libs"
cp v2ray-app/target/v2ray-app-1.0.0-SNAPSHOT.jar "$DIR/libs/v2ray-java.jar"

# Android/Jetifier cannot consume multi-release jar entries (BouncyCastle ships
# META-INF/versions/21 classes) or signature files; strip them.
python3 - "$DIR/libs/v2ray-java.jar" <<'EOF'
import zipfile, shutil, sys
src = sys.argv[1]; dst = src + '.clean'
zin = zipfile.ZipFile(src)
with zipfile.ZipFile(dst, 'w', zipfile.ZIP_DEFLATED) as zout:
    for item in zin.infolist():
        n = item.filename
        if n.startswith('META-INF/versions/'):
            continue
        if n.startswith('META-INF/') and (n.endswith('.SF') or n.endswith('.RSA') or n.endswith('.DSA') or n.endswith('.EC')):
            continue
        # The app already ships slf4j-api 1.7.25 (duplicate class conflict);
        # v2ray-java only uses the basic Logger API which is 1.7-compatible.
        # logback is desktop-only logging; on Android slf4j degrades to NOP.
        if n.startswith('org/slf4j/') or n.startswith('ch/qos/logback/'):
            continue
        zout.writestr(item, zin.read(n))
zin.close()
shutil.move(dst, src)
EOF

echo "Done. v2ray-java fat jar copied into $DIR/libs"

# The Gradle build needs a newer R8 than AGP 7.4 bundles (D8 NPEs on JDK21+
# enum classes). Gradle's JVM cannot reach dl.google.com from some networks,
# so fetch it here with curl and keep it out of git.
R8_JAR="$DIR/../../gradle/r8-8.3.37.jar"
if [ ! -f "$R8_JAR" ]; then
    curl -L -o "$R8_JAR" "https://dl.google.com/dl/android/maven2/com/android/tools/r8/8.3.37/r8-8.3.37.jar"
fi
