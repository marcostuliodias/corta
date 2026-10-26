#!/bin/bash
# Confere tudo o que o Corta precisa. Não instala nada.
# Uma linha por item:  OK <item> <detalhe>  |  FALTA <item> <detalhe>  |  AVISO <item> <detalhe>
# Última linha:        TUDO_PRONTO  |  FALTA_INSTALAR <itens separados por vírgula>  |  INCOMPATIVEL <motivo>
set -uo pipefail
source "$(dirname "$0")/comum.sh"

faltando=()
ok()    { echo "OK $1 $2"; }
falta() { echo "FALTA $1 $2"; faltando+=("$1"); }
aviso() { echo "AVISO $1 $2"; }

# 1. Mac com chip Apple e macOS 14 ou mais novo (exigência da biblioteca MLX).
if [ "$(uname -m)" != "arm64" ]; then
  echo "FALTA mac Este Mac não tem chip Apple (M1 ou mais novo)."
  echo "INCOMPATIVEL chip"
  exit 0
fi
versao_mac="$(sw_vers -productVersion)"
if [ "${versao_mac%%.*}" -lt 14 ]; then
  echo "FALTA mac macOS $versao_mac; precisa ser 14 (Sonoma) ou mais novo."
  echo "INCOMPATIVEL macos"
  exit 0
fi
ok mac "chip Apple, macOS $versao_mac"

# 2. Espaço livre (só conta se o modelo ainda não foi baixado).
livre_gb="$(df -g "$HOME" | awk 'NR==2 {print $4}')"
if [ -f "$MODELO_DIR/.completo" ] || [ "$livre_gb" -ge "$ESPACO_MIN_GB" ]; then
  ok espaco "${livre_gb} GB livres"
else
  echo "FALTA espaco ${livre_gb} GB livres; precisa de pelo menos ${ESPACO_MIN_GB} GB."
  echo "INCOMPATIVEL espaco"
  exit 0
fi

# 3. Homebrew.
if [ -x "$BREW" ]; then ok homebrew "$("$BREW" --version | head -1)"; else falta homebrew "não instalado"; fi

# 4. ffmpeg-full (com legenda gravada).
if ffmpeg_ok; then
  ok ffmpeg "$("$FFMPEG" -version | head -1 | awk '{print $3}')"
else
  falta ffmpeg "ffmpeg-full não instalado"
fi

# 5. yt-dlp e deno (o deno vem junto com o yt-dlp do Homebrew; o YouTube exige).
if command -v yt-dlp >/dev/null; then ok yt-dlp "$(yt-dlp --version)"; else falta yt-dlp "não instalado"; fi
if command -v deno >/dev/null; then ok deno "$(deno --version | head -1 | awk '{print $2}')"; else falta deno "não instalado"; fi

# 6. uv (gerencia o Python do Corta).
if command -v uv >/dev/null; then ok uv "$(uv --version | awk '{print $2}')"; else falta uv "não instalado"; fi

# 6b. Licença e programa (só para quem comprou; o código-fonte não precisa).
if modo_fonte; then
  ok licenca "código-fonte (desenvolvimento)"
else
  if [ -n "$(token_licenca)" ]; then ok licenca "ativada neste Mac"; else falta licenca "não ativada"; fi
  if [ -f "$APP/iniciar.py" ]; then ok pacote "Corta $(cat "$APP/VERSAO" 2>/dev/null)"; else falta pacote "programa não baixado"; fi
fi

# 7. Ambiente Python com as bibliotecas.
if [ -x "$VENV/bin/python" ] && "$VENV/bin/python" -c "import fastapi, mlx_whisper" 2>/dev/null; then
  ok ambiente "bibliotecas instaladas"
else
  falta ambiente "bibliotecas não instaladas"
fi

# 8. Modelo de transcrição (o arquivo .completo só existe depois que o download terminou).
if [ -f "$MODELO_DIR/.completo" ]; then
  ok modelo "Whisper Large v3 Turbo"
else
  falta modelo "Whisper Large v3 Turbo (${MODELO_MB} MB) não baixado"
fi

# 9. Claude em modo linha de comando: a tradução e os destaques vão usar (não bloqueia agora).
if command -v claude >/dev/null; then ok claude "$(claude --version 2>/dev/null | head -1)"; else aviso claude "comando claude não encontrado; tradução e destaques não vão funcionar"; fi

if [ ${#faltando[@]} -eq 0 ]; then
  echo "TUDO_PRONTO"
else
  (IFS=,; echo "FALTA_INSTALAR ${faltando[*]}")
fi
