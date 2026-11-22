# Devolutiva técnica ao revisor — Veste & Cria (22/11/2026)

## Base e método

- Base local: `def38fc4` em `main`, com mudanças do trabalho anterior ainda não
  consolidadas. Não houve push ou merge nesta rodada.
- Evidências examinadas: 9 capturas de Android do solicitante e o PDF de 5
  páginas `a75b7986d698441d8f9501e32905d7c8.pdf` anexado.
- O PDF é uma revisão do **relato anterior**, sem inspeção de código e sem
  testes independentes. As observações a seguir identificam onde reproduzimos
  o defeito diretamente em sprites e código.
- Engine: Godot 4.7.2.stable, Linux headless; ImageMagick para recorte.
- **Não executamos Android real**, Play Billing, galeria nem WhatsApp/Instagram.
  O renderer headless é dummy e não produz captura confiável do SubViewport.

## Matriz de achados

| ID | Situação | Correção e evidência | Risco pendente |
| --- | --- | --- | --- |
| VIS-01 | **Corrigido no processamento local** | `tools/extract_paper_sprites.sh`: máscaras com fechamento vertical preservam tecido branco dos macacões `dress_03..05`; teste amostra 625 pixels da região interna por peça e reprova regiões transparentes. Também reconstitui detalhes brancos das botas. | Rever visual real em 4 modelos no Android; ainda podem existir pequenos halos do JPEG. |
| VIS-03 | **Parcial** | Removidos fragmentos de fileiras adjacentes em `shoes_01`, `04`, `05`; `scripts/paper_sprites.gd` alinha calçados à altura dos pés (584), variando a altura para botas versus sapatilhas. Teste verifica baseline de quatro tipos e ausência de grupos verticais desconectados nos três recortes. | Encaixe por modelo e por peça não validado visualmente em aparelho. |
| VIS-02 | **Parcial** | `scripts/paper_sprites.gd`: extensões passam atrás do rosto, mas cada penteado recebe detalhes frontais para não desaparecer sob a arte do modelo; cachos deixaram de formar uma coroa de blobs acima da cabeça. | O cabelo original vem embutido no modelo; ainda não existe substituição integral de penteado. Exige nova avaliação artística. |
| UI-01 | **Parcial** | `scripts/studio.gd`: categorias, paginação e ações inferiores aumentadas para alvos de 48–49 unidades lógicas, sem invadir paleta. Testes checam 360×800, 540×960, 540×1200, 720×1280. | Insets de notch, barra de gestos, fontes ampliadas e toque em Android continuam pendentes. |
| UX-02 | **Corrigido semanticamente** | Tela final e toast distinguem imagem salva na galeria de arquivo guardado apenas dentro do jogo; botão se chama **Salvar** e existe **Compartilhar**. | Falhas reais de MediaStore devem ser reproduzidas em aparelho. |
| AND-01 | **Parcial; novo bloqueador identificado** | `scripts/android_gallery.gd`: copiar e fechar stream com verificação de exceção, conferir atualização final `IS_PENDING=0` e limpar entrada incompleta; adicionar `ClipData` e permissão de leitura à ação e ao chooser do Android. Manifest inclui FileProvider com `files-path`. | **O APK exportado pelo preset direto atribui a mesma autoridade** `com.pitinga.paperdolls.protest.fileprovider` a `FileProvider` e a `androidx.startup.InitializationProvider` (confirmado por `aapt dump xmltree`). São provedores distintos e deveriam ter autoridades distintas. Diagnosticar a exportação Godot/avaliar template Gradle antes de afirmar compartilhamento funcional. Android real não executado. |
| ART-01 | **Bloqueador de publicação permanece** | `.gitignore` protege `assets/paper/`; `docs/ASSETS-LICENSES.md` registra proveniência incerta e necessidade de licença; CI gera 41 imagens sintéticas em vez de publicar recortes. | Obter licença expressa de titulares ou arte própria antes de qualquer publicação pública. |
| PROC-01 | **Mitigado** | `.github/workflows/test.yml` gera fixtures sintéticas antes de importar; não publica APK/AAB. Script de geração testado em diretório temporário (41 PNG). | CI remoto ainda não executado; testes sintéticos não validam a arte real. |
| AND-02 | **Pendente** | APK de debug v5 foi exportado e verificado; nenhum pedido de permissão Android consta no dump. | Alerta anterior do Play Protect não foi diagnosticado/retirado. Não aconselhar ignorá-lo. |
| BILL-01 | **Pendente, por desenho do preset** | Pro Test tem pacote e flag exclusivos; tests/test_pro_debug_preset.gd passou. | Não testa compra, confirmação nem restauração da Play Store. |

