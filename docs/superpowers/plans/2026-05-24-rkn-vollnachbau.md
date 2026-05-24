# RKN-Vollnachbau Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** PDF so nah wie möglich an das RKN-Protokoll (Rhein-Kreis Neuss 2017) angleichen: SAMPLER immer sichtbar, Messwerte Ankunft+Übergabe, Verlauf auf Seite 2, Section 6 auf 4 Spalten.

**Architecture:** Vier unabhängige Tasks. Task 1 (Model) muss vor Task 2+3+4 abgeschlossen sein. Tasks 2, 3, 4 können danach parallel laufen, berühren aber alle denselben Build — sequenziell ausführen.

**Tech Stack:** Swift 5, SwiftUI, UIKit PDF (UIGraphicsPDFRenderer), Xcode iOS Simulator `id=58572FBD-8FEA-49FD-B5A2-6E8326E4BCED`

---

## Datei-Übersicht

| Datei | Änderung |
|-------|----------|
| `PatProt/Models/Models.swift` | neuer struct `UebergabeMesswerte` + Feld in `EinsatzProtokoll` + `reset()` |
| `PatProt/Views/AbschlussView.swift` | neue Section „Übergabe-Messwerte" |
| `PatProt/Services/PDFGenerator.swift` | Page1: SAMPLER + Messwerte 2-Spalten + Verlauf entfernen; Page2: Verlauf einfügen + Medi vorverlegen + Section 6 auf 4 Spalten |

---

## Task 1: Models.swift — UebergabeMesswerte

**Files:**
- Modify: `PatProt/Models/Models.swift`

- [ ] **Step 1: UebergabeMesswerte struct einfügen**

Direkt vor `// MARK: - Ergebnis / Transportziel (Sektion 8 + 9)` (aktuell Zeile ~524) einfügen:

```swift
// MARK: - Übergabe-Messwerte
struct UebergabeMesswerte: Codable {
    var rrSys:  String = ""
    var rrDia:  String = ""
    var hf:     String = ""
    var spo2:   String = ""
    var af:     String = ""
    var bz:     String = ""
    var temp:   String = ""
}
```

- [ ] **Step 2: Feld in EinsatzProtokoll hinzufügen**

In `class EinsatzProtokoll` nach `@Published var ergebnis = ErgebnisData()` (Zeile ~140) einfügen:

```swift
    @Published var uebergabeMesswerte = UebergabeMesswerte()
```

- [ ] **Step 3: reset() aktualisieren**

In `func reset()` nach `ergebnis = ErgebnisData()` hinzufügen:

```swift
        uebergabeMesswerte = UebergabeMesswerte()
```

- [ ] **Step 4: Build**

```bash
xcodebuild -scheme PatProt -destination 'id=58572FBD-8FEA-49FD-B5A2-6E8326E4BCED' build 2>&1 | tail -3
```

Erwartet: `** BUILD SUCCEEDED **`

- [ ] **Step 5: Commit**

```bash
git -C /Users/lukeslz/Documents/Privat/DLRG/PatProt/PatProt commit -am "feat: add UebergabeMesswerte model"
```

---

## Task 2: AbschlussView.swift — Übergabe-Messwerte Eingabe

**Files:**
- Modify: `PatProt/Views/AbschlussView.swift`

Kontext: `AbschlussView` ist ein `Form` mit mehreren `Section`-Blöcken. `NumpadSheet` wird wie in `MassnahmenView` über `@State private var zeige... = false` + `.sheet(isPresented:)` gesteuert. Alle 7 Felder sind Strings; NumpadSheet gibt String zurück.

- [ ] **Step 1: @State-Variablen für 7 Numpads hinzufügen**

Direkt nach `@State private var mailNichtVerfügbar = false` einfügen:

```swift
    @State private var zeigeUebRrSys  = false
    @State private var zeigeUebRrDia  = false
    @State private var zeigeUebHf     = false
    @State private var zeigeUebSpo2   = false
    @State private var zeigeUebAf     = false
    @State private var zeigeUebBz     = false
    @State private var zeigeUebTemp   = false
```

- [ ] **Step 2: Neue Section „Übergabe-Messwerte" einfügen**

