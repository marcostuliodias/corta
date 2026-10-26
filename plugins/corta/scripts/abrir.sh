#!/bin/bash
# Sobe o servidor do Corta (se ainda não estiver rodando) e abre no navegador.
# Última linha da saída, para o Claude ler:
#   ABERTO <url> | JA_RODANDO <url> | ERRO_<motivo>
set -uo pipefail

source "$(dirname "$0")/comum.sh"
PORTA="${CORTA_PORTA:-4747}"
URL="http://localhost:$PORTA"
LOG="$LOGS/servidor.log"
# Registro maior que 5 MB: guarda o anterior e começa outro.
if [ -f "$LOG" ] && [ "$(stat -f %z "$LOG")" -gt 5000000 ]; then mv "$LOG" "$LOG.anterior"; fi

e_o_corta() { curl -fsS --max-time 2 "http://127.0.0.1:$PORTA/api/saude" 2>/dev/null | grep -q '"app":"corta"'; }
abrir_navegador() { [ -n "${CORTA_NAO_ABRIR:-}" ] || open "$URL"; }

if e_o_corta; then
  abrir_navegador
  echo "JA_RODANDO $URL"
  exit 0
fi

if lsof -nP -iTCP:"$PORTA" -sTCP:LISTEN >/dev/null 2>&1; then
  echo "Outro programa já está usando a porta $PORTA."
  echo "ERRO_PORTA_OCUPADA $PORTA"
  exit 2
fi

UV="$(command -v uv || true)"
if [ -z "$UV" ]; then
  echo "O uv não está instalado."
  echo "ERRO_FALTA_UV"
  exit 3
fi

# O ambiente Python fica fora da pasta do plugin, para sobreviver às atualizações.
export UV_PROJECT_ENVIRONMENT="$VENV"
if [ ! -f "$APP/iniciar.py" ]; then
  echo "O programa do Corta ainda não foi baixado."
  echo "ERRO_FALTA_PACOTE"
  exit 7
fi
cd "$APP" || exit 1

# Na primeira vez o uv baixa o Python e as bibliotecas (leva alguns segundos).
if ! "$UV" sync --frozen --quiet >>"$LOG" 2>&1; then
  tail -20 "$LOG"
  echo "ERRO_PREPARAR_AMBIENTE"
  exit 4
fi

nohup "$UV" run --frozen --no-sync python iniciar.py servidor --porta "$PORTA" >>"$LOG" 2>&1 &
PID=$!
echo "$PID" > "$DADOS/servidor.pid"

for _ in $(seq 1 40); do
  if e_o_corta; then
    abrir_navegador
    echo "ABERTO $URL"
    exit 0
  fi
  if ! kill -0 "$PID" 2>/dev/null; then
    tail -20 "$LOG"
    echo "ERRO_SERVIDOR_CAIU"
    exit 5
  fi
  sleep 0.5
done

tail -20 "$LOG"
echo "ERRO_SERVIDOR_NAO_RESPONDEU"
exit 6
