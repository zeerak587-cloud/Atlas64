#!/bin/bash
# Atlas64 build script

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

KERNEL_SECTORS=128
OUTPUT_IMAGE="atlas64.img"
IMAGE_SIZE=$((512 + KERNEL_SECTORS * 512))

echo "Building Atlas64..."
echo "Architecture: x86-64 long mode"
echo "Output: $OUTPUT_IMAGE"

python3 generate_song.py longer_square_wave_song.wav song_data.h

nasm -f bin boot.asm -o boot.bin
nasm -f elf64 kernel_entry.asm -o kernel_entry.o

gcc -m64 \
    -ffreestanding \
    -fno-pie \
    -fno-pic \
    -fno-stack-protector \
    -mno-red-zone \
    -mcmodel=small \
    -nostdlib \
    -c kernel.c \
    -o kernel.o

ld -m elf_x86_64 \
   -T linker.ld \
   -o kernel.elf \
   kernel_entry.o kernel.o

objcopy -O binary kernel.elf kernel.bin

kernel_size=$(wc -c < kernel.bin)
max_kernel_size=$((KERNEL_SECTORS * 512))

if [ "$kernel_size" -gt "$max_kernel_size" ]; then
    echo "Kernel too large!"
    echo "Size: $kernel_size bytes"
    echo "Limit: $max_kernel_size bytes"
    exit 1
fi

cat boot.bin kernel.bin > "$OUTPUT_IMAGE"
truncate -s "$IMAGE_SIZE" "$OUTPUT_IMAGE"

echo
echo "Build complete!"
echo "Image: $OUTPUT_IMAGE"
echo "Kernel size: $kernel_size bytes"
echo "Kernel limit: $max_kernel_size bytes"
