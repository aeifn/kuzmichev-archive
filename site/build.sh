#!/usr/bin/env bash
# Собирает сайт в _site/: книги в PDF, превью страниц, портрет, index.html.
# Запуск из корня репозитория после `make`.
set -euo pipefail

OUT=_site
TYPST=(typst compile --root . --ignore-system-fonts --font-path template/fonts)

rm -rf "$OUT"
mkdir -p "$OUT/books" "$OUT/img" "$OUT/fonts"

# slug | исходник | PDF | страница для превью
BOOKS=(
  "izbrannye-stihotvoreniya|verses/book/book.typ|verses/book/book.pdf|4"
  "sobranie-sochineniy|completeworks/book.typ|completeworks/book.pdf|10"
  "pisma|letters/book.typ|letters/book.pdf|6"
)

cp site/index.html "$OUT/index.html"

for entry in "${BOOKS[@]}"; do
  IFS='|' read -r slug src pdf preview <<<"$entry"
  cp "$pdf" "$OUT/books/kuzmichev-$slug.pdf"
  "${TYPST[@]}" --pages 1 --ppi 110 "$src" "$OUT/img/$slug-title.png"
  "${TYPST[@]}" --pages "$preview" --ppi 110 "$src" "$OUT/img/$slug-page.png"

  pages=$(grep -a -c -E '/Type ?/Page([^s]|$)' "$pdf")
  bytes=$(wc -c <"$pdf")
  size=$(awk -v b="$bytes" 'BEGIN { printf "%.1f", b / 1048576 }' | tr . ,)
  sed -i.bak -e "s/{{pages:$slug}}/$pages/g" -e "s/{{size:$slug}}/$size/g" "$OUT/index.html"
done

"${TYPST[@]}" --ppi 160 site/portrait.typ "$OUT/img/portrait.png"
cp template/fonts/*.ttf template/fonts/OFL.txt "$OUT/fonts/"
sed -i.bak "s/{{year}}/$(date +%Y)/g" "$OUT/index.html"
rm -f "$OUT"/*.bak

echo "site built in $OUT/"
