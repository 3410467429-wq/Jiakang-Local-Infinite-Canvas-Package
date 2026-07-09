# Canvas Hand Portable Package

This package contains:

- `plugin/` - the Canvas Hand Codex plugin source.
- `canvas-data/` - the exported canvas data from this computer.
- `scripts/Install-CanvasHand-Windows.ps1` - installs the plugin and canvas data on another Windows computer.
- `scripts/Start-CanvasHand-Windows.ps1` - starts the canvas web app manually on port `8000`.

## Install On Another Windows Computer

1. Unzip this folder.
2. Open PowerShell in the unzipped folder.
3. Run:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\scripts\Install-CanvasHand-Windows.ps1
```

The installer copies:

- plugin to `%USERPROFILE%\plugins\canvas-hand`
- canvas data to `%USERPROFILE%\.canvas-hand\canvas`

It also rewrites `plugin\.mcp.json` to use the Node.js path available on the new computer.

After installation, restart Codex and ask:

```text
Open my canvas
```

## Manual Start

If you only want to run the canvas web app without Codex integration:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\scripts\Start-CanvasHand-Windows.ps1
```

Then open:

```text
http://127.0.0.1:8000/
```

## Requirements

- Windows PowerShell.
- Node.js 20+ or Codex's bundled Node runtime.
- Internet access for the first dependency install unless `node_modules` is already installed on the target machine.

