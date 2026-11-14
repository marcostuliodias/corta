FROM node:22-bookworm-slim

RUN apt-get update \
 && apt-get install -y --no-install-recommends ffmpeg curl ca-certificates \
 && rm -rf /var/lib/apt/lists/*

# yt-dlp na última versão (para atualizar: docker compose build --no-cache)
RUN curl -fsSL https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp_linux \
      -o /usr/local/bin/yt-dlp \
 && chmod +x /usr/local/bin/yt-dlp

WORKDIR /app
COPY server.mjs .
COPY public ./public
ENV PORT=8080
USER node
EXPOSE 8080
CMD ["node", "server.mjs"]