Direkt **vor** der Section „Übergabe an anderes Rettungsmittel" einfügen:

```swift
            // Übergabe-Messwerte
            Section {
                uebRow("RR syst.",   $protokoll.uebergabeMesswerte.rrSys,  "mmHg", $zeigeUebRrSys)
                uebRow("RR diast.",  $protokoll.uebergabeMesswerte.rrDia,  "mmHg", $zeigeUebRrDia)
                uebRow("HF /min",    $protokoll.uebergabeMesswerte.hf,     "/min", $zeigeUebHf)
                uebRow("SpO₂ %",     $protokoll.uebergabeMesswerte.spo2,   "%",    $zeigeUebSpo2)
                uebRow("AF /min",    $protokoll.uebergabeMesswerte.af,     "/min", $zeigeUebAf)
                uebRow("BZ",         $protokoll.uebergabeMesswerte.bz,     "mmol", $zeigeUebBz)
                uebRow("Temp °C",    $protokoll.uebergabeMesswerte.temp,   "°C",   $zeigeUebTemp)
            } header: {
                Label("Übergabe-Messwerte", systemImage: "waveform.path.ecg")
            }
```

- [ ] **Step 3: Hilfsfunktion `uebRow` als private func in AbschlussView hinzufügen**

Direkt vor `private func nachExportBereinigen()` einfügen:

```swift
    @ViewBuilder
    private func uebRow(_ label: String, _ value: Binding<String>,
                         _ unit: String, _ zeige: Binding<Bool>) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value.wrappedValue.isEmpty ? "—" : "\(value.wrappedValue) \(unit)")
                .foregroundColor(value.wrappedValue.isEmpty ? .secondary : .primary)
        }
        .contentShape(Rectangle())
        .onTapGesture { zeige.wrappedValue = true }
        .sheet(isPresented: zeige) {
            NumpadSheet(mode: .decimal(label: label, unit: unit, maxDigits: 4),
                        initial: value.wrappedValue) { val in value.wrappedValue = val }
        }
    }
```

- [ ] **Step 4: Build**

```bash
xcodebuild -scheme PatProt -destination 'id=58572FBD-8FEA-49FD-B5A2-6E8326E4BCED' build 2>&1 | tail -3
```

Erwartet: `** BUILD SUCCEEDED **`

- [ ] **Step 5: Commit**

```bash
git -C /Users/lukeslz/Documents/Privat/DLRG/PatProt/PatProt commit -am "feat: add Übergabe-Messwerte input in AbschlussView"
```

---

## Task 3: PDFGenerator.swift — Page 1: SAMPLER + 2-Spalten-Messwerte + Verlauf entfernen

**Files:**
- Modify: `PatProt/Services/PDFGenerator.swift` (nur `drawPage1`)

Alle Änderungen in der Funktion `drawPage1(p:)`.

### Änderung A — SAMPLER: immer alle 7 Zeilen

Den gesamten `do { ... }` Block mit SAMPLER (Zeilen ~376–413, von `// SAMPLER-Anamnese` bis zum schließenden `}`) ersetzen durch:

```swift
        // SAMPLER — immer alle 7 Zeilen anzeigen
        let samplerAllRows: [(String, String)] = [
            ("S – Symptome",       p.sampler.symptome),
            ("A – Allergien",      p.sampler.allergien),
            ("M – Medikamente",    p.medikamentFotos.isEmpty
                                    ? p.sampler.medikamente
                                    : "Medikamentenplan: Foto-Anhang (S. 3ff.)"),
            ("P – Vorgeschichte",  p.sampler.patientenVorgeschichte),
            ("L – Letztes Essen",  p.sampler.letztesMahl),
            ("E – Ereignis",       p.sampler.ereignis),
            ("R – Risikofaktoren", p.sampler.risikofaktoren),
        ]
        for (label, value) in samplerAllRows {
            field(label, value, x:lx, y:y, w:rx-lx, h:11, lw:85)
            y += 11
        }
```

### Änderung B — Section 3: Messwerte Spaltenheader + 2 Wertspalten

**B1 — Nach `subHeader("Messwerte", x:lx, y:y, w:bW1)` die Sub-Labels "Ankunft" / "Übergabe" in den Header schreiben:**

