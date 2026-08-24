# Design: BEFAST-Schema in D – Disability

**Datum:** 2026-05-19  
**Status:** Approved

---

## Scope

BEFAST-Schema (Schlaganfall-Erkennung) in der D-Disability-Ansicht hinzufügen — als aufklappbarer Abschnitt mit Toggle. Daten werden im Modell gespeichert und im PDF ausgegeben.

---

## 1 – Model (`Models.swift` → `DisabilityBefund`)

8 neue Felder ans Ende von `DisabilityBefund` anfügen:

```swift
var befastAktiv: Bool = false
var befastBalance: Bool = false      // B – Balance
var befastEyes: Bool = false         // E – Eyes
var befastFace: Bool = false         // F – Face
var befastArm: Bool = false          // A – Arm
var befastSpeech: Bool = false       // S – Speech
var befastZeitUnbekannt: Bool = false
var befastSymptombeginn: Date? = nil // T – Time
```

Da `DisabilityBefund` bereits `Codable` ist und Swift neue optionale/Bool-Felder mit Defaultwerten rückwärtskompatibel dekodiert, sind keine Archiv-Migrationsprobleme zu erwarten.

---

## 2 – View (`ABCDEDetailViews.swift` → `DisabilityView`)

Neuer `Section` nach dem GCS-Abschnitt und vor dem Pupillen-Abschnitt:

```
Section header: Label("BEFAST-Schema", systemImage: "brain")

  Toggle("BEFAST-Schema", isOn: $befund.befastAktiv)

  if befund.befastAktiv {
    CheckboxRow("B – Balance (Schwindel / Gleichgewichtsstörung)", isOn: $befund.befastBalance)
    CheckboxRow("E – Eyes (Sehstörung / Doppelbilder)", isOn: $befund.befastEyes)
    CheckboxRow("F – Face (Gesichtslähmung / hängender Mundwinkel)", isOn: $befund.befastFace)
    CheckboxRow("A – Arm (Armparese / Armhalteversuch auffällig)", isOn: $befund.befastArm)
    CheckboxRow("S – Speech (Sprachstörung / Aphasie)", isOn: $befund.befastSpeech)
    Toggle("T – Zeitpunkt unbekannt", isOn: $befund.befastZeitUnbekannt)
    if !befund.befastZeitUnbekannt {
      ZeitFeld(label: "T – Symptombeginn", datum: $befund.befastSymptombeginn)
    }
  }
```

`CheckboxRow` ist bereits in `ABCDEDetailViews.swift` definiert und kann direkt genutzt werden.
`ZeitFeld` ist aus `EinsatzOrtView.swift` — sicherstellen dass es zugänglich ist (ggf. in Models.swift oder eigene Datei verschieben, falls nötig). Wenn `ZeitFeld` nicht direkt importierbar ist, alternativ `DatePicker` mit `.datePickerStyle(.compact)` und `displayedComponents: .hourAndMinute` verwenden.

---

## 3 – PDF (`PDFGenerator.swift`)

### 3a – `neItems` erweitern

Nach den bestehenden 9 Zeilen des D-Neurologie-Blocks (`neItems`) werden bei `befastAktiv == true` 6 weitere Zeilen angehängt:

```swift
if gcs.befastAktiv {
    neItems += [
        ("BEFAST B", gcs.befastBalance ? "+" : "–"),
        ("BEFAST E", gcs.befastEyes    ? "+" : "–"),
        ("BEFAST F", gcs.befastFace    ? "+" : "–"),
        ("BEFAST A", gcs.befastArm     ? "+" : "–"),
        ("BEFAST S", gcs.befastSpeech  ? "+" : "–"),
        ("BEFAST T", gcs.befastZeitUnbekannt
            ? "unbekannt"
            : gcs.befastSymptombeginn.map { timeFormatter.string(from: $0) } ?? "—"),
    ]
}
```

`timeFormatter` ist ein lokaler `DateFormatter` mit `dateFormat = "HH:mm"`.

### 3b – Sektionshöhe korrigieren

Zeile 517 (aktuell):
```swift
y = mvColY + CGFloat(max(mvItems.count, atItems.count, ciItems.count))*mvH + 2
```

Ersetzen durch:
```swift
y = mvColY + CGFloat(max(mvItems.count, atItems.count, ciItems.count, neItems.count, haItems.count))*mvH + 2
```

So wächst die Sektionshöhe korrekt mit, wenn BEFAST aktiv ist und D mehr Zeilen hat als die anderen Spalten.

---

## Rückwärtskompatibilität

Bestehende Archive (JSON) dekodieren `DisabilityBefund` ohne die neuen Felder → Swift setzt Bool-Defaults auf `false` und `Date?` auf `nil`. Kein Datenverlust.

---

## Was nicht geändert wird

- ABCDEUebersichtView (kein BEFAST-Status-Badge notwendig)
- ScreenshotParser (BEFAST wird nicht aus dem Meldezettel gelesen)
- iPad-View
