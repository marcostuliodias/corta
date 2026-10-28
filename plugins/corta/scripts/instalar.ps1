# Instala o que falta para o Corta no Windows. Pode rodar quantas vezes quiser: pula o que já existe.
# Equivale ao instalar.sh do Mac e responde com as mesmas mensagens, para o Claude ler igual.
#   powershell -NoProfile -ExecutionPolicy Bypass -File instalar.ps1 licenca <email> <código da transação>
#   powershell -NoProfile -ExecutionPolicy Bypass -File instalar.ps1 [ferramentas] [pacote] [ambiente] [nvidia] [modelo] [teste]
# Sem passos = ferramentas pacote ambiente nvidia modelo teste.
# Cada passo termina com PASSO_OK <passo> ou ERRO_<motivo>. Última linha: INSTALADO ou ERRO_<motivo>.
. "$PSScriptRoot\comum.ps1"

$LOG = Join-Path $LOGS 'instalacao.log'
Add-Content -Path $LOG -Encoding UTF8 -Value "=== $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') instalar.ps1 $($args -join ' ')"

function Falhou($codigo, $saida = 1) { Write-Output $codigo; exit $saida }
function No-Log($linhas) { $linhas | ForEach-Object { Add-Content -Path $LOG -Encoding UTF8 -Value ("    " + $_) } }
function Ultimas-Do-Log { Get-Content $LOG -Tail 15 -Encoding UTF8 }

function Passo-Ferramentas {
  $baixar = @()
  if (-not (Ffmpeg-Ok)) { $baixar += 'ffmpeg' }
  if (-not (Test-Path (Join-Path $BIN 'yt-dlp.exe'))) { $baixar += 'yt-dlp' }
  if (-not (Test-Path (Join-Path $BIN 'deno.exe'))) { $baixar += 'deno' }
  if (-not (Test-Path $UV)) { $baixar += 'uv' }
  if ($baixar.Count -gt 0) { Write-Output "Baixando: $($baixar -join ', ') (ficam em $FERRAMENTAS)" }
  $tmp = Join-Path $FERRAMENTAS 'baixando'
  New-Item -ItemType Directory -Force -Path $tmp | Out-Null

  if ($baixar -contains 'ffmpeg') {
    # Versão completa (GPL) do ffmpeg: traz a libass (legenda gravada) e os codificadores NVIDIA, Intel e AMD.
    $zip = Join-Path $tmp 'ffmpeg.zip'
    if (-not (Baixar 'https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-n8.1-latest-win64-gpl-8.1.zip' $zip)) { Falhou ERRO_DOWNLOAD_FERRAMENTAS 11 }
    $extraido = Join-Path $tmp 'ffmpeg'
    Remove-Item -Recurse -Force $extraido -ErrorAction SilentlyContinue
    Expand-Archive -Path $zip -DestinationPath $extraido -Force
    $pasta = Get-ChildItem $extraido -Directory | Select-Object -First 1
    Remove-Item -Recurse -Force (Join-Path $FERRAMENTAS 'ffmpeg') -ErrorAction SilentlyContinue
    Move-Item $pasta.FullName (Join-Path $FERRAMENTAS 'ffmpeg')
    if (-not (Ffmpeg-Ok)) { Falhou ERRO_FFMPEG 11 }
  }
  if ($baixar -contains 'yt-dlp') {
    if (-not (Baixar 'https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe' (Join-Path $BIN 'yt-dlp.exe'))) { Falhou ERRO_DOWNLOAD_FERRAMENTAS 11 }
  }
  if ($baixar -contains 'deno') {
    # O YouTube exige um interpretador de JavaScript para o yt-dlp: o deno.
    $zip = Join-Path $tmp 'deno.zip'
    if (-not (Baixar 'https://github.com/denoland/deno/releases/latest/download/deno-x86_64-pc-windows-msvc.zip' $zip)) { Falhou ERRO_DOWNLOAD_FERRAMENTAS 11 }
    Expand-Archive -Path $zip -DestinationPath $BIN -Force
  }
  if ($baixar -contains 'uv') {
    $zip = Join-Path $tmp 'uv.zip'
    if (-not (Baixar 'https://github.com/astral-sh/uv/releases/latest/download/uv-x86_64-pc-windows-msvc.zip' $zip)) { Falhou ERRO_DOWNLOAD_FERRAMENTAS 11 }
    Expand-Archive -Path $zip -DestinationPath $BIN -Force
  }
  Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
  Write-Output 'PASSO_OK ferramentas'
}

