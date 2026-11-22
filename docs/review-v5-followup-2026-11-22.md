# Devolutiva ao revisor — capturas V5 e relatório anterior

Data: 22/11/2026. Projeto: `pitinga/game-paper-dolls-mobile`.
Branch de trabalho: `fix/paper-dolls-visual-review-v5`. Base examinada: `aa86717`.

## Método e distinção das versões

O relatório recebido descreve a base `def38fc4` (V4, parcialmente não commitada),
enquanto as cinco capturas mais recentes foram feitas na V5. Assim, os problemas
de V4 não foram automaticamente considerados presentes na V5. Revisamos as
capturas de início, estúdio com desafio, blusas e cabelos e o código existente.
Executamos Godot headless e os testes locais; **não** executamos Android, o
chooser de compartilhamento, o fluxo real da Play Store ou um APK desta rodada.

## Correções já existentes na V5 (`aa86717`)

- Recortes privados reais das quatro bonecas e roupas, inclusive sapatos sem
  duplicar as sandálias originais; as bordas retangulares dos vestidos foram
  removidas. Os PNGs não entram no Git público.
- Interface inicial e de estúdio sem texto cortado; fluxo de **Salvar** e
  **Compartilhar** separado, com mensagens distintas para galeria e armazenamento
  privado; estado de Pro Test restrito ao build de debug com feature dedicada.
- Testes headless, fixtures sintéticas no workflow e documentação dos direitos
  pendentes da arte em `docs/ASSETS-LICENSES.md`.

## Alterações deste acompanhamento (V6 proposta)

| ID | Estado | Ajustes / evidência no código |
| --- | --- | --- |
| VIS-04 / VIS-01 | Mitigado; conferir em aparelho | `tools/extract_paper_sprites.sh`: erosão de 1 px no alfa, máscara dos três vestidos com fragmento superior esquerdo; recortes privados regenerados e examinados sobre fundo escuro. `tests/test_visual_regressions.gd`: todos os 41 sprites, cantos, alfa e listras opacas. |
| UX-03 | Corrigido no código | `scripts/studio.gd`: removidos aviso de configuração de anúncios e nota técnica sobre links. |
| UX-04 | Corrigido no código | `scripts/studio.gd`/`studio_state.gd`: card escolhido marcado com borda e ✓, segundo toque remove e Desfazer restaura. `scripts/paper_sprites.gd`: extras vetoriais agora são desenhados na boneca quando não há PNG. |
| TXT-01 | Corrigido no código | `scripts/catalog.gd`: contador “Shorts e saias”; nomes de roupas por motivo/formato, sem cor enganosa. `tests/test_catalog_and_rules.gd`: regressão. |
| UX-05 | Corrigido no código | Cenários em miniatura com paisagem e boneca reais, borda de seleção e cadeado só para peças Pro ainda não adquiridas. |
| UX-06 | Parcialmente corrigido | `scripts/studio.gd`: Restaurar desaparece quando o Pro já está ativo; o Pro Test não consulta Billing ao voltar ao app (não exibe aviso falso de Google Play); desafios concluídos persistem, exibem estrela e peças do tema têm marcador. “Em breve” visualmente indisponível. Minicartelas temáticas e compra real seguem pendentes. |
| UI-02 | Parcial | Duplo toque para limpar, com janela de 4 s, e ação Voltar por teclado/Android. Teste de layout em 360×800, 540×960, 540×1200, 720×1280. Alvos de 48 **dp reais**, safe area e acessibilidade devem ser medidos em aparelho. |
| VIS-02 | Decisão de produto provisória | As cabeças têm cabelo incorporado na imagem. O complemento traseiro não troca o penteado-base. Foram retirados os arcos de cor clara sobre a franja que apareciam nas capturas V5; futura troca integral requer camadas licenciadas específicas por modelo. |
| UX-02 | Já implementado na V5; Android pendente | Tela de resultado distingue “Salva na galeria” de “Guardada no jogo” e mantém botão Compartilhar. Não existe ainda uma galeria interna de criações. |
| PROC-01 | Corrigido localmente; CI remoto pendente | Branch já commitada antes deste acompanhamento; workflow gera 41 sprites sintéticos sem enviar imagens de origem. A aprovação do CI deste novo commit ainda depende de execução remota. |
| TEST-01 / VIS-03 | Parcial | Verificações estáticas e de alfa para os 41 assets e captura por modelo quando há renderer. Godot headless usa renderer dummy e **não confirma pixels**. Matriz visual de todos os itens × 4 modelos ainda necessita aparelho ou renderer gráfico. |
| ART-01 | Bloqueador de publicação | Não há autorização comercial comprovada da arte de terceiros; nenhum recorte deve ir para repositório público, release ou Play Store antes da licença formal ou substituição por arte original. Não apagar possível marca d'água para contornar direitos. |
| AND-01 / AND-02 / BILL-01 | Pendentes de aparelho e Play Store | Compartilhamento MediaStore/FileProvider, alerta Play Protect e compra/restauração reais não foram executados nesta rodada. O risco do manifesto/FileProvider exportado deve ser validado no APK e no dispositivo. |

