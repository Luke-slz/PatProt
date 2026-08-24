# RKN-Protokoll Anpassung – Design

**Datum:** 2026-05-23  
**Scope:** Models.swift · MassnahmenView · AbschlussView · EinsatzOrtView · PDFGenerator.swift  
**Ziel:** PatProt-PDF so nah wie möglich an das RKN-Protokoll (Rhein-Kreis Neuss 2017) angleichen; fehlende Modell-Felder und App-Eingabe ergänzen.

---

## Referenz

RKN-Protokoll: `https://rettungsdienst.rhein-kreis-neuss.de/wp-content/uploads/2017/05/RD-Protokoll-RKN-2017.jpg`  
Bereits umgesetzte RKN-Features (nicht in diesem Spec): Verlauf-Zeitraster, Body-Silhouette, NACA-Score.

---

## Ist-Zustand vs. RKN

| Bereich | Aktueller Stand | RKN hat |
|---------|----------------|---------|
| Section 1 Fahrzeug | RTW/KTW/FR/NEF | RTW/KTW/NEF/MHW/VRW/RTH + „mit Patient" |
| Section 6 Maßnahmen | 8 Airway + 8 Kreislauf-Items | + CPAP, Heimlich, Defi, Kardioversion, IO-Zugang |
| Section 8 Medikamente | Zeit zuerst, dann Felder | Medikament zuerst, Zeit am Ende |
| Section 9 Übergabe | Nur Freitext | + ZNA/Stroke Unit/Kath.Labor Checkboxen |

---

## Änderungen

### 1. Modell-Erweiterungen (`Models.swift`)

#### 1.1 `MassnahmenBefund` — neue Felder

```swift
// Airway-Erweiterungen
var cpap: Bool = false
var cpapMbar: String = ""
var heimlich: Bool = false

// Kreislauf-Erweiterungen
var defibrillation: Bool = false
var defiJoule: Int = 200
var defiAnzahl: Int = 1
var kardioversion: Bool = false
var kardioversionJoule: Int = 100
var intraossaer: Bool = false
var intraossaerOrt: String = ""
```

#### 1.2 `ErgebnisData` — Transportziel-Typen

```swift
var transportzielZna: Bool = false
var transportzielStrokeUnit: Bool = false
var transportzielKathLabor: Bool = false
var transportzielSonstigesKH: String = ""
```

#### 1.3 `EinsatzOrt` — mit Patient

```swift
var mitPatient: Bool = false
```

---

### 2. App-Views

#### 2.1 `MassnahmenView.swift` — neue Section „Erweiterte Maßnahmen"

Nach der bestehenden Airway-Section, vor Kreislauf:

**Airway-Section Ergänzungen** (nach EGA):
- `CheckboxRow("CPAP (5–15 mBar)", isOn: $befund.cpap)` + Numpad für `cpapMbar`
- `CheckboxRow("Heimlich (Fremdkörper)", isOn: $befund.heimlich)`

**Kreislauf-Section Ergänzungen** (nach peripherVenoes):
- `CheckboxRow("Defibrillation", isOn: $befund.defibrillation)` + Joule-Numpad + Anzahl-Numpad
- `CheckboxRow("Kardioversion", isOn: $befund.kardioversion)` + Joule-Numpad
- `CheckboxRow("Intraossär-Zugang", isOn: $befund.intraossaer)` + `TextField("Ort", text: $befund.intraossaerOrt)`

#### 2.2 `AbschlussView.swift` — neue Section „Transportziel"

Neue `Form`-Section vor den Einsatzbesonderheiten:

```swift
Section("Transportziel") {
    CheckboxRow("ZNA / Notaufnahme", isOn: $protokoll.ergebnis.transportzielZna)
    CheckboxRow("Stroke Unit", isOn: $protokoll.ergebnis.transportzielStrokeUnit)
    CheckboxRow("Kath.-Labor", isOn: $protokoll.ergebnis.transportzielKathLabor)
    TextField("Sonstiges KH", text: $protokoll.ergebnis.transportzielSonstigesKH)
}
```

#### 2.3 `EinsatzOrtView.swift` — Toggle „mit Patient"

Neben dem Sondersignal-Toggle:
```swift
CheckboxRow("mit Patient", isOn: $protokoll.einsatzOrt.mitPatient)
```

---

### 3. PDF-Anpassungen (`PDFGenerator.swift`)

#### 3.1 Section 1 – Fahrzeug-Zeile

