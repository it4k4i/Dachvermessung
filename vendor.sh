#!/usr/bin/env bash
#
# vendor.sh – lädt alle Bibliotheken lokal nach ./lib/ und stellt index.html
# auf lokale Pfade um, sodass die Seite ohne CDN funktioniert.
#
# Verwendung:
#   bash vendor.sh            # nur Bibliotheken lokalisieren
#   bash vendor.sh --fonts    # zusätzlich die Schriften lokal einbinden (DSGVO-freundlich)
#
# Idempotent: mehrfaches Ausführen schadet nicht.
#
set -euo pipefail

WITH_FONTS=0
for arg in "$@"; do
  case "$arg" in
    --fonts) WITH_FONTS=1 ;;
    -h|--help)
      echo "Verwendung: bash vendor.sh [--fonts]"
      echo "  (ohne)    nur Bibliotheken nach lib/ holen und Pfade lokalisieren"
      echo "  --fonts   zusätzlich Schriften nach lib/fonts/ holen und einbinden"
      exit 0 ;;
    *) echo "Unbekannte Option: $arg (erlaubt: --fonts)"; exit 1 ;;
  esac
done

[ -f index.html ] || { echo "FEHLER: index.html nicht gefunden (im selben Ordner ausführen)."; exit 1; }

DL() { curl -fL --retry 3 "$1" -o "$2"; echo "  -> $2"; }

# ---------------------------------------------------------------------------
# 1) Bibliotheken
# ---------------------------------------------------------------------------
echo "Lege lib/ und lib/images/ an ..."
mkdir -p lib lib/images

echo "Lade Bibliotheken ..."
DL "https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"                                   "lib/leaflet.js"
DL "https://unpkg.com/leaflet@1.9.4/dist/leaflet.css"                                  "lib/leaflet.css"
DL "https://unpkg.com/leaflet-draw@1.0.4/dist/leaflet.draw.js"                         "lib/leaflet.draw.js"
DL "https://unpkg.com/leaflet-draw@1.0.4/dist/leaflet.draw.css"                        "lib/leaflet.draw.css"
DL "https://unpkg.com/georaster@1.6.0/dist/georaster.browser.bundle.min.js"            "lib/georaster.js"
DL "https://unpkg.com/georaster-layer-for-leaflet/dist/georaster-layer-for-leaflet.min.js" "lib/georaster-layer.js"
DL "https://unpkg.com/html2canvas@1.4.1/dist/html2canvas.min.js"                       "lib/html2canvas.js"
DL "https://unpkg.com/jspdf@2.5.1/dist/jspdf.umd.min.js"                                "lib/jspdf.js"
DL "https://geographiclib.sourceforge.io/scripts/geographiclib-geodesic.min.js"        "lib/geographiclib.js"

echo "Lade Bild-Assets (Marker, Icons, Spritesheets) ..."
# Leaflet
for f in marker-icon.png marker-icon-2x.png marker-shadow.png layers.png layers-2x.png; do
  DL "https://unpkg.com/leaflet@1.9.4/dist/images/$f" "lib/images/$f"
done
# Leaflet.draw
for f in spritesheet.png spritesheet-2x.png spritesheet.svg; do
  DL "https://unpkg.com/leaflet-draw@1.0.4/dist/images/$f" "lib/images/$f"
done

echo "Stelle Pfade in index.html um (Backup: index.html.bak) ..."
cp index.html index.html.bak

# CSS / JS auf lokal
sed -i \
  -e 's#https://unpkg.com/leaflet@1.9.4/dist/leaflet.css#lib/leaflet.css#g' \
  -e 's#https://unpkg.com/leaflet@1.9.4/dist/leaflet.js#lib/leaflet.js#g' \
  -e 's#https://unpkg.com/leaflet-draw@1.0.4/dist/leaflet.draw.css#lib/leaflet.draw.css#g' \
  -e 's#https://unpkg.com/leaflet-draw@1.0.4/dist/leaflet.draw.js#lib/leaflet.draw.js#g' \
  -e 's#https://unpkg.com/georaster-layer-for-leaflet/dist/georaster-layer-for-leaflet.min.js#lib/georaster-layer.js#g' \
  -e 's#https://unpkg.com/html2canvas@1.4.1/dist/html2canvas.min.js#lib/html2canvas.js#g' \
  -e 's#https://unpkg.com/jspdf@2.5.1/dist/jspdf.umd.min.js#lib/jspdf.js#g' \
  -e 's#https://geographiclib.sourceforge.io/scripts/geographiclib-geodesic.min.js#lib/geographiclib.js#g' \
  -e 's#"https://unpkg.com/georaster"#"lib/georaster.js"#g' \
  index.html

