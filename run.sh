#!/bin/bash
# TinyTextOS Linux / WSL run script

bash delete.sh
bash build.sh

set -e

require_tool() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "Missing required tool: $1"
        echo "Install the run dependencies with:"
        echo "  sudo apt update && sudo apt install -y qemu-system-x86 qemu-system-arm"
        exit 1
    fi
}

require_tool python3

RUN_CONFIG=$(python3 - <<'PY'
import json
import shlex
import sys
from pathlib import Path

config = {
    "architecture": "32",
    "output": "tinyos.img",
}

config_path = Path("build.json")
if config_path.exists():
    loaded = json.loads(config_path.read_text(encoding="utf-8-sig"))
    if not isinstance(loaded, dict):
        sys.exit("Invalid build.json: top-level value must be an object")
    config.update(loaded)

target = str(config.get("architecture", config.get("target", "32"))).strip().lower().replace("-", "_")
target_aliases = {
    "32": ("x86", "qemu-system-i386"),
    "x86": ("x86", "qemu-system-i386"),
    "i386": ("x86", "qemu-system-i386"),
    "i686": ("x86", "qemu-system-i386"),
    "64": ("x86_64", "qemu-system-x86_64"),
    "x64": ("x86_64", "qemu-system-x86_64"),
    "x86_64": ("x86_64", "qemu-system-x86_64"),
    "amd64": ("x86_64", "qemu-system-x86_64"),
    "arm": ("arm", "qemu-system-arm"),
    "arm32": ("arm", "qemu-system-arm"),
    "aarch32": ("arm", "qemu-system-arm"),
    "arm64": ("arm64", "qemu-system-aarch64"),
    "aarch64": ("arm64", "qemu-system-aarch64"),
}

if target not in target_aliases:
    allowed = ", ".join(sorted(target_aliases))
    sys.exit(f"Unsupported architecture '{target}'. Allowed values: {allowed}")

arch, emulator = target_aliases[target]
output = str(config.get("output", "tinyos.img")).strip()
if not output:
    sys.exit("Invalid build.json: output must not be empty")

for key, value in {
    "TARGET": target,
    "ARCH": arch,
    "EMULATOR": emulator,
    "OUTPUT_IMAGE": output,
}.items():
    print(f"{key}={shlex.quote(value)}")
PY
)

eval "$RUN_CONFIG"

require_tool "$EMULATOR"

if [ ! -f "$OUTPUT_IMAGE" ]; then
    echo "$OUTPUT_IMAGE not found. Build first with:"
    echo "  bash ./build.sh"
    exit 1
fi

echo "Running TinyTextOS..."
echo "Architecture: $TARGET ($ARCH)"
echo "Emulator: $EMULATOR"
echo "Image: $OUTPUT_IMAGE"
echo

case "$ARCH" in
    x86|x86_64)
        AUDIO_DRIVER="${TINYTEXTOS_AUDIO_DRIVER:-pa}"

        "$EMULATOR" \
            -machine pc,pcspk-audiodev=audio0 \
            -audiodev "${AUDIO_DRIVER},id=audio0" \
            -drive file="$OUTPUT_IMAGE",format=raw,if=floppy \
            -boot a \
            -snapshot \
            "$@"
        ;;
    arm)
        "$EMULATOR" \
            -M virt \
            -cpu cortex-a15 \
            -nographic \
            -kernel "$OUTPUT_IMAGE" \
            "$@"
        ;;
    arm64)
        "$EMULATOR" \
            -M virt \
            -cpu cortex-a57 \
            -nographic \
            -kernel "$OUTPUT_IMAGE" \
            "$@"
        ;;
    *)
        echo "No run recipe for $ARCH."
        exit 1
        ;;
esac
