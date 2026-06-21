@echo off
REM TinyTextOS Windows run script
setlocal

echo Running TinyTextOS through WSL...
echo.

wsl --cd "%~dp0" bash ./run.sh

if errorlevel 1 (
    echo.
    echo Run failed.
    echo.
    pause
    exit /b 1
)

echo.
echo Finished.
echo.

pause
