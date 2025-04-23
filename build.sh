#!/bin/bash

# This script builds the Unreal project for the AeroSim simulator

# -----------------------------------------------------------------------

BUILD_SCRIPT="$(basename "$0")"

UNREAL_ARGS=""
UPROJECT="$AEROSIM_UNREAL_PROJECT_ROOT/AerosimUE5.uproject"
RHI="vulkan"

CESIUM_SOURCE_PATH="Plugins/CesiumForUnreal"
CESIUM_VERSION="v2.13.2"

# Set default target to build
TARGET="build"

for i in "$@"; do
    case $i in
        launch)
            TARGET="launch"
            ;;
        game)
            TARGET="game"
            ;;
        clean)
            TARGET="clean"
            ;;
        IDS=*)
            IDS="${i#*=}"
            shift
            ;;
        help)
            echo
            echo "Usage: $BUILD_SCRIPT [target] [IDS=\"0,1\"]"
            echo
            echo "Targets:"
            echo "   (default)    Build the Unreal project."
            echo "   launch       Launch the Unreal project in the Editor."
            echo "   game         Launch the Unreal project in stand-alone game mode."
            echo "   clean        Remove the temporary and build files."
            echo "   help         Show this help and quit."
            echo "IDS=\"{comma-separated list of renderer IDs for launching multiple renderer instances}\""
            echo
            exit 1            
            ;;
        *)
            # Pass extra arguments to Unreal
            UNREAL_ARGS="$UNREAL_ARGS $i"
    esac
    shift
done

if [ "$IDS" = "" ]; then
    # Set default renderer IDS to single instance = "0"
    IDS="0"
fi

# IDS_LIST replaces commas with spaces to process them in a loop
IDS_LIST=$(echo "$IDS" | tr ',' ' ')

# Check if AEROSIM_UNREAL_ENGINE_ROOT env var is set
if [ -z "$AEROSIM_UNREAL_ENGINE_ROOT" ]; then
    echo "ERROR: Please set the AEROSIM_UNREAL_ENGINE_ROOT environment variable to the path of your Unreal Engine installation."
    pause_and_exit 1
else
    echo "AEROSIM_UNREAL_ENGINE_ROOT is set to $AEROSIM_UNREAL_ENGINE_ROOT"
fi


# Function to pause and wait for user input
pause_and_exit() {
    local exit_code=$1
    echo
    read -n1 -r -p "Press any key to exit..." key
    echo
    exit $exit_code
}

# Function to check command status and pause on error
check_and_pause() {
    if [ $? -ne 0 ]; then
        echo "Error: Command failed!"
        pause_and_exit 1
    fi
}

# Run setup if needed
if [ ! -d ${CESIUM_SOURCE_PATH} ]; then
    echo "Downloading CesiumForUnreal $CESIUM_VERSION..."
    pushd Plugins > /dev/null
    curl --retry 5 --retry-max-time 120 -L -o CesiumPluginForUnreal.zip https://github.com/CesiumGS/cesium-unreal/releases/download/${CESIUM_VERSION}/CesiumForUnreal-53-${CESIUM_VERSION}.zip
    check_and_pause
    unzip -qq CesiumPluginForUnreal.zip
    check_and_pause
    rm -f CesiumPluginForUnreal.zip
    popd > /dev/null
fi

BUILD_CMD="$AEROSIM_UNREAL_ENGINE_ROOT/Engine/Build/BatchFiles/Linux/Build.sh AerosimUE5Editor Linux Development $UPROJECT"

# Function to find an available terminal emulator
find_terminal_emulator() {
    # List of common terminal emulators to try
    terminals=("gnome-terminal" "konsole" "xfce4-terminal" "xterm")
    
    # First check if x-terminal-emulator exists and what it points to
    if command -v "x-terminal-emulator" >/dev/null 2>&1; then
        # Try to determine what x-terminal-emulator points to
        real_terminal=$(readlink -f $(which x-terminal-emulator) 2>/dev/null)
        if [ -n "$real_terminal" ]; then
            base_name=$(basename "$real_terminal")
            # Check if it's one of our known terminals
            for term in "${terminals[@]}"; do
                if [[ "$base_name" == "$term"* ]]; then
                    echo "$term"
                    return 0
                fi
            done
            # If it's terminator, prefer gnome-terminal if available
            if [[ "$base_name" == "terminator"* ]]; then
                if command -v "gnome-terminal" >/dev/null 2>&1; then
                    echo "gnome-terminal"
                    return 0
                fi
            fi
            # Otherwise, return the actual terminal name for special handling
            echo "$base_name"
            return 0
        fi
        # If we couldn't determine what it points to, just use x-terminal-emulator
        echo "x-terminal-emulator"
        return 0
    fi
    
    # Try each terminal until one is found
    for term in "${terminals[@]}"; do
        if command -v "$term" >/dev/null 2>&1; then
            echo "$term"
            return 0
        fi
    done
    
    return 1
}