Direkt nach `subHeader("Messwerte", x:lx, y:y, w:bW1)` und VOR den anderen `subHeader`-Aufrufen einfügen:

```swift
        let mvLbl: CGFloat = 42
        let mvAnk: CGFloat = (bW1 - mvLbl) / 2
        let mvUeb: CGFloat = bW1 - mvLbl - mvAnk
        txt("Ankunft",  CGRect(x:lx+mvLbl,       y:y+2.5, width:mvAnk-2, height:4.5),
            font:f5, color:.white, align:.center)
        txt("Übergabe", CGRect(x:lx+mvLbl+mvAnk, y:y+2.5, width:mvUeb-2, height:4.5),
            font:f5, color:.white, align:.center)
```

**B2 — Den gesamten Messwerte-Block (Zeilen ~492–517) ersetzen:**

Den Block von `// Messwerte column:` bis zum Ende der `for` Schleife für mvItems ersetzen durch:

```swift
        // Messwerte: Ankunft | Übergabe
        let u = p.uebergabeMesswerte
        let mvH: CGFloat = 11
        let mvItems: [(String, String, String)] = [
            ("RR syst.",  p.circulation.blutdruckSystolisch.map  { "\($0)" } ?? "", u.rrSys),
            ("RR diast.", p.circulation.blutdruckDiastolisch.map { "\($0)" } ?? "", u.rrDia),
            ("HF (/min)", p.circulation.puls.map                 { "\($0)" } ?? "", u.hf),
            ("SpO₂ (%)",  p.breathing.spo2.map                   { "\($0)" } ?? "", u.spo2),
            ("AF (/min)", p.breathing.atemFrequenz.map            { "\($0)" } ?? "", u.af),
            ("BZ",        p.disability.blutzucker.map { String(format:"%.1f",$0) } ?? "", u.bz),
            ("Temp (°C)", p.exposure.temperatur.map   { String(format:"%.1f",$0) } ?? "", u.temp),
        ]
        let mvColY = y
        for (i,(label,ankVal,uebVal)) in mvItems.enumerated() {
            let ry = mvColY + CGFloat(i)*mvH
            let hl = (label == "RR syst." || label == "RR diast.")
            let bg: UIColor = i%2 == 0 ? .white : UIColor(white:0.97,alpha:1)
            fillRect(CGRect(x:lx,y:ry,width:bW1,height:mvH), hl ? hlYellow : bg)
            strokeRect(CGRect(x:lx,y:ry,width:bW1,height:mvH))
            vline(lx+mvLbl, ry, mvH)
            vline(lx+mvLbl+mvAnk, ry, mvH)
            txt(label,  CGRect(x:lx+1.5,         y:ry+2, width:mvLbl-3,    height:mvH-4), font:f6, color:.darkGray)
            txt(ankVal, CGRect(x:lx+mvLbl+1.5,   y:ry+2, width:mvAnk-3,    height:mvH-4), font:f7b, align:.center)
            txt(uebVal, CGRect(x:lx+mvLbl+mvAnk+1.5,y:ry+2,width:mvUeb-3, height:mvH-4), font:f7b, align:.center)
        }
```

**B3 — In der `max()` Berechnung für `y` nach Section 3 die alten `mvItems.count` (9) durch 7 ersetzen:**

Aktuelle Zeile:
```swift
        y = mvColY + CGFloat(max(mvItems.count, atItems.count, ciItems.count, neItems.count, haItems.count))*mvH + 2
```
Bleibt strukturell gleich — da `mvItems` jetzt 7 Einträge hat, wird das automatisch korrekt berechnet. Keine Änderung nötig.

### Änderung C — Section 5 Verlauf aus Page 1 entfernen

Den gesamten Block von `// ── SECTION 5 Verlauf (Zeitraster) ─────────────────` bis zum schließenden `}` des `if !p.diagnose.verlauf.isEmpty` Blocks (Zeilen ~794–850) **löschen**.

Das heißt: Alles von:
```swift
        // ── SECTION 5 Verlauf (Zeitraster) ─────────────────
        secHeader("5. Verlauf / Verlaufsbeschreibung", x:lx, y:y, w:rx-lx)
        y += 11
```
bis einschließlich:
```swift
            y += vFtH
        }
```
entfernen. Der `// Footer` Aufruf `drawFooter(erstelltAm: p.erstelltAm)` bleibt.

