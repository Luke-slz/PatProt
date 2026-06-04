# Protokoll-Überarbeitung Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Vier Verbesserungen am RKN-Protokoll: NA-Spalte entfernen, Diagnosen-Mapping, Zeitraster vereinfachen, NA-nachgefordert-Toggle.

**Architecture:** Alle Änderungen sind in `RKNPDFGenerator.swift`, `PDFGenerator.swift`, `Models.swift` und `KonfigurationView.swift`. Keine neuen Dateien. Die kritischste Änderung ist Task 5 (Diagnosen-Mapping) mit ~60 geänderten Zeilen in `drawSection4`.

**Tech Stack:** Swift, SwiftUI, UIKit (PDF-Rendering), Swift Testing

---

## Dateien

| Datei | Änderung |
|---|---|
| `PatProt/Models/Models.swift` | `naAngefordert: Bool` zu `EinsatzOrt` (Zeile ~282) |
| `PatProt/Views/KonfigurationView.swift` | Toggle "NA nachgefordert" nach "Notarzt" (Zeile ~67) |
| `PatProt/Services/PDFGenerator.swift` | Zeile 412: `notarzt` → `naAngefordert` |
| `PatProt/Services/RKNPDFGenerator.swift` | Section 1 (NA + Zeitraster), Section 4 (Diagnosen), Section 6 (NA-Spalte) |
| `PatProtTests/PatProtTests.swift` | Test für `naAngefordert`-Standardwert |

---

## Task 1: `naAngefordert` Modellfeld + KonfigurationView Toggle

**Files:**
- Modify: `PatProt/Models/Models.swift` (~Zeile 282)
- Modify: `PatProt/Views/KonfigurationView.swift` (~Zeile 67)
- Modify: `PatProtTests/PatProtTests.swift`

- [ ] **Schritt 1: Test schreiben**

Am Ende von `struct PatProtTests` in `PatProtTests/PatProtTests.swift` hinzufügen:

```swift
@Test func naAngefordertDefaultFalse() {
    let ort = EinsatzOrt()
    #expect(ort.naAngefordert == false)
    #expect(ort.notarzt == false)
}
```

- [ ] **Schritt 2: Test laufen lassen — muss SCHEITERN**

```bash
xcodebuild test -scheme PatProt -destination 'platform=iOS Simulator,name=iPhone 17' 2>&1 | grep "naAngefordert"
```

Erwartet: `error: value of type 'EinsatzOrt' has no member 'naAngefordert'`

- [ ] **Schritt 3: Modellfeld hinzufügen**

In `PatProt/Models/Models.swift`, `struct EinsatzOrt`, nach Zeile mit `var notarzt: Bool = false` einfügen:

```swift
var naAngefordert: Bool = false
```

- [ ] **Schritt 4: Test laufen lassen — muss BESTEHEN**

```bash
xcodebuild test -scheme PatProt -destination 'platform=iOS Simulator,name=iPhone 17' 2>&1 | grep -E "naAngefordert|passed|failed"
```

Erwartet: `naAngefordertDefaultFalse()` passed

- [ ] **Schritt 5: Toggle in KonfigurationView hinzufügen**

In `PatProt/Views/KonfigurationView.swift`, die Zeile mit `Toggle("Notarzt", isOn: $protokoll.einsatzOrt.notarzt)` (ca. Zeile 67) finden und **danach** einfügen:

```swift
Toggle("NA nachgefordert", isOn: $protokoll.einsatzOrt.naAngefordert)
```

- [ ] **Schritt 6: Build prüfen**

```bash
xcodebuild build -scheme PatProt -destination 'platform=iOS Simulator,name=iPhone 17' 2>&1 | grep -E "error:|BUILD"
```

Erwartet: `BUILD SUCCEEDED`

- [ ] **Schritt 7: Commit**

```bash
git add PatProt/Models/Models.swift PatProt/Views/KonfigurationView.swift PatProtTests/PatProtTests.swift
git commit -m "feat: naAngefordert-Feld in EinsatzOrt + Toggle in KonfigurationView"
```

---

## Task 2: PDFGenerator + RKNPDFGenerator auf `naAngefordert` umkoppeln

**Files:**
- Modify: `PatProt/Services/PDFGenerator.swift` (Zeile ~412)
- Modify: `PatProt/Services/RKNPDFGenerator.swift` (Zeile ~356)

- [ ] **Schritt 1: PDFGenerator anpassen**

In `PatProt/Services/PDFGenerator.swift` folgende Zeile finden:

```swift
cb("Notarzt nachgefordert", p.einsatzOrt.notarzt, x:rx1+2, y:ry+1, bs:7, lw:80)
```

Ersetzen durch:

```swift
cb("Notarzt nachgefordert", p.einsatzOrt.naAngefordert, x:rx1+2, y:ry+1, bs:7, lw:80)
```

