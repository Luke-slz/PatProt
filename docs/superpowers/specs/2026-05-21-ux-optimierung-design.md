# UX-Optimierung PatProt — Design Spec

**Datum:** 2026-05-21  
**Kontext:** EMS-Protokoll-App für DLRG First Responder Geesthacht. Nutzung im Einsatz: ein-händig, Handschuhe, Stress, schlechtes Licht, teils offline. Sowohl Live-Dokumentation während des Einsatzes als auch Nacherfassung.

---

## Bereich 1 — Zeiten: "Jetzt"-Button + Auto-Alarmzeit

### Ziel
Zeitfelder per Ein-Tipp-Tap setzbar machen. Keine manuelle Tipp-Arbeit für "jetzt gerade".

### Änderungen

**`ZeitFeld` (EinsatzOrtView.swift)**  
Die bestehende HStack bekommt einen "Jetzt"-Button rechts vom TextField:

```
Alarmzeit       14:32   [Jetzt]
Ankunft Patient  ——     [Jetzt]
Abfahrt          ——     [Jetzt]
KH-Ankunft       ——     [Jetzt]
```

- Button: `.buttonStyle(.bordered)`, mindestens 44×44pt Tap-Target
- Beim Tap: aktuelle Zeit (`Date()`) in das Binding schreiben; Datumsteil des bestehenden Datums beibehalten wenn bereits gesetzt, sonst `Date()` vollständig übernehmen
- Das TextField bleibt editierbar für manuelle Korrekturen

**Automatische Alarmzeit**  
In `EinsatzProtokoll.reset()` (oder `init()`) wird `einsatzOrt.alarmzeit = Date()` gesetzt, sodass beim Anlegen eines neuen Protokolls die Alarmzeit bereits auf "jetzt" steht.

---

## Bereich 2 — Universelles Numpad Sheet

### Ziel
Alle Zahlen- und Zeitfelder über ein großes, handschuhfreundliches Numpad eingeben. Kein System-Zahlenpad mehr.

### Neue Komponente: `NumpadSheet`

**Datei:** `Views/NumpadSheet.swift`

**Modi:**

| Modus | Felder | Maxlänge | Auto-Format |
|---|---|---|---|
| `.integer(label, unit)` | Puls, SpO2, AF, Einsatz-Nr. | 3 Ziffern | — |
| `.decimal(label, unit)` | Blutzucker, Gewicht | 4 Ziffern + 1 Komma | `5.4` |
| `.time(label)` | Alarm, Ankunft, Abfahrt, KH | 4 Ziffern | `14:32` (Doppelpunkt nach 2. Ziffer) |
| `.date(label)` | Geburtsdatum | 8 Ziffern | `01.02.1985` (Punkte nach 2. und 4. Ziffer) |
| `.bloodPressure` | RR sys + dia | je 3 Ziffern | Zwei-Schritt: erst sys, dann dia |

**Layout:**

```
┌─────────────────────────┐   .presentationDetents([.medium])
│  Puls (/ min)           │   auf iPhone: halber Screen von unten
│  ┌───────────────────┐  │   auf iPad:   zentrierte floating card
│  │        80         │  │
│  └───────────────────┘  │
│  [ 7 ]  [ 8 ]  [ 9 ]   │   Buttons: ~70×70pt
│  [ 4 ]  [ 5 ]  [ 6 ]   │
│  [ 1 ]  [ 2 ]  [ 3 ]   │
│  [ ⌫ ]  [ 0 ]  [ ✓ ]  │
└─────────────────────────┘
```

- Display zeigt formatierte Eingabe während des Tippens
- `⌫` entfernt letzte Ziffer (Zahl) bzw. letztes Zeichen vor Trenner (Zeit/Datum)
- `✓` übernimmt den Wert ins Binding und schließt das Sheet
- Bei `.bloodPressure`: nach sys-Bestätigung wechselt der Titel zu "Diastolisch", Eingabe startet neu; zweites `✓` schließt das Sheet