- [ ] **Step 1: Änderung A — SAMPLER-Block ersetzen** (Anleitung oben)

- [ ] **Step 2: Änderung B1 — Sub-Labels nach subHeader("Messwerte") einfügen**

- [ ] **Step 3: Änderung B2 — Messwerte-Block ersetzen** (Anleitung oben)

- [ ] **Step 4: Änderung C — Verlauf-Block aus drawPage1 entfernen** (Zeilen ~794–850)

- [ ] **Step 5: Build**

```bash
xcodebuild -scheme PatProt -destination 'id=58572FBD-8FEA-49FD-B5A2-6E8326E4BCED' build 2>&1 | tail -3
```

Erwartet: `** BUILD SUCCEEDED **`

- [ ] **Step 6: Commit**

```bash
git -C /Users/lukeslz/Documents/Privat/DLRG/PatProt/PatProt commit -am "feat: PDF Page1 – SAMPLER 7 Zeilen, 2-Spalten-Messwerte, Verlauf entfernt"
```

---

## Task 4: PDFGenerator.swift — Page 2: Verlauf + Reihenfolge + 4-Spalten Maßnahmen

**Files:**
- Modify: `PatProt/Services/PDFGenerator.swift` (nur `drawPage2`)

Alle Änderungen in der Funktion `drawPage2(p:)`.

Neue Reihenfolge: **4.2 Verletzungen → 5 Verlauf → 4.5 Medikamente → 6 Maßnahmen (4 Spalten + Details) → 7+8 → 9 → Unterschrift**

### Änderung A — Verlauf-Block nach Section 4.2 einfügen

Direkt nach der Zeile `y = max(vmY + 20, spezY0 + CGFloat(spezItems.count)*spezH) + 2` den Verlauf-Block einfügen:

```swift
        // ── SECTION 5 Verlauf (Zeitraster) ─────────────────
        secHeader("5. Verlauf / Verlaufsbeschreibung", x:lx, y:y, w:rx-lx)
        y += 11

        let vLabelW: CGFloat = 36
        let vMaxCols = 8
        let vColW = (rx - lx - vLabelW) / CGFloat(vMaxCols)
        let vRowH: CGFloat = 11
        let vTf = DateFormatter(); vTf.dateFormat = "HH:mm"
        let vMess = Array(p.verlaufMessungen.sorted { $0.zeitpunkt < $1.zeitpunkt }.prefix(vMaxCols))
        let vRows: [(String, (VerlaufsMessung) -> String)] = [
            ("RR sys",  { $0.blutdruckSys.map  { "\($0)" } ?? "" }),
            ("RR dia",  { $0.blutdruckDia.map  { "\($0)" } ?? "" }),
            ("HF /min", { $0.puls.map          { "\($0)" } ?? "" }),
            ("SpO₂ %",  { $0.spo2.map          { "\($0)" } ?? "" }),
            ("AF /min", { $0.atemFrequenz.map  { "\($0)" } ?? "" }),
            ("BZ",      { $0.blutzucker.map    { String(format:"%.1f",$0) } ?? "" }),
            ("Temp °C", { $0.temperatur.map    { String(format:"%.1f",$0) } ?? "" }),
            ("GCS",     { $0.gcsGesamt.map     { "\($0)" } ?? "" }),
        ]
        let vGridY = y
        let vLabelBg = UIColor(red:0.90, green:0.95, blue:1.0, alpha:1)

        fillRect(CGRect(x:lx, y:vGridY, width:vLabelW, height:vRowH), vLightB)
        strokeRect(CGRect(x:lx, y:vGridY, width:vLabelW, height:vRowH))
        txt("Uhrzeit", CGRect(x:lx+2, y:vGridY+2, width:vLabelW-4, height:vRowH-4), font:f6b, color:colBlue)
        for col in 0..<vMaxCols {
            let cx = lx + vLabelW + CGFloat(col)*vColW
            fillRect(CGRect(x:cx, y:vGridY, width:vColW, height:vRowH), vLightB)
            strokeRect(CGRect(x:cx, y:vGridY, width:vColW, height:vRowH))
            let ts = col < vMess.count ? vTf.string(from: vMess[col].zeitpunkt) : ""
            txt(ts, CGRect(x:cx+1, y:vGridY+2, width:vColW-2, height:vRowH-4), font:f6b, color:colBlue, align:.center)
        }
        for (row, (label, fn)) in vRows.enumerated() {
            let ry = vGridY + CGFloat(row + 1) * vRowH
            let dataBg: UIColor = row%2 == 0 ? .white : UIColor(white:0.97, alpha:1)
            fillRect(CGRect(x:lx, y:ry, width:vLabelW, height:vRowH), vLabelBg)
            strokeRect(CGRect(x:lx, y:ry, width:vLabelW, height:vRowH))
            txt(label, CGRect(x:lx+2, y:ry+2, width:vLabelW-4, height:vRowH-4), font:f6, color:colBlue)
            for col in 0..<vMaxCols {
                let cx = lx + vLabelW + CGFloat(col)*vColW
                fillRect(CGRect(x:cx, y:ry, width:vColW, height:vRowH), dataBg)
                strokeRect(CGRect(x:cx, y:ry, width:vColW, height:vRowH))
                let val = col < vMess.count ? fn(vMess[col]) : ""
                txt(val, CGRect(x:cx+1, y:ry+2, width:vColW-2, height:vRowH-4), font:f7b, color:.black, align:.center)
            }
        }
        y = vGridY + CGFloat(vRows.count + 1) * vRowH + 2
        if !p.diagnose.verlauf.isEmpty {
            let vFtH: CGFloat = 22
            fillRect(CGRect(x:lx, y:y, width:rx-lx, height:vFtH), .white)
            strokeRect(CGRect(x:lx, y:y, width:rx-lx, height:vFtH))
            mtxt(p.diagnose.verlauf, CGRect(x:lx+2, y:y+2, width:rx-lx-4, height:vFtH-4), font:f7)
            y += vFtH
        }
```