- [ ] **Schritt 2: RKNPDFGenerator anpassen**

In `PatProt/Services/RKNPDFGenerator.swift` folgende Zeile finden (ca. Zeile 356):

```swift
cbLabel("Notarzt nachgefordert", checked: e.notarzt,  x: gx+1, y: 17, cbSize: 4, labelW: 64)
```

Ersetzen durch:

```swift
cbLabel("Notarzt nachgefordert", checked: e.naAngefordert,  x: gx+1, y: 17, cbSize: 4, labelW: 64)
```

- [ ] **Schritt 3: Build + Tests**

```bash
xcodebuild test -scheme PatProt -destination 'platform=iOS Simulator,name=iPhone 17' 2>&1 | grep -E "error:|BUILD|passed|failed" | tail -10
```

Erwartet: `BUILD SUCCEEDED`, alle Tests grün

- [ ] **Schritt 4: Commit**

```bash
git add PatProt/Services/PDFGenerator.swift PatProt/Services/RKNPDFGenerator.swift
git commit -m "feat: Notarzt-nachgefordert-Checkbox auf naAngefordert umgekoppelt"
```

---

## Task 3: NA-Spalte aus RKNPDFGenerator Section 6 entfernen

**Files:**
- Modify: `PatProt/Services/RKNPDFGenerator.swift` (Zeilen ~1528–1645)

In `drawSection6` gibt es eine `mRow`-Funktion mit zwei Checkboxen (RD + NA) und entsprechende Spaltenköpfe. Die NA-Spalte ist immer leer (kein Einsatz setzt `na: true`).

- [ ] **Schritt 1: Koordinaten und `mRow`-Funktion anpassen**

Finde diesen Block (ca. Zeile 1528):

```swift
let rdX = x + 2
let naX = rdX + 9
let lblX = naX + 9
let lblW = x + w - lblX - 2

func mRow(_ label: String, rd: Bool, na: Bool = false, atY: CGFloat) {
    cb(rd, x: rdX, y: atY+2, size: 5)
    cb(na, x: naX, y: atY+2, size: 5)
    txt(label, CGRect(x: lblX, y: atY+1.5, width: lblW, height: rH-3), font: f5)
}
```

Ersetzen durch:

```swift
let rdX = x + 2
let lblX = rdX + 9
let lblW = x + w - lblX - 2

func mRow(_ label: String, rd: Bool, atY: CGFloat) {
    cb(rd, x: rdX, y: atY+2, size: 5)
    txt(label, CGRect(x: lblX, y: atY+1.5, width: lblW, height: rH-3), font: f5)
}
```

- [ ] **Schritt 2: Ersten NA-Spaltenkopf entfernen (Airway)**

Finde (ca. Zeile 1558):

```swift
txt("RD", CGRect(x: rdX, y: cy, width: 9, height: 6), font: f5, align: .center)
txt("NA", CGRect(x: naX, y: cy, width: 9, height: 6), font: f5, align: .center)
cy += 7
```

Ersetzen durch:

```swift
txt("RD", CGRect(x: rdX, y: cy, width: 9, height: 6), font: f5, align: .center)
cy += 7
```

- [ ] **Schritt 3: Zweiten NA-Spaltenkopf entfernen (Atmung)**

Finde (ca. Zeile 1595):

```swift
txt("RD", CGRect(x: rdX,   y: cy, width: 9, height: 6), font: f5, align: .center)
txt("NA", CGRect(x: naX,   y: cy, width: 9, height: 6), font: f5, align: .center)
```

Ersetzen durch:

```swift
txt("RD", CGRect(x: rdX, y: cy, width: 9, height: 6), font: f5, align: .center)
```

- [ ] **Schritt 4: Dritten NA-Spaltenkopf entfernen (Cirkulation)**

Finde (ca. Zeile 1644):

```swift
txt("RD", CGRect(x: rdX, y: cy, width: 9, height: 6), font: f5, align: .center)
txt("NA", CGRect(x: naX, y: cy, width: 9, height: 6), font: f5, align: .center)
cy += 7
```

Ersetzen durch:

```swift
txt("RD", CGRect(x: rdX, y: cy, width: 9, height: 6), font: f5, align: .center)
cy += 7
```

- [ ] **Schritt 5: Build + Tests**

```bash
xcodebuild test -scheme PatProt -destination 'platform=iOS Simulator,name=iPhone 17' 2>&1 | grep -E "error:|BUILD|passed|failed" | tail -5
```

Erwartet: `BUILD SUCCEEDED`, alle Tests grün

- [ ] **Schritt 6: Commit**

```bash
git add PatProt/Services/RKNPDFGenerator.swift
git commit -m "refactor: NA-Spalte aus Section 6 Maßnahmen entfernt"
```

