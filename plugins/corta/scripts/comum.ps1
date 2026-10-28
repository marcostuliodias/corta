# Caminhos e funções usados por todos os scripts do Corta no Windows. Use com: . "$PSScriptRoot\comum.ps1"
# Equivale ao comum.sh do Mac. Nada aqui pede senha de administrador: tudo fica na pasta do usuário.
#   %LOCALAPPDATA%\Corta               dados: ambiente Python, modelo, pacotes, licença, registros
#   %LOCALAPPDATA%\Corta\ferramentas    ffmpeg, yt-dlp, deno e uv (baixados pelo instalar.ps1)
#   %USERPROFILE%\Videos\Corta          a biblioteca de vídeos

$ErrorActionPreference = 'Continue'
$ProgressPreference = 'SilentlyContinue'   # a barra de progresso do PowerShell deixa os downloads 10x mais lentos
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$RAIZ = Split-Path -Parent $PSScriptRoot
$DADOS = Join-Path $env:LOCALAPPDATA 'Corta'
$LOGS = Join-Path $DADOS 'logs'
$VENV = Join-Path $DADOS 'venv'
$MODELOS = Join-Path $DADOS 'modelos'
$PACOTES = Join-Path $DADOS 'pacotes'
$FERRAMENTAS = Join-Path $DADOS 'ferramentas'
$BIN = Join-Path $FERRAMENTAS 'bin'
$LICENCA = Join-Path $DADOS 'licenca.json'
$LICENCA_URL = if ($env:CORTA_LICENCA_URL) { $env:CORTA_LICENCA_URL } else { 'https://corta-licenca.marcostulio.workers.dev' }

# Onde está o programa: no código-fonte (desenvolvimento) ou no pacote baixado com a licença.
function Caminho-App {
  if (Test-Path (Join-Path $RAIZ 'app\iniciar.py')) { return (Join-Path $RAIZ 'app') }
  $atual = Join-Path $DADOS 'app\atual.txt'
  if (Test-Path $atual) { return (Join-Path $DADOS ('app\' + (Get-Content $atual -Raw).Trim())) }
  return (Join-Path $DADOS 'app\atual')
}
$APP = Caminho-App
function Modo-Fonte { return ($APP -eq (Join-Path $RAIZ 'app')) }

$MODELO_DIR = Join-Path $MODELOS 'whisper-large-v3-turbo'
$MODELO_MB = 1620
$ESPACO_MIN_GB = 6

# Os programas baixados vêm antes do PATH do sistema; o ~/.local/bin é onde o Claude Code se instala.
$env:Path = "$BIN;$(Join-Path $FERRAMENTAS 'ffmpeg\bin');$(Join-Path $env:USERPROFILE '.local\bin');$env:Path"
$FFMPEG = Join-Path $FERRAMENTAS 'ffmpeg\bin\ffmpeg.exe'
$FFPROBE = Join-Path $FERRAMENTAS 'ffmpeg\bin\ffprobe.exe'
$UV = Join-Path $BIN 'uv.exe'
$PYTHON = Join-Path $VENV 'Scripts\python.exe'

# O Python do Corta lê estes valores (corta/config.py).
$env:CORTA_FFMPEG = $FFMPEG
$env:CORTA_FFPROBE = $FFPROBE
$env:CORTA_YTDLP = Join-Path $BIN 'yt-dlp.exe'
$env:CORTA_MODELO_DIR = $MODELO_DIR
$env:UV_PROJECT_ENVIRONMENT = $VENV
$env:UV_PYTHON_INSTALL_DIR = Join-Path $DADOS 'python'
$env:PYTHONUTF8 = '1'

foreach ($pasta in @($DADOS, $LOGS, $MODELOS, $BIN)) { New-Item -ItemType Directory -Force -Path $pasta | Out-Null }

# Identificador deste computador (o mesmo que o Corta calcula em corta/sistema.py).
function Maquina-Id {
  $guid = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Cryptography' -Name MachineGuid).MachineGuid
  $bytes = [System.Text.Encoding]::UTF8.GetBytes("corta:$guid")
  $hash = [System.Security.Cryptography.SHA256]::Create().ComputeHash($bytes)
  return (-join ($hash | ForEach-Object { $_.ToString('x2') })).Substring(0, 32)
}

function Token-Licenca {
  if (-not (Test-Path $LICENCA)) { return '' }
  try { return [string](Get-Content $LICENCA -Raw -Encoding UTF8 | ConvertFrom-Json).token } catch { return '' }
}

# O ffmpeg baixado existe e grava legenda (filtro subtitles, da libass)?
function Ffmpeg-Ok {
  if (-not (Test-Path $FFMPEG)) { return $false }
  $filtros = & $FFMPEG -hide_banner -filters 2>$null
  return [bool]($filtros | Select-String -SimpleMatch ' subtitles ')
}

function Tem-Comando($nome) { return [bool](Get-Command $nome -ErrorAction SilentlyContinue) }

# Placa NVIDIA com driver (o nvidia-smi vem junto com o driver).
function Tem-Nvidia {
  if (Tem-Comando 'nvidia-smi') { & nvidia-smi -L 2>$null | Out-Null; return ($LASTEXITCODE -eq 0) }
  return $false
}

function Saude($porta) {
  try { return Invoke-RestMethod -Uri "http://127.0.0.1:$porta/api/saude" -TimeoutSec 2 } catch { return $null }
}

function Baixar($url, $destino) {
  # Baixa para um arquivo .parcial e só renomeia no fim: um download interrompido não fica parecendo pronto.
  $parcial = "$destino.parcial"
  Remove-Item $parcial -ErrorAction SilentlyContinue
  try { Invoke-WebRequest -Uri $url -OutFile $parcial -UseBasicParsing -TimeoutSec 900 } catch { Remove-Item $parcial -ErrorAction SilentlyContinue; return $false }
  Move-Item -Force $parcial $destino
  return $true
}