# Marker-Icon-URLs im Skript auf lokal
sed -i \
  -e "s#https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon-2x.png#lib/images/marker-icon-2x.png#g" \
  -e "s#https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon.png#lib/images/marker-icon.png#g" \
  -e "s#https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png#lib/images/marker-shadow.png#g" \
  index.html

echo "Bibliotheken lokalisiert."

# ---------------------------------------------------------------------------
# 2) Schriften (optional, nur mit --fonts)
# ---------------------------------------------------------------------------
if [ "$WITH_FONTS" -eq 1 ]; then
  echo ""
  echo "== Schriften lokal einbinden (--fonts) =="

  CSS_URL="https://fonts.googleapis.com/css2?family=Archivo:wght@600;700;800&family=IBM+Plex+Sans:wght@400;500;600&display=swap"
  # Browser-User-Agent -> Google liefert dann moderne woff2-Dateien
  UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124 Safari/537.36"

  mkdir -p lib/fonts
  echo "Lade Schriften-CSS von Google ..."
  RAW="$(curl -fsSL -A "$UA" "$CSS_URL")"

  # EINE gemeinsame, deterministische Reihenfolge der woff2-URLs (in Erscheinungs-
  # reihenfolge im CSS, Duplikate entfernt) – Download und CSS-Umschreibung nutzen sie beide.
  mapfile -t FONT_URLS < <(printf '%s\n' "$RAW" | grep -oE "https://[^)]+\.woff2" | awk '!seen[$0]++')

  if [ "${#FONT_URLS[@]}" -eq 0 ]; then
    echo "WARNUNG: keine woff2-URLs gefunden – evtl. anderer User-Agent nötig. Überspringe Schriften."
  else
    echo "Lade ${#FONT_URLS[@]} Schrift-Dateien (woff2) nach lib/fonts/ ..."
    idx=0
    for url in "${FONT_URLS[@]}"; do
      idx=$((idx+1))
      out="lib/fonts/font_${idx}.woff2"
      curl -fsSL -A "$UA" "$url" -o "$out"
      echo "  -> $out"
    done

    echo "Schreibe lib/fonts.css ..."
    python3 - "$RAW" "${FONT_URLS[@]}" <<'PY'
import sys
raw  = sys.argv[1]
urls = sys.argv[2:]            # exakt dieselbe (deduplizierte) Reihenfolge wie der Download
css = raw
for i, u in enumerate(urls, 1):
    # ersetzt die URL INNERHALB des vorhandenen url(...) -> ergibt url(fonts/font_i.woff2)
    css = css.replace(u, "fonts/font_%d.woff2" % i)
open("lib/fonts.css", "w", encoding="utf-8").write(css)
print("  fonts.css: %d Schnitte" % len(urls))
PY

    # <link> in index.html einfügen (idempotent), direkt nach der leaflet.draw.css-Zeile
    if grep -q 'href="lib/fonts.css"' index.html; then
      echo "index.html: lib/fonts.css ist bereits eingebunden."
    else
      awk '1; /lib\/leaflet\.draw\.css/ && !done { print "<link rel=\"stylesheet\" href=\"lib/fonts.css\" />"; done=1 }' \
        index.html > index.html.tmp && mv index.html.tmp index.html
      echo "index.html: <link href=\"lib/fonts.css\"> eingefügt."
    fi
    echo "Schriften lokal eingebunden."
  fi
fi

# ---------------------------------------------------------------------------
# Abschluss
# ---------------------------------------------------------------------------
echo ""
echo "Fertig. index.html nutzt jetzt lokale Dateien aus ./lib/"
if [ "$WITH_FONTS" -eq 1 ]; then
  echo "Bitte 'index.html', 'lib/' (inkl. lib/fonts/ und lib/fonts.css) committen."
  echo "Die Seite lädt nun keine Schriften mehr von Google."
else
  echo "Bitte 'index.html' und 'lib/' committen."
  echo "Hinweis: Schriften kommen weiterhin von Google. Für DSGVO-konforme,"
  echo "         lokale Schriften erneut mit  'bash vendor.sh --fonts'  ausführen."
fi
echo "(Nur die optionale Straßenkarte benoetigt weiterhin Internet; in der App abschaltbar.)"