---

## Task 4: Zeitraster vereinfachen (RKNPDFGenerator Section 1)

**Files:**
- Modify: `PatProt/Services/RKNPDFGenerator.swift` (Zeilen ~358–387)

Das Zeitraster hat derzeit 8 Zeilen mit Links/Rechts-Split ("vor NA" / "nach NA"). Es wird auf 7 Zeilen mit einer einzigen Wertspalte vereinfacht. "Alarmierung NA" fällt weg.

- [ ] **Schritt 1: Spaltenköpfe ersetzen**

Finde (ca. Zeile 358):

```swift
hline(gx-2, 23, gw+2)
// □Eintr. vor NA / □Eintr. nach NA (Spaltenköpfe)
txt("□ Eintr. vor NA",  CGRect(x: gx+1,    y: 24, width: gw/2-2, height: 5), font: small)
txt("□ Eintr. nach NA", CGRect(x: gx+gw/2, y: 24, width: gw/2-2, height: 5), font: small)
hline(gx-2, 30, gw+2)
```

Ersetzen durch:

```swift
hline(gx-2, 23, gw+2)
txt("Uhrzeit", CGRect(x: gx+45, y: 24, width: gw-46, height: 5), font: small, align: .center)
// Hinweis: 45 = gx+lblW+1 und gw-46 = gw-lblW-2 mit lblW=44 (definiert im nächsten Schritt)
hline(gx-2, 30, gw+2)
```

- [ ] **Schritt 2: `tW`-Berechnung und Zeitraster-Daten ersetzen**

Finde (ca. Zeile 363):

```swift
let grH: CGFloat = 10
let lblW: CGFloat = 44
let tW = (gw - lblW) / 2
var gy: CGFloat = 30
let zeilen: [(String, String, String)] = [
    ("Alarm",          t(e.alarmzeit),    ""),
    ("Ausfahrt",       t(e.ausfahrtzeit), ""),
    ("Ankunft",        "",                t(e.ankunftzeit)),
    ("Alarmierung NA", "",                ""),
    ("Abfahrt",        "",                t(e.abfahrtzeit)),
    ("Übergabe",       "",                t(e.uebergabeZeit ?? e.krankenHausAnkunft)),
    ("Einsatzbereit",  "",                t(e.einsatzbereitZeit)),
    ("Ende",           "",                t(e.endeZeit)),
]
for (label, vVor, vNach) in zeilen {
    fillR(CGRect(x: gx,      y: gy, width: lblW, height: grH), cLight)
    strokeR(CGRect(x: gx,    y: gy, width: lblW, height: grH), lw: 0.3)
    txt(label, CGRect(x: gx+2, y: gy+2, width: lblW-3, height: 5), font: small)
    strokeR(CGRect(x: gx+lblW,     y: gy, width: tW, height: grH), lw: 0.3)
    strokeR(CGRect(x: gx+lblW+tW,  y: gy, width: tW, height: grH), lw: 0.3)
    txt(vVor,  CGRect(x: gx+lblW+1,    y: gy+2, width: tW-2, height: 5), font: f5b, align: .center)
    txt(vNach, CGRect(x: gx+lblW+tW+1, y: gy+2, width: tW-2, height: 5), font: f5b, align: .center)
    gy += grH
}
```

Ersetzen durch:

```swift
let grH: CGFloat = 10
let lblW: CGFloat = 44
let valW = gw - lblW
var gy: CGFloat = 30
let zeilen: [(String, String)] = [
    ("Alarm",         t(e.alarmzeit)),
    ("Ausfahrt",      t(e.ausfahrtzeit)),
    ("Ankunft",       t(e.ankunftzeit)),
    ("Abfahrt",       t(e.abfahrtzeit)),
    ("Übergabe",      t(e.uebergabeZeit ?? e.krankenHausAnkunft)),
    ("Einsatzbereit", t(e.einsatzbereitZeit)),
    ("Ende",          t(e.endeZeit)),
]
for (label, val) in zeilen {
    fillR(CGRect(x: gx,   y: gy, width: lblW, height: grH), cLight)
    strokeR(CGRect(x: gx, y: gy, width: lblW, height: grH), lw: 0.3)
    txt(label, CGRect(x: gx+2, y: gy+2, width: lblW-3, height: 5), font: small)
    strokeR(CGRect(x: gx+lblW, y: gy, width: valW, height: grH), lw: 0.3)
    txt(val, CGRect(x: gx+lblW+1, y: gy+2, width: valW-2, height: 5), font: f5b, align: .center)
    gy += grH
}
```

- [ ] **Schritt 3: Build + Tests**

```bash
xcodebuild test -scheme PatProt -destination 'platform=iOS Simulator,name=iPhone 17' 2>&1 | grep -E "error:|BUILD|passed|failed" | tail -5
```