## Achados especificamente nas cinco imagens V5

1. Traços semicirculares claros surgiam sobre a franja, inclusive sobre cabelos já incorporados à boneca. Eliminados no desenho frontal; extensões continuam por trás.
2. Banner de progresso do desafio e aviso “Desafio concluído!”/“Google Play indisponível” se sobrepunham no topo. O toast foi deslocado para a base da área de desenho, fora do progresso, e o desafio concluído aparece uma vez por desafio. O Pro Test não chama `billing.refresh()` ao retomar sem inicialização, que provocava o aviso de Google Play; há regressão de integração.
3. A seleção de uma bolinha turquesa não significava que o tecido ou o cabelo mudaria para turquesa. A paleta passou a mostrar os tons de filtro **efetivamente usados** nas peças e o rótulo passou a “Tom”. Os cabelos originais não são recoloríveis.
4. A lista de cabelos na V5 oferece complementos; não há alteração completa da franja. Este limite deve ser explicado até termos arte em camadas.
5. A tela inicial está organizada e legível; não houve mudança radical de estilo para preservar o avanço já demonstrado.

## Comandos executados nesta rodada

Ambiente local: Linux, Godot `4.7.2.stable.official`, ImageMagick
`7.1.1-43 Q16 x86_64`; sprites privados extraídos das quatro pranchas fornecidas
para `assets/paper/` (diretório ignorado pelo Git).

```sh
bash tools/extract_paper_sprites.sh ../upload
godot --headless --path . --editor --import --quit
godot --headless --path . --quit
godot --headless --path . --script res://tests/test_catalog_and_rules.gd
godot --headless --path . --script res://tests/test_studio_integration.gd
godot --headless --path . --script res://tests/test_mobile_layout.gd
godot --headless --path . --script res://tests/test_pro_debug_preset.gd
godot --headless --path . --script res://tests/test_visual_regressions.gd
```

Os cinco testes de GDScript finalizaram com **0 falhas** em execução headless.
O teste visual informa explicitamente que a renderização por pixels não está
disponível no renderer dummy. Não afirmar equivalência com Android.
Também foi repetido o fluxo de CI num worktree limpo, gerando as 41 fixtures
sintéticas sem pranchas privadas e verificando os checksums do plugin de cobrança.
O oráculo de sapatos foi ajustado para ignorar a margem transparente *antes* do
desenho, e as regressões passaram nessa execução isolada.

## Próxima revisão / critérios de aceite

1. Instalar APK de debug de **commit rastreado** e verificar cabelos, extras, 
   41 sprites (cantos e halos) em fundo escuro, quatro modelos e controles em
   360 dp reais; capturar telas em cada categoria.
2. Fazer teste funcional Android 14 de Salvar e Compartilhar para WhatsApp,
   Instagram e outros apps, com logcat; examinar manifest final e URI grant.
3. Investigar o Play Protect sem supor a causa e testar assinatura/release via
   Play Store. Não orientar instalação contra alerta de segurança.
4. Validar compra, restauração e entitlement offline com contas de licença.
5. Obter licença comercial dos recortes ou encomendar arte original para
   publicação. Este item continua bloqueante.
