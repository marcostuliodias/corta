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

Leia a última linha:

| Última linha | O que dizer |
|---|---|
| `PARADO` | "O Corta foi fechado. Seus vídeos continuam na biblioteca." |
| `NAO_ESTAVA_RODANDO` | "O Corta já estava fechado." |
| `ERRO_NAO_PAROU` | Diga que não conseguiu fechar e ofereça encerrar o processo que está usando a porta 4747 (`lsof -nP -iTCP:4747 -sTCP:LISTEN`). Peça confirmação antes. |
