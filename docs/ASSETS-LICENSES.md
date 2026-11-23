# Proveniência de imagens — Veste & Cria

**Atualizado em 23/11/2026.** O aplicativo agora usa **apenas o acervo original produzido para o projeto**, sem os recortes das quatro pranchas externas utilizados nos primeiros protótipos.

| Acervo | Arquivos | Origem / uso |
| --- | ---: | --- |
| `assets/free_kawaii/` | 78 PNGs (3 bonecas e 75 itens) | Gerador vetorial original do projeto, `tools/generate_free_kawaii.py` |
| `assets/kawaii/` | 160 PNGs (10 bonecas e 150 itens) | Ilustrações originalmente produzidas para o projeto com ferramentas de imagem, com 39 acessórios finais gerados como vetores originais |
| `assets/icon.svg` | 1 SVG | Ícone original do aplicativo |

Os dois catálogos são distintos: **nenhum dos 160 PNGs PRO é classificado como gratuito**. As roupas Free foram desenhadas com sistema de coordenadas comum à sua respectiva boneca. Os PNGs são separados do código licenciado sob MIT. Esta documentação descreve a procedência, **não garante exclusividade registral nem ausência absoluta de semelhanças acidentais com trabalhos de terceiros**.

## Substituição de artes externas

Os recortes antigos eram associados às quatro pranchas `01-1000347301.jpg`, `02-1000347300.jpg`, `03-1000347299.jpg` e `04-1000347298.jpg`, inicialmente apresentadas como referências de <https://recortar.com.br/bonecas-de-papel/>. As autorizações para redistribuição comercial e modificação não foram comprovadas. Por esse motivo:

1. Todos os modelos e itens antigos (`model_0..3`, `top_00...`, `dress_00...` etc.) foram retirados do catálogo jogável.
2. `scripts/paper_sprites.gd` não carrega mais nenhum arquivo de `assets/paper/`.
3. Os utilitários `tools/extract_paper_sprites.sh` e `tools/create_ci_sprite_fixtures.gd` foram excluídos.
4. O pipeline de teste **falha** se sprites externos aparecerem no checkout ou se o código runtime voltar a mencionar `res://assets/paper/`.
5. `assets/paper/` permanece no `.gitignore` para evitar uma inclusão acidental de arquivos locais legados.

Os antigos PNGs nunca foram commitados neste repositório público, portanto não existem arquivos binários antigos no histórico atual que precisem ser apagados. Quem possuir cópias locais fora do Git deve excluí-las separadamente antes de distribuir um build.

## Verificação antes de comercializar

Mesmo com a procedência substituída, são necessárias verificações de acabamento visual, sobreposição de camadas, memória no Android, revisão dos acessórios vetoriais PRO e políticas da Play Store. A cobrança permanece desabilitada até a aprovação dessas etapas.