function Passo-Ambiente {
  if (-not (Test-Path $UV)) { Falhou ERRO_FALTA_UV 12 }
  if (-not (Test-Path (Join-Path $APP 'iniciar.py'))) { Falhou ERRO_FALTA_PACOTE 24 }
  Write-Output 'Preparando o Python e as bibliotecas do Corta…'
  Push-Location $APP
  # --inexact: não apaga as bibliotecas da NVIDIA, que entram por fora (passo nvidia).
  $saida = & $UV sync --frozen --inexact --quiet 2>&1
  $codigo = $LASTEXITCODE
  Pop-Location
  No-Log $saida
  if ($codigo -ne 0) { Ultimas-Do-Log; Falhou ERRO_AMBIENTE 13 }
  Write-Output 'PASSO_OK ambiente'
}

function Passo-Nvidia {
  # Só com placa NVIDIA: as bibliotecas CUDA deixam a transcrição muitas vezes mais rápida (uns 1,5 GB).
  if (-not (Tem-Nvidia)) { Write-Output 'Sem placa NVIDIA: a transcrição vai usar o processador.'; Write-Output 'PASSO_OK nvidia'; return }
  if (-not (Test-Path $PYTHON)) { Falhou ERRO_FALTA_AMBIENTE 14 }
  & $PYTHON -c "import nvidia.cublas, nvidia.cudnn" 2>$null
  if ($LASTEXITCODE -eq 0) { Write-Output 'As bibliotecas da NVIDIA já estão instaladas.'; Write-Output 'PASSO_OK nvidia'; return }
  Write-Output 'Placa NVIDIA encontrada: baixando as bibliotecas para transcrever com ela (uns 1,5 GB)…'
  $saida = & $UV pip install --python $PYTHON --quiet 'nvidia-cublas-cu12' 'nvidia-cudnn-cu12==9.*' 2>&1
  $codigo = $LASTEXITCODE
  No-Log $saida
  if ($codigo -ne 0) { Write-Output 'AVISO Não deu para instalar as bibliotecas da NVIDIA; a transcrição vai usar o processador.' }
  Write-Output 'PASSO_OK nvidia'
}

function Passo-Licenca($email, $transacao) {
  if (Modo-Fonte) { Write-Output 'Código-fonte: não precisa de licença.'; Write-Output 'PASSO_OK licenca'; return }
  if (-not $email -or -not $transacao) { Falhou ERRO_LICENCA_DADOS 20 }
  Write-Output 'Ativando a licença neste computador…'
  $corpo = @{ email = $email; transacao = $transacao; maquina = (Maquina-Id); nome_maquina = $env:COMPUTERNAME }
  $r = Pedir-Texto "$LICENCA_URL/api/ativar?formato=texto" $corpo
  if ($r.Codigo -eq 0) { Write-Output $r.Texto; Falhou ERRO_LICENCA_INTERNET 21 }
  $resposta = $r.Texto
  if ($resposta.StartsWith('OK ')) {
    $token = $resposta.Substring(3).Trim()
    $json = @{ token = $token; ativado_em = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds() } | ConvertTo-Json -Compress
    [System.IO.File]::WriteAllText($LICENCA, $json, (New-Object System.Text.UTF8Encoding $false))
    Write-Output 'PASSO_OK licenca'
  } elseif ($resposta.StartsWith('ERRO ')) {
    $resto = $resposta.Substring(5)
    $motivo = ($resto -split ' ', 2)[0]
    Write-Output (($resto -split ' ', 2)[1])
    Falhou ("ERRO_LICENCA_" + $motivo.ToUpper()) 22
  } else { Write-Output $resposta; Falhou ERRO_LICENCA_SERVIDOR 23 }
}

