# consented.eu – Consent Checker

Allgemeine GTM-Variablenvorlage mit booleschem Ergebnis. Property, Hosts, Kategorie und optionaler Dienst werden je Variable eingestellt; der Quellcode ist für alle Kunden derselbe.

## Import und Einstellungen

In GTM unter **Vorlagen → Variablenvorlagen → Neu → Importieren** die Datei `template.tpl` auswählen. Danach eine benutzerdefinierte Variable mit dieser Vorlage anlegen.

| Feld | Bedeutung |
|---|---|
| `propertyId` | Öffentliche UUID der veröffentlichten Consented-Property; kein API-Schlüssel. |
| `allowedHosts` | Exakte Hostnamen, durch Komma getrennt; `www.` und Großschreibung werden normalisiert. Keine Wildcards, URLs oder Pfade. Mehrere echte Alias-Domains ausdrücklich aufzählen. |
| `provider` | Standard `consented`. `google` prüft ausschließlich Googles Privacy-&-messaging-API. Kein automatischer Provider-Fallback. |
| `category` | Kategorie-Schlüssel, z. B. `analytics`, `marketing`, `functional`. Muss optional sein und ausdrücklich `true` melden. `disabled` ist eine boolesche false-Konstante. |
| `service` | Optional die exakte veröffentlichte Dienst-ID, z. B. `google-analytics-4`. Kategorie und Dienst müssen beide erlaubt und optional sein. |
| `requireAnalytics` | Optional zusätzlich Analytics-Zustimmung verlangen. Für die 16 Projekte mit Analytics-gesteuertem GTM-Loader aktiviert. |
| `expectedContainer` | Nur im ausdrücklich ausgewählten LW-Website-Modus benötigt. |

Gültiges Consented-Ergebnis erfordert die geladene CMP, dieselbe Property, bekannte Zustandsversionen und eine ausdrücklich erlaubte optionale Kategorie. Bei einem Versionswechsel sperrt die Variable, solange `repromptOnChange` nicht ausdrücklich false ist. Ein Dienst wird zusätzlich auf Existenz, Kategorie, `essential: false` und `hasConsent(service) === true` geprüft. Eine reine Dienstfreigabe bei abgelehnter Kategorie reicht in dieser bewusst strikten Variable nicht.

Für Analytics: Variable `Consent Analytics`, Kategorie `analytics`; für GA4 zusätzlich Dienst `google-analytics-4`. Für Marketing eine getrennte Variable mit Kategorie `marketing`; bei Google Ads zusätzlich Dienst `google-ads`.

Jeden fachlichen Trigger um **Consent-Variable ist gleich true** ergänzen. Zusätzlich einen Custom-Event-Ausnahmetrigger für alle Ereignisse (`.*`) mit **Consent-Variable ist gleich false** verbinden. Bei GA4 die native zusätzliche Einwilligung `analytics_storage` verlangen; bei Marketing-Tags die jeweils benötigten nativen Einwilligungen, beispielsweise `ad_storage`, `ad_user_data`, `ad_personalization`, pflegen. Eine vorbereitete Ausnahme allein schützt kein Tag: sie muss dem Tag zugeordnet sein.

## Google und Übergangsseiten

`provider: google` verwendet ausschließlich `googlefc.getGoogleConsentModeValues()`. Nur die numerische `1` (= GRANTED) gilt; UNKNOWN, DENIED, NOT_APPLICABLE und NOT_CONFIGURED bleiben gesperrt. Analytics und Marketing sind grundsätzlich getrennt; `requireAnalytics` kann zusätzlich Analytics verlangen. Ein gesetzter Dienst darf im Google-Modus nur `google-analytics-4`/Analytics oder `google-ads`/Marketing sein. Googles Zustimmung autorisiert keine fremden Dienste wie Sitzungsaufzeichnung oder Besucherzähler.

Der optionale Modus `website` ist für die vorhandene LW-Website-Bibliothek dokumentiert: `window.__lwSiteTelemetry` muss `loaded === true`, den passenden `container` und den ausdrücklich serverseitig gewählten `provider` (`consented` oder `google`) melden. Bei unbekanntem/falschem Status wird nicht auf den anderen Banner zurückgegriffen. Normale Kunden wählen direkt `consented` oder `google` und benötigen dieses Website-Objekt nicht. Auf den drei Übergangsseiten bleibt aktuell Consented maßgeblich; ein Google-Wechsel erfolgt erst nach bewusster Umstellung der Website.

## Berechtigungen

