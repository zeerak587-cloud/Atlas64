#!/bin/bash
# TinyTextOS Linux / WSL build script

set -e

require_tool() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "Missing required tool: $1"
        echo "Install the build dependencies with:"
        echo "  sudo apt update && sudo apt install -y nasm gcc binutils python3 qemu-system-x86 qemu-system-arm gcc-arm-none-eabi gcc-aarch64-linux-gnu"
        exit 1
    fi
}

find_tool() {
    for tool in "$@"; do
        if command -v "$tool" >/dev/null 2>&1; then
            echo "$tool"
            return 0
        fi
    done

    return 1
}

require_tool python3

BUILD_CONFIG=$(python3 - <<'PY'
import json
import shlex
import sys
from pathlib import Path

config_path = Path("build.json")
config = {
    "architecture": "32",
    "kernelSectors": 16,
    "output": "tinyos.img",
}

if config_path.exists():
    try:
        loaded = json.loads(config_path.read_text(encoding="utf-8-sig"))
    except json.JSONDecodeError as exc:
        sys.exit(f"Invalid build.json: {exc}")

    if not isinstance(loaded, dict):
        sys.exit("Invalid build.json: top-level value must be an object")

    config.update(loaded)

target_value = config.get("architecture", config.get("target", "32"))
target = str(target_value).strip().lower().replace("-", "_")
target_aliases = {
    "32": ("x86", "32", "arch/x86/32"),
    "x86": ("x86", "32", "arch/x86/32"),
    "i386": ("x86", "32", "arch/x86/32"),
    "i686": ("x86", "32", "arch/x86/32"),
    "64": ("x86_64", "64", "arch/x86_64/64"),
    "x64": ("x86_64", "64", "arch/x86_64/64"),
    "x86_64": ("x86_64", "64", "arch/x86_64/64"),
    "amd64": ("x86_64", "64", "arch/x86_64/64"),
    "arm": ("arm", "32", "arch/arm/32"),
    "arm32": ("arm", "32", "arch/arm/32"),
    "aarch32": ("arm", "32", "arch/arm/32"),
    "arm64": ("arm64", "64", "arch/arm64/64"),
    "aarch64": ("arm64", "64", "arch/arm64/64"),
}

if target not in target_aliases:
    allowed = ", ".join(sorted(target_aliases))
    sys.exit(f"Unsupported architecture '{target}'. Allowed values: {allowed}")

arch, bits, source_dir = target_aliases[target]

try:
    kernel_sectors = int(config.get("kernelSectors", 16))
except (TypeError, ValueError):
    sys.exit("Invalid build.json: kernelSectors must be a number")

if kernel_sectors <= 0:
    sys.exit("Invalid build.json: kernelSectors must be greater than 0")

output = str(config.get("output", "tinyos.img")).strip()
if not output:
    sys.exit("Invalid build.json: output must not be empty")

for key, value in {
    "TARGET": target,
    "ARCH": arch,
    "BITS": bits,
    "ARCH_SOURCE_DIR": source_dir,
    "KERNEL_SECTORS": str(kernel_sectors),
    "OUTPUT_IMAGE": output,
}.items():
    print(f"{key}={shlex.quote(value)}")
PY
)

eval "$BUILD_CONFIG"
IMAGE_SIZE=$((512 + KERNEL_SECTORS * 512))

echo "Building TinyTextOS..."
echo "Architecture: $TARGET ($ARCH $BITS-bit)"
echo "Source: $ARCH_SOURCE_DIR"
echo "Output: $OUTPUT_IMAGE"

