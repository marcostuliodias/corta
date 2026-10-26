#!/bin/bash
# Para o servidor do Corta. Última linha: PARADO | NAO_ESTAVA_RODANDO | ERRO_NAO_PAROU
set -uo pipefail

PORTA="${CORTA_PORTA:-4747}"
DADOS="$HOME/Library/Application Support/Corta"
PIDFILE="$DADOS/servidor.pid"

saude() { curl -fsS --max-time 2 "http://127.0.0.1:$PORTA/api/saude" 2>/dev/null; }

RESPOSTA="$(saude || true)"
if ! grep -q '"app":"corta"' <<<"$RESPOSTA"; then
  rm -f "$PIDFILE"
  echo "NAO_ESTAVA_RODANDO"
  exit 0
fi

# O pid do Python vem do próprio servidor; o do pidfile é o do uv, que o iniciou.
PID_PY="$(sed -n 's/.*"pid":\([0-9]*\).*/\1/p' <<<"$RESPOSTA")"
PID_UV="$(cat "$PIDFILE" 2>/dev/null || true)"
for pid in $PID_PY $PID_UV; do kill "$pid" 2>/dev/null || true; done

for _ in $(seq 1 20); do
  if ! saude >/dev/null; then
    rm -f "$PIDFILE"
    echo "PARADO"
    exit 0
  fi
  sleep 0.25
done

echo "ERRO_NAO_PAROU"
exit 1
