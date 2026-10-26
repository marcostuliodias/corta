#!/bin/bash
# Instala o que falta para o Corta. Pode rodar quantas vezes quiser: pula o que já existe.
# Uso: instalar.sh licenca <email> <código da transação>
#      instalar.sh [ferramentas] [pacote] [ambiente] [modelo] [teste]   (sem argumentos = tudo menos licenca)
# Cada passo termina com PASSO_OK <passo> ou ERRO_<motivo>. Última linha: INSTALADO ou ERRO_<motivo>.
set -uo pipefail
source "$(dirname "$0")/comum.sh"

LOG="$LOGS/instalacao.log"
echo "=== $(date '+%Y-%m-%d %H:%M:%S') instalar.sh $*" >>"$LOG"
export HOMEBREW_NO_ENV_HINTS=1 HOMEBREW_NO_INSTALL_CLEANUP=1

falhou() { echo "$1"; exit "${2:-1}"; }

passo_ferramentas() {
  if [ ! -x "$BREW" ]; then
    echo "O Homebrew não está instalado. Ele pede a senha do Mac, então precisa ser instalado no Terminal:"
    echo '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
    falhou ERRO_FALTA_HOMEBREW 10
  fi

  local pacotes=()
  ffmpeg_ok || pacotes+=(ffmpeg-full)
  command -v yt-dlp >/dev/null || pacotes+=(yt-dlp)
  command -v deno   >/dev/null || pacotes+=(deno)
  command -v uv     >/dev/null || pacotes+=(uv)

  if [ ${#pacotes[@]} -gt 0 ]; then
    echo "Instalando pelo Homebrew: ${pacotes[*]}"
    if ! "$BREW" install --quiet "${pacotes[@]}" >>"$LOG" 2>&1; then
      tail -15 "$LOG"
      falhou ERRO_HOMEBREW 11
    fi
  fi
  echo "PASSO_OK ferramentas"
}

passo_ambiente() {
  command -v uv >/dev/null || falhou ERRO_FALTA_UV 12
  echo "Preparando o Python e as bibliotecas do Corta…"
  if ! (cd "$APP" && UV_PROJECT_ENVIRONMENT="$VENV" uv sync --frozen --quiet) >>"$LOG" 2>&1; then
    tail -15 "$LOG"
    falhou ERRO_AMBIENTE 13
  fi
  echo "PASSO_OK ambiente"
}

passo_licenca() {
  local email="${1:-}" transacao="${2:-}"
  if modo_fonte; then echo "Código-fonte: não precisa de licença."; echo "PASSO_OK licenca"; return; fi
  [ -n "$email" ] && [ -n "$transacao" ] || falhou ERRO_LICENCA_DADOS 20
  echo "Ativando a licença neste Mac…"
  local resposta
  resposta="$(curl -sS --max-time 30 -X POST "$LICENCA_URL/api/ativar?formato=texto" \
    --data-urlencode "email=$email" --data-urlencode "transacao=$transacao" \
    --data-urlencode "maquina=$(maquina_id)" --data-urlencode "nome_maquina=$(scutil --get ComputerName 2>/dev/null)" 2>&1)" \
    || { echo "$resposta"; falhou ERRO_LICENCA_INTERNET 21; }
  case "$resposta" in
    "OK "*)
      printf '{"token": "%s", "ativado_em": %s}\n' "${resposta#OK }" "$(date +%s)" > "$LICENCA"
      chmod 600 "$LICENCA"
      echo "PASSO_OK licenca" ;;
    "ERRO "*)
      local motivo="${resposta#ERRO }"; motivo="${motivo%% *}"
      echo "${resposta#ERRO $motivo }"
      falhou "ERRO_LICENCA_$(echo "$motivo" | tr '[:lower:]' '[:upper:]')" 22 ;;
    *) echo "$resposta"; falhou ERRO_LICENCA_SERVIDOR 23 ;;
  esac
}

