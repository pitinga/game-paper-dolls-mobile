# Veste & Cria — Bonecas de Papel

Jogo de vestir bonecas em **Godot 4.7.2** para Android. Um único aplicativo com uma coleção Free completa e uma coleção PRO adicional. O conteúdo funciona sem rede; a compra e a restauração PRO usam Google Play quando habilitadas.

## Coleções originais

| Categoria | Free | PRO |
| --- | ---: | ---: |
| Bonecas | **3** (Amora, Céu, Mel) | **10** (Luna, Yumi, Maya, Clara, Jade, Sol, Amira, Sofia, Isis, Tainá) |
| Blusas | 15 (5 por boneca Free) | 25 |
| Partes inferiores | 15 (5 por boneca Free) | 25 |
| Vestidos | 15 (5 por boneca Free) | 25 |
| Calçados | 15 (5 por boneca Free) | 25 |
| Acessórios | 15 (5 por boneca Free) | 50 |
| **Total de PNGs** | **78** | **160** |

**Free:** três bonecas e 25 peças exclusivas para cada uma. Cada peça Free encaixa exclusivamente em sua boneca; trocar de boneca remove peças incompatíveis. É possível combinar, desfazer, criar desafios e salvar/compartilhar looks.

**PRO:** dez bonecas e 150 roupas/acessórios originais, **sem compartilhar nenhuma imagem com a coleção Free**. Todos os itens PRO podem ser usados nas dez bonecas PRO, preservando a composição ao trocar entre elas.

Todos os **238 PNGs** usam fonte 1024×1536 com canal alfa, coordenadas unificadas e importação via Godot. O cache LRU guarda no máximo 12 texturas grandes ao navegar pelo catálogo. Existem cinco categorias no guarda-roupa: blusas, partes inferiores, vestidos, calçados e acessórios. O seletor de bonecas é paginado para celulares.

Os **recortes antigos de procedência não comprovada foram abandonados**: não há sprites `res://assets/paper/` usados no jogo, nem geração deles no CI. Eles nunca estiveram versionados na `main`, pois o diretório privado `assets/paper/` permanece ignorado. A arte nova utiliza os caminhos `assets/free_kawaii/` e `assets/kawaii/`, com proveniência descrita em [ASSETS-LICENSES.md](docs/ASSETS-LICENSES.md).

## Funcionalidades

- Vestir tocando ou arrastando; vestidos substituem blusa + parte de baixo.
- Paleta de cinco tons, desfazer, tirar peças, confirmação antes de limpar.
- Cinco cenários Free + três PRO; cinco desafios temáticos.
- Exportação PNG **540×640 sem menus** e compartilhamento nativo; validar a ponte de galeria MediaStore/FileProvider em aparelho Android.
- Salvamento local e restauração do estado; migração segura dos modelos Free descontinuados, sem renumerar os índices PRO históricos 4..13.
- Bloqueio de conteúdo premium: `PRO_SALES_ENABLED=false` até aprovação visual, integração de cobrança e testes em dispositivo. Direitos PRO positivos previamente reconhecidos continuam respeitados.

## Executar e testar

```bash
godot --headless --path . --editor --import --quit
godot --headless --path . --script res://tests/test_catalog_and_rules.gd
godot --headless --path . --script res://tests/test_free_kawaii_assets.gd
godot --headless --path . --script res://tests/test_kawaii_assets.gd
godot --headless --path . --script res://tests/test_kawaii_navigation.gd
godot --headless --path . --script res://tests/test_studio_integration.gd
godot --headless --path . --script res://tests/test_mobile_layout.gd
godot --headless --path . --script res://tests/test_visual_regressions.gd
godot --headless --path . --script res://tests/test_pro_debug_preset.gd
LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a godot --path . --script res://tests/test_graphical_export.gd
```

Para jogar:

```bash
godot --path .
```

O GitHub Actions valida os arquivos reais, direitos PRO, layout e exportação gráfica. **Não gera nem publica APK/AAB público**. Os presets Android/Google Play têm o app ID `com.pitinga.paperdolls`; o preset `Android Pro Test` é debug separado com `com.pitinga.paperdolls.protest`, sem permissão INTERNET, que não ativa vendas no app comercial.

## Direitos, privacidade e liberação

- Free: imagens produzidas especialmente para o projeto por gerador original de arte vetorial (`tools/generate_free_kawaii.py`). Cada um dos 78 PNGs foi gerado e persistido individualmente no GitHub.
- PRO: as 160 imagens originais anteriores permanecem integralmente, inclusive 39 acessórios vetoriais que exigem revisão estética adicional. Não houve extração do site recortar.com.br.
- O código é MIT, mas essa licença **não é automaticamente aplicada às imagens**; consultar [ASSETS-LICENSES.md](docs/ASSETS-LICENSES.md).
- **Sem anúncios ativos**. O plugin de Billing é redistribuído sob sua própria licença MIT e usa `pro_unlock` na Play Store quando o serviço for configurado.
- Testes automatizados não substituem revisão manual de encaixe, qualidade visual, consumo de memória, exportação/compartilhamento em celulares e compras/restauração do Google Play.

O lançamento comercial permanece bloqueado até esses critérios de qualidade e segurança serem cumpridos.
