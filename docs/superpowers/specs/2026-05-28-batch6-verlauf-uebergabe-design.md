# Design: Batch 6 — Verlauf & Übergabe

**Datum:** 2026-05-28
**Scope:** Übergabe-Messwerte aus letzter Verlaufsmessung vorausfüllen; GCS-Übergabe aus ABCDE-Disability vorausfüllen

> **Hinweis:** "Verlauf grafisch im PDF" ist bereits implementiert (PDFGenerator.swift, Sektion 5, ~Zeile 995–1048, Tabellen-Grid mit Zeitstempeln und 8 Vitalparameter-Reihen). Kein weiterer Handlungsbedarf.

---

## 1. Übergabe-Messwerte aus Verlauf vorausfüllen

### Ansatz

Die Prefill-Logik wird als Methode auf `EinsatzProtokoll` implementiert, damit sie direkt unit-testbar ist.

### Models.swift — EinsatzProtokoll-Extension

Am Ende des `EinsatzProtokoll`-Blocks (nach der letzten Methode, vor der schließenden `}`), neue Methode:

```swift
func prefillUebergabeMesswerteAusVerlauf() {
    guard let letzte = verlaufMessungen
        .sorted(by: { $0.zeitpunkt < $1.zeitpunkt }).last else { return }
    if uebergabeMesswerte.rrSys.isEmpty, let v = letzte.blutdruckSys  { uebergabeMesswerte.rrSys = "\(v)" }
    if uebergabeMesswerte.rrDia.isEmpty, let v = letzte.blutdruckDia  { uebergabeMesswerte.rrDia = "\(v)" }
    if uebergabeMesswerte.hf.isEmpty,    let v = letzte.puls          { uebergabeMesswerte.hf    = "\(v)" }
    if uebergabeMesswerte.spo2.isEmpty,  let v = letzte.spo2          { uebergabeMesswerte.spo2  = "\(v)" }
    if uebergabeMesswerte.af.isEmpty,    let v = letzte.atemFrequenz  { uebergabeMesswerte.af    = "\(v)" }
    if uebergabeMesswerte.bz.isEmpty,    let v = letzte.blutzucker    { uebergabeMesswerte.bz    = String(format: "%.0f", v) }
    if uebergabeMesswerte.temp.isEmpty,  let v = letzte.temperatur    { uebergabeMesswerte.temp  = String(format: "%.1f", v) }
}
```

Nur leere Felder werden gefüllt — bereits eingetragene Werte bleiben unverändert.

### AbschlussView.swift

In der Form-Ebene `.onAppear` (oder falls kein Form-onAppear existiert, an der Übergabe-Messwerte-Section):

```swift
.onAppear { protokoll.prefillUebergabeMesswerteAusVerlauf() }
```

---

## 2. GCS-Übergabe aus Disability vorausfüllen

### Ansatz

`VerlaufsMessung` enthält nur `gcsGesamt: Int?`, nicht die Einzelwerte (E/V/M). Daher wird aus dem initialen ABCDE-Disability-Befund vorbefüllt — klinisch korrekt, weil dies den Ankunftszustand widerspiegelt.

### Models.swift — EinsatzProtokoll-Extension

Zweite neue Methode, direkt nach `prefillUebergabeMesswerteAusVerlauf()`:

```swift
func prefillGCSAusDisability() {
    guard disability.status != .unbewertet else { return }
    guard uebergabeBefunde.gcsAugen  == 4,
          uebergabeBefunde.gcsVerbal == 5,
          uebergabeBefunde.gcsMotor  == 6 else { return }
    uebergabeBefunde.gcsAugen  = disability.gcsAugen
    uebergabeBefunde.gcsVerbal = disability.gcsVerbal
    uebergabeBefunde.gcsMotor  = disability.gcsMotor
}
```

Bedingungen: Disability muss bewertet sein (`status != .unbewertet`) UND die Übergabe-GCS-Felder müssen noch auf den Struct-Defaults (4+5+6=15) stehen — damit manuelle Anpassungen nie überschrieben werden.

### UebergabeBefundeView.swift

`.onAppear` der Form hinzufügen:

```swift
.onAppear { protokoll.prefillGCSAusDisability() }
```

---

## 3. Tests

```swift
@Test func prefillFuelltUebergabeMesswerteAusVerlauf() {
    let p = EinsatzProtokoll()
    var m = VerlaufsMessung()
    m.blutdruckSys = 120
    m.blutdruckDia = 80
    m.puls         = 72
    m.spo2         = 98
    m.atemFrequenz = 16
    p.verlaufMessungen = [m]
    p.prefillUebergabeMesswerteAusVerlauf()
    #expect(p.uebergabeMesswerte.rrSys == "120")
    #expect(p.uebergabeMesswerte.rrDia == "80")
    #expect(p.uebergabeMesswerte.hf    == "72")
    #expect(p.uebergabeMesswerte.spo2  == "98")
    #expect(p.uebergabeMesswerte.af    == "16")
}

@Test func prefillGCSAusDisabilityWennDefault() {
    let p = EinsatzProtokoll()
    p.disability.status    = .nicht_kritisch
    p.disability.gcsAugen  = 3
    p.disability.gcsVerbal = 4
    p.disability.gcsMotor  = 5
    p.prefillGCSAusDisability()
    #expect(p.uebergabeBefunde.gcsAugen  == 3)
    #expect(p.uebergabeBefunde.gcsVerbal == 4)
    #expect(p.uebergabeBefunde.gcsMotor  == 5)
}

@Test func prefillGCSUeberschreibtNichtManuelleWerte() {
    let p = EinsatzProtokoll()
    p.disability.status    = .nicht_kritisch
    p.disability.gcsAugen  = 3
    p.uebergabeBefunde.gcsAugen = 2  // manuell geändert
    p.prefillGCSAusDisability()
    #expect(p.uebergabeBefunde.gcsAugen == 2)  // bleibt unverändert
}
```

---

## Dateien mit Änderungen

| Datei | Änderungen |
|---|---|
| `PatProt/Models/Models.swift` | 2 neue Methoden auf `EinsatzProtokoll` |
| `PatProt/Views/AbschlussView.swift` | `.onAppear` ruft `prefillUebergabeMesswerteAusVerlauf()` |
| `PatProt/Views/UebergabeBefundeView.swift` | `.onAppear` ruft `prefillGCSAusDisability()` |
| `PatProtTests/PatProtTests.swift` | 3 neue Tests |