Ersetze `vItems`:
```swift
let vItems: [(String, Bool)] = [
    ("RTW", fzUp.contains("RTW")),
    ("KTW", fzUp.contains("KTW")),
    ("NEF", fzUp.contains("NEF")),
    ("MHW", fzUp.contains("MHW")),
    ("VRW", fzUp.contains("VRW")),
    ("RTH", fzUp.contains("RTH")),
    ("FR",  fzUp.contains("FR") || fzUp.contains("FIRST")),
]
```

Sondersignal-Zeile: füge nach `cb("Notarzt", ...)` ein:
```swift
cb("mit Patient", p.einsatzOrt.mitPatient, x:x+130, y:y+1.5, bs:7, lw:45)
```

#### 3.2 Section 6 – Maßnahmen

**maItems1** (Airway) — nach EGA-Zeile ergänzen:
```swift
("CPAP", p.massnahmen.cpap),
("Heimlich (FK)", p.massnahmen.heimlich),
```

**maItems2** (Kreislauf) — nach peripherVenoes ergänzen:
```swift
("Defibrillation", p.massnahmen.defibrillation),
("Kardioversion",  p.massnahmen.kardioversion),
("Intraossär",     p.massnahmen.intraossaer),
```

**Maßnahmen-Details Block** — Zeilen ergänzen:
```swift
if p.massnahmen.defibrillation {
    maDetails.append(("Defi", "\(p.massnahmen.defiJoule) J × \(p.massnahmen.defiAnzahl)"))
}
if p.massnahmen.kardioversion {
    maDetails.append(("Kardioversion", "\(p.massnahmen.kardioversionJoule) J"))
}
if p.massnahmen.cpap && !p.massnahmen.cpapMbar.isEmpty {
    maDetails.append(("CPAP", "\(p.massnahmen.cpapMbar) mBar"))
}
if p.massnahmen.intraossaer && !p.massnahmen.intraossaerOrt.isEmpty {
    maDetails.append(("IO-Zugang", p.massnahmen.intraossaerOrt))
}
```

#### 3.3 Section 8 – Medikamente-Spalten

Neue Spaltenreihenfolge (RKN: Medikament zuerst, Zeit am Ende):
```swift
let mC: [CGFloat] = [mTotW*0.32, mTotW*0.14, mTotW*0.12, mTotW*0.20, mTotW*0.11, mTotW*0.11]
let mHdr = ["Medikament","Dosis","Einheit","Applikationsweg","Zeit",""]
// Werte:
let vals2 = [med.name, med.dosis, med.einheit, med.route, t(med.zeit), ""]
```

#### 3.4 Section 9 – Übergabe Transportziel

Füge vor den Einsatzbesonderheiten-Checkboxen ein:
```swift
subHeader("Transportziel", x:lx, y:y, w:rx-lx)
y += 9.5
let tzItems: [(String, Bool)] = [
    ("ZNA / Notaufnahme", p.ergebnis.transportzielZna),
    ("Stroke Unit", p.ergebnis.transportzielStrokeUnit),
    ("Kath.-Labor", p.ergebnis.transportzielKathLabor),
]
cbRow(tzItems, x:lx, y:y, w:(rx-lx)*0.6)
if !p.ergebnis.transportzielSonstigesKH.isEmpty {
    field("Sonstiges KH", p.ergebnis.transportzielSonstigesKH,
          x:lx+(rx-lx)*0.6, y:y, w:(rx-lx)*0.4, h:10, lw:55)
}
y += 10
```

---

## Nicht verändert

- Seiten-Struktur (2×A4)
- Verlauf-Zeitraster (Section 5)
- Body-Silhouette (Section 4.2)
- NACA-Score (Section 7/8)
- ABCDE-Grid (Section 2)
- SAMPLER (Section 2)
- Alle Diagnose-Abschnitte (Section 4)
- Reanimation (Section 7)
- Footer, Farben, Fonts

---

## Akzeptanzkriterien

1. Section 1 zeigt RTW/KTW/NEF/MHW/VRW/RTH/FR mit Auto-Check
2. „mit Patient" Checkbox in Section 1 vorhanden
3. MassnahmenView hat CPAP, Heimlich, Defi, Kardioversion, IO-Zugang
4. Section 6 PDF zeigt alle neuen Maßnahmen
5. Medikamente-Spalten: Medikament zuerst, Zeit am Ende
6. Section 9 hat ZNA/Stroke Unit/Kath.Labor Checkboxen
7. AbschlussView hat Transportziel-Section
8. Build succeeds after all changes
