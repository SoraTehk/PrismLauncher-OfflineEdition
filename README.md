<p align="center">
<picture>
  <source media="(prefers-color-scheme: dark)" srcset="/program_info/org.prismlauncher.PrismLauncher.logo-darkmode.svg">
  <source media="(prefers-color-scheme: light)" srcset="/program_info/org.prismlauncher.PrismLauncher.logo.svg">
  <img alt="Prism Launcher" src="/program_info/org.prismlauncher.PrismLauncher.logo.svg" width="40%">
</picture>
</p>

https://prismlauncher.org/wiki/development/build-instructions/

```
winget install winget Microsoft.VisualStudio.2022.BuildTools ^
    --override '--add Microsoft.VisualStudio.Workload.VCTools;includeRecommended'
```
```
winget install winget EclipseAdoptium.Temurin.17.JDK
```
```
winget install winget miurahr.aqtinstall
aqt install-qt windows desktop 6 win64_msvc2022_64 -m qtimageformats qtnetworkauth
```
```
cmake --preset windows_msvc -D CMAKE_PREFIX_PATH="C:\path\to\Qt"
cmake --build --preset windows_msvc --config Debug
cmake --install build --config Debug
cmake --install build --config Debug --component portable # If you want to install a portable version
```
