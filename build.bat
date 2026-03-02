@echo off
@setlocal enabledelayedexpansion

@REM This script builds the Unreal project for the AeroSim simulator

@REM -----------------------------------------------------------------------

set BUILD_SCRIPT=%0
set ARGS=%*
set UNREAL_ARGS=
set UPROJECT=%AEROSIM_UNREAL_PROJECT_ROOT%\AerosimUE5.uproject
set RHI=d3d12

set CESIUM_SOURCE_PATH=Plugins\CesiumForUnreal

@REM Set default target to build
if "!ARGS!" == "" (
    set TARGET="build"
    goto :BUILD
)

@REM -----------------------------------------------------------------------
:ARGPARSE

if /i "%~1" == "launch" (
    set TARGET="launch"
) else if /i "%~1" == "game" (
    set TARGET="game"
) else if /i "%~1" == "clean" (
    set TARGET="clean"
) else if /i "%~1" == "IDS" (
    set IDS=%~2
    shift
) else if /i "%~1" == "help" (
    goto :HELP
) else (
    @REM Pass extra arguments to Unreal
    set UNREAL_ARGS=!UNREAL_ARGS! %~1
)
shift
if not "%~1" == "" goto :ARGPARSE

if "!IDS!" == "" (
    @REM Set default renderer IDS to single instance = "0"
    set IDS="0"
)

@REM IDS_LIST removes quotes from IDS to process them in a loop
set IDS_LIST=%IDS:"=%
echo Parsed IDS_LIST: !IDS_LIST!

goto :BUILD

@REM -----------------------------------------------------------------------
:HELP

echo.
echo Usage: %BUILD_SCRIPT% [target] [IDS=^"0,1^"]
    echo.
    echo Targets:
    echo    (default)    Build the Unreal project.
    echo    launch       Launch the Unreal project in the Editor.
    echo    game         Launch the Unreal project in stand-alone game mode.
    echo    clean        Remove the temporary and build files.
    echo    help         Show this help and quit.
    echo IDS=^"{comma-separated list of renderer IDs for launching multiple renderer instances}^"
    goto :EOF

@REM -----------------------------------------------------------------------
:BUILD

@REM Check if AEROSIM_UNREAL_ENGINE_ROOT env var is set
if not defined AEROSIM_UNREAL_ENGINE_ROOT (
    echo ERROR: Please set the AEROSIM_UNREAL_ENGINE_ROOT environment variable to the path of your Unreal Engine installation.
    goto :EOF
) else (
    echo AEROSIM_UNREAL_ENGINE_ROOT is set to %AEROSIM_UNREAL_ENGINE_ROOT%
)

@REM Detect the Unreal Engine minor version from the engine's Build.version file
@REM and select the matching Cesium for Unreal version and download URL prefix.
for /f "tokens=2 delims=:, " %%v in ('findstr /C:"MinorVersion" "%AEROSIM_UNREAL_ENGINE_ROOT%\Engine\Build\Build.version"') do set UE_MINOR_VERSION=%%v
if "!UE_MINOR_VERSION!" == "3" (
    set CESIUM_VERSION=v2.13.2
    set CESIUM_UE_PREFIX=53
) else if "!UE_MINOR_VERSION!" == "7" (
    set CESIUM_VERSION=v2.23.0
    set CESIUM_UE_PREFIX=57
) else (
    echo ERROR: Unsupported Unreal Engine minor version: 5.!UE_MINOR_VERSION!. Supported versions: 5.3, 5.7.
    goto :EOF
)

@REM Run setup if needed - check for version mismatch and re-download if needed
if exist %CESIUM_SOURCE_PATH% (
    set CESIUM_UPLUGIN=%CESIUM_SOURCE_PATH%\CesiumForUnreal.uplugin
    for /f "tokens=2 delims=:, " %%v in ('findstr /C:"VersionName" "!CESIUM_UPLUGIN!" 2^>nul') do set CESIUM_INSTALLED_VERSION=%%~v
    set CESIUM_REQUIRED_VERSION=!CESIUM_VERSION:v=!
    if not "!CESIUM_INSTALLED_VERSION!" == "!CESIUM_REQUIRED_VERSION!" (
        echo CesiumForUnreal version mismatch: installed=!CESIUM_INSTALLED_VERSION!, required=!CESIUM_REQUIRED_VERSION!
        echo Removing installed plugin and re-downloading...
        rmdir /S /Q %CESIUM_SOURCE_PATH%
    )
)
if not exist %CESIUM_SOURCE_PATH% (
    echo Downloading CesiumForUnreal !CESIUM_VERSION! for UE 5.!UE_MINOR_VERSION!...
    pushd Plugins
    curl --retry 5 --retry-max-time 120 -L -o CesiumPluginForUnreal.zip https://github.com/CesiumGS/cesium-unreal/releases/download/!CESIUM_VERSION!/CesiumForUnreal-!CESIUM_UE_PREFIX!-!CESIUM_VERSION!.zip && tar -xf CesiumPluginForUnreal.zip && del CesiumPluginForUnreal.zip
    popd
)

set BUILD_CMD="%AEROSIM_UNREAL_ENGINE_ROOT%\Engine\Build\BatchFiles\Build.bat" AerosimUE5Editor Win64 Development "%UPROJECT%"

if /i !TARGET! == "build" (
    echo Building the Unreal project...
    call !BUILD_CMD!
) else if /i !TARGET! == "launch" (
    echo Launching the project in the Unreal Editor for instances !IDS!...
    call !BUILD_CMD!
    for %%i in (!IDS_LIST!) do (
        @echo Launching instance with ID %%i...
        @echo Launch cmd: "%AEROSIM_UNREAL_ENGINE_ROOT%\Engine\Binaries\Win64\UnrealEditor.exe" %UPROJECT% -%RHI% -log !UNREAL_ARGS! -InstanceId=%%i
        start "AeroSim Unreal Instance %%i" "%AEROSIM_UNREAL_ENGINE_ROOT%\Engine\Binaries\Win64\UnrealEditor.exe" %UPROJECT% -%RHI% -log !UNREAL_ARGS! -InstanceId=%%i
    )
) else if /i !TARGET! == "game" (
    echo Launching the project in the Unreal Editor's stand-alone game mode for instances !IDS!...
    call !BUILD_CMD!
    for %%i in (!IDS_LIST!) do (
        @echo Launching instance with ID %%i...
        @echo Launch cmd: "%AEROSIM_UNREAL_ENGINE_ROOT%\Engine\Binaries\Win64\UnrealEditor" %UPROJECT% -%RHI% -game -log !UNREAL_ARGS! -InstanceId=%%i
        start "AeroSim Unreal Instance %%i" "%AEROSIM_UNREAL_ENGINE_ROOT%\Engine\Binaries\Win64\UnrealEditor" %UPROJECT% -%RHI% -game -log !UNREAL_ARGS! -InstanceId=%%i
    )
) else if /i !TARGET! == "clean" (
    echo Cleaning build files...
    rmdir /S /Q Binaries
	rmdir /S /Q Intermediate
	rmdir /S /Q Plugins\aerosim-unreal-plugin\Binaries
	rmdir /S /Q Plugins\aerosim-unreal-plugin\Intermediate
  	rmdir /S /Q Saved
	rmdir /S /Q DerivedDataCache
)