Erwartet: `BUILD SUCCEEDED`, alle Tests grün

- [ ] **Schritt 4: Commit**

```bash
git add PatProt/Services/RKNPDFGenerator.swift
git commit -m "refactor: Zeitraster auf eine Spalte vereinfacht, Alarmierung NA entfernt"
```

---

## Task 5: Diagnosen-Mapping in RKNPDFGenerator Section 4

**Files:**
- Modify: `PatProt/Services/RKNPDFGenerator.swift` — `drawSection4` (Zeilen ~1055–1233)

`drawSection4` rendert Diagnose-Checkboxen anhand von boolean-Flags im Modell (`d.znsSchlaganfall` etc.). Diese Flags werden von `DiagnoseView` nie gesetzt — dort werden `verdachtsdiagnosen` befüllt. Mit einer lokalen `check()`-Funktion wird jedes Flag mit passenden App-Diagnose-Namen verknüpft. Nicht gematchte Diagnosen landen im Freitext.

- [ ] **Schritt 1: `check()`-Hilfsfunktion und `matchedNames` am Anfang von `drawSection4` einfügen**

Direkt nach der Zeile `let d = protokoll.diagnose` (Zeile ~1056) einfügen:

```swift
let vdNames = Set(protokoll.diagnose.verdachtsdiagnosen.map(\.name))
var matchedNames = Set<String>()
func check(_ flag: Bool, _ names: String...) -> Bool {
    for name in names where vdNames.contains(name) { matchedNames.insert(name) }
    return flag || names.contains(where: { vdNames.contains($0) })
}
```

- [ ] **Schritt 2: ZNS-Gruppe aktualisieren**

Den bestehenden ZNS-Block (ca. Zeile 1082) ersetzen:

```swift
grpHeader("ZNS", x: c1x, atY: c1y, colW: cw); c1y += ghH
for (l, c) in [
    ("akutes zentral-neurol. Defizit", check(d.znsAkutNeuro,   "Bewusstlosigkeit unklarer Genese", "TIA (transitorische ischämische Attacke)")),
    ("Schlaganfall",                   check(d.znsSchlaganfall, "Schlaganfall / Apoplex")),
    ("ICB",                            check(d.znsIcb)),
    ("SAB",                            check(d.znsSab,          "Subarachnoidalblutung (SAB)")),
    ("Krampfanfall",                   check(d.znsKrampfanfall, "Epilepsie / Krampfanfall")),
    ("Status Epilepticus",             check(d.znsEpilepsie,    "Epilepsie / Krampfanfall")),
    ("Fieberkrampf",                   check(d.znsFieberkrampf, "Fieberkrampf")),
] as [(String,Bool)] { row(l, c, x: c1x, atY: c1y, colW: cw); c1y += rH }
```

- [ ] **Schritt 3: Herz-Kreislauf-Gruppe aktualisieren**

Den bestehenden Herz-Kreislauf-Block ersetzen:

```swift
grpHeader("Herz-Kreislauf", x: c1x, atY: c1y, colW: cw); c1y += ghH
row("ACS", check(d.herzAcs, "ACS / Herzinfarkt (STEMI)", "ACS / Herzinfarkt (NSTEMI)", "Angina pectoris"), x: c1x, atY: c1y, colW: cw); c1y += rH
cbLabel("STEMI", checked: check(d.herzStemi,        "ACS / Herzinfarkt (STEMI)"),  x: c1x,          y: c1y, cbSize: 5, gap: 2, labelW: cw*0.42)
cbLabel("VW",    checked: d.herzVW,                                                  x: c1x+cw*0.50,  y: c1y, cbSize: 5, gap: 2, labelW: 16)
cbLabel("HW",    checked: d.herzHW,                                                  x: c1x+cw*0.69,  y: c1y, cbSize: 5, gap: 2, labelW: 16)
c1y += rH
row("kardiogener Schock",    check(d.herzKardiogenerSchock, "Hypotonie / Schock"),                x: c1x, atY: c1y, colW: cw); c1y += rH
cbLabel("Rhythmusstörung",   checked: check(d.herzRhythmus,      "Herzrhythmusstörung"), x: c1x,          y: c1y, cbSize: 5, gap: 2, labelW: cw*0.46)
cbLabel("tachy.",            checked: d.herzRhythmusTachy,                              x: c1x+cw*0.53,  y: c1y, cbSize: 5, gap: 2, labelW: 18)
cbLabel("brady.",            checked: d.herzRhythmusBrady,                              x: c1x+cw*0.73,  y: c1y, cbSize: 5, gap: 2, labelW: 18)
c1y += rH
for (l, c) in [
    ("PM/ICD Fehlfunktion",           check(d.herzPmFehlfunktion)),
    ("Lungenembolie",                 check(d.herzLungenembolie,       "Lungenembolie")),
    ("dekomp. Herzinsuffizienz",      check(d.herzDekomp,              "Herzinsuffizienz / Dekompensation")),
    ("hypertensiver Notfall",         check(d.herzHypertonerNotfall,   "Hypertensive Krise")),
    ("Aortenaneurysma",               check(d.herzAortenaneurysma,     "Aortenaneurysma / Dissektion")),
    ("Hypotonie",                     check(d.herzHypotonie,           "Hypotonie / Schock")),
    ("Synkope",                       check(d.herzSynkope,             "Synkope", "Synkope (kardial)")),
    ("Thrombose/Embolie",             check(d.herzThromboseEmbolie,    "Lungenembolie")),
    ("Herz-Kreislauf-Stillstand",     check(d.herzStillstand)),
    ("Schock unklarer Genese",        check(d.herzSchockUnklarGenese)),
    ("orthostatische Fehlregulation", check(d.herzOrthostatisch)),
    ("unklarer Thoraxschmerz",        check(d.herzUnklarerThoraxschmerz)),
] as [(String,Bool)] { row(l, c, x: c1x, atY: c1y, colW: cw); c1y += rH }
```

