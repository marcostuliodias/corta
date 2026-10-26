---
name: abrir
description: "Abre o Corta no navegador (localhost:4747): a tela com a biblioteca de vídeos, o player com transcrição e o editor de cortes. Use SEMPRE que a pessoa disser 'abre o Corta', 'abrir o Corta', 'inicia o Corta', 'quero usar o Corta', 'cadê a tela do Corta' ou '/corta:abrir'."
---

# Abrir o Corta

Responda sempre em português do Brasil, em frases curtas e sem termos técnicos: quem usa o Corta normalmente não é programador.

## Passo único

Rode o script que fica em `scripts/abrir.sh` na raiz do plugin, dois níveis acima da pasta desta skill:

```bash
bash "<pasta desta skill>/../../scripts/abrir.sh"
```

Na primeira vez pode levar até um minuto, porque o Python e as bibliotecas são baixados. Avise a pessoa antes de rodar.

## O que fazer com a resposta

Leia a **última linha** da saída:

| Última linha | O que dizer |
|---|---|
| `ABERTO <url>` | "O Corta abriu no seu navegador." Passe o link `http://localhost:4747` caso a aba não tenha aparecido. |
| `JA_RODANDO <url>` | "O Corta já estava aberto; abri a aba de novo." |
| `ERRO_FALTA_UV` | O Corta ainda não foi instalado. Diga isso e siga a skill `instalar`. |
| `ERRO_FALTA_PACOTE` | O programa do Corta ainda não foi baixado (ou a licença não foi ativada). Siga a skill `instalar`. |
| `ERRO_PORTA_OCUPADA` | Outro programa está usando a porta 4747. Pergunte se pode tentar em outra porta e rode de novo com `CORTA_PORTA=4748`. |
| `ERRO_PREPARAR_AMBIENTE` | O download das bibliotecas falhou. Confira a internet, leia as linhas de erro acima e tente de novo. |
| `ERRO_SERVIDOR_CAIU` ou `ERRO_SERVIDOR_NAO_RESPONDEU` | Leia as linhas do log que o script mostrou, explique o problema em uma frase e proponha a correção. O log completo fica em `~/Library/Logs/Corta/servidor.log`. |

Para fechar o Corta, use a skill `parar`.
