#!/usr/bin/env bash
# Uso: ./tools/extract_paper_sprites.sh /diretorio/com/as/quatro/imagens
# Apenas pré-processamento mecânico das imagens fornecidas pelo usuário.
set -euo pipefail

source_dir="${1:?Informe o diretório das quatro imagens anexadas}"
output_dir="assets/paper"
mkdir -p "$output_dir"

cut_sprite() {
  local name="$1" sheet="$2" rectangle="$3"
  magick "$source_dir/$sheet" -crop "$rectangle" +repage \
    -alpha on -fuzz 9% -fill none -draw 'color 0,0 floodfill' \
    -trim +repage "$output_dir/$name.png"
  # Muitos recortes têm um detalhe de outra coluna no canto superior esquerdo.
  # Por isso também limpar o fundo branco a partir das outras extremidades.
  local width height
  read -r width height < <(identify -format '%w %h\n' "$output_dir/$name.png")
  magick "$output_dir/$name.png" -alpha on -fuzz 17% -fill none \
    -draw "color $((width - 2)),2 floodfill color 2,$((height - 2)) floodfill" \
    "$output_dir/$name.png"
}

# Os macacões listrados têm listras BRANCAS dentro do tecido. Um flood-fill
# genérico confunde esses detalhes com o fundo e deixa buracos que exibem a
# pele. Fechamento VERTICAL da máscara (sem ligar as duas pernas) recupera a
# silhueta, e a cor final vem da prancha ORIGINAL, inclusive os brancos.
cut_striped_one_piece() {
  local name="$1" sheet="$2" rectangle="$3"
  cut_sprite "$name" "$sheet" "$rectangle"
  local extent mask
  extent="$(magick "$source_dir/$sheet" -crop "$rectangle" +repage \
    -alpha on -fuzz 9% -fill none -draw 'color 0,0 floodfill' \
    -format '%@' info:)"
  mask="$(mktemp --suffix=.png)"
  magick "$output_dir/$name.png" -alpha extract \
    -morphology Close 'Rectangle:1x22' -threshold 50% +profile '*' "$mask"
  magick "$source_dir/$sheet" -crop "$rectangle" +repage \
    -crop "$extent" +repage "$mask" -alpha off \
    -compose CopyOpacity -composite "$output_dir/$name.png"
  rm -- "$mask"
}

# O mesmo problema aparece nos cadarços e nas costuras brancas das botas.
repair_white_boot_details() {
  local name="$1" sheet="$2" rectangle="$3"
  local extent mask
  extent="$(magick "$source_dir/$sheet" -crop "$rectangle" +repage \
    -alpha on -fuzz 9% -fill none -draw 'color 0,0 floodfill' \
    -format '%@' info:)"
  mask="$(mktemp --suffix=.png)"
  magick "$output_dir/$name.png" -alpha extract \
    -morphology Close 'Rectangle:1x13' -threshold 50% +profile '*' "$mask"
  magick "$source_dir/$sheet" -crop "$rectangle" +repage \
    -crop "$extent" +repage "$mask" -alpha off \
    -compose CopyOpacity -composite "$output_dir/$name.png"
  rm -- "$mask"
}

trim_neighbor_shoe_rows() {
  local name="$1" upper="$2" lower="$3"
  local width height
  read -r width height < <(identify -format '%w %h\n' "$output_dir/$name.png")
  magick "$output_dir/$name.png" -crop \
    "${width}x$((height - upper - lower))+0+$upper" +repage \
    -trim +repage "$output_dir/$name.png"
}

clean_alpha_fringe() {
  local name="$1"
  # Recuar 1 px do contorno preenchido pelo fundo claro; as estampas internas
  # continuam intactas, sem apagar listras ou costuras brancas.
  magick "$output_dir/$name.png" \
    \( +clone -alpha extract -morphology Erode 'Diamond:1' \) \
    -compose CopyOpacity -composite "$output_dir/$name.png"
}

cut_sprite model_0 01-1000347301.jpg 514x892+35+43
cut_sprite model_1 02-1000347300.jpg 514x892+35+43
cut_sprite model_2 03-1000347299.jpg 514x892+35+43
cut_sprite model_3 04-1000347298.jpg 380x658+65+95
# A primeira imagem tem uma pequena roupa de outra coluna no canto inferior direito.
for model in model_0 model_1 model_2; do
  magick "$output_dir/$model.png" -region 45x260+456+613 -channel A -evaluate set 0 +channel +region "$output_dir/$model.png"
