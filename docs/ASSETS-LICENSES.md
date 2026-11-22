# Proveniência das ilustrações — Veste & Cria

Situação em 22/11/2026: **não liberadas para distribuição pública**.

As quatro pranchas `01-1000347301.jpg`, `02-1000347300.jpg`,
`03-1000347299.jpg` e `04-1000347298.jpg` foram fornecidas pelo solicitante
como referências visuais. Ele indicou a página
<https://recortar.com.br/bonecas-de-papel/>. Isso **não comprova autoria,
titularidade, permissão para criar derivados nem licença comercial**; a página
também menciona inspiração no Pinterest. Não inferir que imprimir gratuitamente
autorize usar as imagens em um aplicativo.

| Grupo de arquivos locais | Origem fornecida | Status |
| --- | --- | --- |
| `model_0`, `top_00..02`, `bottom_00..02`, `dress_00`, `dress_03`, `dress_06`, `shoes_00`, `shoes_02` | Prancha `01-1000347301.jpg` | Restrito a avaliação privada |
| `model_1`, `top_03..05`, `bottom_03..04`, `dress_01`, `dress_04`, `shoes_01`, `shoes_04` | Prancha `02-1000347300.jpg` | Restrito a avaliação privada |
| `model_2`, `top_06..07`, `bottom_05..07`, `dress_02`, `dress_05`, `dress_07`, `shoes_03`, `shoes_05` | Prancha `03-1000347299.jpg` | Restrito a avaliação privada |
| `model_3`, `accessory_00..02` | Prancha `04-1000347298.jpg` | Restrito a avaliação privada |

`model_*_bare` são variantes técnicas derivadas do modelo correspondente.
Todas as imagens derivadas ficam em `assets/paper/`, ignorado pelo Git. O script
`tools/extract_paper_sprites.sh` documenta os recortes mecânicos, sem incluir
pixels das pranchas. No CI público, `tools/create_ci_sprite_fixtures.gd` cria
**figuras geométricas sintéticas** para exercitar o código; não comprova o
acabamento da arte real.

Para publicar APK, AAB ou peças promocionais: obter autorização escrita dos
respectivos titulares abrangendo reprodução, modificação, redistribuição no
app e uso comercial **ou** substituir integralmente as ilustrações por arte
original com licença documentada. Registrar autor, licença, data, escopo e
comprovante de cada substituição. Não incluir estas quatro pranchas no GitHub
público ou em artefatos de CI público.