- [ ] **Schritt 4: Atmung-Gruppe aktualisieren**

```swift
grpHeader("Atmung", x: c2x, atY: c2y, colW: cw); c2y += ghH
for (l, c) in [
    ("Asthma",                   check(d.atmungAsthma,             "Asthma-Anfall")),
    ("Status asthm.",            check(d.atmungStatusAsthmaticus,  "Asthma-Anfall")),
    ("exacerbierte COPD",        check(d.atmungExazerbiert,        "COPD-Exazerbation")),
    ("Aspiration",               check(d.atmungAspiration,         "Fremdkörperaspiration")),
    ("Pneumonie / Bronchitis",   check(d.atmungPneumonie,          "Pneumonie", "Pneumonie (infektiös)")),
    ("Hyperventilationstetanie", check(d.atmungHyperventilation,   "Hyperventilation")),
    ("LTB (L/T/Bronchitis)",     check(d.atmungLtb,                "Krupp-Syndrom")),
    ("Epiglottitis",             check(d.atmungEpiglottitis,       "Epiglottitis")),
    ("Spontanpneumothorax",      check(d.atmungSpontanpneumothorax)),
    ("Hämoptysis",               check(d.atmungHaemoptysis)),
    ("unkl. Dyspnoe",            check(d.atmungUnklareDyspnoe)),
    ("Lungenödem",               check(d.atmungLungenodem,         "Lungenödem (kardial)")),
    ("Pseudokrupp",              check(d.atmungPseudokrupp,        "Krupp-Syndrom")),
] as [(String,Bool)] { row(l, c, x: c2x, atY: c2y, colW: cw); c2y += rH }
```

- [ ] **Schritt 5: Stoffwechsel- und Abdomen-Gruppe aktualisieren**

```swift
grpHeader("Stoffwechsel", x: c2x, atY: c2y, colW: cw); c2y += ghH
for (l, c) in [
    ("Exsikkose",             check(d.stoffExsikkose,     "Exsikkose / Dehydration")),
    ("Hypoglycämie",          check(d.stoffHypoglykämie,  "Hypoglykämie")),
    ("Hyperglycämie",         check(d.stoffHyperglykämie, "Hyperglykämie", "Diabetisches Koma")),
    ("Urämie/ANV",            check(d.stoffUremie,        "Urämie")),
    ("bek. dialysepflichtig", check(d.stoffDialyse)),
] as [(String,Bool)] { row(l, c, x: c2x, atY: c2y, colW: cw); c2y += rH }

grpHeader("Abdomen", x: c2x, atY: c2y, colW: cw); c2y += ghH
row("akutes Abdomen",  check(d.abdoAkutes,  "Akutes Abdomen", "Appendizitisverdacht", "Ileus", "Ulkus-Perforation"), x: c2x, atY: c2y, colW: cw); c2y += rH
row("Kolik allgemein", check(d.abdoKoliken, "Gallenkolik", "Nierenkolik"),                                            x: c2x, atY: c2y, colW: cw); c2y += rH
cbLabel("GIB",    checked: check(d.abdoGibOben||d.abdoGibUnten, "GI-Blutung (obere)", "GI-Blutung (untere)"), x: c2x,          y: c2y, cbSize: 5, gap: 2, labelW: 16)
cbLabel("obere",  checked: check(d.abdoGibOben,                 "GI-Blutung (obere)"),                         x: c2x+cw*0.24,  y: c2y, cbSize: 5, gap: 2, labelW: 20)
cbLabel("untere", checked: check(d.abdoGibUnten,                "GI-Blutung (untere)"),                        x: c2x+cw*0.57,  y: c2y, cbSize: 5, gap: 2, labelW: 20)
c2y += rH
row("Gallenkolik", check(d.abdoGallenkolik||d.abdoGalleNiere, "Gallenkolik"),  x: c2x, atY: c2y, colW: cw); c2y += rH
row("Nierenkolik", check(d.abdoNierenkolik,                   "Nierenkolik"),  x: c2x, atY: c2y, colW: cw); c2y += rH
```