## Evidência de execução local

Comandos executados, Godot 4.7.2.stable (Linux):

```text
bash tools/extract_paper_sprites.sh /workspace/scratch/0a2de41e74e6/upload
  -> Recortados: 41 arquivos PNG
godot --headless --path . --editor --quit
  -> reimportação concluída
godot --headless --path . --script res://tests/test_catalog_and_rules.gd
  -> exit 0; 0 falhas
godot --headless --path . --script res://tests/test_studio_integration.gd
  -> exit 0; 0 falhas
godot --headless --path . --script res://tests/test_mobile_layout.gd
  -> exit 0; 0 falhas
godot --headless --path . --script res://tests/test_visual_regressions.gd
  -> exit 0; 0 falhas em alpha/geometria; render omitido no modo dummy
godot --headless --path . --script res://tests/test_pro_debug_preset.gd
  -> exit 0; 0 falhas
(cd addons/GodotGooglePlayBilling && sha256sum -c SHA256SUMS)
  -> exit 0; 2 hashes OK
godot --headless --path DIRETORIO_TEMPORARIO --script res://tools/create_ci_sprite_fixtures.gd
  -> exit 0; 41 arquivos sintéticos
```

Exportação privada adicional:

- Preset: `Android Pro Test`, debug, pacote `com.pitinga.paperdolls.protest`.
- Nome/versão: `0.1.0-pro-test.5`, versionCode `5`, API 24–36.
- Saída local: `build/paper-dolls-pro-test-v5.apk`.
- Assinatura: `apksigner verify --verbose` exit 0, esquemas v2 e v3 OK.
- `aapt dump permissions`: nenhuma permissão solicitada.
- `aapt dump xmltree ... AndroidManifest.xml`: duas entradas `<provider>` com
  a mesma autoridade, apesar de classes diferentes; **falha estrutural a
  resolver antes do aceite do compartilhamento**. `res/xml/godot_provider_paths.xml`
  contém `files-path` com raiz `/`.
- Tentativa adicional de exportação com `gradle_build/use_gradle_build=true`
  retornou **exit 1**, pois o Gradle Wrapper precisa baixar
  `gradle-8.11.1-bin.zip` de `services.gradle.org`, inacessível neste ambiente.
  O preset de teste foi devolvido ao modo direto (`false`), sem publicar a
  saída incompleta. Não declarar este teste como aprovado.
- SHA-256: `ec2bad00caf049ad375bdee937ada59187bc948d74fcb64f8d25fddd71a77c5c`.
- **Somente avaliação privada**, por incluir recortes sem licença demonstrada.

## Testes de aceitação para a próxima rodada

1. Comparar capturas dos quatro modelos vestindo cada um dos três macacões
   listrados; não pode haver pele aparecendo entre as listras nem lacunas na virilha.
2. Inspecionar botas/sapatilhas com e sem roupa longa, em cada modelo: a sola
   deve tocar a linha do chão e a canela não deve desaparecer.
3. Alternar todos os quatro penteados em cada modelo; verificar mudanças
   visíveis sem sobreposição do rosto, sombras indevidas ou adornos sobrando.
4. Navegar com dedos reais, notch e barra de gestos; testar 360dp e telas
   longas, e desfazer/limpar após trocar peças.
5. Corrigir/explicar a colisão de autoridades de provedores no manifesto;
   reexportar e verificar autoridades distintas com `aapt`.
6. Salvar na galeria, desligar acesso a mídia, compartilhar pelo chooser,
   WhatsApp e Instagram; validar URI e imagem recebida, incluindo falhas.
7. Reavaliar alerta do Play Protect sem instruir o usuário a contornar o aviso.
8. Resolver ART-01, depois repetir a matriz no conjunto de **arte licenciada**
   antes de distribuir ao público.
