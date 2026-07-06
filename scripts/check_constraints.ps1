# Enforce project constraints on Windows.
param([string]$Target = "desktop")

$ErrorActionPreference = "Stop"

function Fail($message) {
    Write-Error "ERROR: $message"
    exit 1
}

$odinVersion = & odin version
if ($odinVersion -notlike "*dev-2026-07*") {
    Fail "Expected Odin dev-2026-07, got: $odinVersion"
}

$odinRoot = & odin root
$raylibFile = Join-Path $odinRoot "vendor\raylib\raylib.odin"
$raylibMatch = Select-String -Path $raylibFile -Pattern 'VERSION\s+::\s+"([^"]+)"' | Select-Object -First 1
if (-not $raylibMatch -or $raylibMatch.Matches.Groups[1].Value -ne "6.0") {
    Fail "Expected raylib 6.0, got: $($raylibMatch.Matches.Groups[1].Value)"
}

if (-not (Select-String -Path "src\game.odin" -Pattern '^WIDTH\s+::\s+720')) {
    Fail "WIDTH must be 720 in src/game.odin"
}
if (-not (Select-String -Path "src\game.odin" -Pattern '^HEIGHT\s+::\s+720')) {
    Fail "HEIGHT must be 720 in src/game.odin"
}

if (-not (Test-Path "extern\box3d\include\box3d\box3d.h")) {
    Fail "extern/box3d submodule is missing"
}

if ($Target -eq "web") {
    if (-not (Test-Path "build\web\index.wasm")) {
        Fail "build/web/index.wasm is missing"
    }
    $wasmSize = (Get-Item "build\web\index.wasm").Length
    $dataSize = if (Test-Path "build\web\index.data") { (Get-Item "build\web\index.data").Length } else { 0 }
    $total = $wasmSize + $dataSize
    $max = 64 * 1024 * 1024
    Write-Host "Web package size: $total bytes (max $max bytes)"
    if ($total -gt $max) {
        Fail "wasm + data exceeds 64 MiB"
    }
} else {
    if (-not (Test-Path "build\desktop\game.exe")) {
        Fail "build/desktop/game.exe is missing"
    }
}

Write-Host "All constraint checks passed for $Target"
