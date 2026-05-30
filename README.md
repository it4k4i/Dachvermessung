# Dachvermessung – GeoTIFF im Browser messen

Ein einseitiges Web-Tool, mit dem **nicht-technische Kunden** ein Orthofoto (GeoTIFF aus
WebODM) selbst im Browser öffnen und darauf messen können – **Flächen (m²/ha), Strecken
und Punkte** – ohne Installation, ohne Account und **ohne dass die Datei hochgeladen wird**.

Gedacht für Drohnen-Dachvermessungen: Du exportierst das Orthofoto, der Kunde zieht es in
diese Seite und plant seine PV-Anlage (Modulanordnung, verfügbare Dachfläche, Hindernisse)
eigenständig.

## Datenschutz

- Das GeoTIFF wird **lokal im Browser** (Arbeitsspeicher) gelesen und gerendert
  (`geotiff.js` / `georaster`). Es wird **nicht** an einen Server gesendet.
- Es werden **kein IndexedDB, localStorage oder sessionStorage** verwendet. Tab schließen
  oder neu laden = alle Messungen weg, nichts bleibt auf dem Gerät zurück.
- Persistiert wird nur der normale HTTP-Cache des Browsers für die öffentlichen
  Programmbibliotheken und – falls eingeblendet – die OpenStreetMap-Kartenkacheln.
  Für maximalen Datenschutz die Hintergrundkarte deaktivieren (Checkbox unten links) und
  die Bibliotheken lokal einbinden (siehe „Ohne CDN betreiben").

## Auf GitHub Pages veröffentlichen

1. Neues Repository anlegen und diese Dateien hineinlegen (`index.html` muss im Wurzel-
   verzeichnis oder im Ordner `/docs` liegen).
2. **Settings → Pages**: Source = *Deploy from a branch*, Branch = `main`, Ordner = `/ (root)`
   (oder `/docs`, falls du es dort ablegst).
3. Nach kurzer Zeit ist die Seite erreichbar unter
   `https://<dein-benutzername>.github.io/<repo-name>/`.

Tipp: Heißt das Repository `<dein-benutzername>.github.io`, läuft die Seite direkt unter
`https://<dein-benutzername>.github.io/`.

Die Datei `.nojekyll` sorgt dafür, dass GitHub Pages die Dateien unverändert ausliefert.

### Eigene Domain

Für eine eigene (Sub-)Domain – z. B. `vermessung.bahl-netz.de`:

1. Eine Datei `CNAME` mit genau einer Zeile anlegen: `vermessung.bahl-netz.de`
2. Beim DNS-Provider einen `CNAME`-Eintrag setzen, der auf
   `<dein-benutzername>.github.io` zeigt.
3. In **Settings → Pages** die Custom Domain eintragen und „Enforce HTTPS" aktivieren.

## Bedienung (so erklärst du es dem Kunden)

> 1. Link öffnen.
> 2. GeoTIFF-Datei ins Fenster ziehen (oder „Datei auswählen").
> 3. Werkzeug wählen: **Fläche** (Dachfläche in m²), **Strecke** oder **Punkt**.
> 4. Auf das Dach klicken. Fläche schließen: auf den ersten Punkt klicken.
>    Strecke beenden: Doppelklick.
> 5. Ergebnisse erscheinen rechts inkl. Summe.

### Speichern, Laden, Export

- **Projekt speichern / laden:** Über „Projekt → Speichern" werden alle Einzeichnungen als
  `.json` gesichert; „Laden" stellt sie wieder her. Das (große) Orthofoto wird **nicht**
  mitgespeichert – beim erneuten Öffnen einfach dieselbe GeoTIFF-Datei laden, dann liegen die
  Messungen wieder darüber.
- **PNG / PDF:** Exportiert die aktuelle Kartenansicht inklusive aller Einzeichnungen und
  Beschriftungen, mit Titel- und Summenkopf. Für einen sauberen Export wird die
  OpenStreetMap-Hintergrundkarte dabei automatisch ausgeblendet (cross-origin).
- **GeoJSON / CSV:** Reine Messdaten für die Weiterverarbeitung in GIS bzw. Tabellen.
- **Hell-/Dunkelmodus:** Umschalter oben rechts; Startwert nach System-Einstellung.

## Unterstützte Dateien

- Standard-GeoTIFF und **Cloud Optimized GeoTIFF (COG)**, RGB- und RGBA-Orthofotos.
- WebODM-Orthofotos liegen meist in UTM (EPSG:326xx); die Reprojektion auf die Webkarte
  passiert automatisch. Flächen werden geodätisch berechnet (für Dachgrößen praktisch exakt).
- Der transparente/NoData-Rand (typisches schwarzes Drumherum aus WebODM) wird ausgeblendet.

**Große Dateien:** Limit ist der Browser-Arbeitsspeicher (grob mehrere 100 MB). Bei sehr
großen Orthofotos vorher als COG exportieren, dann wird nur die nötige Auflösungsstufe
geladen:

```bash
gdal_translate odm_orthophoto.tif ortho_cog.tif -of COG -co COMPRESS=DEFLATE
```

## Ohne CDN betreiben (optional, empfohlen für die Kundenseite)

Standardmäßig lädt `index.html` Leaflet, Leaflet.draw, georaster, georaster-layer-for-leaflet
und Turf von einem CDN. Damit die Seite **keine externen Abhängigkeiten** hat (robuster und
auch offline lauffähig, abgesehen von den OSM-Kacheln), einmalig lokal ausführen:

```bash
bash vendor.sh
```

Das Skript lädt alle Bibliotheken nach `lib/` herunter, holt die nötigen Marker-/Icon-Bilder
und stellt die Pfade in `index.html` auf lokal um (ein Backup wird als `index.html.bak`
abgelegt). Danach `lib/` und `index.html` mit committen.

## Technik

- [Leaflet](https://leafletjs.com/) – Kartenanzeige
- [georaster](https://github.com/GeoTIFF/georaster) / [georaster-layer-for-leaflet](https://github.com/GeoTIFF/georaster-layer-for-leaflet) – GeoTIFF-Rendering im Browser
- [Leaflet.draw](https://github.com/Leaflet/Leaflet.draw) – Zeichenwerkzeuge
- [Turf.js](https://turfjs.org/) – geodätische Flächen- und Längenberechnung
- [html2canvas](https://html2canvas.hertzen.com/) – PNG-Export der Kartenansicht
- [jsPDF](https://github.com/parallax/jsPDF) – PDF-Export
- Keine Build-Schritte, kein Backend – eine einzige HTML-Datei.

## Lizenz

MIT – siehe `LICENSE`. Die genutzten Bibliotheken stehen unter ihren jeweiligen Lizenzen.
