# Veste & Cria — Bonecas de Papel

Jogo de vestir bonecas, em português, feito em **Godot 4.7.2** para Android. O código é aberto. A revisão visual de teste utiliza temporariamente recortes das quatro imagens fornecidas pelo usuário; as permissões de redistribuição dessas ilustrações ainda precisam ser esclarecidas antes da publicação.

## O que já está implementado

- Escolha de **4 personagens grátis** e **10 bonecas originais kawaii PRO** (Luna, Yumi, Maya, Clara, Jade, Sol, Amira, Sofia, Isis e Tainá), em poses ilustradas.
- Guarda-roupa grátis com **30 roupas**, **12 acessórios** e **4 penteados**. O pacote kawaii PRO contém **100 roupas/calçados** (25 blusas, 25 partes inferiores, 25 vestidos e 25 sapatos) e **50 acessórios**. A coleção antiga de 24 peças Pro é mantida por compatibilidade.
- Arrastar com dedo ou tocar na miniatura para vestir; peças se encaixam por categoria. Vestido substitui blusa + parte de baixo.
- Trocar peça, retirar categoria, variar cores, desfazer e limpar o look.
- **8 cenários**, sendo 5 grátis e 3 Pro; **5 desafios temáticos** sem cronômetro, com progresso de 0 a 2.
- Tela de conclusão com **Salvar** e **Compartilhar**, em linguagem infantil. A imagem é criada sem menus. No Android, o compartilhamento usa o seletor de aplicativos para WhatsApp, Instagram e outros apps instalados; exige validação em aparelho.
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
godot --headless --path . --script res://tests/test_kawaii_assets.gd
godot --headless --path . --script res://tests/test_kawaii_navigation.gd
godot --headless --path . --script res://tests/test_studio_integration.gd
godot --headless --path . --script res://tests/test_mobile_layout.gd
godot --headless --path . --script res://tests/test_visual_regressions.gd
godot --headless --path . --script res://tests/test_pro_debug_preset.gd
```

`export_presets.cfg` prepara Android **7+ (API 24), ARM64** e uma única versão Free + Pro interno. O CI executa testes, mas **não distribui APK/AAB** em um repositório público. APKs de teste são construídos localmente e compartilhados apenas com quem vai testar.

O preset adicional **Android Pro Test** serve exclusivamente para gerar um APK de depuração com conteúdo premium liberado, app ID `com.pitinga.paperdolls.protest`. A liberação só funciona quando o binário é de **debug** e contém a feature `paper_dolls_pro_test`; nem a exportação Android normal nem o AAB Google Play incluem essa feature.

Para gerar o APK com as ferramentas Android e templates de exportação instalados:

```bash
godot --headless --path . --export-debug "Android Pro Test" build/paper-dolls-pro-test.apk
```

Este preset usa a exportação Android direta do Godot (sem Gradle/Google Play Billing), pois testa conteúdo e interface, **não** o fluxo de pagamento. O pacote de teste não substitui o jogo instalado pela Play Store. O APK permanece ignorado pelo Git.

Os **160 sprites PNG RGBA (1024×1536)** são incluídos no pacote Godot, usando IDs estáveis e o mesmo sistema de coordenadas. O seletor das 14 bonecas possui paginação para celulares, e as texturas grandes do pacote kawaii usam cache LRU limitado a 12 entradas para reduzir o consumo de memória.

**A cobrança PRO permanece suspensa** na versão comercial, mesmo após a integração: é necessária avaliação visual em aparelhos Android (encaixe fino e consistência dos 39 acessórios vetoriais), verificação de licenciamento e teste real da Play Store antes de habilitar pagamentos. A versão Pro Test continua disponível somente no preset de debug.

O build Pro de teste é **offline** e não solicita permissão `INTERNET`. A versão 0.1.0-pro-test.5 recupera as faixas brancas de macacões, remove fragmentos de outros sapatos, ajusta a base dos pés, diferencia os estados de salvamento e aumenta os alvos de toque. Um alerta do Play Protect foi registrado na instalação anterior: privilégios mínimos não garantem aprovação pelo Play Protect; se classificado como nocivo, o alerta precisa ser investigado junto ao Google antes de recomendar a instalação.

## Privacidade e compras

- **Anúncios desativados** nesta versão. Nenhum identificador de produção do AdMob foi integrado.
- A experiência de vestir e os PNGs são gratuitos. Pro acrescenta peças, variações e cenários exclusivos.
- O plugin `GodotGooglePlayBilling` (MIT; cópia da versão usada no Pong) permite adquirir e restaurar `pro_unlock` via Play Store quando o produto for criado no Console e o app for distribuído pelo Google Play.
- Uma confirmação positiva de Pro é persistida. Falhas/ausência temporária na resposta do Google Play **não removem** o direito previamente reconhecido.
- A imagem é gravada em `user://criacoes/` (armazenamento interno do aplicativo); em Android 10+ há uma **ponte experimental** para a galeria via MediaStore. O botão Compartilhar usa a galeria quando disponível e, em caso contrário, tenta oferecer o arquivo interno via `FileProvider` ao seletor nativo do Android 7+. No Android 7–9 ainda não há gravação direta na galeria. A ponte não foi validada num dispositivo real e não deve ser anunciada como garantia de salvamento ou compartilhamento externo até o teste.
- Somente jogos efetivamente publicados terão links de instalação. Não há URL inventada para apps ainda não lançados.

## Direitos autorais

As imagens de referência foram fornecidas pelo usuário. Nesta revisão, seus recortes são usados **somente no protótipo privado de avaliação visual**. As imagens não são licenciadas sob a MIT do código. `assets/paper/` está ignorado pelo Git e **não deve entrar em repositório público, APK distribuído ao público ou Play Store sem comprovar autorização dos titulares**; antes do lançamento, obter uma licença de uso adequada ou substituí-los por arte própria licenciável. O CI usa figuras geométricas sintéticas, que testam o código mas não o acabamento da arte. Proveniência e limitações: [ASSETS-LICENSES.md](docs/ASSETS-LICENSES.md). O código de montagem permanece MIT; o plugin Billing tem licença MIT própria em `addons/GodotGooglePlayBilling/LICENSE`.

**Nova coleção original:** os cinco PNGs `assets/kawaii/` foram gerados para este projeto com ChatGPT Images, sem incorporar arquivos do site Recortar ou de artistas terceiros. As artes são distribuídas separadamente do código MIT; consulte [KAWAII-COLLECTION.md](docs/KAWAII-COLLECTION.md). Os itens kawaii só ficam visíveis quando a boneca compatível é selecionada. `PRO_SALES_ENABLED` continua `false`: este primeiro conjunto não conclui o lançamento comercial.

## Próximos critérios de aceite

1. Testar arrastar, largar, menus e layout em Android com toque real, notch e telas 16:9 / 20:9.
2. Validar MediaStore, FileProvider e o compartilhamento em WhatsApp/Instagram no Android 10–14; estender exportação para a galeria no Android 7–9 (sem permissões desnecessárias).
3. Criar produto `pro_unlock` na Play Console, testar compra, cancelamento, restauração e conta offline.
4. Colocar links Play Store dos outros jogos apenas após publicação.
5. Revisar privacidade, classificação etária, dados de loja e políticas de anúncios antes de publicar.
