<p align="center">
<picture>
  <source media="(prefers-color-scheme: dark)" srcset="/program_info/org.prismlauncher.PrismLauncher.logo-darkmode.svg">
  <source media="(prefers-color-scheme: light)" srcset="/program_info/org.prismlauncher.PrismLauncher.logo.svg">
  <img alt="Prism Launcher" src="/program_info/org.prismlauncher.PrismLauncher.logo.svg" width="40%">
</picture>
</p>

Prism Launcher with offline accounts unlocked (no Microsoft account needed), built as a self-contained portable app.

Upstream build docs: https://prismlauncher.org/wiki/development/build-instructions/

## Prerequisites (Windows x64)

| Tool | Version | Notes |
|---|---|---|
| Visual Studio Build Tools | 2026 | "Desktop development with C++" workload; its recommended components bring CMake, Ninja and the Windows SDK |
| Qt | 6.8 or newer (6.11.2 tested) | MSVC 2022 64-bit kit plus the Qt Image Formats and Qt Network Authorization modules |
| JDK | 17 to 25 (Temurin 25 tested) | Only used to compile the launcher's small Java helpers |
| Git | any | Needed for the submodules |

```bat
winget install --id Microsoft.VisualStudio.BuildTools --exact --override "--passive --wait --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended"
winget install --id EclipseAdoptium.Temurin.25.JDK --exact
winget install --id Git.Git --exact
winget install --id miurahr.aqtinstall --exact
aqt install-qt windows desktop 6.11.2 win64_msvc2022_64 -m qtimageformats qtnetworkauth -O C:\Coding\Qt
```

The Qt Online Installer works too: pick Qt 6.11.2 > MSVC 2022 64-bit, and under Additional Libraries pick Qt Image Formats and Qt Network Authorization.

## Build

```bat
git clone --recursive https://github.com/HuySora/PrismLauncher-OfflineEdition.git
cd PrismLauncher-OfflineEdition
build.bat
```

- The top of `build.bat` lists every path it needs (`QT_PATH`, `JDK_PATH`, `VS_PATH`, `CMAKE_PATH`, `NINJA_PATH`); edit them there, or set an environment variable with the same name. An empty value means "find it automatically".
- It also sets how hard the build may load the PC: `LINK_JOBS` (programs linked at once, about 2 GB of RAM each) and `BUILD_PRIORITY` (`belownormal` keeps the PC usable).
- `build.bat clean` rebuilds from scratch, `build.bat debug` makes a Debug build (runs only on a PC with Visual Studio), `build.bat tests` also builds the unit tests.
- The first build takes about 30 to 40 minutes: vcpkg compiles the C++ dependencies once, and Release builds use link-time optimization. After that, a change usually rebuilds in a few minutes.

## Output

`install\` is the portable launcher. Zip that folder and share it: it includes Qt and the Visual C++ runtime, so the other PC needs nothing installed (the launcher downloads Java for Minecraft by itself). It keeps all its data next to `prismlauncher.exe`, so zip it before running it yourself, or run a copy.

## Disk usage

| Location | Size | Purpose |
|---|---|---|
| `build\` | about 3.3 GB | Intermediate build files, safe to delete (the next build is a full rebuild) |
| `install\` | about 46 MB | The portable launcher |
| `cmake\vcpkg\downloads\` | 300 to 500 MB | Tools (PowerShell 7, 7-Zip, ...) and sources vcpkg downloaded, reused by later builds; archives already unpacked under `tools\` can be deleted |
| `%LOCALAPPDATA%\vcpkg\` | about 400 MB | vcpkg's registry clone and binary cache (shared with other vcpkg projects), makes later configures take seconds |
