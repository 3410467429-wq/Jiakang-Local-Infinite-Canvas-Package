# Canvas Hand Portable

Canvas Hand Portable 是一个可迁移的本地无限画布包，适合在 Codex 中进行图片生成、图片标注和基于箭头批注的图片重绘。

本仓库/压缩包包含：

- `plugin/`：Canvas Hand 的 Codex 插件源码
- `canvas-data/`：空的数据目录占位；真实画布默认只保存在用户电脑中
- `scripts/Install-CanvasHand-Windows.ps1`：Windows 一键安装脚本
- `scripts/Start-CanvasHand-Windows.ps1`：手动启动画布服务脚本

## 功能

- 在 Codex 侧边栏打开本地画布
- 将生成图片放到画布上
- 在画布上用箭头和文字标注修改意见
- 让 Codex 读取标注并生成修改后的新图片
- 画布数据保存在本地，可迁移到其他电脑

## 环境要求

- Windows
- PowerShell
- Node.js 20+，或 Codex 自带的 Node.js 运行时
- 首次安装依赖时需要网络
- Codex Desktop，用于插件能力和 in-app browser 打开画布

## 方式一：让 Codex 帮你安装

在新电脑的 Codex 中直接输入：

```text
请帮我安装这个 GitHub 仓库里的 Canvas Hand 插件：
https://github.com/3410467429-wq/AI---

要求：
1. 克隆仓库
2. 运行 scripts/Install-CanvasHand-Windows.ps1
3. 安装完成后启动画布服务
4. 打开 http://127.0.0.1:8000/
```

如果你使用的是 zip 文件，可以输入：

```text
请帮我安装这个压缩包里的 Canvas Hand 插件：
C:\Users\你的用户名\Downloads\canvas-hand-portable.zip

解压后运行 scripts/Install-CanvasHand-Windows.ps1，然后打开我的 canvas。
```

## 方式二：从 GitHub 手动安装

```powershell
git clone https://github.com/3410467429-wq/AI---.git
cd AI---\canvas-hand-portable
Set-ExecutionPolicy -Scope Process Bypass
.\scripts\Install-CanvasHand-Windows.ps1
```

安装完成后重启 Codex，然后在 Codex 中输入：

```text
Open my canvas
```

## 方式三：从 zip 手动安装

1. 解压 zip 到任意普通目录，例如：

```text
C:\Users\你的用户名\Downloads\canvas-hand-portable
```

2. 在解压后的目录打开 PowerShell。

3. 运行：

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\scripts\Install-CanvasHand-Windows.ps1
```

4. 重启 Codex，然后输入：

```text
Open my canvas
```

## 安装后文件位置

安装脚本默认会复制到：

```text
%USERPROFILE%\plugins\canvas-hand
%USERPROFILE%\.canvas-hand\canvas
%USERPROFILE%\.agents\plugins\marketplace.json
```

安装脚本会备份旧插件、保留已有画布数据，并把 Canvas Hand 注册到 Personal marketplace。若当前环境支持 `codex plugin add`，脚本还会尝试自动安装；否则请在 Codex 的 Plugins 面板中启用 Canvas Hand。

完成后重启 Codex，并新建一个任务，让新的 skill 和 MCP 工具被完整加载。

## 手动启动画布服务

如果只想打开画布网页，不使用 Codex 插件能力，可以运行：

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\scripts\Start-CanvasHand-Windows.ps1
```

然后在浏览器打开：

```text
http://127.0.0.1:8000/
```

画布服务默认使用端口 `8000`。Canvas Hand 的 Codex 工具也默认连接这个端口，因此不要随意改成其他端口。

## 数据与隐私

真实画布默认保存在 `%USERPROFILE%\.canvas-hand\canvas`，不会随便携包发布。仓库的 `.gitignore` 会忽略 `canvas-data/` 下的画布快照、标注图和生成图片。

请勿强制提交 `canvas.json`、`marked.png` 或其他画布文件；这些文件可能包含嵌入图片、原始文件名和私人标注。

## 本地开发

```powershell
cd plugin
npm install
npm run dev
```

提交前执行：

```powershell
npm run build
```

## 常见问题

### 安装后 Codex 还是打不开画布

先重启 Codex，再输入：

```text
Open my canvas
```

如果仍然失败，手动运行：

```powershell
.\scripts\Start-CanvasHand-Windows.ps1
```

确认 `http://127.0.0.1:8000/` 能打开。

### PowerShell 提示脚本不能运行

在当前 PowerShell 窗口运行：

```powershell
Set-ExecutionPolicy -Scope Process Bypass
```

然后重新执行安装脚本。

### 提示找不到 Node.js

安装 Node.js 20+，或先打开 Codex 让它准备好自带运行时后再执行安装。

### 画布数据在哪里

默认位置为：

```text
%USERPROFILE%\.canvas-hand\canvas
```

迁移画布时请在 Canvas Hand 服务停止后复制这个目录，不要把个人画布提交到公开仓库。

## License

MIT
