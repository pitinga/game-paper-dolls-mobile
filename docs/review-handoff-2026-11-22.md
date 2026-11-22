# Relatório técnico para revisão — Veste & Cria / Paper Dolls Mobile

**Data:** 22/11/2026 (horário de Brasília)
**Repositório:** `pitinga/game-paper-dolls-mobile`
**Motor:** Godot `4.7.2.stable.official.ed1daf0bf`, GDScript
**Artefato avaliado:** Android Pro Test `0.1.0-pro-test.4`, `versionCode=4`
**Objetivo:** corrigir defeitos visuais reportados em capturas do Android e simplificar o fluxo de salvar e compartilhar looks.

## 1. Base de código e limites da revisão

- `HEAD` local **antes das alterações**: `def38fc4e7e78be0a3771b9542925e61d4f598f6` (`build(android): add isolated Pro debug APK preset and test`).
- As alterações descritas estão **no diretório de trabalho local de `main`, ainda sem commit e sem push**. Não atribuir esta versão a uma branch remota ou a um commit que não existe.
- Arquivos novos: `scripts/paper_sprites.gd`, `tools/extract_paper_sprites.sh`, `tests/test_mobile_layout.gd`, respectivos `.uid` gerados e **41 imagens PNG** em `assets/paper/`.
- Arquivos alterados: `scripts/studio.gd`, `scripts/android_gallery.gd`, `scripts/portrait_canvas.gd`, `scripts/catalog.gd`, `export_presets.cfg`, `tests/test_studio_integration.gd`, `tests/test_pro_debug_preset.gd`, `.github/workflows/test.yml` e `README.md`.
- O diretório `build/` contém o APK de teste, não versionado.
- **Alerta de direitos autorais:** as quatro pranchas de origem foram fornecidas pelo usuário, mas vieram de material associado ao site recortar.com.br. O direito de redistribuição não foi comprovado. Os recortes em `assets/paper/` e o APK com essas imagens são **apenas para avaliação privada**. Não publicar arte/APK em repositório público, releases ou Play Store sem licença adequada ou substituição por arte autorizada.

### Matriz de status

| ID | Problema relatado | Estado após alteração | Limite de evidência |
|---|---|---|---|
| VIS-01 | Vestidos exibem retângulos de fundo | **Corrigido nas amostras verificadas** | Alguns recortes testados por transparência; falta revisar todo o catálogo em dispositivo |
| VIS-02 | Opções de cabelo não produzem efeito | **Alteração funcional implementada** | Alteração de look visível em Godot desktop; qualidade artística ainda provisória |
| VIS-03 | Roupas/sapatos se sobrepõem incorretamente | **Ajustado parcialmente** | Encaixes usam retângulos fixos; falta matriz com quatro modelos e todas as peças |
| UI-01 | Textos, paleta e botões se sobrepõem | **Corrigido nos cenários exercitados** | Geometria testada em quatro dimensões; faltam notch, barras e gestos em Android |
| UX-01 | Tela infantil exibe “Salvar PNG” | **Corrigido** | Interface agora exibe “Salvar” e “Compartilhar”; verificado no desktop |
| AND-01 | Compartilhar imagem por aplicativos | **Implementado, não validado em Android** | APIs nativas só podem ser validadas em aparelho/emulador Android |
| SEC-01 | APK Pro e permissões | **Exportação/assinatura verificadas** | Play Protect anteriormente sinalizou o app; causa não identificada |
| LIC-01 | Uso público dos recortes do site | **Bloqueador de publicação** | Exige comprovação de licença ou substituição da arte |

## 2. Alterações por área e testes de regressão

### VIS-01 — Remoção de fundos e recortes das pranchas

**Causa:** imagens de roupas extraídas como recortes retangulares mantinham partes do fundo original; o vestido aparecia cercado por um bloco colorido sobre a boneca.

