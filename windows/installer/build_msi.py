"""Package an existing Flutter Windows x64 release with WiX 4."""
import argparse
import hashlib
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import uuid
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[2]
NS = "http://wixtoolset.org/schemas/v4/wxs"
ET.register_namespace("", NS)


def node(parent, tag, **attrs):
    return ET.SubElement(parent, f"{{{NS}}}{tag}", attrs)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--release-dir", type=Path, default=ROOT / "build/windows/x64/runner/Release")
    parser.add_argument("--crt-dir", required=True, type=Path)
    parser.add_argument("--wix", type=Path, default=ROOT / "build/tools/wix/wix.exe")
    args = parser.parse_args()
    release = args.release_dir.resolve()
    for path in [release / "iot_hub_client.exe", release / "flutter_windows.dll", release / "data/app.so", args.crt_dir / "vcruntime140.dll", args.wix]:
        if not path.is_file():
            raise SystemExit(f"Missing required build input: {path}")
    version = re.search(r"^version:\s*(\d+\.\d+\.\d+)", (ROOT / "pubspec.yaml").read_text(), re.M).group(1)
    output = ROOT / "build/installer"
    output.mkdir(parents=True, exist_ok=True)
    work = Path(tempfile.mkdtemp(prefix="msi-", dir=output))
    stage = work / "payload"
    shutil.copytree(release, stage, ignore=shutil.ignore_patterns("*.pdb", "*.lib", "*.exp"))
    (stage / "iot_hub_client.exe").rename(stage / "IOHubDash.exe")
    for dll in args.crt_dir.glob("*.dll"):
        shutil.copy2(dll, stage / dll.name)
    wix = ET.Element(f"{{{NS}}}Wix")
    package = node(wix, "Package", Name="IOHub Dash", Manufacturer="IdentSpace", Version=version,
                   UpgradeCode="9E946314-B99F-4722-B764-392B1E5F9B15", Scope="perUser", Language="1033", InstallerVersion="500")
    node(package, "MajorUpgrade", DowngradeErrorMessage="A newer version of IOHub Dash is already installed.")
    node(package, "MediaTemplate", EmbedCab="yes", CompressionLevel="high")
    node(package, "Icon", Id="AppIcon", SourceFile=str(ROOT / "windows/runner/resources/iohubdash.ico"))
    node(package, "Property", Id="ARPPRODUCTICON", Value="AppIcon")
    feature = node(package, "Feature", Id="MainFeature", Title="IOHub Dash", Level="1")
    local = node(package, "StandardDirectory", Id="LocalAppDataFolder")
    programs = node(local, "Directory", Id="UserPrograms", Name="Programs")
    vendor = node(programs, "Directory", Id="VendorFolder", Name="IdentSpace")
    install = node(vendor, "Directory", Id="INSTALLFOLDER", Name="IOHub Dash")
    directory_nodes = {"": install}
    directory_ids = ["UserPrograms", "VendorFolder", "INSTALLFOLDER"]
    for directory in sorted((p for p in stage.rglob("*") if p.is_dir()), key=lambda p: p.as_posix()):
        relative = directory.relative_to(stage)
        key = relative.as_posix()
        ident = "Dir_" + hashlib.sha256(key.encode()).hexdigest()[:24]
        directory_nodes[key] = node(directory_nodes[relative.parent.as_posix() if relative.parent != Path(".") else ""], "Directory", Id=ident, Name=directory.name)
        directory_ids.append(ident)
    files = sorted(p for p in stage.rglob("*") if p.is_file())
    for file in files:
        relative = file.relative_to(stage)
        ident = hashlib.sha256(relative.as_posix().encode()).hexdigest()[:24]
        parent = directory_nodes[relative.parent.as_posix() if relative.parent != Path(".") else ""]
        component = node(parent, "Component", Id="Cmp_" + ident, Guid=str(uuid.uuid5(uuid.UUID("9e946314-b99f-4722-b764-392b1e5f9b15"), relative.as_posix().lower())), Bitness="always64")
        node(component, "File", Id="File_" + ident, Source=str(file))
        node(component, "RegistryValue", Root="HKCU", Key=r"Software\IdentSpace\IOHubDash\InstallerFiles", Name=ident, Type="integer", Value="1", KeyPath="yes")
        node(feature, "ComponentRef", Id="Cmp_" + ident)
    menu = node(package, "StandardDirectory", Id="ProgramMenuFolder")
    menu_folder = node(menu, "Directory", Id="AppMenuFolder", Name="IOHub Dash")
    node(package, "StandardDirectory", Id="DesktopFolder")
    shortcuts = node(menu_folder, "Component", Id="AppShortcuts", Guid="*", Bitness="always64")
    for ident, directory in [("StartMenuShortcut", "AppMenuFolder"), ("DesktopShortcut", "DesktopFolder")]:
        node(shortcuts, "Shortcut", Id=ident, Directory=directory, Name="IOHub Dash", Target="[INSTALLFOLDER]IOHubDash.exe", WorkingDirectory="INSTALLFOLDER", Icon="AppIcon")
    for index, ident in enumerate(directory_ids + ["AppMenuFolder"]):
        node(shortcuts, "RemoveFolder", Id=f"RemoveFolder_{index}", Directory=ident, On="uninstall")
    node(shortcuts, "RegistryValue", Root="HKCU", Key=r"Software\IdentSpace\IOHubDash", Name="Installed", Type="integer", Value="1", KeyPath="yes")
    node(feature, "ComponentRef", Id="AppShortcuts")
    source = work / "IOHubDash.wxs"
    ET.indent(wix)
    ET.ElementTree(wix).write(source, encoding="utf-8", xml_declaration=True)
    msi = output / f"IOHubDash-{version}-windows-x64.msi"
    env = dict(os.environ, DOTNET_ROLL_FORWARD="Major")
    subprocess.run([str(args.wix.resolve()), "build", str(source), "-arch", "x64", "-o", str(msi)], env=env, check=True)
    print(f"MSI: {msi} ({msi.stat().st_size:,} bytes); {len(files)} payload files")


if __name__ == "__main__":
    main()
