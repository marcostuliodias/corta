# Sobe o servidor do Corta no Windows (se ainda não estiver rodando) e abre no navegador.
# Equivale ao abrir.sh do Mac. Última linha da saída, para o Claude ler:
#   ABERTO <url> | JA_RODANDO <url> | ERRO_<motivo>
. "$PSScriptRoot\comum.ps1"

$PORTA = if ($env:CORTA_PORTA) { [int]$env:CORTA_PORTA } else { 4747 }
$URL = "http://localhost:$PORTA"
$LOG = Join-Path $LOGS 'servidor.log'
# Registro maior que 5 MB: guarda o anterior e começa outro.
if ((Test-Path $LOG) -and (Get-Item $LOG).Length -gt 5MB) { Move-Item -Force $LOG "$LOG.anterior" }

function E-O-Corta { $s = Saude $PORTA; return ($s -and $s.app -eq 'corta') }
function Abrir-Navegador { if (-not $env:CORTA_NAO_ABRIR) { Start-Process $URL } }

if (E-O-Corta) { Abrir-Navegador; Write-Output "JA_RODANDO $URL"; exit 0 }

if (Get-NetTCPConnection -LocalPort $PORTA -State Listen -ErrorAction SilentlyContinue) {
  Write-Output "Outro programa já está usando a porta $PORTA."
  Write-Output "ERRO_PORTA_OCUPADA $PORTA"
  exit 2
}
if (-not (Test-Path $UV)) { Write-Output 'O uv não está instalado.'; Write-Output 'ERRO_FALTA_UV'; exit 3 }
if (-not (Test-Path (Join-Path $APP 'iniciar.py'))) { Write-Output 'O programa do Corta ainda não foi baixado.'; Write-Output 'ERRO_FALTA_PACOTE'; exit 7 }

# Na primeira vez o uv baixa o Python e as bibliotecas (leva alguns segundos).
Push-Location $APP
$saida = & $UV sync --frozen --inexact --quiet 2>&1
$codigo = $LASTEXITCODE
Pop-Location
$saida | ForEach-Object { Add-Content -Path $LOG -Encoding UTF8 -Value $_ }
if ($codigo -ne 0) { Get-Content $LOG -Tail 20 -Encoding UTF8; Write-Output 'ERRO_PREPARAR_AMBIENTE'; exit 4 }

# O servidor roda numa janela escondida, por um arquivo .cmd com o ambiente certo. Assim ele continua
# depois que o Claude e o PowerShell fecham, e os programas que ele chama (ffmpeg, yt-dlp) não abrem janela.
$iniciador = Join-Path $DADOS 'iniciar-servidor.cmd'
$linhas = @(
  '@echo off',
  'chcp 65001 >nul',
  "set ""PATH=$env:Path""",
  "set ""CORTA_FFMPEG=$env:CORTA_FFMPEG""",
  "set ""CORTA_FFPROBE=$env:CORTA_FFPROBE""",
  "set ""CORTA_YTDLP=$env:CORTA_YTDLP""",
  "set ""CORTA_MODELO_DIR=$env:CORTA_MODELO_DIR""",
  "set ""UV_PROJECT_ENVIRONMENT=$VENV""",
  "set ""UV_PYTHON_INSTALL_DIR=$env:UV_PYTHON_INSTALL_DIR""",
  'set "PYTHONUTF8=1"'
)
if ($env:CORTA_BIBLIOTECA) { $linhas += "set ""CORTA_BIBLIOTECA=$env:CORTA_BIBLIOTECA""" }
$linhas += @(
  "cd /d ""$APP""",
  """$UV"" run --frozen --no-sync python iniciar.py servidor --porta $PORTA >> ""$LOG"" 2>&1"
)
[System.IO.File]::WriteAllLines($iniciador, $linhas, (New-Object System.Text.UTF8Encoding $false))
$processo = Start-Process -FilePath 'cmd.exe' -ArgumentList '/c', "`"$iniciador`"" -WindowStyle Hidden -PassThru
Set-Content -Path (Join-Path $DADOS 'servidor.pid') -Value $processo.Id -Encoding ASCII

for ($i = 0; $i -lt 60; $i++) {
  if (E-O-Corta) { Abrir-Navegador; Write-Output "ABERTO $URL"; exit 0 }
  if ($processo.HasExited) { Get-Content $LOG -Tail 20 -Encoding UTF8; Write-Output 'ERRO_SERVIDOR_CAIU'; exit 5 }
  Start-Sleep -Milliseconds 500
}
Get-Content $LOG -Tail 20 -Encoding UTF8
Write-Output 'ERRO_SERVIDOR_NAO_RESPONDEU'
exit 6