**Alteração:** `tools/extract_paper_sprites.sh` usa ImageMagick para extrair as pranchas, remover o fundo por flood-fill a partir de múltiplos cantos e eliminar um pequeno fragmento estranho em três vestidos. Os resultados ficam em `assets/paper/*.png`. `scripts/paper_sprites.gd::_fit_centered/_fit_top/draw_item_on_doll` os desenha com alfa.

**Evidência:** `tests/test_mobile_layout.gd` verifica cantos transparentes de `dress_00`, `dress_01` e `dress_02`. Visualmente, o primeiro vestido foi vestido na execução desktop e o retângulo de fundo não apareceu.

**Limites:** não há teste de máscara para cada pixel e cada uma das 41 imagens; o flood-fill por tolerância pode preservar halo ou apagar detalhes de cor parecida com o fundo. Revalidar cortes com imagens-alvo antes de aceitar.

### VIS-02 — Penteados e camadas

**Causa:** alguns itens de cabelo existiam no catálogo, mas não geravam modificação visível adequada sobre as bonecas recortadas.

**Alteração:** `scripts/paper_sprites.gd::draw_stage/_draw_hair_style` desenha extensões para `solto`, `trancas` e `cacheado` **atrás** da base do rosto/cabelo, e detalhes de `coques` por cima. `scripts/catalog.gd::MODEL_HAIR` aproxima as cores das quatro personagens. A primeira tentativa de fios sobre o rosto foi descartada após inspeção visual; a versão entregue usa a ordenação corrigida.

**Evidência:** `tests/test_mobile_layout.gd` percorre quatro IDs de cabelo, verifica que cada escolha substitui a anterior; o efeito visual de `solto` foi visto na execução desktop.

**Limites:** os recortes originais já contêm cabelo fixo. As opções atuais são complementos, **não** quatro penteados ilustrados integralmente em cada modelo. Não aceitar o teste de estado como prova de qualidade visual. Recomenda-se arte dedicada para os penteados.

### VIS-03 — Geometria de roupa e calçados

**Causa:** parte das roupas não coincidia com a cintura/torso; a sandália embutida no personagem podia continuar aparecendo debaixo do sapato escolhido.

**Alteração:** `SHORTS_RECT`, `PANTS_RECT`, `DRESS_RECT`, `SHOES_RECT` em `scripts/paper_sprites.gd` definem posições compartilhadas para a cena lógica de 540×640. O script de extração gera `model_0_bare` até `model_3_bare` com remoção da região inferior; `draw_stage()` troca para a versão sem sandálias apenas quando há calçado selecionado.

**Evidência:** `tests/test_mobile_layout.gd` verifica inclusão de retângulos, presença dos modelos alternativos e alfa na região inferior. No desktop, foi observada a montagem do primeiro vestido.

**Limites:** a máscara de pés é aproximada; em alguns sapatos, modelos ou posições podem surgir lacunas ou contornos duplos. As coordenadas não têm rigging por modelo. Matriz manual ainda requerida.

### UI-01 — Responsividade e áreas de toque

**Causa:** quatro botões do cabeçalho tinham limites fixos que colidiam em telas menores, e os círculos da paleta chegavam à faixa dos comandos inferiores.

**Alteração:** `scripts/studio.gd::_studio_header_rects` calcula quatro retângulos proporcionais, usados tanto por `_draw_studio` quanto por `_studio_tap`. `WARDROBE_HEIGHT=360` separa cards, paginação, cores e rodapé; `_pointer_up`, `_card_at` e `_studio_tap` usam a mesma referência. A área do rodapé tem prioridade de toque; o rótulo “Cor” muda de posição em telas estreitas. `_label_layout` centraliza as strings no desenho (ajuste acumulado nesta revisão local).

**Evidência:** `tests/test_mobile_layout.gd` cobre 360×800, 540×960, 540×1200 e 720×1280 (limites de botões, prancheta e espaço paleta/rodapé); `tests/test_studio_integration.gd` foi atualizado para o novo Y da categoria. Telas inicial/estúdio/conclusão foram abertas e inspecionadas no Godot desktop em viewport 540×960.

