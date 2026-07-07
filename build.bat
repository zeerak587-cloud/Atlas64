@echo off
REM Atlas64 Windows build launcher

setlocal

echo.
echo Running Atlas64 build system through WSL...
echo.

wsl --cd "%~dp0" bash ./build.sh

if errorlevel 1 (
    echo.
    echo Build failed.
    echo If dependencies are missing, run this in WSL:
    echo sudo apt update ^&^& sudo apt install -y nasm gcc binutils python3 qemu-system-x86
    echo.
    pause
    exit /b 1
)

echo.
echo Finished.
echo.
pause
