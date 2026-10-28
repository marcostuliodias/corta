# Atualiza o que costuma quebrar com o tempo (o yt-dlp, quando os sites mudam) e
# acerta as bibliotecas depois que o plugin foi atualizado. Equivale ao atualizar.sh do Mac.
# Última linha: ATUALIZADO | ERRO_<motivo>
. "$PSScriptRoot\comum.ps1"

$LOG = Join-Path $LOGS 'instalacao.log'
Add-Content -Path $LOG -Encoding UTF8 -Value "=== $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') atualizar.ps1"
$YTDLP = Join-Path $BIN 'yt-dlp.exe'

if (-not (Test-Path $YTDLP)) { Write-Output 'As ferramentas não estão instaladas. Rode a instalação do Corta primeiro.'; Write-Output 'ERRO_FALTA_FERRAMENTAS'; exit 10 }

$antes = (& $YTDLP --version 2>$null)
Write-Output 'Atualizando o baixador de vídeos (yt-dlp)…'
& $YTDLP -U 2>&1 | ForEach-Object { Add-Content -Path $LOG -Encoding UTF8 -Value ("    " + $_) }
$depois = (& $YTDLP --version 2>$null)
if ($antes -eq $depois) { Write-Output "yt-dlp já estava na versão mais nova ($depois)." } else { Write-Output "yt-dlp: $antes → $depois" }

if (-not (Modo-Fonte)) {
  Write-Output 'Procurando versão nova do Corta…'
  $versaoAntes = if (Test-Path (Join-Path $APP 'VERSAO')) { (Get-Content (Join-Path $APP 'VERSAO') -Raw).Trim() } else { '?' }
  $saida = & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'instalar.ps1') pacote
  $saida | Where-Object { $_ -ne 'INSTALADO' } | ForEach-Object { Write-Output $_ }
  if (-not ($saida | Select-String -SimpleMatch 'PASSO_OK pacote')) { Write-Output 'ERRO_PACOTE'; exit 14 }
  $APP = Caminho-App
  $versaoDepois = if (Test-Path (Join-Path $APP 'VERSAO')) { (Get-Content (Join-Path $APP 'VERSAO') -Raw).Trim() } else { '?' }
  if ($versaoAntes -eq $versaoDepois) { Write-Output "O Corta já estava na versão mais nova ($versaoDepois)." } else { Write-Output "Corta: $versaoAntes → $versaoDepois" }
}

Write-Output 'Conferindo as bibliotecas do Corta…'
Push-Location $APP
$saida = & $UV sync --frozen --inexact --quiet 2>&1
$codigo = $LASTEXITCODE
Pop-Location
$saida | ForEach-Object { Add-Content -Path $LOG -Encoding UTF8 -Value ("    " + $_) }
if ($codigo -ne 0) { Get-Content $LOG -Tail 15 -Encoding UTF8; Write-Output 'ERRO_AMBIENTE'; exit 13 }
Write-Output 'ATUALIZADO'
