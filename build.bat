@echo off
REM TinyTextOS Windows build script
setlocal

echo.
echo Running TinyTextOS build system through WSL...
echo.

wsl --cd "%~dp0" bash ./build.sh

if errorlevel 1 (
    echo.
    echo Build failed.
    echo If dependencies are missing, run this in WSL:
    echo sudo apt update ^&^& sudo apt install -y nasm gcc binutils python3 qemu-system-x86 qemu-system-arm gcc-arm-none-eabi gcc-aarch64-linux-gnu
    echo.
    pause
    exit /b 1
)

echo.
echo Finished.
echo.

pause
