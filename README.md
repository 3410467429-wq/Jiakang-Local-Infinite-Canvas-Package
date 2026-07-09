# AI---
# Canvas Hand Portable

Canvas Hand Portable 是一个可迁移的本地无限画布包，适合在 Codex 中进行图片生成、图片标注和基于箭头批注的图片重绘。

本仓库/压缩包包含：

- `plugin/`：Canvas Hand 的 Codex 插件源码
- `canvas-data/`：当前导出的画布数据
- `scripts/Install-CanvasHand-Windows.ps1`：Windows 一键安装脚本
- `scripts/Start-CanvasHand-Windows.ps1`：手动启动画布服务脚本

## 功能

- 在 Codex 侧边栏打开本地画布
- 将生成图片放到画布上
- 在画布上用箭头和文字标注修改意见
- 让 Codex 读取标注并生成修改后的新图片
- 画布数据保存在本地，可迁移到其他电脑
## 安装
Codex安装
```text
请帮我安装这个 GitHub 仓库里的 Canvas Hand 插件：
https://github.com/3410467429-wq/AI---

要求：
1. 克隆仓库
2. 运行 scripts/Install-CanvasHand-Windows.ps1
3. 安装完成后启动画布服务
4. 打开 http://127.0.0.1:8000/
```

重启 Codex，在 Codex 里说：

```text
Open my canvas
```
后面可以正常使用

另一种安装方式

1. 解压到任意普通目录，例如：

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
```

如果目标电脑上已经存在同名目录，安装脚本会先备份旧目录，再写入新文件。