case "$ARCH:$BITS" in
    x86:32)
        require_tool nasm
        require_tool gcc
        require_tool ld
        require_tool truncate
        python3 generate_song.py longer_square_wave_song.wav song_data.h
        nasm -f bin "$ARCH_SOURCE_DIR/boot.asm" -o boot.bin
        nasm -f elf32 "$ARCH_SOURCE_DIR/kernel_entry.asm" -o kernel_entry.o
        gcc -m32 -I"$ARCH_SOURCE_DIR/include" -ffreestanding -fno-pie -fno-pic -fno-stack-protector -nostdlib -c kernel.c -o kernel.o
        ld -m elf_i386 -T "$ARCH_SOURCE_DIR/linker.ld" -o kernel.bin --oformat binary kernel_entry.o kernel.o
        kernel_size=$(wc -c < kernel.bin)
        max_kernel_size=$((KERNEL_SECTORS * 512))

        if [ "$kernel_size" -gt "$max_kernel_size" ]; then
            echo "Kernel is too large: ${kernel_size} bytes"
            echo "Bootloader currently loads only ${max_kernel_size} bytes."
            echo "Increase KERNEL_SECTORS in $ARCH_SOURCE_DIR/boot.asm and build.json."
            exit 1
        fi

        cat boot.bin kernel.bin > "$OUTPUT_IMAGE"
        truncate -s "$IMAGE_SIZE" "$OUTPUT_IMAGE"
        ;;
    x86_64:64)
        require_tool nasm
        require_tool gcc
        require_tool ld
        require_tool truncate
        python3 generate_song.py longer_square_wave_song.wav song_data.h
        nasm -f bin "$ARCH_SOURCE_DIR/boot.asm" -o boot.bin
        nasm -f elf64 "$ARCH_SOURCE_DIR/kernel_entry.asm" -o kernel_entry.o
        gcc -m64 -mno-red-zone -I"$ARCH_SOURCE_DIR/include" -ffreestanding -fno-pie -fno-pic -fno-stack-protector -nostdlib -c kernel.c -o kernel.o
        ld -m elf_x86_64 -T "$ARCH_SOURCE_DIR/linker.ld" -o kernel.bin --oformat binary kernel_entry.o kernel.o
        kernel_size=$(wc -c < kernel.bin)
        max_kernel_size=$((KERNEL_SECTORS * 512))

        if [ "$kernel_size" -gt "$max_kernel_size" ]; then
            echo "Kernel is too large: ${kernel_size} bytes"
            echo "Bootloader currently loads only ${max_kernel_size} bytes."
            echo "Increase KERNEL_SECTORS in $ARCH_SOURCE_DIR/boot.asm and build.json."
            exit 1
        fi

        cat boot.bin kernel.bin > "$OUTPUT_IMAGE"
        truncate -s "$IMAGE_SIZE" "$OUTPUT_IMAGE"
        ;;
    arm:32)
        ARM_CC=$(find_tool arm-none-eabi-gcc arm-linux-gnueabi-gcc arm-linux-gnueabihf-gcc) || {
            echo "Missing ARM cross compiler."
            echo "Install it with:"
            echo "  sudo apt update && sudo apt install -y gcc-arm-none-eabi qemu-system-arm"
            exit 1
        }
        "$ARM_CC" -mcpu=cortex-a15 -ffreestanding -nostdlib -nostartfiles -fno-builtin -Wall -Wextra \
            -T "$ARCH_SOURCE_DIR/linker.ld" \
            "$ARCH_SOURCE_DIR/start.S" "$ARCH_SOURCE_DIR/kernel.c" \
            -o "$OUTPUT_IMAGE"
        ;;
    arm64:64)
        ARM64_CC=$(find_tool aarch64-none-elf-gcc aarch64-linux-gnu-gcc) || {
            echo "Missing ARM64 cross compiler."
            echo "Install it with:"
            echo "  sudo apt update && sudo apt install -y gcc-aarch64-linux-gnu qemu-system-arm"
            exit 1
        }
        "$ARM64_CC" -ffreestanding -nostdlib -nostartfiles -fno-builtin -Wall -Wextra \
            -T "$ARCH_SOURCE_DIR/linker.ld" \
            "$ARCH_SOURCE_DIR/start.S" "$ARCH_SOURCE_DIR/kernel.c" \
            -o "$OUTPUT_IMAGE"
        ;;
    *)
        echo "No build recipe for $ARCH $BITS-bit."
        exit 1
        ;;
esac

echo
echo "Build complete: $OUTPUT_IMAGE"
echo
