@echo off
rem Builds PrismLauncher-OfflineEdition and installs a portable copy into .\install
rem
rem Usage: build.bat [clean] [debug] [tests]
rem   clean   Delete .\build first and rebuild everything
rem   debug   Debug build instead of Release (only runs on a machine with Visual Studio)
rem   tests   Also build the unit tests (23 more programs to link)
rem
rem Output: .\build (intermediate files) and .\install (the portable launcher), as set in CMakePresets.json.
rem Prerequisites are listed in README.md.
setlocal EnableExtensions

rem ================================ Paths this build needs ================================
rem Edit them here, or set an environment variable with the same name to override one.
rem An empty value means "find it automatically".
rem   QT_PATH     Qt kit for MSVC 2022 64-bit, with Qt Image Formats and Qt Network Authorization
rem   JDK_PATH    JDK 17 to 25, only compiles the launcher's small Java helpers (empty: javac from PATH)
rem   VS_PATH     Visual Studio or Build Tools with the C++ workload (empty: the newest one, via vswhere)
rem   CMAKE_PATH  Folder with cmake.exe 3.28 or newer (empty: PATH, else the copy that comes with Visual Studio)
rem   NINJA_PATH  Folder with ninja.exe (empty: the copy that comes with Visual Studio)
if not defined QT_PATH set "QT_PATH=C:\Coding\Qt\6.11.2\msvc2022_64"
if not defined JDK_PATH set "JDK_PATH=C:\Coding\jdk-25.0.4.101-hotspot_EclipseAdoptium"
if not defined VS_PATH set "VS_PATH=C:\Coding\MVS\BuildTools_18"
if not defined CMAKE_PATH set "CMAKE_PATH=C:\Coding\cmake\bin"
if not defined NINJA_PATH set "NINJA_PATH="

rem ============================ How hard the build may load this PC ============================
rem   LINK_JOBS       Programs linked at the same time; each Release link can take about 2 GB of RAM
rem   BUILD_PRIORITY  CPU priority: belownormal or low keeps the PC usable, normal finishes a bit sooner
if not defined LINK_JOBS set "LINK_JOBS=2"
if not defined BUILD_PRIORITY set "BUILD_PRIORITY=belownormal"
rem =============================================================================================

cd /d "%~dp0"
set "CONFIG=Release"
set "CLEAN="
set "BUILD_TESTS=OFF"

:parse_args
if "%~1"=="" goto :args_done
if /i "%~1"=="clean" (
    set "CLEAN=1"
) else if /i "%~1"=="debug" (
    set "CONFIG=Debug"
) else if /i "%~1"=="tests" (
    set "BUILD_TESTS=ON"
) else (
    echo Unknown argument "%~1". Usage: build.bat [clean] [debug] [tests]
    exit /b 1
)
shift
goto :parse_args
:args_done

echo --- Checking prerequisites ---
if not exist "%QT_PATH%\lib\cmake\Qt6\Qt6Config.cmake" (
    echo QT_PATH is not a Qt kit: "%QT_PATH%". See the top of build.bat.
    exit /b 1
)

if not defined JDK_PATH goto :jdk_from_path
if not exist "%JDK_PATH%\bin\javac.exe" (
    echo JDK_PATH has no bin\javac.exe: "%JDK_PATH%". See the top of build.bat.
    exit /b 1
)
set "JAVA_HOME=%JDK_PATH%"
set "PATH=%JDK_PATH%\bin;%PATH%"
goto :jdk_done
:jdk_from_path
where javac >nul 2>&1 || (
    echo javac not found: set JDK_PATH at the top of build.bat.
    exit /b 1
)
:jdk_done

set "NEED_SUBMODULES="
if not exist "cmake\vcpkg\bootstrap-vcpkg.bat" set "NEED_SUBMODULES=1"
if not exist "libraries\libnbtplusplus\CMakeLists.txt" set "NEED_SUBMODULES=1"
if defined NEED_SUBMODULES (
    echo Fetching git submodules...
    git submodule update --init --recursive || exit /b 1
)

rem Load the Visual Studio developer environment so cl.exe and its ninja/cmake are found
if defined VSCMD_VER goto :vs_done
if defined VS_PATH goto :vs_check
set "VSWHERE=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
if exist "%VSWHERE%" for /f "usebackq delims=" %%i in (`call "%VSWHERE%" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath`) do set "VS_PATH=%%i"
if not defined VS_PATH (
    echo Visual Studio with the C++ build tools was not found: set VS_PATH at the top of build.bat.
    exit /b 1
)
:vs_check
if not exist "%VS_PATH%\Common7\Tools\VsDevCmd.bat" (
    echo VS_PATH is not a Visual Studio folder: "%VS_PATH%". See the top of build.bat.
    exit /b 1
)
rem VsDevCmd runs vswhere by name; keeping its folder on PATH avoids a harmless "not recognized" message
set "PATH=%PATH%;%ProgramFiles(x86)%\Microsoft Visual Studio\Installer"
call "%VS_PATH%\Common7\Tools\VsDevCmd.bat" -arch=amd64 -host_arch=amd64 -no_logo
:vs_done