# Function to launch a terminal with the given command
launch_terminal() {
    local cmd="$1"
    local instance_id="$2"
    local terminal
    local escaped_cmd
    
    # Ensure critical environment variables are preserved
    local env_vars=""
    if [ -n "$AEROSIM_CESIUM_TOKEN" ]; then
        env_vars="AEROSIM_CESIUM_TOKEN='$AEROSIM_CESIUM_TOKEN' "
    fi
    
    # Add other important environment variables here if needed
    if [ -n "$AEROSIM_UNREAL_ENGINE_ROOT" ]; then
        env_vars+="AEROSIM_UNREAL_ENGINE_ROOT='$AEROSIM_UNREAL_ENGINE_ROOT' "
    fi
    
    # Modify command to include a pause after execution and preserve environment variables
    # This ensures the terminal stays open to show errors
    modified_cmd="${env_vars}$cmd; exit_code=\$?; echo ''; if [ \$exit_code -ne 0 ]; then echo 'Command failed with exit code \$exit_code. Press Enter to close...'; else echo 'Command completed successfully. Press Enter to close...'; fi; read -p ''"
    
    # Escape the command for shell interpretation
    escaped_cmd=$(printf "%q " "$modified_cmd")
    
    terminal=$(find_terminal_emulator)
    
    if [ -n "$terminal" ]; then
        echo "Using terminal: $terminal"
        case "$terminal" in
            "gnome-terminal")
                # gnome-terminal handles quoting differently
                "$terminal" --title="AeroSim Unreal Instance $instance_id" -- bash -c "$modified_cmd" &
                ;;
            "konsole")
                # konsole needs explicit escaping
                "$terminal" --new-tab --title="AeroSim Unreal Instance $instance_id" -e bash -c "$escaped_cmd" &
                ;;
            "xfce4-terminal")
                # xfce4-terminal similar to konsole
                "$terminal" --title="AeroSim Unreal Instance $instance_id" -x bash -c "$escaped_cmd" &
                ;;
            "terminator")
                # terminator is similar to gnome-terminal
                "$terminal" --title="AeroSim Unreal Instance $instance_id" -e "$modified_cmd" &
                ;;
            "x-terminal-emulator")
                # If we couldn't determine the actual terminal, try the most compatible approach
                "$terminal" -e bash -c "$modified_cmd" &
                ;;
            *)
                # Default fallback for xterm and others
                "$terminal" -T "AeroSim Unreal Instance $instance_id" -e bash -c "$escaped_cmd" &
                ;;
        esac
        # Small sleep to ensure terminals don't conflict with each other on startup
        sleep 0.5
    else
        echo "Warning: No suitable terminal emulator found. Running command directly..."
        # Run in background with output redirected to file
        eval "${env_vars}$cmd" > "unreal_instance_${instance_id}.log" 2>&1 &
        echo "Command running in background. Output redirected to unreal_instance_${instance_id}.log"
    fi
}

case "$TARGET" in
    build)
        echo "Building the Unreal project..."
        $BUILD_CMD
        check_and_pause
        ;;
    launch)
        echo "Launching the project in the Unreal Editor..."
        $BUILD_CMD
        check_and_pause
        for i in $IDS_LIST; do
            echo "Launching instance with ID $i..."
            cmd="$AEROSIM_UNREAL_ENGINE_ROOT/Engine/Binaries/Linux/UnrealEditor $UPROJECT -$RHI $UNREAL_ARGS -InstanceID=$i"
            echo "$cmd"
            launch_terminal "$cmd" "$i"
            # Terminal launched in background with pause mechanism for errors
        done
        ;;
    game)
        echo "Launching the project in the Unreal Editor's stand-alone game mode..."
        $BUILD_CMD
        check_and_pause
        for i in $IDS_LIST; do
            echo "Launching instance with ID $i..."
            cmd="$AEROSIM_UNREAL_ENGINE_ROOT/Engine/Binaries/Linux/UnrealEditor $UPROJECT -$RHI $UNREAL_ARGS -game -InstanceID=$i"
            echo "$cmd"
            launch_terminal "$cmd" "$i"
            # Terminal launched in background with pause mechanism for errors
        done
        ;;
    clean)
        echo "Cleaning build files..."
        rm -rf Binaries Intermediate Plugins/aerosim-unreal-plugin/Binaries Plugins/aerosim-unreal-plugin/Intermediate Saved DerivedDataCache
        check_and_pause
        pause_and_exit 0
        ;;
    *)
        echo "Unknown target: $TARGET"
        echo "Run '$BUILD_SCRIPT help' for usage."
        pause_and_exit 1
        ;;
esac
