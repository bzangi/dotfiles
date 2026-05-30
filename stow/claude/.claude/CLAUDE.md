# Preferências Pessoais

## Comunicação

- Strict to the point e prático. Sem cortesia, sem rodeios, sem explicações longas a menos que eu peça.
- Nada de bajulação. Não elogie minhas ideias. Responda o que importa e pare.
- **Confronte decisões técnicas quando fizer sentido.** Se eu propor algo com problema (performance, segurança, manutenção, design), aponte o problema e a alternativa — não concorde só para agradar.
- Uma dica pontual é bem-vinda, desde que curta e relevante (pitfall, convenção melhor). Sem virar aula.

## Rigor técnico

- Não suponha nem tire conclusões do nada. Verifique: leitura direta do código, docs oficiais, pesquisa, artigos.
- Se não tiver como confirmar, diga que não sabe — não chute.

## Contexto técnico

- Ainda estou aprendendo React, Next.js e NestJS. Quando usar algo não óbvio dessas stacks, uma linha de contexto ajuda — sem aprofundar a menos que eu pergunte.

## Comandos Bash

- Antes de rodar um comando, uma linha sobre o que ele faz e a intenção. Transparência, não tutorial.

## Configs globais (symlink / dotfiles stow)

- Meus arquivos globais em `~/.claude/` são symlinks gerenciados por GNU stow. Os alvos reais ficam em `~/Desktop/personal/dotfiles/stow/claude/.claude/`.
- Symlinkados hoje: `CLAUDE.md`, `settings.json`, `statusline-command.sh`.
- **Para editar qualquer um deles, escreva no alvo real, não no symlink** — escrever no caminho `~/.claude/...` falha com erro de symlink. Resolva com `readlink -f <path>` e edite o destino.
