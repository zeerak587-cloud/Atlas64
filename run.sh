#!/bin/bash
# Atlas32 Run Script

set -e

bash delete.sh
bash build.sh

require_tool() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "Missing required tool: $1"
        exit 1
    fi
}

require_tool qemu-system-i386

OUTPUT_IMAGE="atlas32.img"

if [ ! -f "$OUTPUT_IMAGE" ]; then
    echo "$OUTPUT_IMAGE not found."
    exit 1
fi

echo "Running Atlas32..."
echo

AUDIO_DRIVER="${ATLAS32_AUDIO_DRIVER:-pa}"

qemu-system-i386 \
    -machine pc,pcspk-audiodev=audio0 \
    -audiodev "${AUDIO_DRIVER},id=audio0" \
    -drive file="$OUTPUT_IMAGE",format=raw,if=floppy \
    -boot a \
    -snapshot \
    "$@"
