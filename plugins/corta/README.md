# Corta

Baixe, transcreva, traduza e corte vídeos no seu Mac. O Corta abre uma tela no navegador (http://localhost:4747) com a biblioteca de vídeos, um player com a transcrição ao lado e um editor de cortes. Tudo roda no seu computador: nenhum vídeo é enviado para servidor.

**Requisitos:** Mac com chip Apple (M1 ou mais novo) e o Claude Code instalado e conectado à sua conta (a tradução usa a sua assinatura do Claude).

## Como usar

- "instala o Corta" ou `/corta:instalar`: confere o Mac e instala o que faltar (uma vez só).
- "abre o Corta" ou `/corta:abrir`: liga o Corta e abre a tela no navegador.
- "fecha o Corta" ou `/corta:parar`: desliga o Corta.
- "atualiza o Corta" ou `/corta:atualizar`: atualiza o baixador de vídeos (quando um site para de funcionar) e as bibliotecas.
- "o Corta deu erro" ou `/corta:ajuda`: junta as informações e explica o problema.

O passo a passo completo para quem vai instalar está em [INSTALACAO.md](../../INSTALACAO.md).

## Onde ficam as coisas

- Vídeos: `~/Movies/Corta`
- Ambiente do programa: `~/Library/Application Support/Corta`
- Registros: `~/Library/Logs/Corta/` (servidor, instalação e transcrição)

## Estado

Versão 0.8.0:

- **Biblioteca:** baixa vídeos por link (com pausa e retomada) e importa vídeos do Mac. Formatos que o navegador não toca (ProRes, AVI, MKV…) ganham uma cópia em MP4 automaticamente.
- **Transcrição:** feita no próprio Mac, com o idioma detectado sozinho, em frases curtas que acompanham a fala. A legenda pode ser baixada em `.srt`.
- **Tradução:** feita pelo seu Claude (a assinatura que você já tem, sem chave de API) para português, inglês, espanhol e outros idiomas. Ele lê o vídeo inteiro antes, para manter nomes e termos iguais do começo ao fim, e cada frase traduzida fica no mesmo tempo da original. Se parar no meio, continua de onde parou sem gastar de novo.
- **Destaques:** o Claude lê o vídeo e sugere de 3 a 10 trechos de 15 a 90 segundos com mais chance de prender a atenção num Reels, Short ou TikTok, cada um com título, gancho, motivo e nota. Dá para dizer o que você procura ("trechos sobre vendas") e assistir cada trecho direto no Cinema.
- **Studio:** escolha o trecho clicando nas frases (Shift+clique para terminar), a partir de um destaque ou do Cinema, ajuste o início e o fim em meio segundo, escolha o formato (9:16, 1:1 ou 16:9) e o enquadramento, o estilo da legenda (clássico, caixa ou karaokê) e se ela mostra o original, a tradução ou os dois. A prévia mostra a legenda exatamente como vai sair. O corte é exportado em MP4 na pasta `cortes` do vídeo.
- **Cinema:** player com legenda original, traduzida ou as duas (a palavra falada acende), transcrição ao lado que acompanha o vídeo, clique numa frase para pular até ela, busca dentro do vídeo e busca no que foi falado em todos os vídeos, nas duas línguas. O Corta lembra onde você parou.
- Atalhos no Cinema: espaço (tocar e pausar), ← → (frase anterior e próxima), F (tela cheia), / (buscar).



Cada vídeo fica numa pasta própria dentro de `~/Movies/Corta`, com o vídeo, a capa e um `item.json`. Remover um vídeo pela tela manda a pasta para a Lixeira.
