@echo off
setlocal

set OUT_DIR=build\desktop
set SRC_DIR=src
set BOX3D_DIR=extern\box3d

if not exist %OUT_DIR% mkdir %OUT_DIR%

:: Build Box3D library
if not exist build\box3d mkdir build\box3d
cd build\box3d
cmake ..\..\%BOX3D_DIR% -DBOX3D_SAMPLES=OFF -DBOX3D_TEST=OFF -DBOX3D_BENCHMARK=OFF
cmake --build . --config Release --parallel
cd ..\..

copy build\box3d\src\Release\box3d.lib %OUT_DIR%

:: Build game
odin build %SRC_DIR% -out:%OUT_DIR%\game.exe -o:speed

echo Desktop build created in %OUT_DIR%
