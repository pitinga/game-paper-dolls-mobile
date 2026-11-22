# Checklist para o revisor

Base: Godot 4.7.2, projeto `game-paper-dolls-mobile`, versão inicial 0.1.0.

## Código e testes

- `scripts/catalog.gd`: unicidade de IDs, contagens, premium e desafios.
- `scripts/studio_state.gd`: troca/limpeza de roupas, compatibilidade de camadas, undo, storage e sanitização.
- `scripts/doll_art.gd`: personagens, roupas e cenários gerados por desenhos originais.
- `scripts/studio.gd`: navegação, toque, drag, menus, Free/Pro e captura.
- `scripts/play_billing_bridge.gd`: adaptador do Pong reutilizado, sujeito a testes de compra/restauração na Play Store.
- `scripts/android_gallery.gd`: integração **experimental**, ainda sem validação no Android; falha deve preservar PNG privado.
- `tests/test_catalog_and_rules.gd`: 0 falhas esperado.
- `tests/test_studio_integration.gd`: 0 falhas esperado. O teste conhece e trata o renderer dummy em headless.
- `tests/test_pro_debug_preset.gd`: garante que o desbloqueio de teste não entre nos presets de produção.

## Cenários manuais essenciais

1. Arrastar/tocar peças de todas as categorias em Android 7, 10 e 14.
2. Arrastar com segundo dedo pressionado e percorrer a interface com gestos longos.
3. Vestido depois de blusa/calça; desfazer e trocar modelo; reiniciar app e recuperar look.
4. Aplicar 5 variações de cor, 8 cenários conforme autorização Pro, e completar 5 desafios.
5. Salvar imagem, encontrar na galeria em Android 10+, compartilhar e verificar se a UI não aparece no PNG.
6. Em Android 7–9, confirmar arquivo interno e definir fluxo de exportação pública.
7. Comprar Pro, cancelar, restaurar e testar quando sem rede/Google Play com compra positiva anterior.
8. Layout em 360x640, 540x960, 540x1200 e tablet; checar notch e botões de navegação.
9. Verificar que não há APK/AAB público, segredos nem IDs de anúncios. `Android Pro Test` é um APK debug em pacote separado (`com.pitinga.paperdolls.protest`), sem cobrança real.
