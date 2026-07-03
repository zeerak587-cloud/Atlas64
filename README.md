# Atlas32.img

![Logo](logo.png)

Atlas32 is a tiny 32-bit protected-mode operating system written in C and Assembly.

It boots directly into a simple VGA text-mode terminal and includes a small command shell, keyboard input, PC-speaker music playback, a RAM-only text-file system, and a tiny script editor.

## Features

* 32-bit protected mode kernel
* Custom bootloader
* VGA 80×25 text-mode display
* PS/2 keyboard input
* Command-line shell
* Real-time clock command
* PC-speaker song playback
* RAM-only text files
* RAM-only script programs
* Reboot command
* No external operating system required

## Commands

| Command           | What it does                         |
| ----------------- | ------------------------------------ |
| `help`            | Shows the command list               |
| `clear`           | Clears the screen                    |
| `about`           | Shows Atlas32 information            |
| `time`            | Displays the current RTC time        |
| `reset`           | Reboots the computer or emulator     |
| `creator`         | Shows creator information            |
| `play song`       | Plays a song through the PC speaker  |
| `create file`     | Creates a RAM-only text file         |
| `name+`           | Opens a saved text file named `name` |
| `create program`  | Opens the tiny binary script editor  |
| `run binary file` | Runs the saved RAM-only script       |

## Text Files

Atlas32 can store small text files in RAM.

Run:

```text
create file
```

Type your text, then press Enter twice on blank lines to finish writing. Atlas32 will ask for a file name.

For example:

```text
> create file

| Hello from Atlas32
| This file only exists in RAM.
|
|

Name this file: test
Saved. Type test+ to read it.
```

Later, read it with:

```text
test+
```

Text files disappear after rebooting because Atlas32 does not yet have disk storage.

## Tiny Script Programs

Atlas32 includes a very small script editor.

Run:

```text
create program
```

Available script commands:

```text
print (Hello World)
delay (2)
```

Example:

```text
print (Hello from a binary file!)
delay (1)
print (This appeared one second later.)
```

Press Enter twice on blank lines to save the program in RAM, then run:

```text
run binary file
```

## Building

Atlas32 needs an x86 cross-compiler, NASM, and a tool such as `make`.

Typical tools needed:

```text
nasm
i686-elf-gcc
i686-elf-ld
make
qemu-system-i386
```

Build the image:

```bash
make
```

Run it in QEMU:

```bash
qemu-system-i386 -drive format=raw,file=Atlas32.img
```

## Project Goals

Atlas32 is an experiment in making a small operating system from scratch. Future ideas include:

* Disk or floppy storage
* A real filesystem
* More shell commands
* Better text editing
* Color themes
* Loading programs from disk
* Mouse support
* Simple graphics mode
* A tiny application format

## Creator

Created by Zeerak Khan.

* GitHub: https://github.com/zeerak587-cloud
* Scratch: https://scratch.mit.edu/users/Cute_Seal_WOW/

License

This project is licensed under the MIT License.
