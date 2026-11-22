# Veste & Cria — Bonecas de Papel

Jogo de vestir bonecas, em português, feito em **Godot 4.7.2** para Android. Projeto com código aberto e arte original feita por desenhos vetoriais em GDScript.

## O que já está implementado

- Escolha de **4 personagens** com tons de pele e cabelos diferentes, mas a mesma base de encaixe de roupas.
- Guarda-roupa grátis com **30 roupas**, **12 acessórios** e **4 penteados**. Coleção extra de 24 peças Pro.
- Arrastar com dedo ou tocar na miniatura para vestir; peças se encaixam por categoria. Vestido substitui blusa + parte de baixo.
- Trocar peça, retirar categoria, variar cores, desfazer e limpar o look.
- **8 cenários**, sendo 5 grátis e 3 Pro; **5 desafios temáticos** sem cronômetro, com progresso de 0 a 2.
- Tela de conclusão e botão para salvar **PNG limpo, sem menus**.
- Um único aplicativo com produto interno não consumível `pro_unlock`, sem permissões para abrir Pro gratuitamente por um botão.
- Salva as configurações do look localmente; funciona sem rede na parte de vestir.
- Menu "Mais jogos" preparado para divulgar os outros títulos quando seus links oficiais estiverem disponíveis.

## Executar

```bash
godot --path .
```

## Testar

```bash
godot --headless --path . --editor --import --quit
godot --headless --path . --script res://tests/test_catalog_and_rules.gd
godot --headless --path . --script res://tests/test_studio_integration.gd
```

Não houve geração ou publicação de APK/AAB nesta rodada. `export_presets.cfg` prepara Android **7+ (API 24), ARM64** e uma única versão Free + Pro interno. O CI executa testes, mas não distribui arquivos binários em um repositório público.

## Privacidade e compras

- **Anúncios desativados** nesta versão. Nenhum identificador de produção do AdMob foi integrado.
- A experiência de vestir e os PNGs são gratuitos. Pro acrescenta peças, variações e cenários exclusivos.
- O plugin `GodotGooglePlayBilling` (MIT; cópia da versão usada no Pong) permite adquirir e restaurar `pro_unlock` via Play Store quando o produto for criado no Console e o app for distribuído pelo Google Play.
- Uma confirmação positiva de Pro é persistida. Falhas/ausência temporária na resposta do Google Play **não removem** o direito previamente reconhecido.
- O PNG é gravado em `user://criacoes/` (armazenamento interno do aplicativo). Há uma **ponte experimental** de MediaStore/ShareSheet para Android 10+; se ela falhar, o PNG interno é mantido. No Android 7–9 ainda não há gravação direta na galeria. A ponte não foi validada num dispositivo real e não deve ser anunciada como garantia de compartilhamento até o teste.
- Somente jogos efetivamente publicados terão links de instalação. Não há URL inventada para apps ainda não lançados.

## Direitos autorais

As imagens de referência de bonecas de papel serviram para compreender a mecânica do jogo. **Não foram incluídas sprites, roupas ou personagens copiados do site de referência**. A arte atual é programática e original, com licença MIT no código. O plugin Billing incluído tem licença MIT própria em `addons/GodotGooglePlayBilling/LICENSE`.

## Próximos critérios de aceite

1. Testar arrastar, largar, menus e layout em Android com toque real, notch e telas 16:9 / 20:9.
2. Validar a ponte MediaStore/ShareSheet no Android 10–14 e estender exportação para a galeria no Android 7–9 (sem permissões desnecessárias).
3. Criar produto `pro_unlock` na Play Console, testar compra, cancelamento, restauração e conta offline.
4. Colocar links Play Store dos outros jogos apenas após publicação.
5. Revisar privacidade, classificação etária, dados de loja e políticas de anúncios antes de publicar.
