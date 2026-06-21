@echo off
REM TinyTextOS Windows cleanup script
setlocal

echo Deleting compiled files using WSL...
echo.

wsl --cd "%~dp0" bash ./delete_compiled_stuff.sh

if errorlevel 1 (
    echo.
    echo Cleanup failed.
    echo.
    pause
    exit /b 1
)

echo Done! :)

pause
