param(
  [string]$PluginTarget = "$HOME\plugins\canvas-hand",
  [string]$CanvasTarget = "$HOME\.canvas-hand\canvas"
)

$ErrorActionPreference = "Stop"
$PackageRoot = Split-Path -Parent $PSScriptRoot
$PluginSource = Join-Path $PackageRoot "plugin"
$CanvasSource = Join-Path $PackageRoot "canvas-data"

function Backup-IfExists($Path) {
  if (Test-Path -LiteralPath $Path) {
    $backup = "$Path.backup-$(Get-Date -Format yyyyMMdd-HHmmss)"
    Move-Item -LiteralPath $Path -Destination $backup
    Write-Host "Backed up existing path: $backup"
  }
}

function Find-CommandPath($Name) {
  $cmd = Get-Command $Name -ErrorAction SilentlyContinue
  if ($cmd) { return $cmd.Source }
  return $null
}

$CodexNode = Join-Path $HOME ".cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe"
$CodexPnpm = Join-Path $HOME ".cache\codex-runtimes\codex-primary-runtime\dependencies\bin\pnpm.cmd"

$node = if (Test-Path -LiteralPath $CodexNode) { $CodexNode } else { Find-CommandPath "node" }
$pnpm = if (Test-Path -LiteralPath $CodexPnpm) { $CodexPnpm } else { Find-CommandPath "pnpm" }
$npm = Find-CommandPath "npm"

if (-not $node) {
  throw "Node.js was not found. Install Node.js 20+ or run this after Codex has installed its bundled runtime."
}

Backup-IfExists $PluginTarget
Backup-IfExists $CanvasTarget

New-Item -ItemType Directory -Force -Path (Split-Path -Parent $PluginTarget), (Split-Path -Parent $CanvasTarget) | Out-Null
Copy-Item -LiteralPath $PluginSource -Destination $PluginTarget -Recurse -Force
Copy-Item -LiteralPath $CanvasSource -Destination $CanvasTarget -Recurse -Force

$mcp = @{
  mcpServers = @{
    "canvas-hand" = @{
      command = $node
      args = @("./mcp/hello-server.mjs")
      cwd = "."
    }
  }
}
$mcpPath = Join-Path $PluginTarget ".mcp.json"
$mcp | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $mcpPath -Encoding UTF8

Push-Location $PluginTarget
try {
  if ($pnpm) {
    & $pnpm install --frozen-lockfile
  } elseif ($npm) {
    & $npm install
  } else {
    Write-Warning "No pnpm or npm was found. Dependencies were not installed."
  }
} finally {
  Pop-Location
}

Write-Host ""
Write-Host "Canvas Hand installed."
Write-Host "Plugin: $PluginTarget"
Write-Host "Canvas data: $CanvasTarget"
Write-Host "Next: restart Codex, then ask: Open my canvas"

