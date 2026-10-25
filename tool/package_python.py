import argparse
import json
import os
import shutil
import subprocess
import sys

PLATFORM_NAMES = {
    "windows": "Windows",
    "android": "Android",
    "ios": "iOS",
    "darwin": "Darwin",
    "macos": "Darwin",
    "linux": "Linux",
}


def resolve_tool(name):
    path = shutil.which(name)
    if path is None:
        raise SystemExit(f"'{name}' not found.")
    return path


def resolve_platform(device_id, flutter):
    proc = subprocess.run(
        [flutter, "devices", "--machine"],
        capture_output=True,
        text=True,
    )
    if proc.returncode != 0:
        raise SystemExit(f"Error: {proc.stderr}")
    devices = json.loads(proc.stdout)
    device = next((d for d in devices if d.get("id") == device_id), None)
    if device is None:
        raise SystemExit(f"Device '{device_id}' not found.")
    target_platform = str(device.get("targetPlatform") or "")
    prefix = target_platform.split("-")[0]
    name = PLATFORM_NAMES.get(prefix)
    if name is None:
        raise SystemExit(f"Platform '{target_platform}' does not support python packaging.")
    return name


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--device-id", default="")
    parser.add_argument("--platform", default="")
    parser.add_argument("--python-version", default="3.12")
    args = parser.parse_args()

    platform = args.platform
    if not platform:
        if not args.device_id:
            raise SystemExit("No device selected.")
        platform = resolve_platform(args.device_id, resolve_tool("flutter"))

    root = os.getcwd()
    env = dict(os.environ)
    env["SERIOUS_PYTHON_VERSION"] = args.python_version
    env["SERIOUS_PYTHON_APP"] = os.path.join(root, "build", "app")
    env["SERIOUS_PYTHON_SITE_PACKAGES"] = os.path.join(root, "build", "site-packages")
    if platform in ("Android", "iOS"):
        env["SERIOUS_PYTHON_ALLOW_SOURCE_DISTRIBUTIONS"] = "jsonpath"

    print(f"Packaging python for '{platform}'")
    proc = subprocess.run(
        [
            resolve_tool("dart"),
            "run",
            "serious_python:main",
            "package",
            "lib/plugin/tvbox/pyramid",
            "-p",
            platform,
            "-r",
            "-r",
            "-r",
            "lib/plugin/tvbox/pyramid/requirements.txt",
        ],
        env=env,
    )
    if proc.returncode == 0:
        print(f"Python packaged for '{platform}'.\n")
    else:
        print(f"Packaging failed with exit code {proc.returncode}", file=sys.stderr)
    sys.exit(proc.returncode)


if __name__ == "__main__":
    main()