Nur den URL-Host lesen; `Consented.loaded` lesen; `Consented.config`, `Consented.getConsent`, `Consented.hasConsent` und `googlefc.getGoogleConsentModeValues` aufrufen. Für den optionalen Website-Modus nur drei Statusfelder lesen. Keine Schreibrechte, keine Requests, keine Cookies, kein Local Storage und keine Protokollierung.

## Sicherheit und Prüfung

Die Vorlagen verwenden GTMs sandboxed JavaScript. `unsafe-eval`, Custom HTML und benutzerdefinierte JavaScript-Variablen sind dafür nicht erforderlich. Die Website-CSP muss GTM und beim CMP-Tag die festen consented.eu-Skriptrouten weiterhin erlauben; ein Nonce ist keine Freigabe für eval.

Fehlende, fehlerhafte, veraltete oder fremde CMP-Daten erteilen keine Zustimmung. Der Checker liefert nur nach positiven Prüfungen `true`; ein Ausführungsfehler ergibt keine positive Erlaubnis und darf niemals über eine Bedingung „ist nicht false“ behandelt werden. Tag-Bedingungen immer als **ist gleich true** konfigurieren. Eine CSP- oder Berechtigungssperre darf nicht durch eine großzügigere Rückfallregel umgangen werden.

Die Prüfung läuft gegen die geladene öffentliche CMP-API, nicht gegen einen kopierten Data-Layer-Wert oder selbst gelesene Cookies. Beliebiger bereits auf derselben Seite ausgeführter Fremdcode kann Browserzustände verändern; die Variable ist keine Sicherheitsgrenze gegen eine vollständig kompromittierte Seite.

Bauen und die kleinen isolierten Tests ausführen (Node.js 18 oder neuer, keine npm-Abhängigkeiten):

```sh
node scripts/build.cjs
node tests/test.cjs
```

Die Tests erzwingen die deklarierten Berechtigungen in einer Node-VM, prüfen die tatsächlich gebaute `template.tpl` und sperren dynamische Codeerzeugung. Zusätzliche Szenarien stehen im GTM-Vorlageneditor unter „Tests“. **Diese Simulation ersetzt keinen echten Import, keinen GTM-Compilerlauf und keine Website-Vorschau.** Nach dem Import im GTM-Editor testen und im Tag Assistant die native Consent-Reihenfolge sowie echte Requests mit Ablehnung, getrennten Zustimmungen und Widerruf prüfen. Die Gallery-Freigabe ist noch nicht beantragt.

## GitHub und Community Template Gallery

Für jedes Template wird ein eigenes öffentliches Repository benötigt, jeweils mit genau einer `template.tpl` im Wurzelverzeichnis. Die Archive enthalten Quellcode, Tests, Apache-2.0-Lizenz und `metadata.yaml`. Die Vorlagen enthalten keine Kunden-IDs, Tokens, Kontodaten oder festen Kunden-Hostnamen. Die UUID im Test ist ein synthetischer Testwert.

`metadata.yaml` muss auf einen tatsächlich erreichbaren Commit mit der gewünschten `template.tpl` verweisen. `node scripts/release.cjs` trägt den aktuellen lokalen Git-Commit ein; anschließend die Metadaten committen. Beim GitHub-Push muss diese Historie erhalten bleiben. Beim erneuten Hochladen nur der Einzeldateien entsteht ein neuer Commit: dann den Versions-SHA erneut setzen. Den Dokumentationslink nach Anlegen des GitHub-Repositorys auf dessen README ändern.

Vor der Einreichung: beide GTM-Editor-Tests und Website-Vorschau abnehmen, Repository auf `main` bereitstellen, Issues aktivieren und Googles Gallery-Nutzungsbedingungen im GTM-Editor selbst bestätigen. Weder ein GitHub-Push noch eine Gallery-Einreichung wurde durch dieses Paket vorgenommen. Eine Community-Vorlage ist keine Zertifizierung als Google-CMP.

Lizenz: Apache-2.0, Copyright 2026 LW IT Solutions.

## Primärquellen

- [Google: Consent-Template und native Consent-APIs](https://developers.google.com/tag-platform/tag-manager/templates/consent-apis)
- [Google: Sandbox-APIs und Berechtigungen](https://developers.google.com/tag-platform/tag-manager/templates/api)
- [Google: CSP und Custom Templates](https://developers.google.com/tag-platform/security/guides/csp#custom_javascript_variables)
- [Google: Community Template Gallery](https://developers.google.com/tag-platform/tag-manager/templates/gallery)
- [consented.eu Dokumentation](https://consented.eu/docs)
