#!/bin/bash
# Atlas32 Linux / WSL cleanup script

set -e

echo "Deleting compiled files..."

rm -f boot.bin
rm -f kernel_entry.o
rm -f kernel.o
rm -f kernel.bin
rm -f tinyos.img
rm -f song_data.h

echo "Done! :)"
