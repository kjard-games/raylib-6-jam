@echo off
setlocal

set EMSCRIPTEN_SDK_DIR=c:\SDK\emsdk
set OUT_DIR=build\web
set SRC_DIR=src
set BOX3D_DIR=extern\box3d

if not exist %OUT_DIR% mkdir %OUT_DIR%

set EMSDK_QUIET=1
call %EMSCRIPTEN_SDK_DIR%\emsdk_env.bat

:: Build Box3D for wasm
if not exist build\box3d_wasm mkdir build\box3d_wasm
cd build\box3d_wasm
emcmake cmake ..\..\%BOX3D_DIR% -DBOX3D_SAMPLES=OFF -DBOX3D_TEST=OFF -DBOX3D_BENCHMARK=OFF -DBOX3D_DISABLE_SIMD=ON
if %ERRORLEVEL% neq 0 exit /b 1
emmake cmake --build . --config Release --parallel
if %ERRORLEVEL% neq 0 exit /b 1
cd ..\..

:: Build Box3D bridge for wasm
emcc -c %SRC_DIR%\box3d\bridge.c -I%BOX3D_DIR%\include -O2 -o %OUT_DIR%\box3d_bridge.wasm.o
if %ERRORLEVEL% neq 0 exit /b 1

:: Build Odin code for wasm
odin build %SRC_DIR%\main_web -target:js_wasm32 -build-mode:obj -define:RAYLIB_WASM_LIB=env.o -out:%OUT_DIR%\game.wasm.o
if %ERRORLEVEL% neq 0 exit /b 1

for /f "delims=" %%i in ('odin root') do set "ODIN_PATH=%%i"
copy "%ODIN_PATH%\core\sys\wasm\js\odin.js" "%OUT_DIR%"

set files=%OUT_DIR%\game.wasm.o %OUT_DIR%\box3d_bridge.wasm.o build\box3d_wasm\src\libbox3d.a "%ODIN_PATH%\vendor\raylib\wasm\libraylib.a"

set flags=-sUSE_GLFW=3 -sWASM_BIGINT -sWARN_ON_UNDEFINED_SYMBOLS=0 -sASSERTIONS -sALLOW_MEMORY_GROWTH=1 -sINITIAL_HEAP=33554432 -sSTACK_SIZE=65536 --shell-file %SRC_DIR%\main_web\index_template.html --preload-file assets

cmd /c emcc -o %OUT_DIR%\index.html %files% %flags%

del %OUT_DIR%\game.wasm.o %OUT_DIR%\box3d_bridge.wasm.o

echo Web build created in %OUT_DIR%
