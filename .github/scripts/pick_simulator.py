#!/usr/bin/env python3
"""Pick an available iPhone simulator on the runner.

GitHub's `macos-latest` image changes its Xcode and its bundled runtimes without notice, so
hardcoding a device name and an OS version is the main reason these workflows rot. This picks
the newest available iOS runtime and the "best" iPhone available for it, and prints the result
as `key=value` lines ready to be appended to `$GITHUB_ENV`.

Overrides (both optional) come from the workflow inputs:
  --device   exact device name, e.g. "iPhone 16 Pro"
  --runtime  exact iOS version, e.g. "18.2"
"""

import argparse
import json
import re
import subprocess
import sys


def simctl_json(*args):
    out = subprocess.run(
        ["xcrun", "simctl", "list", *args, "--json"],
        check=True, capture_output=True, text=True,
    ).stdout
    return json.loads(out)


def version_key(version):
    return tuple(int(part) for part in re.findall(r"\d+", version)) or (0,)


def device_rank(name):
    """Rank iPhones so the newest, most capable model wins.

    Sorts by model number first ("iPhone 16" beats "iPhone 15"), then by tier, so that a
    "Pro Max" is preferred over a "Pro" over a plain model. `iPhone SE (3rd generation)` and
    similar fall back to their generation number, which keeps them below the numbered models.
    """
    model = re.search(r"iPhone\s+(\d+)", name)
    model_number = int(model.group(1)) if model else 0
    tier = 0
    if "Pro Max" in name:
        tier = 3
    elif "Pro" in name:
        tier = 2
    elif "Plus" in name:
        tier = 1
    return (model_number, tier, name)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--device", default="")
    parser.add_argument("--runtime", default="")
    args = parser.parse_args()

    runtimes = [
        runtime for runtime in simctl_json("runtimes")["runtimes"]
        if runtime.get("isAvailable") and runtime.get("platform") == "iOS"
    ]
    if args.runtime:
        runtimes = [runtime for runtime in runtimes if runtime["version"] == args.runtime]
        if not runtimes:
            sys.exit(f"No available iOS runtime matches '{args.runtime}'.")
    if not runtimes:
        sys.exit("No available iOS runtimes on this runner.")

    runtimes.sort(key=lambda runtime: version_key(runtime["version"]))
    devices_by_runtime = simctl_json("devices", "available")["devices"]

    # Walk the runtimes newest-first: the newest one occasionally ships with no usable iPhone.
    for runtime in reversed(runtimes):
        candidates = [
            device for device in devices_by_runtime.get(runtime["identifier"], [])
            if device.get("isAvailable") and device["name"].startswith("iPhone")
        ]
        if args.device:
            candidates = [device for device in candidates if device["name"] == args.device]
        if not candidates:
            continue

        chosen = sorted(candidates, key=lambda device: device_rank(device["name"]))[-1]
        print(f"SIMULATOR_UDID={chosen['udid']}")
        print(f"SIMULATOR_NAME={chosen['name']}")
        print(f"SIMULATOR_OS={runtime['version']}")
        print(f"SIMULATOR_RUNTIME={runtime['identifier']}")
        return

    wanted = f" named '{args.device}'" if args.device else ""
    sys.exit(f"No available iPhone simulator{wanted} for any installed iOS runtime.")


if __name__ == "__main__":
    main()
