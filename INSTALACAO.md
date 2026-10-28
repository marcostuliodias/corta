# Como instalar o Corta

O Corta baixa, transcreve, traduz e corta vídeos no seu Mac. Ele abre uma tela no navegador e o Claude cuida da instalação para você. A instalação leva de 10 a 20 minutos, e você só faz isso uma vez.

**Prefere ver com imagens?** Acesse o passo a passo em **corta-site.marcostulio.workers.dev/instalar**. Travou em algum passo? Chame no WhatsApp: **(31) 97131-5886**.

---

## Antes de começar

Você precisa de:

- **Um Mac com chip Apple** (M1, M2, M3, M4 ou mais novo). Para conferir: clique na maçã no canto superior esquerdo da tela → **Sobre Este Mac** → linha "Chip".
- **macOS 14 (Sonoma) ou mais novo.**
- **Uns 5 GB livres no disco.**
- **Uma assinatura do Claude** (Pro ou Max). A tradução e os destaques usam a sua assinatura, sem custo extra.
- **A compra do Corta** (você recebe o código da transação no e-mail da Hotmart).

---

## Passo 1. Instalar o Claude Code

Se você já usa o Claude Code no Terminal, pule para o passo 2.

1. Aperte **Command + Espaço**, digite **Terminal** e aperte **Enter**.
2. Cole este comando e aperte **Enter**:
   ```
   curl -fsSL https://claude.ai/install.sh | bash
   ```
3. Quando terminar, feche o Terminal e abra de novo.
4. Digite `claude` e aperte **Enter**. Na primeira vez, ele abre o navegador para você entrar na sua conta do Claude.

---

## Passo 2. Adicionar o Corta

Com o Claude aberto no Terminal, digite estes dois comandos (um de cada vez):

```
/plugin marketplace add marcostuliodias/corta
/plugin install corta@corta
```

Depois feche o Claude (digite `/exit`) e abra de novo (`claude`).

---

## Passo 3. Ativar e instalar

Tenha à mão o **e-mail que você usou na compra** e o **código da transação**. O código começa com **HP** e está no e-mail de confirmação da Hotmart (por exemplo HP1234567890123).

No Claude, escreva:

> **instala o Corta**

O Claude pede o e-mail e o código, ativa a sua licença neste Mac, baixa o programa e instala o resto sozinho, com a sua autorização: as ferramentas de vídeo e o programa que transcreve, que tem 1,6 GB. No fim ele faz um teste: o Mac fala uma frase e o Corta transcreve.

**Se o seu Mac não tiver o Homebrew** (a base que instala as ferramentas de vídeo), o Claude vai pedir que você cole um comando no Terminal e digite a senha do Mac. As letras da senha não aparecem enquanto você digita, e isso é normal. É a única vez que você digita algo fora do Claude.

**A licença vale em até 2 Macs.** Para trocar de computador, chame no WhatsApp: (31) 97131-5886.

---

## Passo 4. Usar

No Claude, escreva:

> **abre o Corta**

A tela do Corta abre no seu navegador (endereço `http://localhost:4747`). Ela continua funcionando enquanto o Mac estiver ligado, mesmo que você feche o Claude.

| Para… | Diga ao Claude |
|---|---|
| Abrir a tela | "abre o Corta" |
| Fechar | "fecha o Corta" |
| Quando um vídeo parar de baixar | "atualiza o Corta" |
| Quando algo der errado | "o Corta deu erro" |

Na tela:

1. **Biblioteca:** cole o link de um vídeo (YouTube, Instagram, TikTok…) ou arraste um vídeo do computador. Ele é transcrito sozinho.
2. **Cinema:** assista com a legenda e a transcrição ao lado. Traduza, busque qualquer palavra e peça os **destaques**, os melhores trechos para Reels e Shorts.
3. **Studio:** escolha o trecho, o formato (9:16, 1:1 ou 16:9) e o estilo da legenda, e exporte o corte.

Seus vídeos ficam em **Filmes → Corta**, e cada vídeo tem a própria pasta, com os cortes dentro.

---

## Atualizar o Corta

Quando sair uma versão nova, digite no Claude:

```
/plugin marketplace update corta
/plugin update corta@corta
```

Depois diga: **atualiza o Corta**.

---

## Problemas comuns

| O que acontece | O que fazer |
|---|---|
| "O Corta não abre" | Diga ao Claude: "abre o Corta". Se der erro, diga: "o Corta deu erro". |
| Um vídeo do YouTube parou de baixar | Diga: "atualiza o Corta". Os sites mudam e o baixador precisa de atualização. |
| Vídeo do Instagram pede login | Vídeos privados ou que pedem login ainda não funcionam. |
| "Não encontrei essa compra" | Confira o e-mail usado na compra e o código HP. Se acabou de comprar, espere 2 minutos. |
| "Sua assinatura do Corta terminou" | Renove pelo link que aparece. Seus vídeos e cortes continuam no Mac. |
| A tradução diz que o limite acabou | O limite de uso da sua assinatura do Claude acabou por agora. Tente mais tarde: a tradução continua de onde parou. |
| Pouco espaço no disco | Remova vídeos antigos pela tela do Corta (eles vão para a Lixeira). |

---

## Desinstalar

1. Diga ao Claude: **fecha o Corta**.
2. No Claude: `/plugin uninstall corta@corta`
3. Para liberar o espaço, apague estas pastas no Finder (menu **Ir → Ir para a Pasta…**):
   - `~/Library/Application Support/Corta` (programa e modelo, uns 3 GB)
   - `~/Library/Logs/Corta` (registros)
   - `~/Movies/Corta` (**seus vídeos e cortes**: só apague se não precisar mais deles)
