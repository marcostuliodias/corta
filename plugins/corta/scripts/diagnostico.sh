#!/bin/bash
# Junta tudo o que ajuda a entender um problema do Corta. Não muda nada.
set -uo pipefail
source "$(dirname "$0")/comum.sh"
PORTA="${CORTA_PORTA:-4747}"

echo "== Versão do plugin"
grep -o '"version": *"[^"]*"' "$RAIZ/.claude-plugin/plugin.json" | head -1

echo; echo "== Ferramentas"
bash "$(dirname "$0")/verificar.sh"

echo; echo "== Servidor"
if resposta="$(curl -fsS --max-time 2 "http://127.0.0.1:$PORTA/api/saude" 2>/dev/null)"; then
  echo "LIGADO $resposta"
else
  echo "DESLIGADO (porta $PORTA)"
  lsof -nP -iTCP:"$PORTA" -sTCP:LISTEN 2>/dev/null | tail -n +2 | awk '{print "  porta ocupada por: " $1 " (pid " $2 ")"}'
fi

echo; echo "== Biblioteca"
BIB="${CORTA_BIBLIOTECA:-$HOME/Movies/Corta}"
echo "$BIB: $(find "$BIB" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | wc -l | tr -d ' ') vídeos, $(du -sh "$BIB" 2>/dev/null | cut -f1)"
echo "Espaço livre: $(df -h "$HOME" | awk 'NR==2 {print $4}')"

for nome in servidor instalacao transcricao; do
  arquivo="$LOGS/$nome.log"
  [ -f "$arquivo" ] || continue
  echo; echo "== Últimas linhas de $nome.log"
  tail -25 "$arquivo"
done
