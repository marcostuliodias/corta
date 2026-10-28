# Junta tudo o que ajuda a entender um problema do Corta no Windows. Não muda nada.
. "$PSScriptRoot\comum.ps1"
$PORTA = if ($env:CORTA_PORTA) { [int]$env:CORTA_PORTA } else { 4747 }

Write-Output '== Versão do plugin'
(Get-Content (Join-Path $RAIZ '.claude-plugin\plugin.json') -Raw | ConvertFrom-Json).version

Write-Output ''; Write-Output '== Ferramentas'
& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'verificar.ps1')

Write-Output ''; Write-Output '== Servidor'
$s = Saude $PORTA
if ($s) { Write-Output "LIGADO $($s | ConvertTo-Json -Compress -Depth 4)" }
else {
  Write-Output "DESLIGADO (porta $PORTA)"
  Get-NetTCPConnection -LocalPort $PORTA -State Listen -ErrorAction SilentlyContinue | ForEach-Object {
    $p = Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue
    Write-Output "  porta ocupada por: $($p.ProcessName) (pid $($_.OwningProcess))"
  }
}

Write-Output ''; Write-Output '== Biblioteca'
$bib = if ($env:CORTA_BIBLIOTECA) { $env:CORTA_BIBLIOTECA } else { Join-Path $env:USERPROFILE 'Videos\Corta' }
if (Test-Path $bib) {
  $pastas = @(Get-ChildItem $bib -Directory -ErrorAction SilentlyContinue).Count
  $tamanho = [math]::Round(((Get-ChildItem $bib -Recurse -File -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum) / 1GB, 1)
  Write-Output "$bib`: $pastas vídeos, $tamanho GB"
} else { Write-Output "$bib`: ainda não existe" }
Write-Output "Espaço livre: $([math]::Floor((Get-PSDrive -Name $env:USERPROFILE.Substring(0, 1)).Free / 1GB)) GB"

foreach ($nome in 'servidor', 'instalacao', 'transcricao') {
  $arquivo = Join-Path $LOGS "$nome.log"
  if (-not (Test-Path $arquivo)) { continue }
  Write-Output ''; Write-Output "== Últimas linhas de $nome.log"
  Get-Content $arquivo -Tail 25 -Encoding UTF8
}
