# IOHub Dash Windows MSI

Build the Flutter release first:

```powershell
flutter build windows --release
dotnet tool install wix --version 4.0.6 --tool-path build/tools/wix
python windows/installer/build_msi.py --crt-dir "C:/Program Files/Microsoft Visual Studio/2022/Community/VC/Redist/MSVC/14.40.33807/x64/Microsoft.VC143.CRT"
```

Adjust the Visual Studio CRT directory for your installation. Python 3 and .NET
are required. The script enables .NET major-version roll-forward for WiX.
If WiX is already installed in the build directory, omit its install command.

Output: `build/installer/IOHubDash-<version>-windows-x64.msi`.
Version is read from `pubspec.yaml`; payload is the complete Windows release
without debugging symbols, plus the app-local Visual C++ x64 CRT DLLs.

The MSI installs for the current user under
`%LOCALAPPDATA%/Programs/IdentSpace/IOHub Dash`, adds Start menu and desktop
shortcuts, and supports upgrades through a stable UpgradeCode. Keep the
UpgradeCode and component GUID namespace unchanged for future releases.
Increase the three-part version in pubspec.yaml for upgrades; the Flutter build
number after `+` is not used as the MSI version. The MSI is not code-signed.

WiX documentation: https://docs.firegiant.com/wix/using-wix/
