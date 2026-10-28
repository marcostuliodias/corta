# Confere tudo o que o Corta precisa no Windows. Não instala nada. Equivale ao verificar.sh do Mac.
# Uma linha por item:  OK <item> <detalhe>  |  FALTA <item> <detalhe>  |  AVISO <item> <detalhe>
# Última linha:        TUDO_PRONTO  |  FALTA_INSTALAR <itens separados por vírgula>  |  INCOMPATIVEL <motivo>
. "$PSScriptRoot\comum.ps1"

$faltando = New-Object System.Collections.Generic.List[string]
function Ok($item, $detalhe) { Write-Output "OK $item $detalhe" }
function Falta($item, $detalhe) { Write-Output "FALTA $item $detalhe"; $faltando.Add($item) }
function Aviso($item, $detalhe) { Write-Output "AVISO $item $detalhe" }

# 1. Windows 10 ou 11, 64 bits, processador Intel ou AMD.
$versao = [System.Environment]::OSVersion.Version
$arquitetura = if ($env:PROCESSOR_ARCHITEW6432) { $env:PROCESSOR_ARCHITEW6432 } else { $env:PROCESSOR_ARCHITECTURE }
if ($arquitetura -ne 'AMD64') {
  Write-Output "FALTA windows Este computador não tem processador Intel ou AMD de 64 bits ($arquitetura)."
  Write-Output 'INCOMPATIVEL processador'
  exit 0
}
if ($versao.Major -lt 10) {
  Write-Output "FALTA windows Windows $($versao.Major).$($versao.Minor); precisa ser o 10 ou o 11."
  Write-Output 'INCOMPATIVEL windows'
  exit 0
}
$nomeWindows = if ($versao.Build -ge 22000) { 'Windows 11' } else { 'Windows 10' }
Ok windows "$nomeWindows (build $($versao.Build)), 64 bits"

# 2. Espaço livre (só conta se o modelo ainda não foi baixado).
$livreGb = [math]::Floor((Get-PSDrive -Name $env:LOCALAPPDATA.Substring(0, 1)).Free / 1GB)
if ((Test-Path (Join-Path $MODELO_DIR '.completo')) -or $livreGb -ge $ESPACO_MIN_GB) {
  Ok espaco "$livreGb GB livres"
} else {
  Write-Output "FALTA espaco $livreGb GB livres; precisa de pelo menos $ESPACO_MIN_GB GB."
  Write-Output 'INCOMPATIVEL espaco'
  exit 0
}

# 3. Ferramentas baixadas pelo instalador.
if (Ffmpeg-Ok) { Ok ffmpeg ((& $FFMPEG -version | Select-Object -First 1) -split ' ')[2] } else { Falta ffmpeg 'não instalado' }
$ytdlp = Join-Path $BIN 'yt-dlp.exe'
if (Test-Path $ytdlp) { Ok yt-dlp (& $ytdlp --version) } else { Falta yt-dlp 'não instalado' }
$deno = Join-Path $BIN 'deno.exe'
if (Test-Path $deno) { Ok deno ((& $deno --version | Select-Object -First 1) -split ' ')[1] } else { Falta deno 'não instalado' }
if (Test-Path $UV) { Ok uv ((& $UV --version) -split ' ')[1] } else { Falta uv 'não instalado' }

# 4. Licença e programa (só para quem comprou; o código-fonte não precisa).
if (Modo-Fonte) {
  Ok licenca 'código-fonte (desenvolvimento)'
} else {
  if (Token-Licenca) { Ok licenca 'ativada neste computador' } else { Falta licenca 'não ativada' }
  if (Test-Path (Join-Path $APP 'iniciar.py')) { Ok pacote "Corta $((Get-Content (Join-Path $APP 'VERSAO') -Raw -ErrorAction SilentlyContinue).Trim())" } else { Falta pacote 'programa não baixado' }
}

# 5. Ambiente Python com as bibliotecas.
$ambienteOk = $false
if (Test-Path $PYTHON) { & $PYTHON -c "import fastapi, faster_whisper" 2>$null; $ambienteOk = ($LASTEXITCODE -eq 0) }
if ($ambienteOk) { Ok ambiente 'bibliotecas instaladas' } else { Falta ambiente 'bibliotecas não instaladas' }

# 6. Placa de vídeo: com NVIDIA a transcrição é muito mais rápida (não bloqueia).
if (Tem-Nvidia) {
  $placa = (& nvidia-smi --query-gpu=name --format=csv,noheader 2>$null | Select-Object -First 1)
  $cuda = $false
  if ($ambienteOk) { & $PYTHON -c "import nvidia.cublas, nvidia.cudnn" 2>$null; $cuda = ($LASTEXITCODE -eq 0) }
  if ($cuda) { Ok nvidia "$($placa): a transcrição usa a placa" } else { Falta nvidia "$($placa) encontrada, mas faltam as bibliotecas para usá-la" }
} else {
  Aviso nvidia 'sem placa NVIDIA: a transcrição usa o processador e fica mais lenta (uma live de 1 hora pode levar mais de 1 hora)'
}

# 7. Modelo de transcrição (o arquivo .completo só existe depois que o download terminou).
if (Test-Path (Join-Path $MODELO_DIR '.completo')) { Ok modelo 'Whisper Large v3 Turbo' } else { Falta modelo "Whisper Large v3 Turbo ($MODELO_MB MB) não baixado" }

# 8. Claude em modo linha de comando: a tradução e os destaques vão usar (não bloqueia agora).
if (Tem-Comando 'claude') { Ok claude ((& claude --version 2>$null | Select-Object -First 1)) } else { Aviso claude 'comando claude não encontrado; tradução e destaques não vão funcionar' }

if ($faltando.Count -eq 0) { Write-Output 'TUDO_PRONTO' } else { Write-Output "FALTA_INSTALAR $($faltando -join ',')" }
