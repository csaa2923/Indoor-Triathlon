# Studio Tri · Apple Watch Puls

Die Apple Watch erfasst Puls mit HealthKit in einem Indoor-Training. WatchConnectivity sendet Messwerte an die gekoppelte iPhone-App; deren WebView zeigt die bestehende Vercel-Seite samt Puls an. Die Daten bleiben lokal auf den Geräten (abgesehen von der optionalen Apple-Health-Aufzeichnung). Keine Health-Daten werden an Vercel gesendet.

## Installieren

1. Auf einem Mac Xcode und [XcodeGen](https://github.com/yonaskolb/XcodeGen) installieren. Im Ordner `apple` `xcodegen generate` ausführen; `StudioTri.xcodeproj` öffnen.
2. Für **beide** Targets unter Signing & Capabilities eigenes Apple-Team auswählen und gegebenenfalls die Bundle-IDs anpassen; bei der Watch HealthKit aktivieren.
3. Auf einem echten gekoppelten iPhone samt Apple Watch installieren. In der Watch-App `Starten` tippen und Health-Zugriff erlauben. Im iPhone die Strecke wählen und den Wettkampf starten.
4. Optional auf dem iPhone `Watch starten` tippen, wenn die Watch-App erreichbar und geöffnet ist. Live-Puls im Cockpit und Ø / Max in Zieltafel und Trainingslog prüfen. Die Watch beendet die Health-Aufzeichnung mit `Beenden`.

Die native iPhone-App lädt die Online-Seite `https://indoor-triathlon-wolfgang.vercel.app/`. Sie besitzt einen **eigenen** WebView-Speicher; ältere Safari-Logs werden nicht übernommen. Die Web-PWA allein hat keinen Watch-Zugriff. Für zuverlässige Live-Messwerte sollten iPhone und Watch gekoppelt und in Reichweite bleiben; bei Funklücken zeigt die App keinen veralteten Puls als aktuell an. Ohne Mac, Code-Signierung und echtes Gerät lässt sich die HealthKit-Strecke nicht abschließend testen.
