@echo off
setlocal enabledelayedexpansion

set OUT_DIR=build\desktop
set SCRIPT_DIR=%~dp0
set SRC_DIR=%SCRIPT_DIR%src
set BOX3D_DIR=%SCRIPT_DIR%extern\box3d
set RAYLIB_DIR=%SCRIPT_DIR%extern\raylib

if not exist "%OUT_DIR%" mkdir "%OUT_DIR%"

:: Build Box3D library
if not exist "%SCRIPT_DIR%build\box3d" mkdir "%SCRIPT_DIR%build\box3d"
cd "%SCRIPT_DIR%build\box3d"
cmake "%BOX3D_DIR%" -DBOX3D_SAMPLES=OFF -DBOX3D_UNIT_TESTS=OFF -DBOX3D_BENCHMARKS=OFF -DCMAKE_BUILD_TYPE=Release
if errorlevel 1 exit /b 1
cmake --build . --config Release --parallel
if errorlevel 1 exit /b 1
cd "%SCRIPT_DIR%"

:: Build Raylib 6 for desktop
if not exist "%SCRIPT_DIR%build\raylib_desktop\raylib\Release\raylib.lib" (
    if not exist "%SCRIPT_DIR%build\raylib_desktop" mkdir "%SCRIPT_DIR%build\raylib_desktop"
    cd "%SCRIPT_DIR%build\raylib_desktop"
    cmake "%RAYLIB_DIR%" -DCMAKE_BUILD_TYPE=Release -DBUILD_EXAMPLES=OFF -DBUILD_GAMES=OFF -DUSE_EXTERNAL_GLFW=OFF -DPLATFORM=Desktop
    if errorlevel 1 exit /b 1
    cmake --build . --config Release --parallel
    if errorlevel 1 exit /b 1
    cd "%SCRIPT_DIR%"
)

:: Compile Box3D bridge
cl /c "%SRC_DIR%\box3d\bridge.c" /I"%BOX3D_DIR%\include" /O2 /Fo"%OUT_DIR%\box3d_bridge.obj"
if errorlevel 1 exit /b 1

:: Copy Box3D library to package directory (for Odin foreign import)
copy /Y "%SCRIPT_DIR%build\box3d\src\Release\box3d.lib" "%SRC_DIR%\box3d\libbox3d.lib"

:: Swap in the Raylib 6 library that we built from extern/raylib
for /f "tokens=*" %%a in ('odin root') do set ODIN_ROOT=%%a
if "%ODIN_ROOT:~-1%"=="\" set ODIN_ROOT=%ODIN_ROOT:~0,-1%
copy /Y "%SCRIPT_DIR%build\raylib_desktop\raylib\Release\raylib.lib" "%ODIN_ROOT%\vendor\raylib\windows\raylib.lib"

:: Build game
odin build "%SRC_DIR%" -out:"%OUT_DIR%\game.exe" -o:speed -extra-linker-flags:"%OUT_DIR%\box3d_bridge.obj %SCRIPT_DIR%build\box3d\src\Release\box3d.lib"
if errorlevel 1 exit /b 1

echo Desktop build created in %OUT_DIR%\game.exe