### Änderung B — Medikamente vor Maßnahmen verschieben

Den gesamten Medikamente-Block (aktuell `// ── SECTION 6.5 Medikamente ──────────────────────` Zeilen ~1150–1185) **ausschneiden** und direkt nach dem Verlauf-Block (nach `y += vFtH` bzw. `y += 2`) **einfügen**.

Dabei die Section-Header-Bezeichnung von `"6.5 Medikamente"` auf `"4.5 Medikamente"` ändern:

```swift
        // ── SECTION 4.5 Medikamente ───────────────────────
        if !p.medikamente.isEmpty {
            secHeader("4.5 Medikamente", x:lx, y:y, w:rx-lx)
            y += 11
            let mTotW = rx - lx
            let mC: [CGFloat] = [mTotW*0.32, mTotW*0.14, mTotW*0.12, mTotW*0.20, mTotW*0.11, mTotW*0.11]
            let mHdr = ["Medikament","Dosis","Einheit","Applikationsweg","Zeit",""]
            fillRect(CGRect(x:lx,y:y,width:mTotW,height:9), vLightB)
            strokeRect(CGRect(x:lx,y:y,width:mTotW,height:9))
            var hx = lx
            for (i,h2) in mHdr.enumerated() {
                txt(h2, CGRect(x:hx+1,y:y+1,width:mC[i]-2,height:7), font:f6b, color:colBlue)
                hx += mC[i]
            }
            y += 9
            let medH: CGFloat = 10
            for (idx, med) in p.medikamente.enumerated() {
                if y + medH > pageSize.height - 15 { break }
                let bg = idx%2==0 ? UIColor.white : UIColor(white:0.97,alpha:1)
                fillRect(CGRect(x:lx,y:y,width:mTotW,height:medH), bg)
                strokeRect(CGRect(x:lx,y:y,width:mTotW,height:medH))
                var mx2 = lx
                let vals2 = [med.name, med.dosis, med.einheit, med.route, t(med.zeit), ""]
                for (j,val2) in vals2.enumerated() {
                    if j < vals2.count-1 { vline(mx2+mC[j], y, medH) }
                    txt(val2, CGRect(x:mx2+1.5,y:y+1.5,width:mC[j]-3,height:medH-3), font:f7)
                    mx2 += mC[j]
                }
                y += medH
            }
            y += 2
        }
```

