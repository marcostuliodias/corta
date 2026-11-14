// Servidor dentro do container: recebe o link, roda o yt-dlp num diretório
// temporário, entrega o arquivo e apaga tudo em seguida. Nada fica salvo.
import http from "node:http";
import { spawn } from "node:child_process";
import { createReadStream } from "node:fs";
import { mkdtemp, readdir, readFile, rm, stat } from "node:fs/promises";
import { existsSync } from "node:fs";
import { tmpdir } from "node:os";
import path from "node:path";
import { randomUUID, timingSafeEqual } from "node:crypto";

const PORT = Number(process.env.PORT || 8080);
const TTL_MS = 30 * 60 * 1000;
const jobs = new Map(); // id -> { state, percent, error, dir, file, created }

const ACCESS_KEY = process.env.ACCESS_KEY || "";
if (!ACCESS_KEY) { console.error("Defina ACCESS_KEY (a senha de acesso)."); process.exit(1); }
const INDEX_HTML = await readFile(new URL("./public/index.html", import.meta.url));

// cookies opcionais (Instagram/Stories, YouTube): coloque em ./cookies/cookies.txt
const COOKIES_PATH = "/data/cookies.txt";
const cookiesFile = existsSync(COOKIES_PATH) ? COOKIES_PATH : null;

// trava simples contra tentativas de senha: 10 erros por IP a cada 15 min
const fails = new Map();
function clientIp(req) { return (req.headers["x-forwarded-for"] || req.socket.remoteAddress || "").split(",")[0].trim(); }
function keyOk(req, url) {
  const ip = clientIp(req);
  const now = Date.now();
  const f = (fails.get(ip) || []).filter((t) => now - t < 15 * 60_000);
  if (f.length >= 10) return "limit";
  const given = String(req.headers["x-key"] || url.searchParams.get("key") || "");
  const a = Buffer.from(given), b = Buffer.from(ACCESS_KEY);
  if (a.length === b.length && timingSafeEqual(a, b)) return true;
  fails.set(ip, [...f, now]);
  return false;
}

function json(res, code, body) {
  res.writeHead(code, { "content-type": "application/json" });
  res.end(JSON.stringify(body));
}

function readBody(req) {
  return new Promise((resolve, reject) => {
    let data = "";
    req.on("data", (c) => {
      data += c;
      if (data.length > 10_000) reject(new Error("corpo grande demais"));
    });
    req.on("end", () => resolve(data));
    req.on("error", reject);
  });
}

function ytdlpArgs(url, mode, dir) {
  const args = [
    "--no-playlist",
    "--newline",
    "--no-colors",
    "--windows-filenames",
    "--js-runtimes", "node",
    "--progress-template", "download:PROGRESS %(progress._percent_str)s",
    "-o", path.join(dir, "%(title).120B.%(ext)s"),
  ];
  if (cookiesFile) args.push("--cookies", cookiesFile);
  if (mode === "mp3") {
    args.push("-x", "--audio-format", "mp3", "--audio-quality", "0");
  } else {
    // melhor qualidade, preferindo H.264 (abre em qualquer lugar)
    args.push("-S", "vcodec:h264,res,acc", "-f", "bv*+ba/b", "--merge-output-format", "mp4");
  }
  args.push("--", url);
  return args;
}

