# Baixador

Uma barra para colar o link, baixar e pronto. Nada fica salvo: o arquivo é apagado do servidor assim que o download termina.

- **Tela + senha:** Cloudflare Worker (`src/index.ts`, `public/index.html`)
- **Motor:** container com yt-dlp + ffmpeg (`container/`), via Cloudflare Containers
- Funciona com YouTube, Shorts, Reels, TikTok e os outros sites que o yt-dlp suporta.

## Publicar (uma vez)

Pré-requisitos: conta Cloudflare com plano **Workers Paid** (Containers exige), Node 20+ e **Docker Desktop aberto** (o wrangler monta a imagem no seu computador).

```bash
cd downloader
npm install
npx wrangler login
npx wrangler secret put ACCESS_KEY      # a senha que você vai digitar na tela
npx wrangler deploy
```

O deploy mostra o endereço (`https://baixador.<sua-conta>.workers.dev`). Na primeira vez a Cloudflare leva alguns minutos para preparar o container. Depois abra o endereço, digite a senha e use.

## Stories e conteúdo que exige login (Instagram etc.)

Stories só baixam com você logado. Exporte os cookies do navegador no formato Netscape (extensão "Get cookies.txt LOCALLY") e salve:

```bash
npx wrangler secret put YTDLP_COOKIES < cookies.txt
```

Use uma conta secundária se possível: as plataformas podem limitar contas usadas assim. `cookies.txt` já está no `.gitignore`; nunca o suba no GitHub.

## Manutenção

- **Parou de funcionar num site?** O yt-dlp é atualizado quase toda semana. Rode `npx wrangler deploy` de novo: a imagem é refeita com a versão mais nova.
- **YouTube pedindo "confirme que você não é um robô":** IPs de datacenter são bloqueados com frequência. Colocar cookies do YouTube em `YTDLP_COOKIES` costuma resolver; se não, só com proxy residencial.
- O container dorme sozinho após 10 min sem uso (você só paga enquanto está ligado).

## Testar localmente sem Cloudflare

Com `yt-dlp` e `ffmpeg` instalados: `node container/server.mjs` sobe o motor na porta 8080 (`POST /start`, `GET /status/:id`, `GET /file/:id`).
