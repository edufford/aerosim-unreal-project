#!/bin/bash

UNREAL_PROJECT="$AEROSIM_UNREAL_PROJECT_ROOT/AerosimUE5.uproject"
RHI="vulkan"
PACKAGE_CONFIG="Shipping"

CESIUM_SOURCE_PATH="Plugins/CesiumForUnreal"
CESIUM_VERSION="v2.13.2"

OPTS=`getopt -o h --long config: -n 'parse-options' -- "$@"`
eval set -- "$OPTS"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --config)
            PACKAGE_CONFIG="$2"
            shift 2
            ;;
        *)
            shift
            ;;
    esac
done

# Set build folder
BUILD_FOLDER="$AEROSIM_UNREAL_PROJECT_ROOT/package-$PACKAGE_CONFIG/"

# Display the current config
echo "Package config: $PACKAGE_CONFIG"

# Run setup if needed
if [ ! -d ${CESIUM_SOURCE_PATH} ]; then
    echo "Downloading CesiumForUnreal $CESIUM_VERSION..."
    pushd Plugins > /dev/null
    curl --retry 5 --retry-max-time 120 -L -o CesiumPluginForUnreal.zip https://github.com/CesiumGS/cesium-unreal/releases/download/${CESIUM_VERSION}/CesiumForUnreal-53-${CESIUM_VERSION}.zip
    unzip -qq CesiumPluginForUnreal.zip
    rm -f CesiumPluginForUnreal.zip
    popd > /dev/null
fi

# Run Unreal Automation Tool (UAT) with the specified parameters
"$AEROSIM_UNREAL_ENGINE_ROOT/Engine/Build/BatchFiles/RunUAT.sh" \
    BuildCookRun \
    -project="$UNREAL_PROJECT" \
    -platform="Linux" \
    -clientconfig="$PACKAGE_CONFIG" \
    -cook \
    -stage \
    -archive \
    -package \
    -build \
    -archivedirectory="$BUILD_FOLDER" \
    -prereqs \
    -TargetPlatform="Linux" \
    -utf8output