async function startJob(url, mode) {
  const id = randomUUID();
  const dir = await mkdtemp(path.join(tmpdir(), "dl-"));
  const job = { state: "running", percent: 0, error: null, dir, file: null, created: Date.now() };
  jobs.set(id, job);

  const p = spawn("yt-dlp", ytdlpArgs(url, mode, dir));
  let tail = [];
  const onLine = (line) => {
    const m = line.match(/^PROGRESS\s+([\d.]+)%/);
    if (m) job.percent = Math.min(99, Number(m[1]));
    else if (line.trim()) tail = [...tail.slice(-9), line.trim()];
  };
  for (const stream of [p.stdout, p.stderr]) {
    let buf = "";
    stream.on("data", (c) => {
      buf += c;
      const lines = buf.split("\n");
      buf = lines.pop();
      lines.forEach(onLine);
    });
  }
  p.on("error", (e) => {
    job.state = "error";
    job.error = "Falha ao iniciar o yt-dlp: " + e.message;
  });
  p.on("close", async (code) => {
    if (job.state === "error") return;
    try {
      const files = (await readdir(dir)).filter((f) => !/\.(part|ytdl|temp)$/i.test(f));
      let best = null;
      for (const f of files) {
        const s = await stat(path.join(dir, f));
        if (!best || s.size > best.size) best = { name: f, size: s.size };
      }
      if (code === 0 && best) {
        job.file = best;
        job.percent = 100;
        job.state = "done";
      } else {
        job.state = "error";
        const errs = tail.filter((l) => /error/i.test(l));
        job.error = (errs.at(-1) || tail.at(-1) || `yt-dlp terminou com código ${code}`).slice(0, 400);
      }
    } catch (e) {
      job.state = "error";
      job.error = e.message;
    }
  });
  return id;
}

async function dropJob(id) {
  const job = jobs.get(id);
  if (!job) return;
  jobs.delete(id);
  await rm(job.dir, { recursive: true, force: true });
}

setInterval(() => {
  for (const [id, job] of jobs) if (Date.now() - job.created > TTL_MS) dropJob(id);
}, 60_000).unref();

const server = http.createServer(async (req, res) => {
  try {
    const url = new URL(req.url, "http://x");

    if (req.method === "GET" && (url.pathname === "/" || url.pathname === "/index.html")) {
      res.writeHead(200, { "content-type": "text/html; charset=utf-8", "cache-control": "no-store" });
      return res.end(INDEX_HTML);
    }
    if (!url.pathname.startsWith("/api/")) return json(res, 404, { error: "Não encontrado." });

    const ok = keyOk(req, url);
    if (ok === "limit") return json(res, 429, { error: "Muitas tentativas. Espere 15 minutos." });
    if (!ok) return json(res, 401, { error: "Senha incorreta." });

    const apiPath = url.pathname.slice(4); // /api/start -> /start
    const parts = apiPath.split("/").filter(Boolean);

    if (req.method === "POST" && apiPath === "/start") {
      const { url: link, mode } = JSON.parse((await readBody(req)) || "{}");
      let u;
      try { u = new URL(link); } catch { return json(res, 400, { error: "Link inválido." }); }
      if (!/^https?:$/.test(u.protocol)) return json(res, 400, { error: "Link inválido." });
      const id = await startJob(u.href, mode === "mp3" ? "mp3" : "mp4");
      return json(res, 200, { id });
    }

    if (req.method === "GET" && parts[0] === "status" && parts[1]) {
      const job = jobs.get(parts[1]);
      if (!job) return json(res, 404, { error: "Download não encontrado." });
      return json(res, 200, {
        state: job.state,
        percent: job.percent,
        error: job.error,
        filename: job.file?.name ?? null,
        size: job.file?.size ?? null,
      });
    }

    if (req.method === "GET" && parts[0] === "file" && parts[1]) {
      const id = parts[1];
      const job = jobs.get(id);
      if (!job || job.state !== "done") return json(res, 404, { error: "Arquivo não está pronto." });
      const name = job.file.name;
      res.writeHead(200, {
        "content-type": "application/octet-stream",
        "content-length": job.file.size,
        "content-disposition": `attachment; filename*=UTF-8''${encodeURIComponent(name)}`,
      });
      const stream = createReadStream(path.join(job.dir, name));
      stream.pipe(res);
      res.on("close", () => dropJob(id)); // apagou depois de enviar
      return;
    }

    json(res, 404, { error: "Não encontrado." });
  } catch (e) {
    json(res, 500, { error: e.message });
  }
});

server.listen(PORT, "0.0.0.0", () => console.log("baixador no ar na porta", PORT));