rem Configured CMake and Ninja go first on PATH, ahead of the copies that come with Visual Studio
if not defined CMAKE_PATH goto :cmake_done
if not exist "%CMAKE_PATH%\cmake.exe" (
    echo CMAKE_PATH has no cmake.exe: "%CMAKE_PATH%". See the top of build.bat.
    exit /b 1
)
set "PATH=%CMAKE_PATH%;%PATH%"
:cmake_done
if not defined NINJA_PATH goto :ninja_done
if not exist "%NINJA_PATH%\ninja.exe" (
    echo NINJA_PATH has no ninja.exe: "%NINJA_PATH%". See the top of build.bat.
    exit /b 1
)
set "PATH=%NINJA_PATH%;%PATH%"
:ninja_done

where cl >nul 2>&1 || (
    echo cl.exe not found after loading Visual Studio, see README.md.
    exit /b 1
)
where cmake >nul 2>&1 || (
    echo cmake not found: set CMAKE_PATH at the top of build.bat.
    exit /b 1
)
where ninja >nul 2>&1 || (
    echo ninja not found: set NINJA_PATH at the top of build.bat, or install the "C++ CMake tools for Windows" Visual Studio component.
    exit /b 1
)

set "SHOW_JDK=%JDK_PATH%"
if not defined SHOW_JDK set "SHOW_JDK=javac from PATH"
set "SHOW_CMAKE=%CMAKE_PATH%"
if not defined SHOW_CMAKE set "SHOW_CMAKE=from PATH or Visual Studio"
set "SHOW_NINJA=%NINJA_PATH%"
if not defined SHOW_NINJA set "SHOW_NINJA=from Visual Studio"
echo   Qt     %QT_PATH%
echo   JDK    %SHOW_JDK%
echo   VS     %VS_PATH%
echo   CMake  %SHOW_CMAKE%
echo   Ninja  %SHOW_NINJA%
echo   Load   %LINK_JOBS% links at a time, %BUILD_PRIORITY% priority, unit tests %BUILD_TESTS%

rem vcpkg's own downloader can hang forever on large GitHub downloads (seen with its PowerShell 7 download).
rem Route its downloads through curl.exe, which ships with Windows 10+; vcpkg still checks every file's SHA512.
if not defined X_VCPKG_ASSET_SOURCES set "X_VCPKG_ASSET_SOURCES=clear;x-script,curl.exe --fail --location --silent --show-error --retry 3 --output {dst} {url}"

rem ARTIFACT_NAME turns on the auto-updater, which would replace this build with official Prism (no offline patch)
set "ARTIFACT_NAME="

rem A build folder configured from another location (e.g. before moving the repo) fails to configure, so start fresh
if exist "build\CMakeCache.txt" findstr /b /i /l /c:"CMAKE_HOME_DIRECTORY:INTERNAL=%CD:\=/%" "build\CMakeCache.txt" >nul || (
    echo build\ was configured for a different source folder, starting fresh.
    set "CLEAN=1"
)
if defined CLEAN if exist build (
    echo --- Removing build\ ---
    rmdir /s /q build
)

rem Configure and build run at BUILD_PRIORITY (every compiler and linker they start inherits it),
rem and Ninja links at most LINK_JOBS programs at once, so the PC keeps enough RAM to stay usable.
echo.
echo --- Configuring (the first run downloads and builds dependencies, this takes a while) ---
start "" /%BUILD_PRIORITY% /b /wait cmake --preset windows_msvc -D CMAKE_PREFIX_PATH="%QT_PATH%" -D BUILD_TESTING=%BUILD_TESTS% -D "CMAKE_JOB_POOLS=link=%LINK_JOBS%" -D CMAKE_JOB_POOL_LINK=link
if errorlevel 1 goto :failed

echo.
echo --- Building (%CONFIG%) ---
start "" /%BUILD_PRIORITY% /b /wait cmake --build --preset windows_msvc --config %CONFIG%
if errorlevel 1 goto :failed

echo.
echo --- Installing portable copy into install\ ---
cmake --install build --config %CONFIG% || goto :failed
cmake --install build --config %CONFIG% --component portable || goto :failed

echo.
echo --- Build complete ---
echo Portable launcher: %CD%\install\prismlauncher.exe
echo Zip the install folder to share it. Running it from there stores instances and accounts inside it.
exit /b 0

:failed
echo.
echo --- Build failed, see the errors above ---
exit /b 1
