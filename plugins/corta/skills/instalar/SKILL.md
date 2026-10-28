---
name: instalar
description: "Use SEMPRE que a pessoa pedir para instalar, ativar ou configurar o Corta ('instala o Corta', 'ativa o Corta', 'ativar a licença do Corta', 'configura o Corta', 'primeira vez usando o Corta', 'comprei o Corta', '/corta:instalar') ou quando outra skill do Corta responder ERRO_FALTA_UV, ERRO_FALTA_PACOTE ou pedir para ativar. Ativa a licença com o e-mail e o código da compra, baixa o programa, confere o Mac e instala o que faltar, com autorização, e testa a transcrição. Para só conferir o estado do Corta, use a skill ajuda."
---

# Instalar o Corta

Responda sempre em português do Brasil, em frases curtas e sem termos técnicos: quem instala o Corta normalmente não é programador. Fale "o programa que transcreve" em vez de "Whisper", e "as ferramentas de vídeo" em vez de "ffmpeg / yt-dlp", a não ser que a pessoa pergunte.

Os scripts ficam em `scripts/`, na raiz do plugin, dois níveis acima da pasta desta skill. Defina e use em todos os comandos:

```bash
S="<pasta desta skill>/../../scripts"
```

Todos os scripts podem rodar quantas vezes for preciso: eles pulam o que já está instalado.

## 1. Conferir o computador

```bash
bash "$S/verificar.sh"
```

Cada linha é `OK`, `FALTA` ou `AVISO` com um item. A última linha decide o caminho:

- `TUDO_PRONTO`: diga que o Corta já está instalado e ofereça abrir (skill `abrir`).
- `INCOMPATIVEL chip`: o Corta precisa de Mac com chip Apple (M1 ou mais novo). Explique com gentileza e pare.
- `INCOMPATIVEL macos`: precisa do macOS 14 (Sonoma) ou mais novo. Explique como atualizar (Ajustes do Sistema → Geral → Atualização de Software) e pare.
- `INCOMPATIVEL espaco`: falta espaço no disco. Diga quanto há e quanto precisa, e pare.
- `FALTA_INSTALAR <itens>`: siga para o passo 2.

## 2. Ativar a licença (se aparecer `FALTA licenca`)

Peça para a pessoa, numa mensagem só:
- o **e-mail usado na compra**;
- o **código da transação**, que começa com **HP** e está no e-mail de confirmação da Hotmart (por exemplo HP1234567890123). Licenças de cortesia usam um código que começa com CORTESIA-.

Depois rode (com aspas):

```bash
bash "$S/instalar.sh" licenca "<email>" "<código>"
```

| Saída | O que fazer |
|---|---|
| `PASSO_OK licenca` | Siga em frente. |
| `ERRO_LICENCA_NAO_ENCONTRADA` | Mostre a mensagem e peça para conferir o e-mail e o código. Se a compra acabou de ser feita, espere 2 minutos e tente de novo. |
| `ERRO_LICENCA_MAQUINA` | A licença já está em 2 Macs. Explique e oriente a chamar o suporte no WhatsApp (31) 97131-5886 para liberar. |
| `ERRO_LICENCA_REEMBOLSADA`, `_CANCELADA`, `_EXPIRADA`, `_SUSPENSA` | Mostre a mensagem do servidor, que diz o que fazer. |
| `ERRO_LICENCA_INTERNET` | Sem conexão com o servidor de licença: confira a internet. |

Nunca invente nem "teste" códigos: use só o que a pessoa informou.

## 3. Pedir autorização

Mostre uma lista curta do que vai ser instalado, a partir dos itens que faltam, e avise:
- o download total fica perto de **2,5 GB** se faltar tudo (o modelo de transcrição tem 1,6 GB), e o Corta ocupa cerca de **4 GB** no disco depois de instalado;
- leva de **5 a 15 minutos**, conforme a internet;
- dá para usar o computador normalmente enquanto isso.

Pergunte se pode instalar. Só continue depois de um "sim".

## 4. Se faltar o Homebrew

O Homebrew é a base que instala as ferramentas de vídeo, e ele pede a senha do Mac. Por isso **a própria pessoa** precisa rodar um comando no Terminal. Você não consegue digitar a senha por ela. Explique assim:

1. Aperte **Command + Espaço**, digite **Terminal** e aperte **Enter**.
2. Cole este comando e aperte **Enter**:
   ```
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```
3. Quando pedir a senha, digite a senha do Mac e aperte **Enter**. As letras não aparecem enquanto você digita, e isso é normal.
4. Se perguntar algo, aperte **Enter** para confirmar.
5. Espere aparecer "Installation successful" (de 5 a 10 minutos) e me diga "pronto".

Quando a pessoa disser que terminou, rode `verificar.sh` de novo. Só siga se a linha do `homebrew` estiver `OK`.

## 5. Instalar, um passo de cada vez

Rode cada passo num comando separado, com o tempo limite do Bash em 10 minutos (600000 ms), e conte para a pessoa em uma frase o que terminou antes de seguir para o próximo:

```bash
bash "$S/instalar.sh" ferramentas   # ferramentas de vídeo e o uv (2 a 5 min)
bash "$S/instalar.sh" pacote        # o programa do Corta, baixado com a licença (alguns segundos)
bash "$S/instalar.sh" ambiente      # Python e bibliotecas (1 a 3 min)
bash "$S/instalar.sh" modelo        # programa que transcreve, 1,6 GB (3 a 10 min)
bash "$S/instalar.sh" teste         # o Mac fala uma frase e o Corta transcreve
```

Cada passo termina em `PASSO_OK <passo>` quando deu certo.

**Se o passo `modelo` estourar o tempo limite**, rode o mesmo comando de novo: o download continua de onde parou. As linhas `PROGRESSO NN%` mostram quanto já foi baixado.

### Erros

| Saída | O que fazer |
|---|---|
| `ERRO_FALTA_HOMEBREW` | Volte ao passo 4. |
| `ERRO_FALTA_LICENCA` | Volte ao passo 2. |
| `ERRO_PACOTE_NEGADO` | A licença não está ativa: mostre a mensagem que apareceu. |
| `ERRO_PACOTE_DOWNLOAD` ou `ERRO_PACOTE_INCOMPLETO` | A internet caiu: rode `pacote` de novo. |
| `ERRO_HOMEBREW` | Leia as linhas acima do erro. Se falar de permissão ou de "Command Line Tools", peça para a pessoa rodar `brew doctor` no Terminal e colar o resultado aqui. |
| `ERRO_AMBIENTE` | Quase sempre é internet. Confira e rode o passo de novo. |
| `ERRO_DOWNLOAD` ou `ERRO_MODELO` | Internet caiu ou falta espaço. Rode `modelo` de novo. |
| `ERRO_TESTE` | Leia a linha `TRANSCRICAO` (o que o Corta entendeu) e o fim de `~/Library/Logs/Corta/instalacao.log`. Explique em uma frase e proponha a correção. |

O registro completo da instalação fica em `~/Library/Logs/Corta/instalacao.log`.

Se a pessoa travar e você não conseguir resolver, passe o passo a passo com imagens (https://corta-site.marcostulio.workers.dev/instalar/) e o WhatsApp do suporte: (31) 97131-5886.

## 6. Concluir

Rode `verificar.sh` mais uma vez. Com `TUDO_PRONTO`:
- diga que o Corta está instalado e mostre a frase que ele transcreveu no teste;
- se apareceu `AVISO claude`, explique que a tradução e os destaques vão precisar do Claude Code instalado, e que o resto funciona;
- ofereça abrir o Corta (skill `abrir`).