function Passo-Pacote {
  if (Modo-Fonte) { Write-Output 'Código-fonte: o programa já está aqui.'; Write-Output 'PASSO_OK pacote'; return }
  $token = Token-Licenca
  if (-not $token) { Falhou ERRO_FALTA_LICENCA 24 }
  $r = Pedir-Texto "$LICENCA_URL/api/pacote/info?formato=texto&plataforma=windows&token=$token"
  if ($r.Codigo -eq 0) { Write-Output $r.Texto; Falhou ERRO_LICENCA_INTERNET 21 }
  $info = $r.Texto
  if (-not $info.StartsWith('OK ')) {
    try { Write-Output ($info | ConvertFrom-Json).mensagem } catch { Write-Output $info }
    Falhou ERRO_PACOTE_NEGADO 25
  }
  $partes = $info -split ' '
  $versao = $partes[1]; $tamanho = [long]$partes[2]
  $destino = Join-Path $DADOS "app\$versao"
  $atual = Join-Path $DADOS 'app\atual.txt'
  if ((Test-Path (Join-Path $destino 'iniciar.py')) -and (Test-Path $atual) -and ((Get-Content $atual -Raw).Trim() -eq $versao)) {
    Write-Output "O Corta $versao já está baixado."; Write-Output 'PASSO_OK pacote'; return
  }
  Write-Output "Baixando o Corta $versao ($([math]::Round($tamanho / 1MB)) MB)…"
  New-Item -ItemType Directory -Force -Path $PACOTES, (Join-Path $DADOS 'app') | Out-Null
  $arquivo = Join-Path $PACOTES "corta-$versao.tar"
  if (-not (Baixar "$LICENCA_URL/api/pacote/baixar?plataforma=windows&token=$token" $arquivo)) { Falhou ERRO_PACOTE_DOWNLOAD 26 }
  if ((Get-Item $arquivo).Length -ne $tamanho) { Remove-Item $arquivo; Falhou ERRO_PACOTE_INCOMPLETO 27 }
  $novo = "$destino.novo"
  Remove-Item -Recurse -Force $novo -ErrorAction SilentlyContinue
  New-Item -ItemType Directory -Force -Path $novo | Out-Null
  & tar -xf $arquivo -C $novo --strip-components 1 2>&1 | ForEach-Object { No-Log $_ }
  if (-not (Test-Path (Join-Path $novo 'iniciar.py'))) { Falhou ERRO_PACOTE_ARQUIVO 28 }
  Remove-Item -Recurse -Force $destino -ErrorAction SilentlyContinue
  Move-Item $novo $destino
  Set-Content -Path $atual -Value $versao -Encoding ASCII
  $script:APP = $destino
  # Guarda só as duas versões mais novas.
  Get-ChildItem (Join-Path $DADOS 'app') -Directory | Sort-Object LastWriteTime -Descending | Select-Object -Skip 2 | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
  Get-ChildItem $PACOTES -File | Sort-Object LastWriteTime -Descending | Select-Object -Skip 2 | Remove-Item -Force -ErrorAction SilentlyContinue
  Write-Output 'PASSO_OK pacote'
}

function Python-Corta([string[]]$argumentos) {
  Push-Location $APP
  $saida = & $PYTHON iniciar.py instalacao @argumentos 2>&1
  Pop-Location
  return $saida
}

function Passo-Modelo {
  if (-not (Test-Path $PYTHON)) { Falhou ERRO_FALTA_AMBIENTE 14 }
  $saida = Python-Corta @('modelo')
  $saida | ForEach-Object { Write-Output $_ }
  No-Log $saida
  if (-not (Test-Path (Join-Path $MODELO_DIR '.completo'))) { Falhou ERRO_MODELO 15 }
  Write-Output 'PASSO_OK modelo'
}

function Passo-Teste {
  if (-not (Test-Path (Join-Path $MODELO_DIR '.completo'))) { Falhou ERRO_FALTA_MODELO 16 }
  $saida = Python-Corta @('teste')
  $saida | ForEach-Object { Write-Output $_ }
  No-Log $saida
  if (-not ($saida | Select-String -Pattern '^TESTE_OK')) { Falhou ERRO_TESTE 17 }
  Write-Output 'PASSO_OK teste'
}

if ($args.Count -ge 1 -and $args[0] -eq 'licenca') {
  Passo-Licenca $args[1] $args[2]
  Write-Output 'INSTALADO'
  exit 0
}

$passos = if ($args.Count -gt 0) { $args } else { @('ferramentas', 'pacote', 'ambiente', 'nvidia', 'modelo', 'teste') }
foreach ($p in $passos) {
  switch ($p) {
    'ferramentas' { Passo-Ferramentas }
    'pacote' { Passo-Pacote }
    'ambiente' { Passo-Ambiente }
    'nvidia' { Passo-Nvidia }
    'modelo' { Passo-Modelo }
    'teste' { Passo-Teste }
    default { Falhou "ERRO_PASSO_DESCONHECIDO $p" 2 }
  }
}
Write-Output 'INSTALADO'
