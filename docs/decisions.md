# Decisões do jogo — Veste & Cria

## Ciclo básico

1. Menu: começar, escolher uma entre quatro bonecas ou iniciar um desafio.
2. No ateliê: selecionar categoria e arrastar/tocar uma roupa, sapato, acessório ou cabelo.
3. A roupa é posicionada automaticamente na silhueta (sem depender de coordenadas exatas do dedo).
4. É possível escolher uma variação de cor, trocar cenário, desfazer e limpar.
5. Tela final: salvar PNG sem elementos da interface; compartilhar quando o Android permitir.

## Regras de montagem

- Um item por categoria; vestido elimina blusa e parte de baixo. Vestir blusa ou parte de baixo elimina vestido.
- Calçados, cabelo e acessórios são independentes.
- Um toque seleciona o item. Arrastar é opcional e o dedo que iniciou o gesto mantém a posse até ser solto; dedos extras não roubam a seleção.
- Arrastar para fora da vitrine sem soltar na boneca não troca o look. Toque direto na vitrine substitui a ação de arrastar.
- Botão "Tirar" remove a categoria atual. "Limpar" remove todas as peças e pode ser desfeito.
- Cinco desafios possuem tema e exigem duas peças daquele tema para conclusão; não há temporizador nem ranking.

## Conteúdo

| Grupo | Grátis | Pro extra |
|---|---:|---:|
| Modelos | 4 | 0 |
| Peças de roupa (blusas, partes de baixo, vestidos, sapatos) | 30 | 16 |
| Cabelos | 4 | 4 |
| Acessórios | 12 | 4 |
| Cenários | 5 | 3 |
| Desafios | 5 | 0 |

O catálogo usa desenhos vetoriais originais; as variações de cor não exigem novas sprites.

## Comercialização e bem-estar

- Um aplicativo, `com.pitinga.paperdolls`, Android 7+/ARM64.
- Produto interno permanente `pro_unlock`. Compra e restauração requerem Play Console e Google Play Billing nativo; não existe botão de simulação para desbloquear Pro no release.
- Quem foi reconhecido como Pro conserva acesso mesmo após falhas intermitentes de verificação. Este comportamento prioriza a experiência de compradores sobre tentativas agressivas de monetização.
- Sem IDs de produção de anúncios; não há anúncio intersticial ou vídeo neste build.
- O acesso ao salvamento de PNG nunca depende de comprar Pro.
- Para público infantil, revisar política de famílias, classificação e declaração de dados da Play Store antes do lançamento.

## Divulgação entre jogos

O menu "Mais jogos" sugere Pong, 2048 e novidades, mas não tem botões de instalação sem link oficial da Play Store. Um link só deve ser inserido depois de verificado e o destino deve ser claramente identificado.

## Limites de validação

Testes headless executam catálogo, regras, ações de toque, persistência e codificação PNG. **O renderizador dummy do CI não fornece imagem de SubViewport**; testes de pixels da composição e da integração MediaStore/ShareSheet precisam de execução gráfica e aparelhos Android 7, 10 e 14. Nenhuma APK/AAB foi criada por esta etapa.
