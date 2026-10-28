---
name: atualizar
description: "Atualiza o Corta: o baixador de vídeos (yt-dlp, que precisa de atualização quando o YouTube, o Instagram ou o TikTok mudam) e as bibliotecas depois de uma versão nova do plugin. Use quando a pessoa disser 'atualiza o Corta', 'o download parou de funcionar', 'não baixa mais do YouTube', 'deu erro ao baixar', 'tem versão nova do Corta?' ou '/corta:atualizar'."
---

# Atualizar o Corta

Responda sempre em português do Brasil, em frases curtas e sem termos técnicos.

Os scripts ficam em `scripts/`, dois níveis acima da pasta desta skill:

```bash
S="<pasta desta skill>/../../scripts"
```

## 1. Atualizar as ferramentas

```bash
bash "$S/atualizar.sh"
```

**No Windows**, os scripts são `.ps1` com o mesmo nome e respondem com as mesmas linhas. Troque `bash "<script>.sh"` por:

```bash
powershell -NoProfile -ExecutionPolicy Bypass -File "<pasta do script>/<script>.ps1"
```

Para saber o sistema: se `uname -s` mostrar `Darwin`, é Mac; se mostrar `MINGW`, `MSYS` ou `CYGWIN`, ou se não houver `uname`, é Windows.


Use o tempo limite do Bash em 10 minutos (600000 ms). A última linha diz o resultado:

| Última linha | O que dizer |
|---|---|
| `ATUALIZADO` | Conte o que mudou (a linha `yt-dlp: … → …`, ou que já estava na versão mais nova). |
| `ERRO_FALTA_HOMEBREW` | O Corta ainda não foi instalado: siga a skill `instalar`. |
| `ERRO_HOMEBREW` ou `ERRO_AMBIENTE` | Leia as linhas acima do erro, explique em uma frase e proponha a correção. |

## 2. Reiniciar o Corta

Se o Corta estiver aberto, ele precisa ser reiniciado para usar o que foi atualizado:

```bash
bash "$S/parar.sh" && bash "$S/abrir.sh"
```

## 3. Versão nova do plugin

Se a pessoa perguntar se há uma versão nova do Corta, explique que ela atualiza o plugin com estes dois comandos no Claude (e depois volta aqui para o passo 1):

```
/plugin marketplace update corta
/plugin update corta@corta
```
