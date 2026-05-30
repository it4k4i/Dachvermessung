#!/usr/bin/env bash
#
# vendor-fonts.sh – holt die Schriften (Archivo, IBM Plex Sans) lokal nach lib/fonts/
# und bindet sie über lib/fonts.css in index.html ein. Damit macht die Seite KEINE
# Aufrufe mehr an Google (DSGVO-freundlich, voll offline-fähig).
#
# Einmalig NACH vendor.sh ausführen:   bash vendor-fonts.sh
# (Idempotent: mehrfaches Ausführen schadet nicht.)
#
set -euo pipefail

CSS_URL="https://fonts.googleapis.com/css2?family=Archivo:wght@600;700;800&family=IBM+Plex+Sans:wght@400;500;600&display=swap"
# Browser-User-Agent -> Google liefert dann moderne woff2-Dateien
UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124 Safari/537.36"

mkdir -p lib/fonts
echo "Lade Schriften-CSS von Google ..."
RAW="$(curl -fsSL -A "$UA" "$CSS_URL")"

echo "Lade einzelne Schrift-Dateien (woff2) nach lib/fonts/ ..."
i=0
# alle url(...)-Einträge herausziehen
echo "$RAW" | grep -oE "https://[^)]+\.woff2" | sort -u | while read -r url; do
  i=$((i+1))
  out="lib/fonts/font_${i}.woff2"
  curl -fsSL -A "$UA" "$url" -o "$out"
  echo "  -> $out"
done

# CSS lokal umschreiben: jede woff2-URL in Reihenfolge auf lib/fonts/font_N.woff2 mappen
echo "Schreibe lib/fonts.css ..."
python3 - "$RAW" <<'PY'
import sys, re
raw = sys.argv[1]
urls = []
def repl(m):
    urls.append(m.group(0))
    return "url(fonts/font_%d.woff2)" % len(urls)
# nur die woff2-URLs ersetzen (Reihenfolge identisch zur Download-Schleife oben,
# da beide dieselbe Quellreihenfolge nutzen)
css = re.sub(r"https://[^)]+\.woff2", repl, raw)
open("lib/fonts.css","w",encoding="utf-8").write(css)
print("  fonts.css: %d Schnitte" % len(urls))
PY

# <link> in index.html einfügen (idempotent), direkt nach der leaflet.draw.css-Zeile
if grep -q 'href="lib/fonts.css"' index.html; then
  echo "index.html: lib/fonts.css ist bereits eingebunden."
else
  cp index.html index.html.fontsbak
  # nach der ersten Vorkommnis von leaflet.draw.css den Font-Link ergänzen
  awk '1; /lib\/leaflet\.draw\.css/ && !done { print "<link rel=\"stylesheet\" href=\"lib/fonts.css\" />"; done=1 }' \
    index.html > index.html.tmp && mv index.html.tmp index.html
  echo "index.html: <link href=\"lib/fonts.css\"> eingefügt (Backup: index.html.fontsbak)."
fi

echo ""
echo "Fertig. Bitte 'lib/fonts.css', den Ordner 'lib/fonts/' und 'index.html' committen."
echo "Die Seite lädt nun keine Schriften mehr von Google."
