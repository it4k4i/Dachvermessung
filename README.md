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
  Programmbibliotheken und – falls eingeblendet – die Kartenkacheln der Hintergrundkarte.
  Die Hintergrundkarte ist **standardmäßig ausgeschaltet** (die Dachvermessung erfolgt auf dem
  Orthofoto); für maximalen Datenschutz einfach aus lassen. Wird sie eingeblendet, lädt der
  Browser Kacheln von CARTO (auf OpenStreetMap-Daten basierend) – dabei werden nur ungefähre
  Koordinaten + IP angefragt, **nie das Orthofoto**. Für einen komplett externen-frei
  ausgelieferten Auftritt zusätzlich die Bibliotheken lokal einbinden (siehe „Ohne CDN betreiben").

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

## Auf GitLab Pages veröffentlichen

GitLab Pages ist ebenfalls statisches Hosting und funktioniert genauso – **auch der CDN-freie
Betrieb über `vendor.sh` ist dort möglich** (die `lib/`-Dateien werden einfach mit ausgeliefert).
Der einzige Unterschied: GitLab braucht eine kleine CI-Datei `.gitlab-ci.yml` im Wurzelverzeichnis:

```yaml
pages:
  stage: deploy
  script:
    - mkdir -p public
    - cp -r index.html lib public/ 2>/dev/null || cp index.html public/
  artifacts:
    paths: [public]
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
```

Ablauf: Dateien (inkl. optional `lib/` nach `bash vendor.sh`) ins Repo legen, committen, pushen.
Die Seite erscheint unter `https://<benutzer>.gitlab.io/<repo>/`. `.nojekyll` wird hier nicht
benötigt. Eigene Domain analog unter **Settings → Pages**.

## Bedienung (so erklärst du es dem Kunden)

Die Oberfläche ist in drei nummerierte Schritte gegliedert und enthält oben rechts einen
Knopf **„Anleitung"** mit einer bebilderten Kurzhilfe.

> 1. **Luftbild laden** – die `.tif`-Datei ins Fenster ziehen oder „Datei auswählen".
> 2. **Werkzeug wählen** – *Fläche messen*, *Länge messen* oder *Punkt setzen*.
> 3. **Auf das Dach klicken** – Eckpunkte setzen. Fläche schließen: wieder auf den ersten Punkt
>    klicken. Länge beenden: Doppelklick. Die Werte erscheinen sofort rechts inkl. Gesamtsumme.
> 4. **Benennen &amp; aus-/einblenden** – in der Ergebnisliste jede Messung per Stift-Symbol
>    umbenennen (z. B. „Dach Süd") und per Häkchen vorübergehend ausblenden; die Gesamtfläche
>    zählt nur sichtbare Messungen.
> 5. **Speichern** – *Als PDF* oder *Als Bild* für den Versand; *Arbeit sichern* zum
>    Späterweitermachen.

Ein laufender Hinweistext unter den Werkzeugen sagt jederzeit, was als Nächstes zu klicken ist.

### Speichern, Laden, Export

- **Als PDF / Als Bild:** exportiert die aktuelle Kartenansicht inklusive aller Einzeichnungen
  und Beschriftungen, mit Titel- und Summenkopf (das PDF zusätzlich mit einer Messliste). Für
  einen sauberen Export wird eine ggf. eingeblendete Straßenkarte automatisch ausgeblendet.
- **Arbeit sichern / Sicherung öffnen:** speichert alle Einzeichnungen als `.json` und stellt
  sie wieder her. Das (große) Luftbild wird **nicht** mitgespeichert – beim erneuten Öffnen
  einfach dieselbe `.tif` laden, dann liegen die Messungen wieder darüber.
- **Für Fachleute (GIS-Daten):** im aufklappbaren Bereich liegen **GeoJSON** und **CSV** für die
  Weiterverarbeitung.
- **Hell-/Dunkelmodus:** Umschalter oben rechts; Startwert nach System-Einstellung.

### Hintergrundkarte

Standardmäßig wird **nur das Luftbild** angezeigt – darauf wird gemessen. Optional lässt sich
unten links eine einfache **Straßenkarte** (CARTO, auf OpenStreetMap-Basis) zur groben
Orientierung einblenden; sie ist kostenlos nutzbar. Über denselben Regler kann das Luftbild
durchscheinend gemacht werden.

Hochauflösende Luftbild-/Satellitendienste sind bewusst **nicht** eingebaut: bundesweite
amtliche Dienste (BKG-DOP20) sind für gewerbliche Drittnutzung kostenpflichtig, und Esri/Google
sind für den kommerziellen Direktabruf nicht frei. Das eigene Orthofoto ist ohnehin die genaue
Messgrundlage.

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

Funktioniert sowohl mit GitHub Pages als auch mit GitLab Pages.

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
- Flächen-/Längenberechnung: **eigene geodätische Funktion** (lokale Projektion mit
  WGS84-Krümmungsradien) – keine externe Geometrie-Bibliothek nötig
- [html2canvas](https://html2canvas.hertzen.com/) – PNG-Export der Kartenansicht
- [jsPDF](https://github.com/parallax/jsPDF) – PDF-Export
- Keine Build-Schritte, kein Backend – eine einzige HTML-Datei.

## Messgenauigkeit

Die Flächen werden **geodätisch** berechnet: Die gezeichneten Eckpunkte liegen als echte
WGS84-Koordinaten (Länge/Breite) vor und werden um ihren Schwerpunkt-Breitengrad mit den
korrekten Erd-Krümmungsradien (Meridian- und Querkrümmungsradius) in lokale Meter projiziert;
darauf folgt die Gauss’sche Trapezformel. Gegen eine geodätische Referenz getestet:

| Dachkante | Fläche | Abweichung der Methode |
|-----------|--------|------------------------|
| 8 m       | 64 m²  | < 0,001 % |
| 15 m      | 225 m² | < 0,001 % |
| 40 m      | 1 600 m² | < 0,001 % |

Die frühere Kugelnäherung hatte eine breitengradabhängige Abweichung von rund 0,1–0,2 % und
wurde deshalb ersetzt. **Wichtig:** Die absolute Lagegenauigkeit hängt von der
Georeferenzierung deines Orthofotos ab (Bodenkontrollpunkte/GPS in WebODM) sowie von der
Klickgenauigkeit – nicht von der Rechenmethode. Für m²-genaue PV-Planung sollte das Orthofoto
also sauber referenziert sein (idealerweise mit GCPs/RTK).

## Sicherheit & Code-Qualität

- **Kein Server, kein Upload:** reine Client-Anwendung; Datei und Messungen verlassen das Gerät
  nicht. Keine Nutzung von `localStorage`/`sessionStorage`/`IndexedDB`.
- **XSS-Härtung:** alle Bezeichnungen werden HTML-escaped, bevor sie in die Oberfläche oder in
  Karten-Popups geschrieben werden; beim Laden von Projektdateien werden Typ (nur
  `area`/`line`/`point`) und Länge der Bezeichnungen validiert. Eigene Namen für Messungen
  werden ebenfalls escaped und auf 80 Zeichen begrenzt. Eine manipulierte Projektdatei kann
  damit keinen Code ausführen.
- **CSV-Injection-Schutz:** beim CSV-Export werden Zellen, die mit `= + - @` beginnen,
  neutralisiert, damit Tabellenprogramme sie nicht als Formel ausführen.
- **Abhängigkeiten:** Standardmäßig werden Bibliotheken vom CDN (unpkg) geladen. Für den
  produktiven Einsatz wird **`vendor.sh`** empfohlen – dann lädt der Browser ausschließlich
  Dateien von deiner eigenen Domain (kein Drittanbieter-CDN, keine Lieferketten-Abhängigkeit).
  Wer beim CDN bleibt, kann zusätzlich Subresource-Integrity-Hashes (`integrity="sha384-…"`)
  an den `<script>`-Tags ergänzen.
- **Optionale Content-Security-Policy:** Wer die Seite auf eigener Domain betreibt, kann im
  `<head>` z. B. ergänzen (bei lokal eingebundenen Bibliotheken strenger setzbar):
  ```html
  <meta http-equiv="Content-Security-Policy"
        content="default-src 'self'; script-src 'self' 'unsafe-inline' https://unpkg.com;
                 style-src 'self' 'unsafe-inline' https://unpkg.com https://fonts.googleapis.com;
                 font-src https://fonts.gstatic.com; img-src 'self' data: blob: https:;
                 connect-src 'self' https: blob:; worker-src 'self' blob:;">
  ```
  Vor dem Scharfschalten kurz testen (georaster nutzt teils Web-Worker/Blobs).
- **Fehlerbehandlung:** Datei-Lesen, Rendern und Export sind in `try/catch` gekapselt; schlägt
  ein Export-CDN fehl, bleibt das Messen funktionsfähig und es erscheint eine klare Meldung.

## Erfüllt die Anforderungen? (Checkliste)

| Anforderung | Status |
|-------------|--------|
| Kunde bekommt das GeoTIFF (E-Mail/WeTransfer) und öffnet es selbst | ✅ Datei wird lokal geöffnet (Ziehen/Auswählen) |
| Öffnen im Browser – keine Installation, kein Account | ✅ Eine statische HTML-Seite, nichts zu installieren |
| Kunde misst selbst: Polygone, m², Punkte, Linien | ✅ Werkzeuge „Fläche/Länge/Punkt", Werte sofort sichtbar |
| Eigenständige PV-Planung (Flächen, Hindernisse, Strecken) | ✅ beliebig viele Messungen, Summe, Export als PDF/Bild |
| Kostenlos | ✅ keine Lizenz-/Abokosten |
| Idealerweise ohne Upload auf fremde Server | ✅ Datei + Messungen bleiben im Browser; kein Upload |
| WebODM nicht öffentlich hosten | ✅ WebODM bleibt bei dir; nur die fertige Datei wird weitergegeben |
| Nichts in eine kostenpflichtige Cloud hochladen | ✅ keine Cloud-Plattform nötig |
| Kunden nicht technikaffin – Installation ein No-Go | ✅ geführte 3-Schritt-Oberfläche + „Anleitung", keine Installation |

Einzige externe Verbindungen im Standardbetrieb: die Programmbibliotheken vom CDN und – nur
falls eingeblendet – die optionale Straßenkarte. Beide lassen sich per `vendor.sh` bzw. durch
Ausschalten der Straßenkarte vermeiden; **die GeoTIFF-Datei selbst wird nie übertragen.**

## Lizenz

MIT – siehe `LICENSE`. Die genutzten Bibliotheken stehen unter ihren jeweiligen Lizenzen.