**Limites:** os testes de geometria não equivalem a testes de screenshot, nem cobrem orientação alterada, fonte do sistema, display cutout ou teclado de navegação do Android.

### UX-01 — Texto amigável para criança

**Causa:** exibição de “PNG” e nome técnico do arquivo na tela final.

**Alteração:** `scripts/studio.gd::_draw_finish/_handle_tap/export_png` mostra **SALVAR**, **COMPARTILHAR**, **CRIAR OUTRO LOOK**, além de confirmação simples (“Criação salva”); os termos técnicos ficaram restritos ao código/logs. O botão Compartilhar permanece disponível antes de salvar.

**Evidência:** tela final aberta em Godot desktop; o botão Salvar gerou confirmação “Imagem salva no aplicativo!”. `tests/test_studio_integration.gd` exercita o caminho headless sem textura de GPU, **não** verifica os pixels do arquivo exportado.

### AND-01 — Galeria e compartilhamento Android

**Causa:** o fluxo anterior dependia de URI de galeria; quando essa URI falhava ou não existia, o compartilhamento não podia iniciar.

**Alteração:** `scripts/android_gallery.gd::save_png` tenta MediaStore no Android 10+ (API 29+); em falha, mantém cópia privada. `share_image(local_path,gallery_uri)` prioriza a URI da galeria e usa `androidx.core.content.FileProvider` sobre o arquivo privado na ausência dela; cria `Intent.ACTION_SEND` com MIME `image/png` e permissão temporária de leitura. `scripts/studio.gd::share_creation` salva antes de compartilhar, se necessário.

**Evidência:** o código GDScript compila e exporta. O APK possui o `FileProvider` do template padrão do Godot e foi inspecionado estaticamente. **Não houve teste efetivo de abertura do chooser, cópia via MediaStore, entrega da URI, WhatsApp ou Instagram no Android.**

**Pontos prioritários para o revisor:**

1. Confirmar JavaClassWrapper/AndroidRuntime, overload `java.nio.file.Files.copy(Path,OutputStream)`, controle de exceções e fechamento dos streams em dispositivo.
2. Testar API 24–28 (arquivo privado + FileProvider) e API 29–35+ (MediaStore + FileProvider fallback).
3. Em caso de falha da galeria, a mensagem “Imagem salva no aplicativo!” não implica visibilidade na galeria; definir UX antes de produção.
4. Confirmar URI, `FLAG_GRANT_READ_URI_PERMISSION`, abertura/retorno do chooser, e recebimento efetivo por WhatsApp/Instagram, inclusive Stories.
5. Verificar que o `startActivity` assíncrono na UI thread relata falhas adequadamente; o retorno imediato de `share_image` não comprova que outro app recebeu a foto.

## 3. Comandos e resultados efetivamente executados

**Ambiente:** Linux do executor; Godot `4.7.2.stable.official.ed1daf0bf`; Android SDK Build Tools `36.1.0`. Não foi executado Android físico, emulador, Play Store nem profiler.

| Comando | Resultado observado |
|---|---|
| `godot --headless --path . --editor --import --quit` | Exit `0`; importação dos sprites concluída |
| `godot --headless --path . --script res://tests/test_catalog_and_rules.gd` | Exit `0`; **0 falhas** |
| `godot --headless --path . --script res://tests/test_studio_integration.gd` | Exit `0`; **0 falhas** |
| `godot --headless --path . --script res://tests/test_mobile_layout.gd` | Exit `0`; **0 falhas** |
| `godot --headless --path . --script res://tests/test_pro_debug_preset.gd` | Exit `0`; **0 falhas** |
| `godot --headless --path . --export-debug 'Android Pro Test' build/paper-dolls-pro-test-ui-share.apk` | Exit `0`; APK gerado e assinado |
| `apksigner verify --verbose build/paper-dolls-pro-test-ui-share.apk` | Exit `0`; assinatura v2 e v3 **verificadas**; 1 signatário |
| `aapt dump badging build/paper-dolls-pro-test-ui-share.apk` | `com.pitinga.paperdolls.protest`; API mínima `24`, alvo `36`, `arm64-v8a`, versionCode `4` |
| `aapt dump permissions build/paper-dolls-pro-test-ui-share.apk` | Nenhuma permissão declarada na listagem |

