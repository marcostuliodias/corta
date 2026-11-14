import { Container, getContainer } from "@cloudflare/containers";

interface Env {
  DOWNLOADER: DurableObjectNamespace<Downloader>;
  ASSETS: Fetcher;
  ACCESS_KEY: string; // senha de acesso (wrangler secret put ACCESS_KEY)
  YTDLP_COOKIES?: string; // opcional: cookies.txt para Instagram/Stories (wrangler secret put YTDLP_COOKIES)
}

// Container com yt-dlp + ffmpeg. Dorme sozinho depois de 10 min sem uso.
export class Downloader extends Container<Env> {
  defaultPort = 8080;
  sleepAfter = "10m";

  constructor(ctx: DurableObjectState<{}>, env: Env) {
    super(ctx, env);
    this.envVars = { YTDLP_COOKIES: env.YTDLP_COOKIES ?? "" };
  }
}

function sameKey(a: string, b: string): boolean {
  const enc = new TextEncoder();
  const x = enc.encode(a);
  const y = enc.encode(b);
  if (x.length !== y.length) return false;
  let diff = 0;
  for (let i = 0; i < x.length; i++) diff |= x[i] ^ y[i];
  return diff === 0;
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);
    if (!url.pathname.startsWith("/api/")) return env.ASSETS.fetch(request);

    const key = request.headers.get("x-key") ?? url.searchParams.get("key") ?? "";
    if (!env.ACCESS_KEY || !sameKey(key, env.ACCESS_KEY)) {
      return Response.json({ error: "Senha incorreta." }, { status: 401 });
    }

    // /api/start -> /start, /api/status/ID -> /status/ID, /api/file/ID -> /file/ID
    const target = new URL(request.url);
    target.pathname = url.pathname.slice(4);
    target.searchParams.delete("key");

    // Uma única instância atende tudo (uso pessoal).
    const container = getContainer(env.DOWNLOADER, "main");
    return container.fetch(new Request(target, request));
  },
} satisfies ExportedHandler<Env>;
