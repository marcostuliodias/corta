#!/bin/bash
# Atualiza o que costuma quebrar com o tempo (o yt-dlp, quando os sites mudam) e
# acerta as bibliotecas depois que o plugin foi atualizado.
# Última linha: ATUALIZADO | ERRO_<motivo>
set -uo pipefail
source "$(dirname "$0")/comum.sh"

LOG="$LOGS/instalacao.log"
echo "=== $(date '+%Y-%m-%d %H:%M:%S') atualizar.sh" >>"$LOG"
export HOMEBREW_NO_ENV_HINTS=1 HOMEBREW_NO_INSTALL_CLEANUP=1

if [ ! -x "$BREW" ]; then
  echo "O Homebrew não está instalado. Rode a instalação do Corta primeiro."
  echo "ERRO_FALTA_HOMEBREW"
  exit 10
fi

antes="$(yt-dlp --version 2>/dev/null || echo 'não instalado')"
echo "Atualizando o baixador de vídeos (yt-dlp)…"
if ! "$BREW" upgrade --quiet yt-dlp deno >>"$LOG" 2>&1; then
  # "upgrade" falha quando já está na última versão em algumas versões do Homebrew: confere.
  command -v yt-dlp >/dev/null || { tail -15 "$LOG"; echo "ERRO_HOMEBREW"; exit 11; }
fi
depois="$(yt-dlp --version 2>/dev/null || echo '?')"
if [ "$antes" = "$depois" ]; then echo "yt-dlp já estava na versão mais nova ($depois)."; else echo "yt-dlp: $antes → $depois"; fi

if ! modo_fonte; then
  echo "Procurando versão nova do Corta…"
  antes_corta="$(cat "$APP/VERSAO" 2>/dev/null || echo '?')"
  if ! bash "$(dirname "$0")/instalar.sh" pacote | grep -v '^INSTALADO$'; then
    echo "ERRO_PACOTE"
    exit 14
  fi
  APP="$DADOS/app/atual"
  depois_corta="$(cat "$APP/VERSAO" 2>/dev/null || echo '?')"
  if [ "$antes_corta" = "$depois_corta" ]; then echo "O Corta já estava na versão mais nova ($depois_corta)."; else echo "Corta: $antes_corta → $depois_corta"; fi
fi

echo "Conferindo as bibliotecas do Corta…"
if ! (cd "$APP" && UV_PROJECT_ENVIRONMENT="$VENV" uv sync --frozen --quiet) >>"$LOG" 2>&1; then
  tail -15 "$LOG"
  echo "ERRO_AMBIENTE"
  exit 13
fi

echo "ATUALIZADO"