**Einbindung:**  
Jede betroffene Zeile im Form wird zum Tap-Target via `.contentShape(Rectangle())`. Das TextField wechselt auf `disabled(true)` (read-only) und zeigt nur den Wert an. Tap auf die Zeile öffnet das NumpadSheet via `@State private var zeigeNumpad = false`.

**Betroffene Views und Felder:**

| View | Felder |
|---|---|
| `EinsatzOrtView` | Einsatz-Nr. (`.integer`), Zeiten (`.time`), Geburtsdatum (`.date`), Gewicht (`.decimal`) |
| `BreathingView` | Atemfrequenz (`.integer`), SpO2 (`.integer`) |
| `CirculationView` | Puls (`.integer`), Blutdruck (`.bloodPressure`) |
| `DisabilityView` | Blutzucker (`.decimal`) |

**Zeiten-Sonderfall:**  
`ZeitFeld` bekommt sowohl den "Jetzt"-Button (Bereich 1) als auch die Numpad-Anbindung. Tap auf die Zeile → Numpad; "Jetzt"-Button → direkt setzen ohne Sheet.

---

## Bereich 3 — Floating "Weiter"-Button

### Ziel
"Weiter"-Button ist auf jedem Step-Screen immer sichtbar, ohne nach unten scrollen zu müssen.

### Umsetzung

`.safeAreaInset(edge: .bottom)` auf dem Form — sauberster SwiftUI-Weg, kein ZStack-Hack:

```swift
.safeAreaInset(edge: .bottom) {
    Button(action: onWeiter) {
        Label("Weiter", systemImage: "arrow.right.circle.fill")
            .frame(maxWidth: .infinity)
            .padding()
    }
    .buttonStyle(.borderedProminent)
    .tint(Color("RDOrange"))
    .padding([.horizontal, .bottom])
    .background(.bar)
}
```

Der bisherige Button am Ende des Forms entfällt in allen betroffenen Views.

**Betroffene Views — alle Step-Views mit Aktions-Button am Formende:**

| View | Button-Label |
|---|---|
| `EinsatzOrtView` | Weiter zur Befunderhebung |
| `NotfallGeschehenView` | Weiter |
| `AirwayView` | Zurück zur Übersicht |
| `BreathingView` | Zurück zur Übersicht |
| `CirculationView` | Zurück zur Übersicht |
| `DisabilityView` | Zurück zur Übersicht |
| `ExposureView` | Zurück zur Übersicht |
| `SamplerView` | Weiter |
| `SinnhaftView` | Weiter |
| `DiagnoseView` | Weiter |
| `VerlaufView` | Weiter |
| `MassnahmenView` | Weiter |
| `MedikamenteView` | Weiter |

In allen diesen Views: bisheriger Button am Formende entfernen, stattdessen `.safeAreaInset(edge: .bottom)` mit identischer Aktion und Label.

---

## Nicht im Scope

- Offline-Fähigkeit: App ist bereits vollständig offline-first, kein Handlungsbedarf
- Navigation zwischen Steps: bestehender NavigationStack bleibt unverändert
- iPad-spezifische Layouts: alle drei Änderungen funktionieren unverändert auf iPad

---

## Testkriterien

- [ ] Neues Protokoll öffnen → Alarmzeit ist bereits gesetzt
- [ ] "Jetzt"-Button setzt korrekte Zeit, Datum bleibt erhalten
- [ ] NumpadSheet öffnet sich bei Tap auf jede betroffene Zeile
- [ ] `.time`-Modus formatiert `1432` → `14:32` korrekt
- [ ] `.date`-Modus formatiert `01021985` → `01.02.1985` korrekt
- [ ] `.bloodPressure` wechselt nach sys-Eingabe automatisch zu dia
- [ ] ⌫ entfernt Ziffern korrekt in allen Modi
- [ ] "Weiter"-Button auf jedem Step ohne Scrollen sichtbar
- [ ] Alles funktioniert auf iPhone und iPad
