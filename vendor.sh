#!/usr/bin/env bash
#
# vendor.sh – lädt alle Bibliotheken lokal nach ./lib/ und stellt index.html
# auf lokale Pfade um, sodass die Seite ohne CDN funktioniert.
#
# Einmalig ausführen:   bash vendor.sh
#
set -euo pipefail

DL() { curl -fL --retry 3 "$1" -o "$2"; echo "  -> $2"; }

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
  -e 's#"https://unpkg.com/georaster"#"lib/georaster.js"#g' \
  index.html

# Marker-Icon-URLs im Skript auf lokal
sed -i \
  -e "s#https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon-2x.png#lib/images/marker-icon-2x.png#g" \
  -e "s#https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon.png#lib/images/marker-icon.png#g" \
  -e "s#https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png#lib/images/marker-shadow.png#g" \
  index.html

echo ""
echo "Fertig. index.html nutzt jetzt lokale Dateien aus ./lib/"
echo "Bitte 'lib/' und 'index.html' committen. (Nur die OSM-Hintergrundkarte"
echo "benoetigt weiterhin Internet; sie laesst sich in der App ausblenden.)"
