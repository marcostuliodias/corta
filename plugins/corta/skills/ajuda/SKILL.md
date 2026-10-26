---
name: ajuda
description: "Use SEMPRE para qualquer pergunta sobre o estado do Corta ou problema com ele, antes de investigar por conta própria: 'o Corta está instalado?', 'confere o Corta', 'o Corta não funciona', 'não baixa vídeo', 'não tá baixando do YouTube', 'deu erro no Corta', 'a tradução falhou', 'o corte não saiu', 'a tela não abre', '/corta:ajuda'. Roda um diagnóstico que só lê (ferramentas, servidor, biblioteca, espaço e registros) e explica a causa em português simples."
---

# Ajuda do Corta

Responda sempre em português do Brasil, em frases curtas e sem termos técnicos. Primeiro entenda, depois proponha: não mude nada sem a pessoa concordar.

## 1. Juntar as informações

```bash
bash "<pasta desta skill>/../../scripts/diagnostico.sh"
```

O relatório mostra a versão, as ferramentas (`OK`/`FALTA`), se o servidor está ligado, a biblioteca, o espaço livre e as últimas linhas dos registros.

## 2. Problemas comuns

| O que aparece | Causa provável | O que propor |
|---|---|---|
| `FALTA` em alguma ferramenta | Instalação incompleta | Skill `instalar` (ela pula o que já existe). |
| Servidor `DESLIGADO` | O Corta foi fechado ou o Mac reiniciou | Skill `abrir`. |
| Porta ocupada por outro programa | Outro app usando a porta 4747 | Abrir em outra porta: `CORTA_PORTA=4748 bash …/scripts/abrir.sh`. |
| Erro ao baixar ("não é robô", "login", "não disponível") | O site mudou ou pediu login | Skill `atualizar`. Vídeo privado ou que pede login ainda não é suportado. |
| Tradução ou destaques: "O Claude não está conectado" | O Claude Code não está logado | Pedir para a pessoa abrir o Claude Code e entrar na conta. |
| Tradução ou destaques: "limite de uso" | Limite da assinatura do Claude | Tentar mais tarde. A tradução continua de onde parou. |
| Pouco espaço livre (menos de 2 GB) | Disco cheio | Remover vídeos antigos pela tela do Corta (vão para a Lixeira). |
| Erro na transcrição | Arquivo sem som ou corrompido | Ver `transcricao.log` e explicar em uma frase. |

Se nada disso explicar, mostre para a pessoa as 3 a 5 linhas do registro que parecem ser o erro e diga, em uma frase, o que elas querem dizer.

Os registros completos ficam em `~/Library/Logs/Corta/` e a biblioteca em `~/Movies/Corta/`.
