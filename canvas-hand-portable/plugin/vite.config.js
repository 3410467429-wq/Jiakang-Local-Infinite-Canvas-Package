import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import fs from "node:fs";
import path from "node:path";

// 画布数据存哪：默认存进固定目录 ~/.canvas-hand/canvas（一个画布、反复用，对小白最省心，
// 不跟 codex 对话的项目跑）。仍可用环境变量覆盖到别处。
import os from "node:os";
const DEFAULT_CANVAS_DIR = path.join(os.homedir(), ".canvas-hand", "canvas");
const canvasDir = path.resolve(
  process.env.CANVAS_HAND_CANVAS_DIR ??
    (process.env.CANVAS_HAND_PROJECT_DIR
      ? path.join(process.env.CANVAS_HAND_PROJECT_DIR, "canvas")
      : DEFAULT_CANVAS_DIR)
);
const CANVAS_FILE = path.join(canvasDir, "canvas.json");
// 带箭头标记的导出图，固定存这张，每轮覆盖（AI 处理完就不要了，不留历史）
const MARKED_PNG = path.join(canvasDir, "marked.png");
const MAX_CANVAS_BYTES = 64 * 1024 * 1024;
const MAX_MARKED_IMAGE_BYTES = 64 * 1024 * 1024;

function readRequestBody(req, res, maxBytes, onComplete) {
  const chunks = [];
  let size = 0;
  let rejected = false;
  req.on("data", (chunk) => {
    if (rejected) return;
    size += chunk.length;
    if (size > maxBytes) {
      rejected = true;
      res.statusCode = 413;
      res.end("请求内容过大");
      return;
    }
    chunks.push(chunk);
  });
  req.on("end", () => {
    if (!rejected) onComplete(Buffer.concat(chunks));
  });
  req.on("error", (error) => {
    if (res.writableEnded) return;
    res.statusCode = 400;
    res.end(`读取请求失败：${error.message}`);
  });
}

function writeFileAtomic(filePath, data) {
  fs.mkdirSync(path.dirname(filePath), { recursive: true });
  const tempPath = `${filePath}.${process.pid}.${Date.now()}.tmp`;
  try {
    fs.writeFileSync(tempPath, data);
    try {
      fs.renameSync(tempPath, filePath);
    } catch {
      // Windows 某些文件系统不允许 rename 覆盖现有文件。
      fs.rmSync(filePath, { force: true });
      fs.renameSync(tempPath, filePath);
    }
  } finally {
    fs.rmSync(tempPath, { force: true });
  }
}

// 这就是“教服务员新活”的地方：一个 Vite 插件，给服务员加“耳朵”
function canvasStoragePlugin() {
  return {
    name: "canvas-storage",
    configureServer(server) {
      // 给服务员加一只耳朵，专门听所有 /api/* 的请求
      server.middlewares.use((req, res, next) => {
        // —— 活儿①：保存。听到 “POST /api/save” 就干 ——
        if (req.method === "POST" && req.url === "/api/save") {
          readRequestBody(req, res, MAX_CANVAS_BYTES, (buffer) => {
            try {
              const body = buffer.toString("utf8");
              JSON.parse(body); // 不让损坏或不完整的 JSON 覆盖正常画布。
              writeFileAtomic(CANVAS_FILE, body);
              res.statusCode = 200;
              res.end("已存盘");
            } catch (error) {
              res.statusCode = 400;
              res.end(`画布数据无效：${error.message}`);
            }
          });
          return; // 这活接了，不往下传
        }

        // —— 活儿③：接“带箭头标记的 PNG”。听到 “POST /api/save-png” 就干 ——
        // 跟上面 /api/save 几乎一样，唯一不同：收到的是 base64 文字，写盘前要转回二进制
        if (req.method === "POST" && req.url === "/api/save-png") {
          readRequestBody(req, res, MAX_MARKED_IMAGE_BYTES, (buffer) => {
            try {
              const body = buffer.toString("utf8");
              if (!body.startsWith("data:image/png;base64,")) throw new Error("只接受 PNG data URL");
              const base64 = body.slice(body.indexOf(",") + 1);
              writeFileAtomic(MARKED_PNG, Buffer.from(base64, "base64"));
              res.statusCode = 200;
              res.end("已存图");
            } catch (error) {
              res.statusCode = 400;
              res.end(`标注图片无效：${error.message}`);
            }
          });
          return;
        }

        // —— 活儿②：读取。听到 “GET /api/load” 就干（你拍的决策：GET=前端来取东西）——
        if (req.method === "GET" && req.url === "/api/load") {
          // 首次没有 canvas.json（干净环境/空画布）→ 回一个空对象，别崩。
          // 前端收到空对象会跳过加载、用 tldraw 默认空画布；MCP 收到会兜底成空 store。
          if (!fs.existsSync(CANVAS_FILE)) {
            res.statusCode = 200;
            res.setHeader("content-type", "application/json");
            res.end("{}");
            return;
          }
          const data = fs.readFileSync(CANVAS_FILE, "utf-8"); // 从磁盘把画读出来
          res.statusCode = 200;
          res.end(data); // 把读到的内容原样回给前端
          return;
        }

        // —— 活儿④：把标注截图(marked.png)读成 base64 回给调用方 ——
        // 给 MCP 用：MCP 不再自己开文件，改成来这儿要（走 HTTP，碰文件的只剩后端一只手）
        if (req.method === "GET" && req.url === "/api/marked") {
          if (!fs.existsSync(MARKED_PNG)) {
            res.statusCode = 404;
            res.end(JSON.stringify({ error: "marked.png 不存在" }));
            return;
          }
          const base64 = fs.readFileSync(MARKED_PNG).toString("base64");
          res.statusCode = 200;
          res.setHeader("content-type", "application/json");
          res.end(JSON.stringify({ base64 }));
          return;
        }

        next(); // 不是我管的请求，交给下一个处理（比如正常递网页）
      });
    },
  };
}

export default defineConfig({
  plugins: [react(), canvasStoragePlugin()], // 把这项新活挂到服务员身上
  server: {
    host: "127.0.0.1",
    port: Number(process.env.CANVAS_HAND_PORT ?? 8000),
  },
});