passo_pacote() {
  if modo_fonte; then echo "Código-fonte: o programa já está aqui."; echo "PASSO_OK pacote"; return; fi
  local token; token="$(token_licenca)"
  [ -n "$token" ] || falhou ERRO_FALTA_LICENCA 24
  local info versao tamanho
  info="$(curl -sS --max-time 30 "$LICENCA_URL/api/pacote/info?formato=texto&token=$token" 2>&1)" || { echo "$info"; falhou ERRO_LICENCA_INTERNET 21; }
  case "$info" in "OK "*) ;; *) echo "$info" | sed -n 's/.*"mensagem": *"\([^"]*\)".*/\1/p'; falhou ERRO_PACOTE_NEGADO 25 ;; esac
  read -r _ versao tamanho <<<"$info"
  if [ -f "$DADOS/app/$versao/iniciar.py" ] && [ "$(readlink "$DADOS/app/atual")" = "$versao" ]; then
    echo "O Corta $versao já está baixado."; echo "PASSO_OK pacote"; return
  fi
  echo "Baixando o Corta $versao ($(( tamanho / 1000000 )) MB)…"
  mkdir -p "$PACOTES" "$DADOS/app"
  local arquivo="$PACOTES/corta-$versao.tar"
  curl -fsS --max-time 600 -o "$arquivo.parcial" "$LICENCA_URL/api/pacote/baixar?token=$token" || falhou ERRO_PACOTE_DOWNLOAD 26
  [ "$(stat -f %z "$arquivo.parcial")" = "$tamanho" ] || { rm -f "$arquivo.parcial"; falhou ERRO_PACOTE_INCOMPLETO 27; }
  mv "$arquivo.parcial" "$arquivo"
  rm -rf "$DADOS/app/$versao.novo" && mkdir -p "$DADOS/app/$versao.novo"
  tar -xf "$arquivo" -C "$DADOS/app/$versao.novo" --strip-components 1 || falhou ERRO_PACOTE_ARQUIVO 28
  # A marca d'água muda o binário: o macOS só carrega depois de reassinar (assinatura local).
  codesign -s - -f "$DADOS/app/$versao.novo"/corta*.so >>"$LOG" 2>&1 || falhou ERRO_PACOTE_ASSINATURA 29
  rm -rf "$DADOS/app/$versao" && mv "$DADOS/app/$versao.novo" "$DADOS/app/$versao"
  ln -sfn "$versao" "$DADOS/app/atual"
  APP="$DADOS/app/atual"
  # Guarda só as duas versões mais novas.
  ls -1t "$DADOS/app" | grep -v -E '^atual$' | tail -n +3 | while read -r velha; do rm -rf "$DADOS/app/$velha"; done
  ls -1t "$PACOTES" | tail -n +3 | while read -r velho; do rm -f "$PACOTES/$velho"; done
  echo "PASSO_OK pacote"
}

python_corta() { (cd "$APP" && "$VENV/bin/python" iniciar.py instalacao "$@"); }

passo_modelo() {
  [ -x "$VENV/bin/python" ] || falhou ERRO_FALTA_AMBIENTE 14
  python_corta modelo 2>>"$LOG" | tee -a "$LOG"
  [ -f "$MODELO_DIR/.completo" ] || falhou ERRO_MODELO 15
  echo "PASSO_OK modelo"
}

passo_teste() {
  [ -f "$MODELO_DIR/.completo" ] || falhou ERRO_FALTA_MODELO 16
  local saida
  saida="$(python_corta teste 2>>"$LOG")"
  echo "$saida" | tee -a "$LOG"
  grep -q '^TESTE_OK' <<<"$saida" || falhou ERRO_TESTE 17
  echo "PASSO_OK teste"
}

if [ "${1:-}" = "licenca" ]; then
  passo_licenca "${2:-}" "${3:-}"
  echo "INSTALADO"
  exit 0
fi

passos=("$@")
[ ${#passos[@]} -eq 0 ] && passos=(ferramentas pacote ambiente modelo teste)
for p in "${passos[@]}"; do
  case "$p" in
    ferramentas|pacote|ambiente|modelo|teste) "passo_$p" ;;
    *) falhou "ERRO_PASSO_DESCONHECIDO $p" 2 ;;
  esac
done
echo "INSTALADO"
