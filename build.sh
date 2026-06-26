#!/bin/bash
# Atlas32 Build Script

set -e

require_tool() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "Missing required tool: $1"
        exit 1
    fi
}

require_tool nasm
require_tool gcc
require_tool ld
require_tool truncate
require_tool python3

KERNEL_SECTORS=512
OUTPUT_IMAGE="atlas32.img"
IMAGE_SIZE=$((512 + KERNEL_SECTORS * 512))

echo "Building Atlas32..."
echo "Architecture: x86 (32-bit)"
echo "Output: $OUTPUT_IMAGE"

# Generate song header
python3 generate_song.py longer_square_wave_song.wav song_data.h

# Assemble bootloader
nasm -f bin boot.asm -o boot.bin

# Assemble kernel entry
nasm -f elf32 kernel_entry.asm -o kernel_entry.o

# Compile kernel
gcc -m32 \
    -ffreestanding \
    -fno-pie \
    -fno-pic \
    -fno-stack-protector \
    -nostdlib \
    -c kernel.c \
    -o kernel.o

# Link kernel
ld -m elf_i386 \
   -T linker.ld \
   -o kernel.bin \
   --oformat binary \
   kernel_entry.o kernel.o

# Check size
kernel_size=$(wc -c < kernel.bin)
max_kernel_size=$((KERNEL_SECTORS * 512))

if [ "$kernel_size" -gt "$max_kernel_size" ]; then
    echo "Kernel too large!"
    echo "Size: $kernel_size bytes"
    echo "Limit: $max_kernel_size bytes"
    exit 1
fi

# Build image
cat boot.bin kernel.bin > "$OUTPUT_IMAGE"

truncate -s "$IMAGE_SIZE" "$OUTPUT_IMAGE"

echo
echo "Build complete!"
echo "Image: $OUTPUT_IMAGE"
echo "Kernel size: $kernel_size bytes"
echo "Kernel limit: $max_kernel_size bytes"
