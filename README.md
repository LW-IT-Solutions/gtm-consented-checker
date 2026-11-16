# consented.eu – Consent Checker

Allgemeine GTM-Variable für ganze Kategorien und granulare Dienstentscheidungen. Keine festen Kundendomains oder Property-IDs im Code.

## Vorrang der Dienstentscheidung

| Kategorie | Expliziter Dienstwert | Ergebnis für den Dienst |
|---|---|---|
| an | fehlt | erlaubt |
| an | false | gesperrt |
| aus | true | erlaubt |
| aus | fehlt oder false | gesperrt |

Ein explizites Dienst-true/false hat Vorrang vor der Kategorie. Nur ein wirklich fehlender Wert (`undefined`) erbt die Kategorie; null, Strings oder Zahlen zählen nicht als Zustimmung. Dienst und Kategorie müssen im veröffentlichten Katalog vorhanden und passend zugeordnet sein. Pflichtdienste erlauben keine optionalen Pixel.

## Felder

- `category`: z. B. analytics, marketing oder functional. Ohne Dienst wird nur die Kategorie geprüft. `disabled` ist eine false-Konstante.
- `service`: exakte Dienst-ID, z. B. google-analytics-4, mouseplayer oder stats4u.
- `serviceIds`: alternativ eine kommagetrennte ODER-Liste; mindestens ein wirklich vorhandener erlaubter Dienst muss passen.
- `allowEssential`: standardmäßig false. Nur ausdrücklich als notwendig konfigurierte Dienste der notwendigen Kategorie dürfen damit ohne Besucherauswahl erlaubt sein; keine optionale Analytics-Freigabe daraus ableiten.
- `requireAnalytics`: optional mindestens einen effektiv erlaubten Analytics-Dienst zusätzlich verlangen. Eine einzeln erlaubte Analytics-Leistung erfüllt dies auch bei ausgeschalteter Gesamtkategorie.
- `provider`, `propertyId`, `allowedHosts`, `expectedContainer`, `allowGoogleFallback`: siehe unten.

Jeden Tracking-Trigger positiv mit der passenden Dienstvariable equals true filtern und zusätzlich einen Ausnahme-Trigger (`.*`, Dienstvariable equals false) am Tag verbinden. Eine vorbereitete Ausnahme ohne Zuordnung schützt kein Tag. Native zusätzliche Consent-Prüfungen bleiben erhalten. Bei GA4 müssen sowohl der Trigger als auch eine dienstgenau aktualisierte native analytics_storage-Freigabe passen.

Das Website-Ladegate ist unabhängig: Wird GTM erst nach Analytics-Einwilligung geladen, muss auch GTM selbst erlaubt sein. Eine explizite GTM-Ablehnung wird durch eine GA4-Einzelfreigabe nicht überschrieben.

## Berechtigungen

Nur URL-Host, Consented.loaded und drei kleine optionale Website-Bindungsfelder lesen; Consented.config/getConsent und googlefc.getGoogleConsentModeValues ausführen. Keine Schreib-, Skriptlade- oder Consent-Schreibrechte.

## Installation und CSP

In GTM unter Vorlagen die `template.tpl` als Tag- bzw. Variablenvorlage importieren. Die Vorlagen verwenden ausschließlich die GTM-Sandbox und native APIs; keine jsm-Variable, kein Custom HTML und kein unsafe-eval. GTM und die tatsächlich genutzten CMP-Skriptrouten müssen weiterhin zur Website-CSP passen. Nonces erlauben keine eval-Ausführung.

`propertyId` ist die öffentliche UUID einer veröffentlichten Property. `allowedHosts` enthält exakte kommagetrennte Hostnamen, keine Wildcards, URLs oder Pfade. Großschreibung und www werden normalisiert. Host, Property und aktuelle Consent-Version werden geprüft. Bei ausdrücklich deaktiviertem `repromptOnChange` bleibt ein älterer bekannter Consent gültig.

## Google und Übergangsmodus

`provider=consented` verwendet ausschließlich consented.eu. `provider=google` verwendet ausschließlich `googlefc.getGoogleConsentModeValues()` aus Googles vorab eingebautem Privacy-&-messaging-Banner. Nur die numerische 1 (GRANTED) zählt. UNKNOWN, DENIED, NOT_APPLICABLE, NOT_CONFIGURED, Strings und fehlende Werte erlauben keine Ausführung.

Der optionale Modus `website` prüft eine vorhandene explizite Bindung unter `window.__lwSiteTelemetry`: loaded muss true sein und container dem Feld `expectedContainer` entsprechen; provider muss consented oder google sein. Eine falsche oder unvollständige vorhandene Bindung bleibt gesperrt. Nur bei vollständig fehlender Bindung und bewusst gesetztem `allowGoogleFallback=true` wird eine geladene Consented-CMP benutzt, andernfalls das ausdrückliche Google-Signal. Eine geladene, aber ablehnende Consented-CMP wird dadurch nicht umgangen.

Googles vier Consent-Mode-Signale liefern keine separaten Dienstentscheidungen für MousePlayer, Stats4U, Chat, Answely oder reCAPTCHA. Diese Dienste bleiben im Google-Modus gesperrt. Die implementierte Google-Zuordnung umfasst nur Google Analytics 4 und GTM (Analytics) sowie Google Ads und Google AdSense (Marketing). Für Marketing werden alle drei Werbezwecke verlangt. Der Fallback ist keine pauschale Trackingfreigabe.

## Bauen, Tests und Veröffentlichung

```sh
node scripts/build.cjs
node tests/test.cjs
```

Node.js 18 oder neuer; keine npm-Abhängigkeiten. Die Tests führen den tatsächlich gebauten Sandboxcode mit erzwungenen deklarierten Permissions und gesperrter dynamischer Codeerzeugung in einer Node-VM aus. Zusätzliche Szenarien stehen im GTM-Editor. Das ersetzt keinen echten Google-GTM-Compilerlauf, keinen Import und keine Tag-Assistant-Vorschau. Nach dem Import zuerst Kategorien, Einzeldienste, spätere Freigaben und Widerruf im Preview prüfen.

Jede Vorlage hat ein eigenes GitHub-Repository mit einer `template.tpl`, Apache-2.0-Lizenz, `metadata.yaml`, Quellcode und Tests. `metadata.yaml` referenziert einen echten Commit mit der gewünschten Vorlage; die Historie beim Push erhalten. Nach Quelländerungen testen, committen, `node scripts/release.cjs` ausführen und die geänderten Metadaten committen. Ein öffentlicher Repository-Upload ist noch keine Google-Gallery-Zulassung oder CMP-Zertifizierung. Die Einreichung und Bestätigung der Gallery-Nutzungsbedingungen im GTM-Editor erfolgt separat.

Kein Zugriff auf Besucher-Cookies, Local Storage oder Logging. Die Variable ist keine Sicherheitsgrenze gegen bereits vollständig kompromittierten Seitencode. Fehler oder fehlende Daten sind nie durch „ist nicht false“ freizugeben: positive Trigger immer als „ist gleich true“ konfigurieren.

Copyright 2026 LW IT Solutions; Apache-2.0.

## Primärquellen

- [Google Consent-APIs](https://developers.google.com/tag-platform/tag-manager/templates/consent-apis)
- [Sandbox-APIs](https://developers.google.com/tag-platform/tag-manager/templates/api)
- [CSP](https://developers.google.com/tag-platform/security/guides/csp#custom_javascript_variables)
- [Community Template Gallery](https://developers.google.com/tag-platform/tag-manager/templates/gallery)
