param(
  [string]$PluginDir = "$HOME\plugins\canvas-hand",
  [string]$CanvasDir = "$HOME\.canvas-hand\canvas",
  [int]$Port = 8000
)

$ErrorActionPreference = "Stop"

function Find-CommandPath($Name) {
  $cmd = Get-Command $Name -ErrorAction SilentlyContinue
  if ($cmd) { return $cmd.Source }
  return $null
}

$PackagePlugin = Join-Path (Split-Path -Parent $PSScriptRoot) "plugin"
if (Test-Path -LiteralPath $PackagePlugin) {
  $PluginDir = $PackagePlugin
}

$CodexNodeBin = Join-Path $HOME ".cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin"
$CodexPnpm = Join-Path $HOME ".cache\codex-runtimes\codex-primary-runtime\dependencies\bin\pnpm.cmd"
if (Test-Path -LiteralPath $CodexNodeBin) {
  $env:PATH = "$CodexNodeBin;$env:PATH"
}

$pnpm = if (Test-Path -LiteralPath $CodexPnpm) { $CodexPnpm } else { Find-CommandPath "pnpm" }
$npm = Find-CommandPath "npm"

if (-not (Test-Path -LiteralPath $PluginDir)) {
  throw "Plugin directory was not found: $PluginDir"
}

New-Item -ItemType Directory -Force -Path $CanvasDir | Out-Null
$env:CANVAS_HAND_CANVAS_DIR = $CanvasDir
$env:CANVAS_HAND_PORT = "$Port"

Push-Location $PluginDir
try {
  if (-not (Test-Path -LiteralPath (Join-Path $PluginDir "node_modules"))) {
    if ($pnpm) {
      & $pnpm install --frozen-lockfile
    } elseif ($npm) {
      & $npm install
    } else {
      throw "No pnpm or npm was found, and node_modules is missing."
    }
  }

  Write-Host "Canvas Hand: http://127.0.0.1:$Port"
  if ($pnpm) {
    & $pnpm run dev -- --host 127.0.0.1 --port $Port
  } elseif ($npm) {
    & $npm run dev -- --host 127.0.0.1 --port $Port
  } else {
    throw "No pnpm or npm was found."
  }
} finally {
  Pop-Location
}

