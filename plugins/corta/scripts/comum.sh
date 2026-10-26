# Caminhos e funções usados por todos os scripts do Corta. Use com: source comum.sh

RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DADOS="$HOME/Library/Application Support/Corta"
LOGS="$HOME/Library/Logs/Corta"
VENV="$DADOS/venv"
MODELOS="$DADOS/modelos"
PACOTES="$DADOS/pacotes"

# Onde está o programa: no código-fonte (desenvolvimento) ou no pacote baixado com a licença.
if [ -f "$RAIZ/app/iniciar.py" ]; then
  APP="$RAIZ/app"
else
  APP="$DADOS/app/atual"
fi
LICENCA_URL="${CORTA_LICENCA_URL:-https://corta-licenca.marcostulio.workers.dev}"
LICENCA="$DADOS/licenca.json"

# true quando roda do código-fonte (desenvolvimento): não precisa de licença nem de pacote.
modo_fonte() { [ "$APP" = "$RAIZ/app" ]; }

# Identificador deste Mac (o mesmo que o Corta calcula em licenca.py).
maquina_id() {
  local uuid
  uuid="$(ioreg -rd1 -c IOPlatformExpertDevice | awk -F'"' '/IOPlatformUUID/ {print $4}')"
  printf "corta:%s" "$uuid" | shasum -a 256 | cut -c1-32
}

token_licenca() { sed -n 's/.*"token": *"\([^"]*\)".*/\1/p' "$LICENCA" 2>/dev/null | head -1; }

# Modelo de transcrição padrão (Whisper Large v3 Turbo para chips Apple).
MODELO_REPO="mlx-community/whisper-large-v3-turbo"
MODELO_DIR="$MODELOS/whisper-large-v3-turbo"
MODELO_MB=1620

# Espaço mínimo livre para instalar (modelo + bibliotecas + folga).
ESPACO_MIN_GB=5

# CORTA_BREW_DIR permite simular um Mac sem Homebrew nos testes.
BREW_DIR="${CORTA_BREW_DIR:-/opt/homebrew}"
BREW="$BREW_DIR/bin/brew"

# O Claude nem sempre herda o PATH do Terminal: garante o Homebrew e o ~/.local/bin.
export PATH="$BREW_DIR/bin:$HOME/.local/bin:$PATH"

# O ffmpeg-full traz a libass (legenda gravada no vídeo). O ffmpeg comum do Homebrew não.
FFMPEG="$BREW_DIR/opt/ffmpeg-full/bin/ffmpeg"
FFPROBE="$BREW_DIR/opt/ffmpeg-full/bin/ffprobe"
# Na frente do PATH para que o Whisper e o yt-dlp também usem o ffmpeg-full.
export PATH="$BREW_DIR/opt/ffmpeg-full/bin:$PATH"

# O Python do Corta lê estes valores (corta/config.py).
export CORTA_MODELO_REPO="$MODELO_REPO" CORTA_MODELO_DIR="$MODELO_DIR"
export CORTA_FFMPEG="$FFMPEG" CORTA_FFPROBE="$FFPROBE"

# Confere se o ffmpeg-full existe e grava legenda. Guarda a saída antes do grep:
# com pipefail, "ffmpeg | grep -q" falha quando o grep para de ler cedo.
ffmpeg_ok() {
  [ -x "$FFMPEG" ] || return 1
  local filtros
  filtros="$("$FFMPEG" -hide_banner -filters 2>/dev/null)"
  grep -q ' subtitles ' <<<"$filtros"
}

mkdir -p "$DADOS" "$LOGS" "$MODELOS"