### Änderung C — Section 6 auf 4 Spalten umstrukturieren

Den gesamten Block `// ── SECTION 6 Maßnahmen ────────────────────────────` bis `y = maY1 + maH + 2` (aktuelle Zeilen ~1017–1110) **ersetzen** durch:

```swift
        // ── SECTION 6 Maßnahmen ────────────────────────────
        secHeader("6. Maßnahmen", x:lx, y:y, w:rx-lx)
        y += 11

        let totalW = rx - lx
        let m6W1 = totalW * 0.25
        let m6W2 = totalW * 0.26
        let m6W3 = totalW * 0.25
        let m6W4 = totalW - m6W1 - m6W2 - m6W3
        let m6x1 = lx
        let m6x2 = lx + m6W1
        let m6x3 = lx + m6W1 + m6W2
        let m6x4 = lx + m6W1 + m6W2 + m6W3

        subHeader("Airway / Stabilisation", x:m6x1, y:y, w:m6W1)
        subHeader("Kreislauf / Zugänge",    x:m6x2, y:y, w:m6W2)
        subHeader("Weitere Maßnahmen",      x:m6x3, y:y, w:m6W3)
        subHeader("Lagerung / Transport",   x:m6x4, y:y, w:m6W4)
        y += 9.5

        let maH: CGFloat = 9.5
        let maItems1: [(String,Bool)] = [
            ("Atemweg freimachen",  p.massnahmen.atemwegFreimachen),
            ("Cervikalstütze/HWS",  p.massnahmen.cervikalStuetze),
            ("Absaugung",           p.massnahmen.absaugung),
            ("Sauerstoffgabe",      p.massnahmen.sauerstoffgabe),
            ("Maskenbeatmung",      p.massnahmen.maskenbeatmung),
            ("Mask.beat. unmöglich",p.massnahmen.maskenbeatmungUnmoeglich),
            ("EGA supraglottisch",  p.massnahmen.supraglottisch),
            ("Atemweg erschwert",   p.massnahmen.atemwegErschwert),
            ("CPAP",                p.massnahmen.cpap),
            ("Heimlich (FK)",       p.massnahmen.heimlich),
        ]
        let maItems2: [(String,Bool)] = [
            ("Peripher-venös",     p.massnahmen.peripherVenoes),
            ("Defibrillation",     p.massnahmen.defibrillation),
            ("Kardioversion",      p.massnahmen.kardioversion),
            ("Intraossär",         p.massnahmen.intraossaer),
            ("Tourniquet",         p.massnahmen.tourniquet),
            ("Verband / Wundvers.",p.massnahmen.verband),
            ("Beckenschlinge",     p.massnahmen.beckenschlinge),
            ("Krisenintervention", p.massnahmen.krisenintervention),
            ("Entbindung",         p.massnahmen.entbindung),
        ]
        let maItems3: [(String,Bool)] = [
            ("Wärmeerhalt", p.massnahmen.waermeerhalt),
            ("Kühlung",     p.massnahmen.kuehlung),
        ]
        let maItems4: [(String,Bool)] = [
            ("OK-Hochlagerung",    p.massnahmen.okHochlagerung),
            ("Flachlagerung",      p.massnahmen.flachlagerung),
            ("Schocklagerung",     p.massnahmen.schocklagerung),
            ("Herz-Tieflage",      p.massnahmen.herzTieflage),
            ("Linksseitenlage",    p.massnahmen.linksseitenlage),
            ("Sitzender Transport",p.massnahmen.sitzenderTransport),
            ("Vakuummatratze",     p.massnahmen.vakuummatratze),
            ("Schaufeltrage",      p.massnahmen.schaufeltrage),
            ("Extremit.schienung", p.massnahmen.extremitaetenschienung),
        ]

        let allCols: [([(String,Bool)], CGFloat, CGFloat)] = [
            (maItems1, m6x1, m6W1), (maItems2, m6x2, m6W2),
            (maItems3, m6x3, m6W3), (maItems4, m6x4, m6W4),
        ]
        let maY0 = y
        for (items, cx, cw) in allCols {
            for (i,(label,checked)) in items.enumerated() {
                let ry = maY0 + CGFloat(i)*maH
                let bg: UIColor = i%2==0 ? .white : UIColor(white:0.97,alpha:1)
                fillRect(CGRect(x:cx,y:ry,width:cw,height:maH), bg)
                strokeRect(CGRect(x:cx,y:ry,width:cw,height:maH))
                cb(label, checked, x:cx+2, y:ry+1, bs:7, lw:cw-12)
            }
        }
        y = maY0 + CGFloat(max(maItems1.count, maItems2.count, maItems3.count, maItems4.count))*maH + 1

        // Monitoring (volle Breite)
        subHeader("Monitoring", x:lx, y:y, w:rx-lx)
        y += 9.5
        let monItems: [(String,Bool)] = [
            ("SpO₂",          p.massnahmen.monSpo2),
            ("NIBP",           p.massnahmen.monNibp),
            ("BZ",             p.massnahmen.monBz),
            ("EKG / AED-Monitor", p.massnahmen.monEkg),
            ("Temperatur",     p.massnahmen.monTemperatur),
        ]
        let maY1 = y
        let monColW = (rx - lx) / CGFloat(monItems.count)
        for (i,(label,checked)) in monItems.enumerated() {
            let col = lx + CGFloat(i) * monColW
            fillRect(CGRect(x:col,y:maY1,width:monColW,height:maH), i%2==0 ? .white : UIColor(white:0.97,alpha:1))
            strokeRect(CGRect(x:col,y:maY1,width:monColW,height:maH))
            cb(label, checked, x:col+2, y:maY1+1, bs:7, lw:monColW-12)
        }
        y = maY1 + maH + 2
```

