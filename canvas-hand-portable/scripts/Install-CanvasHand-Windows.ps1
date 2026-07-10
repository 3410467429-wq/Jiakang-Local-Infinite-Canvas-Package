param(
  [string]$PluginTarget = "$HOME\plugins\canvas-hand",
  [string]$CanvasTarget = "$HOME\.canvas-hand\canvas",
  [string]$MarketplacePath = "$HOME\.agents\plugins\marketplace.json",
  [switch]$SkipCodexInstall
)

$ErrorActionPreference = "Stop"
$PackageRoot = Split-Path -Parent $PSScriptRoot
$PluginSource = Join-Path $PackageRoot "plugin"

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

function Ensure-PersonalMarketplaceEntry($Path) {
  $parent = Split-Path -Parent $Path
  New-Item -ItemType Directory -Force -Path $parent | Out-Null

  if (Test-Path -LiteralPath $Path) {
    $marketplace = Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json
  } else {
    $marketplace = [pscustomobject]@{
      name = "personal"
      interface = [pscustomobject]@{ displayName = "Personal" }
      plugins = @()
    }
  }

  if (-not $marketplace.name) {
    $marketplace | Add-Member -NotePropertyName name -NotePropertyValue "personal" -Force
  }
  if (-not $marketplace.interface) {
    $marketplace | Add-Member -NotePropertyName interface -NotePropertyValue ([pscustomobject]@{ displayName = "Personal" }) -Force
  }

  $otherPlugins = @($marketplace.plugins | Where-Object { $_.name -ne "canvas-hand" })
  $canvasHandEntry = [pscustomobject]@{
    name = "canvas-hand"
    source = [pscustomobject]@{
      source = "local"
      path = "./plugins/canvas-hand"
    }
    policy = [pscustomobject]@{
      installation = "AVAILABLE"
      authentication = "ON_INSTALL"
    }
    category = "Productivity"
  }
  $marketplace | Add-Member -NotePropertyName plugins -NotePropertyValue @($otherPlugins + $canvasHandEntry) -Force

  if (Test-Path -LiteralPath $Path) {
    Copy-Item -LiteralPath $Path -Destination "$Path.backup-$(Get-Date -Format yyyyMMdd-HHmmss)" -Force
  }
  $tempPath = "$Path.tmp"
  $marketplace | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $tempPath -Encoding UTF8
  Move-Item -LiteralPath $tempPath -Destination $Path -Force
  return $marketplace.name
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

New-Item -ItemType Directory -Force -Path (Split-Path -Parent $PluginTarget), (Split-Path -Parent $CanvasTarget) | Out-Null
Copy-Item -LiteralPath $PluginSource -Destination $PluginTarget -Recurse -Force
New-Item -ItemType Directory -Force -Path $CanvasTarget | Out-Null

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
    $env:CI = "true"
    & $pnpm install --frozen-lockfile
    if ($LASTEXITCODE -ne 0) { throw "pnpm install failed with exit code $LASTEXITCODE." }
  } elseif ($npm) {
    & $npm install
    if ($LASTEXITCODE -ne 0) { throw "npm install failed with exit code $LASTEXITCODE." }
  } else {
    throw "No pnpm or npm was found. Dependencies could not be installed."
  }
} finally {
  Pop-Location
}

$marketplaceName = Ensure-PersonalMarketplaceEntry $MarketplacePath
$codex = Find-CommandPath "codex"
if (-not $SkipCodexInstall) {
  if ($codex) {
    & $codex plugin add "canvas-hand@$marketplaceName"
    if ($LASTEXITCODE -ne 0) {
      Write-Warning "Canvas Hand was registered in the personal marketplace, but Codex CLI could not install it automatically. Enable it from the Codex Plugins panel."
    }
  } else {
    Write-Warning "Codex CLI was not found. Canvas Hand is available in the Personal marketplace; enable it from the Codex Plugins panel."
  }
}

Write-Host ""
Write-Host "Canvas Hand installed."
Write-Host "Plugin: $PluginTarget"
Write-Host "Canvas data: $CanvasTarget"
Write-Host "Marketplace: $MarketplacePath"
Write-Host "Next: restart Codex, start a new task, then ask: Open my canvas"
