---
name: parar
description: "Fecha o Corta: desliga o servidor local que mantém a tela aberta em localhost:4747. Use quando a pessoa disser 'fecha o Corta', 'para o Corta', 'desliga o Corta', 'encerra o Corta' ou '/corta:parar'."
---

# Parar o Corta

Responda sempre em português do Brasil, em frases curtas.

Rode:

```bash
bash "<pasta desta skill>/../../scripts/parar.sh"
```

**No Windows**, os scripts são `.ps1` com o mesmo nome e respondem com as mesmas linhas. Troque `bash "<script>.sh"` por:

```bash
powershell -NoProfile -ExecutionPolicy Bypass -File "<pasta do script>/<script>.ps1"
```

Para saber o sistema: se `uname -s` mostrar `Darwin`, é Mac; se mostrar `MINGW`, `MSYS` ou `CYGWIN`, ou se não houver `uname`, é Windows.

Leia a última linha:

| Última linha | O que dizer |
|---|---|
| `PARADO` | "O Corta foi fechado. Seus vídeos continuam na biblioteca." |
| `NAO_ESTAVA_RODANDO` | "O Corta já estava fechado." |
| `ERRO_NAO_PAROU` | Diga que não conseguiu fechar e ofereça encerrar o processo que está usando a porta 4747 (`lsof -nP -iTCP:4747 -sTCP:LISTEN`). Peça confirmação antes. |
