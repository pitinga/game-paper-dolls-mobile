# Veste & Cria — catálogo Kawaii PRO (integração Godot)

## Conteúdo integrado

- **10 bonecas kawaii originais**: Luna, Yumi, Maya, Clara, Jade, Sol, Amira, Sofia, Isis e Tainá. Os quatro modelos gratuitos legados continuam disponíveis (14 modelos no total).
- **100 roupas e calçados**: 25 tops, 25 partes inferiores, 25 vestidos e 25 calçados.
- **50 acessórios**: tiaras, chapéus, bolsas, óculos, colares, pulseiras e cachecóis.
- **160 PNGs** com canvas 1024 × 1536 e canal alfa, preservados em `assets/kawaii/`.
- O inventário de IDs e nomes está em `scripts/kawaii_collection.gd` (gerado a partir de `docs/KAWAII-PRO-ASSET-MANIFEST.json`).
- `scripts/catalog.gd` expõe as peças como premium e compatíveis com qualquer uma das dez bonecas kawaii, **não** com os quatro modelos antigos.
- `scripts/paper_sprites.gd` faz renderização pelo mesmo sistema de coordenadas; `scripts/studio.gd` disponibiliza quatro modelos por página e navegação entre as quatro páginas.

## Compatibilidade e segurança

- O jogo **mantém IDs PRO antigos** (`pro_kawaii_*_00`) e índices de boneca PRO 4..13 para preservar looks de versões anteriores. Os antigos quatro modelos Free foram retirados por limitações de direitos; o índice legado 3 é reservado e não selecionável.
- Trocar entre bonecas PRO mantém o look escolhido; trocar para uma boneca Free remove itens incompatíveis. Cada boneca Free tem seus próprios 25 itens e não compartilha roupas com outra boneca.
- O bloqueio Pro não pode ser burlado por edição do arquivo de looks: o jogo valida direito e categoria antes da restauração.
- O modo Pro Test só libera conteúdo no preset debug dedicado; **PRO_SALES_ENABLED permanece false** na distribuição normal. A nova coleção Free de 78 PNGs fica em `assets/free_kawaii/` e não contém os 160 PNGs PRO.
- O cache de texturas Free e PRO tem limite compartilhado de 12 elementos, para não reter 238 imagens grandes em memória durante a navegação.

## Testes automatizados

```bash
godot --headless --path . --editor --import --quit
godot --headless --path . --script res://tests/test_catalog_and_rules.gd
godot --headless --path . --script res://tests/test_kawaii_assets.gd
godot --headless --path . --script res://tests/test_kawaii_navigation.gd
LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a godot --path . --script res://tests/test_graphical_export.gd
```

Os testes verificam os 160 PNGs, dimensões, transparência nos cantos, IDs únicos, disponibilidade premium, navegação, persistência dos looks e exportação gráfica de modelos selecionados. **Isso não equivale à aprovação manual de acabamento nem à verificação visual individual de todos os 150 acessórios e roupas em cada uma das dez bonecas.**

## Aprovação necessária antes de comercializar

1. Testar em aparelho Android as três bonecas Free e dez bonecas PRO, todas as categorias, os encaixes das roupas e a exportação.
2. Revisar a coerência estética dos 39 acessórios gerados por desenho vetorial programático (estilo mais plano que a aquarela das bonecas).
3. Confirmar que todos os recortes de `assets/paper/` permanecem ausentes do build; conferir procedência dos novos assets em `docs/ASSETS-LICENSES.md`.
4. Testar o fluxo de compra/restauração na Play Store e manter vendas desligadas até a aprovação.

O catálogo kawaii não foi extraído do site recortar.com.br. Parte foi gerada com ferramentas de imagem e parte como desenho vetorial original para este projeto. Não se presume exclusividade registral ou garantia absoluta de inexistência de semelhanças com trabalhos de terceiros.