**Achtung:** Der `maDetails`-Block (nach Monitoring) bleibt **unverändert** stehen — er ist bereits vorhanden und korrekt. Nur den Medikamente-Block (6.5) nach dem Details-Block entfernen (er wurde schon als 4.5 weiter oben eingefügt).

- [ ] **Step 1: Änderung A — Verlauf-Block nach Section 4.2 einfügen**

- [ ] **Step 2: Änderung B — Medikamente-Block nach Verlauf verschieben und auf „4.5" umbenennen**

Den alten Medikamente-Block (Zeilen ~1150–1185 in der aktuellen Datei, nach maDetails) löschen.

- [ ] **Step 3: Änderung C — Section 6 von 3 auf 4 Spalten umstrukturieren** (Block ersetzen wie oben)

- [ ] **Step 4: Build**

```bash
xcodebuild -scheme PatProt -destination 'id=58572FBD-8FEA-49FD-B5A2-6E8326E4BCED' build 2>&1 | tail -3
```

Erwartet: `** BUILD SUCCEEDED **`

- [ ] **Step 5: Test**

```bash
xcodebuild test -scheme PatProt -destination 'id=58572FBD-8FEA-49FD-B5A2-6E8326E4BCED' 2>&1 | grep -E "TEST (SUCCEEDED|FAILED)"
```

Erwartet: `** TEST SUCCEEDED **`

- [ ] **Step 6: Commit**

```bash
git -C /Users/lukeslz/Documents/Privat/DLRG/PatProt/PatProt commit -am "feat: PDF Page2 – Verlauf, Medi 4.5, 4-Spalten-Maßnahmen"
```

---

## Akzeptanzkriterien

1. Section 2 SAMPLER zeigt immer alle 7 Zeilen S/A/M/P/L/E/R (auch leer)
2. Section 3 Messwerte hat zwei Wertspalten: „Ankunft" und „Übergabe"  
3. PDF Seite 1 hat keinen Verlauf-Block mehr
4. PDF Seite 2: Reihenfolge ist 4.2 → 5 Verlauf → 4.5 Medi → 6 Maßnahmen → 7 → 8 → 9
5. Section 6 hat 4 Spalten: Airway / Kreislauf / Weitere / Lagerung
6. AbschlussView hat „Übergabe-Messwerte"-Section mit 7 Feldern
7. Build und alle Tests bestehen