done

# Quando há sapato escolhido, não desenhar a sandália que já aparece no modelo.
for index in 0 1 2 3; do
  model="$output_dir/model_$index.png"
  read -r width height < <(identify -format '%w %h\n' "$model")
  # Cortar apenas as sandálias, sem apagar a canela acima dos novos sapatos.
  erase_from=$((height * 94 / 100))
  magick "$model" -region "${width}x$((height - erase_from))+0+$erase_from" \
    -channel A -evaluate set 0 +channel +region "$output_dir/model_${index}_bare.png"
done

cut_sprite top_00 01-1000347301.jpg 217x194+357+1062
cut_sprite top_01 01-1000347301.jpg 218x194+639+1062
cut_sprite top_02 01-1000347301.jpg 219x196+916+1061
cut_sprite top_03 02-1000347300.jpg 222x199+354+1061
cut_sprite top_04 02-1000347300.jpg 221x199+635+1059
cut_sprite top_05 02-1000347300.jpg 220x197+914+1060
cut_sprite top_06 03-1000347299.jpg 221x198+354+1061
cut_sprite top_07 03-1000347299.jpg 224x197+635+1061

cut_sprite bottom_00 01-1000347301.jpg 220x129+82+1113
cut_sprite bottom_01 01-1000347301.jpg 220x229+361+1275
cut_sprite bottom_02 01-1000347301.jpg 218x127+85+1375
cut_sprite bottom_03 02-1000347300.jpg 220x124+82+1254
cut_sprite bottom_04 02-1000347300.jpg 224x235+636+1270
cut_sprite bottom_05 03-1000347299.jpg 224x231+359+1275
cut_sprite bottom_06 03-1000347299.jpg 220x128+83+1120
cut_sprite bottom_07 03-1000347299.jpg 224x233+913+1275

cut_sprite dress_00 01-1000347301.jpg 338x298+506+642
cut_sprite dress_01 02-1000347300.jpg 338x299+506+640
cut_sprite dress_02 03-1000347299.jpg 339x299+506+640
cut_striped_one_piece dress_03 01-1000347301.jpg 232x428+863+43
cut_striped_one_piece dress_04 02-1000347300.jpg 232x427+861+45
cut_striped_one_piece dress_05 03-1000347299.jpg 232x428+863+45
cut_sprite dress_06 01-1000347301.jpg 232x263+564+370
cut_sprite dress_07 03-1000347299.jpg 230x291+891+497
for name in dress_00 dress_01 dress_02; do
  magick "$output_dir/$name.png" -region 37x45+0+0 -channel A -evaluate set 0 +channel +region "$output_dir/$name.png"
done

cut_sprite shoes_00 01-1000347301.jpg 218x99+1205+1040
cut_sprite shoes_01 02-1000347300.jpg 218x97+1205+1400
cut_sprite shoes_02 01-1000347301.jpg 218x103+1205+1144
cut_sprite shoes_03 03-1000347299.jpg 218x111+1205+1144
cut_sprite shoes_04 02-1000347300.jpg 218x108+1205+1256
cut_sprite shoes_05 03-1000347299.jpg 218x101+1205+1395
# Os retângulos de origem atravessavam filas de calçados: os sprites continham
# metades de OUTROS pares no alto/rodapé, visíveis no palco e no catálogo.
trim_neighbor_shoe_rows shoes_01 24 0
trim_neighbor_shoe_rows shoes_04 17 27
trim_neighbor_shoe_rows shoes_05 22 0
repair_white_boot_details shoes_00 01-1000347301.jpg 218x99+1205+1040
repair_white_boot_details shoes_02 01-1000347301.jpg 218x103+1205+1144
repair_white_boot_details shoes_03 03-1000347299.jpg 218x111+1205+1144

cut_sprite accessory_00 04-1000347298.jpg 118x116+99+971
cut_sprite accessory_01 04-1000347298.jpg 118x120+99+1091
cut_sprite accessory_02 04-1000347298.jpg 118x123+99+1218

for file in "$output_dir"/top_*.png "$output_dir"/bottom_*.png \
    "$output_dir"/dress_*.png "$output_dir"/shoes_*.png; do
  clean_alpha_fringe "$(basename "$file" .png)"
done

printf 'ImageMagick: %s\n' "$(magick -version | head -1)"
printf 'Recortados: %s arquivos PNG\n' "$(find "$output_dir" -type f -name '*.png' | wc -l)"