- [ ] **Schritt 6: Psychiatrie- und Gyn-Gruppe aktualisieren**

```swift
grpHeader("Psychiatrie", x: c3x, atY: c3y, colW: cw); c3y += ghH
for (l, c) in [
    ("psych. Ausnahmezustand", check(d.psychAkut,        "Akute Psychose / Erregungszustand")),
    ("psychosoz. Krise",       check(d.psychKrise,        "Psychiatrische Krise", "Panikattacke")),
    ("Depressionen",           check(d.psychDepressionen)),
    ("Manie",                  check(d.psychManie,        "Manie")),
    ("Intoxikation",           check(d.psychIntoxikation, "Alkoholintoxikation", "Medikamenten-Intoxikation", "Drogenintoxikation")),
    ("Entzug/Delir",           check(d.psychEntzug,       "Alkoholentzugsdelir")),
    ("Suizidalität",           check(d.psychSuizidal,     "Suizidversuch")),
] as [(String,Bool)] { row(l, c, x: c3x, atY: c3y, colW: cw); c3y += rH }

grpHeader("Gyn./Geb.-hilfe", x: c3x, atY: c3y, colW: cw); c3y += ghH
for (l, c) in [
    ("Schwangerschaft > 35. SSW", check(d.gynSchwangerschaft35,            "Schwangerschaftskomplikation")),
    ("Geburt",                    check(d.gynGeburt,                        "Drohende / stattfindende Geburt")),
    ("Extrauterine Gravidität",   check(d.gynExtrauterine||d.gynSonstige,  "Extrauteringravidität")),
    ("Eklampsie",                 check(d.gynEklampsie,                    "Eklampsie / Präeklampsie")),
    ("vaginale Blutung",          check(d.gynVaginalblutung,               "Vaginale Blutung", "Fehlgeburt / Abort")),
] as [(String,Bool)] { row(l, c, x: c3x, atY: c3y, colW: cw); c3y += rH }
```

- [ ] **Schritt 7: Infektionen-Gruppe aktualisieren**

```swift
grpHeader("Infektionen", x: c3x, atY: c3y, colW: cw); c3y += ghH
row("unkl. Fieber",            check(d.infektUnklarFieber, "Fieber unklarer Genese"),                       x: c3x, atY: c3y, colW: cw); c3y += rH
row("Meningitis/Enzephalitis", check(d.infektMeningitis,   "Meningitis / Enzephalitis", "Meningitis (bakteriell)"), x: c3x, atY: c3y, colW: cw); c3y += rH
cbLabel("offen -MRSA-", checked: check(d.infektMrsaOffen),   x: c3x,          y: c3y, cbSize: 5, gap: 2, labelW: cw*0.47)
cbLabel("gedeckt",      checked: check(d.infektMrsaGedeckt), x: c3x+cw*0.56,  y: c3y, cbSize: 5, gap: 2, labelW: 28)
c3y += rH
row("MRE",       check(d.infektMre),       x: c3x, atY: c3y, colW: cw); c3y += rH
row("Hepatitis", check(d.infektHepatitis), x: c3x, atY: c3y, colW: cw); c3y += rH
```

- [ ] **Schritt 8: Spalte 4 (HIV/Sonstiges) aktualisieren**

Den bestehenden ersten `for`-Block in Spalte 4 ersetzen:

```swift
for (l, c) in [
    ("HIV",                        check(d.infektHiv)),
    ("TBC",                        check(d.infektTbc)),
    ("hochkontag. Erreger (SARS)", check(d.infektHighToxSars, "COVID-19 / SARS")),
    ("Gastroenteritis",            check(d.infektGastro,       "Gastroenteritis")),
] as [(String,Bool)] { row(l, c, x: c4x, atY: c4y, colW: c4w); c4y += rH }
```

Den zweiten `for`-Block in Spalte 4 (nach dem "Sonstiges"-Header) ersetzen:

