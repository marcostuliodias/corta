# Baixador

Uma barra para colar o link, baixar e pronto. Nada fica salvo: o arquivo é apagado do servidor assim que o download termina. Uso pessoal, protegido por senha.

Roda na sua própria VPS (Hostinger ou qualquer outra) com Docker. Funciona com YouTube, Shorts, Reels, TikTok e os outros sites que o yt-dlp suporta.

## Instalar na VPS (uma vez)

**1. Docker na VPS.** No painel da Hostinger, ao criar ou reinstalar a VPS, escolha o sistema "Ubuntu com Docker". Se já tem uma VPS com Ubuntu: `curl -fsSL https://get.docker.com | sh`.

**2. (Recomendado) Um endereço com HTTPS.** Aponte um subdomínio para o IP da VPS, criando um registro **A** no DNS (ex.: `baixar.seudominio.com` -> IP da VPS). O HTTPS é automático e gratuito. Sem domínio também funciona, por `http://IP-DA-VPS`, mas a senha viaja sem criptografia.

**3. Baixar e ligar.** Conecte por SSH (`ssh root@IP-DA-VPS`) e rode:

```bash
git clone -b claude/laughing-cori-imyiza https://github.com/marcostuliodias/corta.git
cd corta/downloader
cp .env.example .env
nano .env                 # troque ACCESS_KEY e, se tiver, DOMAIN
docker compose up -d --build
```

Abra o endereço no navegador, digite a senha e use. Se o repositório for privado, o `git clone` pede login do GitHub (use um token de acesso).

## Stories e conteúdo que exige login (Instagram etc.)

Exporte os cookies do navegador no formato Netscape (extensão "Get cookies.txt LOCALLY") e salve na VPS como `cookies/cookies.txt`, dentro da pasta `downloader`. Depois: `docker compose restart baixador`. Use uma conta secundária se puder. Nunca suba esse arquivo no GitHub (já está no `.gitignore`).

## Manutenção

- **Parou de funcionar num site?** O yt-dlp é atualizado quase toda semana:
  ```bash
  cd corta/downloader && docker compose build --no-cache baixador && docker compose up -d
  ```
- **YouTube pedindo "confirme que você não é um robô":** IPs de VPS são bloqueados com frequência. Colocar os cookies do YouTube em `cookies/cookies.txt` costuma resolver.
- **Ver erros:** `docker compose logs -f baixador`
- **Desligar:** `docker compose down`

## Segurança

Só a senha protege o acesso. Use uma senha longa. Após 10 tentativas erradas, o IP fica bloqueado por 15 minutos. Baixe apenas conteúdo seu ou que você tem permissão para baixar.
