# Para o servidor do Corta no Windows. Última linha: PARADO | NAO_ESTAVA_RODANDO | ERRO_NAO_PAROU
. "$PSScriptRoot\comum.ps1"

$PORTA = if ($env:CORTA_PORTA) { [int]$env:CORTA_PORTA } else { 4747 }
$PIDFILE = Join-Path $DADOS 'servidor.pid'

$resposta = Saude $PORTA
if (-not ($resposta -and $resposta.app -eq 'corta')) {
  Remove-Item $PIDFILE -ErrorAction SilentlyContinue
  Write-Output 'NAO_ESTAVA_RODANDO'
  exit 0
}

# O pid do Python vem do próprio servidor; o do arquivo é o do cmd que o iniciou.
# /T encerra também o que eles chamaram (uv, ffmpeg, yt-dlp).
$pids = @($resposta.pid)
if (Test-Path $PIDFILE) { $pids += (Get-Content $PIDFILE -Raw).Trim() }
foreach ($p in $pids) { if ($p) { & taskkill /PID $p /T /F 2>&1 | Out-Null } }

for ($i = 0; $i -lt 20; $i++) {
  if (-not (Saude $PORTA)) { Remove-Item $PIDFILE -ErrorAction SilentlyContinue; Write-Output 'PARADO'; exit 0 }
  Start-Sleep -Milliseconds 250
}
Write-Output 'ERRO_NAO_PAROU'
exit 1