```swift
for (l, c) in [
    ("Anaphylaxie Grad 1/2",      check(d.infektAnaphylaxie12,      "Allergische Reaktion (leicht)")),
    ("Anaphylaxie Grad 3/4",      check(d.infektAnaphylaxie34,      "Anaphylaxie (schwer)")),
    ("sept. Schock",              check(d.infektSeptSchock,          "Sepsis / septischer Schock")),
    ("Hitzeerschöpf./Hitzschl.", check(d.infektHitze,               "Hitzeerschöpfung", "Hitzschlag")),
    ("Unterkül./Erfrierung",      check(d.infektUnterku,            "Unterkühlung")),
    ("Ertrinken",                 check(d.infektErtrinken,           "Ertrinken / Beinaheertrinken")),
    ("SIDS",                      check(d.infektSids,                "SIDS-Verdacht")),
    ("Intoxikation",              check(d.infektIntoxikation,        "Alkoholintoxikation", "Medikamenten-Intoxikation", "Drogenintoxikation")),
    ("akute Lumbago",             check(d.infektAkuteLumbalgie)),
    ("palliative Situation",      check(d.infektPalliativ,           "Palliativversorgung")),
    ("med. Behandlungskomplik.",  check(d.infektBehandlungKompl)),
    ("Epistaxis",                 check(d.infektEpistaxis)),
    ("urologische Erkrankung",    check(d.infektUrologisch,          "Harnwegsinfekt / Urosepsis")),
] as [(String,Bool)] { row(l, c, x: c4x, atY: c4y, colW: c4w); c4y += rH }
```

- [ ] **Schritt 9: Freitext-Feld mit adaptiver Höhe und nicht gematchten Diagnosen ersetzen**

Den bestehenden Diagnose/Leitsymptom-Block (ca. Zeile 1226) ersetzen:

```swift
// ── Diagnose/Leitsymptom (nicht gematchte Diagnosen + Freitext) ──────────
let diagBottom = max(c1y, c2y, c3y, c4y) + 2
for i in 1..<4 { vline(lx + CGFloat(i)*cw, y0+20, diagBottom - y0 - 20) }
hline(lx, diagBottom, W-8)

let unmatchedVD = protokoll.diagnose.verdachtsdiagnosen
    .filter { !matchedNames.contains($0.name) }
    .map(\.name)

var diagText: [String] = []
if !d.leitsymptom.isEmpty { diagText.append(d.leitsymptom) }
if !unmatchedVD.isEmpty { diagText.append(unmatchedVD.joined(separator: ", ")) }
if !d.diagnoseFreitext.isEmpty { diagText.append(d.diagnoseFreitext) }

let joined = diagText.joined(separator: " · ")
let fieldH = max(14, min(40, CGFloat(diagText.filter { !$0.isEmpty }.count) * 8 + 4))
labeledField("Diagnose/Leitsymptom", joined, x: lx, y: diagBottom, w: W-8, h: fieldH)
```

- [ ] **Schritt 10: Build + alle Tests**

```bash
xcodebuild test -scheme PatProt -destination 'platform=iOS Simulator,name=iPhone 17' 2>&1 | grep -E "error:|BUILD|passed|failed" | tail -10
```

Erwartet: `BUILD SUCCEEDED`, alle Tests grün

- [ ] **Schritt 11: Commit**

```bash
git add PatProt/Services/RKNPDFGenerator.swift
git commit -m "feat: Diagnosen-Mapping Section 4 – verdachtsdiagnosen werden zu Checkboxen"
```

---

## Task 6: Fehlende Diagnosen in DiagnoseView ergänzen

**Files:**
- Modify: `PatProt/Views/DiagnoseView.swift`
- Modify: `PatProt/Services/RKNPDFGenerator.swift` — `drawSection4` (check()-Aufrufe ergänzen)

Mehrere RKN-PDF-Checkboxen haben keine entsprechende App-Diagnose. Diese werden in die bestehenden `DiagnoseKategorie`-Listen eingetragen und in Task 5 gemappt.

- [ ] **Schritt 1: Neue Diagnosen in DiagnoseView.swift eintragen**

In `PatProt/Views/DiagnoseView.swift` die `static let alle: [DiagnoseKategorie]` ergänzen:

**ZNS Erkrankungen** — nach "Subarachnoidalblutung (SAB)" einfügen:
```swift
"ICB (Intrakranielle Blutung)",
```

**Herz-Kreislauf Erkrankungen** — nach "Perikarditis" einfügen:
```swift
"PM / ICD-Fehlfunktion",
"Herz-Kreislauf-Stillstand",
"Schock unklarer Genese",
"Orthostatische Dysregulation",
"Unklarer Thoraxschmerz",
```

**Atemwegserkrankungen** — nach "Krupp-Syndrom" einfügen:
```swift
"Spontanpneumothorax",
"Hämoptysis",
"Unklare Dyspnoe",
```

**Stoffwechsel Erkrankungen** — nach "Urämie" einfügen:
```swift
"Dialysepflicht / Niereninsuffizienz",
```

**Psychiatrische Erkrankungen / Intoxikation** — nach "Panikattacke" einfügen:
```swift
"Depressionen",
```