O comando de exportação usou variáveis `GODOT_ANDROID_KEYSTORE_DEBUG_PATH/USER/PASSWORD` apontando para um keystore de **debug local**. Não há assinatura de release para Play Store e nenhum segredo deve ser copiado para a revisão.

**SHA-256 do APK examinado:** `cf22b54d3b039667c8d025ad0ce14014a124668f70547fb0a1779500d6528283`.

**Arquivo:** `build/paper-dolls-pro-test-ui-share.apk` (aprox. 30 MiB, para teste privado).

## 4. Regressões recomendadas antes do aceite

### P1 — Produto, Android e licenciamento

- [ ] **ART-01:** obter licença verificável das imagens ou substituí-las por recursos originais autorizados **antes** de qualquer push público de `assets/paper/` ou distribuição pública do APK.
- [ ] **AND-01:** executar salvar, salvar novamente, compartilhar sem salvar, compartilhar depois de salvar e após reiniciar o app no Android 14 do usuário; validar arquivo real recebido no WhatsApp e Instagram.
- [ ] **AND-02:** investigar o alerta anterior “App nocivo bloqueado” do Play Protect. **Não** pedir para o testador ignorar proteção como solução.
- [ ] **VIS-01:** inspecionar cada uma das 41 imagens alfa e cada vestido/roupa montada; comparação por screenshots/golden images em resoluções 360×800, 540×960 e 20:9.
- [ ] **VIS-02:** verificar todos os penteados nas quatro bonecas, incluindo a qualidade do cabelo original e recortes; decidir se o protótipo precisa de novo conjunto de cabelos desenhados especificamente.

### P2 — Interação, persistência e compatibilidade

- [ ] Testar drag, toque simples, segundo dedo, troca rápida de categoria, desfazer e limpar com controles do Android.
- [ ] Conferir todos os sapatos com as versões `model_*_bare` para detectar lacunas nas pernas e calçados duplicados.
- [ ] Testar salvamento da galeria em Android 10, 12, 14 e fallback no Android 7–9; o texto do app deve refletir o destino real.
- [ ] Adicionar teste de screenshot/bitmap do arquivo exportado, sem controles, em vez de depender somente do caminho headless sem render.
- [ ] Verificar Pro comprado/restaurado e disponibilidade offline; o APK **Pro Test** não exercita Google Play Billing real.
- [ ] Confirmar que a pipeline não referencia `assets/paper` ausentes: **o CI no GitHub falhará** se o código/testes forem enviados sem os sprites necessários.

## 5. Instruções ao revisor e veredito solicitado

1. Revisar a **árvore local não commitada** a partir de `def38fc4`, não apenas o diff de arquivos rastreados (`git diff` omite scripts, sprites e testes ainda não adicionados ao índice).
2. Verificar em especial `scripts/paper_sprites.gd`, `tools/extract_paper_sprites.sh`, `scripts/studio.gd`, `scripts/android_gallery.gd` e `tests/test_mobile_layout.gd`.
3. Separar “passou no teste headless” de “validado em Android” e “qualidade visual aceita”.
4. Classificar por **confirmado**, **não reproduzido**, **pendente de aparelho** ou **decisão de produto**; trazer contraexemplos concretos e testes que falhem antes da próxima correção.
5. Não aprovar publicação, merge ou distribuição pública de ilustrações até resolver **ART-01**. Não declarar o compartilhamento externo concluído sem testar **AND-01**.

**Veredito de implementação:** melhorias de UI, recortes e UX aplicadas; **4 suítes headless verdes**, exportação APK e assinatura verificadas. **Aceite de experiência visual e compartilhamento Android: pendente. Publicação: bloqueada por licenciamento das imagens e validação Play Protect.**