**Infektionen** — nach "Harnwegsinfekt / Urosepsis" einfügen:
```swift
"MRE (multiresistente Erreger)",
"Hepatitis",
"HIV / AIDS",
"Tuberkulose (TBC)",
"MRSA offen",
"MRSA gedeckt",
```

**sonst. Erkrankungen** — nach "Palliativversorgung" einfügen:
```swift
"Akute Lumbago / Rückenschmerzen",
"Medizinische Behandlungskomplikation",
"Epistaxis (Nasenbluten)",
```

- [ ] **Schritt 2: check()-Aufrufe in drawSection4 um neue Namen erweitern**

In `PatProt/Services/RKNPDFGenerator.swift` — `drawSection4` — folgende `check()`-Aufrufe ergänzen (die bisher leeren Mappings):

```swift
// ZNS
("ICB",  check(d.znsIcb, "ICB (Intrakranielle Blutung)")),

// Herz-Kreislauf
("PM/ICD Fehlfunktion",           check(d.herzPmFehlfunktion,        "PM / ICD-Fehlfunktion")),
("Herz-Kreislauf-Stillstand",     check(d.herzStillstand,            "Herz-Kreislauf-Stillstand")),
("Schock unklarer Genese",        check(d.herzSchockUnklarGenese,    "Schock unklarer Genese")),
("orthostatische Fehlregulation", check(d.herzOrthostatisch,         "Orthostatische Dysregulation")),
("unklarer Thoraxschmerz",        check(d.herzUnklarerThoraxschmerz, "Unklarer Thoraxschmerz")),

// Atmung
("Spontanpneumothorax", check(d.atmungSpontanpneumothorax, "Spontanpneumothorax")),
("Hämoptysis",          check(d.atmungHaemoptysis,         "Hämoptysis")),
("unkl. Dyspnoe",       check(d.atmungUnklareDyspnoe,      "Unklare Dyspnoe")),

// Stoffwechsel
("bek. dialysepflichtig", check(d.stoffDialyse, "Dialysepflicht / Niereninsuffizienz")),

// Psychiatrie
("Depressionen", check(d.psychDepressionen, "Depressionen")),

// Infektionen
cbLabel("offen -MRSA-", checked: check(d.infektMrsaOffen,   "MRSA offen"), ...)
cbLabel("gedeckt",      checked: check(d.infektMrsaGedeckt, "MRSA gedeckt"), ...)
row("MRE",       check(d.infektMre,             "MRE (multiresistente Erreger)"), ...)
row("Hepatitis", check(d.infektHepatitis,        "Hepatitis"), ...)
// Spalte 4:
("HIV",  check(d.infektHiv,  "HIV / AIDS")),
("TBC",  check(d.infektTbc,  "Tuberkulose (TBC)")),
("akute Lumbago",            check(d.infektAkuteLumbalgie,   "Akute Lumbago / Rückenschmerzen")),
("med. Behandlungskomplik.", check(d.infektBehandlungKompl,  "Medizinische Behandlungskomplikation")),
("Epistaxis",                check(d.infektEpistaxis,         "Epistaxis (Nasenbluten)")),
```

**Hinweis:** Das sind Korrekturen zu den in Task 5 erstellten `check()`-Aufrufen. In Task 5 stehen diese als `check(d.xxx)` ohne Namen — jetzt werden die Namen ergänzt. Den kompletten Code-Kontext findet man in Task 5.

- [ ] **Schritt 3: Build + Tests**

```bash
xcodebuild test -scheme PatProt -destination 'platform=iOS Simulator,name=iPhone 17' 2>&1 | grep -E "error:|BUILD|passed|failed" | tail -5
```

Erwartet: `BUILD SUCCEEDED`, alle Tests grün

- [ ] **Schritt 4: Commit**

```bash
git add PatProt/Views/DiagnoseView.swift PatProt/Services/RKNPDFGenerator.swift
git commit -m "feat: Fehlende PDF-Diagnosen in DiagnoseView ergänzt + Mapping vervollständigt"
```

---

## Abschluss-Check

Nach allen Tasks:
- [ ] Alle Tests grün (`xcodebuild test`)
- [ ] KonfigurationView zeigt "Notarzt" + "NA nachgefordert" als separate Toggles
- [ ] PDF "Notarzt nachgefordert"-Checkbox reagiert auf `naAngefordert`, nicht `notarzt`
- [ ] RKN PDF Section 6: nur noch eine Checkbox-Spalte (RD, kein NA)
- [ ] RKN PDF Zeitraster: 7 Zeilen, eine Wert-Spalte, kein "Alarmierung NA"
- [ ] RKN PDF Section 4: Diagnosen aus DiagnoseView kreuzen passende Checkboxen an
- [ ] Neue Diagnosen in DiagnoseView verfügbar und in Section 4 gemappt
