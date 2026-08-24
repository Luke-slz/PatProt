# PDF-Protokoll DIVI-Revision – Implementierungsplan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Duplikate entfernen, DIVI-Konformität herstellen und Übersichtlichkeit des generierten PDF-Einsatzprotokolls verbessern.

**Architecture:** Alle Änderungen befinden sich ausschließlich in `Services/PDFGenerator.swift`. Die Funktion `drawPage1` erhält sieben isolierte Eingriffe; `drawPage2` bleibt unverändert. Keine Modelländerungen notwendig.

**Tech Stack:** Swift, UIKit (UIGraphicsPDFRenderer), kein externes Framework.

---

## Dateiübersicht

| Datei | Aktion | Inhalt |
|-------|--------|--------|
| `PatProt/Services/PDFGenerator.swift` | Modify | Alle 7 Änderungen |

Referenzdokument: `docs/superpowers/specs/2026-05-23-pdf-divi-revision-design.md`

---

## Build-Befehl (Verifikation nach jedem Task)

```bash
cd /Users/lukeslz/Documents/Privat/DLRG/PatProt/PatProt
xcodebuild build \
  -project PatProt.xcodeproj \
  -scheme PatProt \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -quiet 2>&1 | grep -E "(error:|BUILD)"
```

Erwartete Ausgabe: `BUILD SUCCEEDED` (keine `error:` Zeilen)

---

## Task 1: Patientenblock bereinigen

**Files:**
- Modify: `PatProt/Services/PDFGenerator.swift:214–242`

Entfernt: Krankenkasse, Versichertenart-CBs, Kostenträger-Kennz., Status, Arzt-Nr., Datum-Duplikat.
Behalten: Name, geb. am + Geschlecht, Versicherungs-Nr. + Gewicht.

- [ ] **Schritt 1: Den alten Patientenblock (Zeilen 214–242) ersetzen**

Ersetze den gesamten `// Left: insurance / patient header` Block:

```swift
// Left: patient header (klinisch relevante Felder)
do {
    let x = lx; let w = c1 - lx
    field("Name des Patienten",
          "\(p.patientDaten.nachname), \(p.patientDaten.vorname)",
          x:x, y:y, w:w, h:14, lw:w*0.38, hl:true)
    field("geb. am", d(p.patientDaten.geburtsDatum),
          x:x, y:y+14, w:w*0.55, h:12, lw:38)
    field("Geschlecht", p.patientDaten.geschlecht.rawValue,
          x:x+w*0.55, y:y+14, w:w*0.45, h:12, lw:42)
    let fw2 = w / 2
    field("Versicherten-Nr.", p.patientDaten.versicherungsNummer,
          x:x, y:y+26, w:fw2, h:12, lw:fw2*0.5)
    let gewStr = p.patientDaten.gewicht.map { String(format: "%.0f kg", $0) } ?? ""
    field("Gewicht", gewStr, x:x+fw2, y:y+26, w:fw2, h:12, lw:fw2*0.5)
}
```

- [ ] **Schritt 2: Build ausführen**

```bash
cd /Users/lukeslz/Documents/Privat/DLRG/PatProt/PatProt
xcodebuild build -project PatProt.xcodeproj -scheme PatProt \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -quiet 2>&1 | grep -E "(error:|BUILD)"
```

Erwartete Ausgabe: `BUILD SUCCEEDED`

- [ ] **Schritt 3: Commit**

```bash
git -C /Users/lukeslz/Documents/Privat/DLRG/PatProt/PatProt \
  commit -am "fix(pdf): entferne leere Kassenfelder aus Patientenblock"
```

---

## Task 2: Einsatznummer aus Titelblock entfernen

**Files:**
- Modify: `PatProt/Services/PDFGenerator.swift:302–314`

Einsatznummer steht bereits im Header (Header-Zeile 203) und in Section 1 (Zeitblock). Der dritte Auftritt im Titelblock wird entfernt.

- [ ] **Schritt 1: Titelblock anpassen**

Finde den `// ── EINSATZPROTOKOLL title block` Block und ersetze ihn:

```swift
// ── EINSATZPROTOKOLL title block ──────────────────
do {
    let x = lx; let w = c1 - lx; let bh: CGFloat = 55
    fillRect(CGRect(x:x,y:y,width:w,height:bh), vLightB)
    strokeRect(CGRect(x:x,y:y,width:w,height:bh))
    txt("EINSATZPROTOKOLL",
        CGRect(x:x+3,y:y+4,width:w-6,height:16), font:f13b, color:colBlue)
    cb("Notfallsanitäter", p.verfasser == .notfallsanitaeter,
       x:x+3, y:y+24, bs:7, lw:80)
    cb("Rettungssanitäter", p.verfasser == .rettungssanitaeter,
       x:x+3, y:y+36, bs:7, lw:80)
    y += bh
}
```

(Entfernt: `txt("Einsatznummer:")` und `valBox(p.einsatzOrt.einsatzNummer, ...)`)

- [ ] **Schritt 2: Build ausführen**

```bash
xcodebuild build -project PatProt.xcodeproj -scheme PatProt \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -quiet 2>&1 | grep -E "(error:|BUILD)"
```

- [ ] **Schritt 3: Commit**

```bash
git -C /Users/lukeslz/Documents/Privat/DLRG/PatProt/PatProt \
  commit -am "fix(pdf): einsatznummer nur noch 2x (header + section 1)"
```

---

## Task 3: Fahrzeugtypen RTW/KTW/FR/NEF mit Auto-Check

**Files:**
- Modify: `PatProt/Services/PDFGenerator.swift:251–261`

Ersetzt die nutzlose `[("NKW", false)]`-Zeile durch vier praxisrelevante Fahrzeugtypen, die automatisch aus dem Fahrzeugnamen erkannt werden.

- [ ] **Schritt 1: Fahrzeugtyp-Checkboxen ersetzen**

Finde den Bereich `// Vehicle checkboxes` in der rechten Section-1-do-Klammer und ersetze:

```swift
// Vehicle checkboxes — auto-detect aus fahrzeugName
let fzUp = p.einsatzOrt.fahrzeugName.uppercased()
let vItems: [(String, Bool)] = [
    ("RTW", fzUp.contains("RTW")),
    ("KTW", fzUp.contains("KTW")),
    ("FR",  fzUp.contains("FR") || fzUp.contains("FIRST")),
    ("NEF", fzUp.contains("NEF")),
]
let vColW = w / CGFloat(vItems.count)
fillRect(CGRect(x:x, y:y, width:w, height:11), .white)
strokeRect(CGRect(x:x, y:y, width:w, height:11))
for (i,(label,checked)) in vItems.enumerated() {
    cb(label, checked, x:x+CGFloat(i)*vColW+2, y:y+1.5, bs:7, lw:vColW-11)
}
y += 11
```

Die Ersetzung schließt die alten Zeilen `let fz = ...` und `let cbW = w/7` mit ein — beide fallen weg.

- [ ] **Schritt 2: Build ausführen**

```bash
xcodebuild build -project PatProt.xcodeproj -scheme PatProt \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -quiet 2>&1 | grep -E "(error:|BUILD)"
```

- [ ] **Schritt 3: Commit**

```bash
git -C /Users/lukeslz/Documents/Privat/DLRG/PatProt/PatProt \
  commit -am "fix(pdf): fahrzeugtypen RTW/KTW/FR/NEF mit auto-check"
```

---

## Task 4: Section 1 Zeitblock bereinigen

**Files:**
- Modify: `PatProt/Services/PDFGenerator.swift:279–298`

Ändert: "Übergabe an RD" → "Ankunft Zielklinik" (DIVI-Terminus, in Times Block 2). Führt "Einsatzart" und "Stichwort" zu einem Feld zusammen.

- [ ] **Schritt 1: Times-Block-2 und Einsatzort/Stichwort-Zeile ersetzen**

Ersetze die bisherigen Zeilen (Times Block 2 + Einsatzort/Stichwort). Times Block 2 beginnt mit `labeledVal("Übergabe an RD", ...)`:

```swift
// Times Block 2: Ankunft Zielklinik + Einsatz-Nr. (2 Felder)
let tW2 = w / 2
labeledVal("Einsatz-Nr.", p.einsatzOrt.einsatzNummer,
           x:x, y:y, w:tW2, labelH:7, valH:11)
// Stichwort kombiniert (SCHADA-Code · Einsatzart-Freitext)
let stichwortText = [p.einsatzOrt.stichwort, p.einsatzOrt.einsatzArt]
    .filter { !$0.isEmpty }.joined(separator: " · ")
labeledVal("Stichwort", stichwortText,
           x:x+tW2, y:y, w:tW2, labelH:7, valH:11)
y += 18

// Einsatzort (volle Breite)
let adresseText = [p.einsatzOrt.adresse, p.einsatzOrt.zusatz]
    .filter { !$0.isEmpty }.joined(separator: ", ")
field("Einsatzort", adresseText, x:x, y:y, w:w, h:11, lw:42)
y += 11
```

- [ ] **Schritt 3: Build ausführen**

```bash
xcodebuild build -project PatProt.xcodeproj -scheme PatProt \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -quiet 2>&1 | grep -E "(error:|BUILD)"
```

- [ ] **Schritt 4: Commit**

```bash
git -C /Users/lukeslz/Documents/Privat/DLRG/PatProt/PatProt \
  commit -am "fix(pdf): einsatzart+stichwort zusammengeführt, übergabe→zielklinik"
```

---

## Task 5: SAMPLER nach Section 2 verschieben

**Files:**
- Modify: `PatProt/Services/PDFGenerator.swift` — ABCDE-Loop (~Zeile 442–459) + SAMPLER-Block (~Zeile 784–817)

Dies ist der umfangreichste Task. Drei Schritte:
1. SAMPLER-Block aus dem Ende von Seite 1 entfernen
2. SAMPLER-Block direkt vor der ABCDE-Schleife einfügen
3. Dekorativbuchstaben (S,M,P,L,R) aus ABCDE-Schleife entfernen + Content-Breite anpassen

- [ ] **Schritt 1: SAMPLER-Block-Code extrahieren (gedanklich merken)**

Der zu verschiebende Block beginnt mit `if y + 80 < pageSize.height - 15 {` und endet nach der `for (label, value) in samplerData` Schleife. Dieser Block wird an eine neue Stelle verschoben (Schritt 3).

- [ ] **Schritt 2: ABCDE-Schleife bereinigen — Dekorativbuchstaben entfernen, Breite anpassen**

Finde den ABCDE-Loop (beginnt mit `for i in 0..<5 {`). Ersetze ihn vollständig:

```swift
let rowH: CGFloat = 15
for i in 0..<5 {
    let ry = y + CGFloat(i)*rowH
    // Buchstaben-Box A–E (links, 12pt)
    fillRect(CGRect(x:lx, y:ry, width:12, height:rowH), subBlue)
    txt(abcdeLetters[i],
        CGRect(x:lx+1, y:ry+3, width:10, height:rowH-6),
        font:f7b, color:.white, align:.center)
    // Content (volle Breite bis rx)
    let cw = rx - lx - 12
    fillRect(CGRect(x:lx+12, y:ry, width:cw, height:rowH),
             i%2==0 ? .white : UIColor(white:0.97,alpha:1))
    strokeRect(CGRect(x:lx+12, y:ry, width:cw, height:rowH))
    let isOB = abcdeRaw[i].isEmpty
    txt(abcdeVals[i],
        CGRect(x:lx+14, y:ry+3, width:cw-4, height:rowH-6),
        font: isOB ? UIFont.italicSystemFont(ofSize: 7) : f7,
        color: abcdeColors[i])
    // Kein SAMPLER-Buchstabe mehr rechts
}
y += CGFloat(5)*rowH
```

Ebenfalls entfernen: Die Zeile `let samplerLetters = ["S","M","P","L","R"]` (kurz vor der ABCDE-Schleife, ~Zeile 403).

- [ ] **Schritt 3: SAMPLER-Block vor dem ABCDE-Grid einfügen**

Direkt vor dem `let abcdeLetters = ["A","B","C","D","E"]` Block, nach den Notfallgeschehen-Feldern, einfügen:

```swift
// SAMPLER-Anamnese — DIVI Section 2
do {
    var samplerData: [(String, String)] = []
    if !p.sampler.symptome.isEmpty {
        samplerData.append(("S – Symptome", p.sampler.symptome))
    }
    if !p.sampler.allergien.isEmpty {
        samplerData.append(("A – Allergien", p.sampler.allergien))
    }
    if !p.medikamentFotos.isEmpty {
        samplerData.append(("M – Medikamente", "Medikamentenplan: Foto-Anhang (S. 3ff.)"))
    } else if !p.sampler.medikamente.isEmpty {
        samplerData.append(("M – Medikamente", p.sampler.medikamente))
    }
    if !p.sampler.patientenVorgeschichte.isEmpty {
        samplerData.append(("P – Vorgeschichte", p.sampler.patientenVorgeschichte))
    }
    if !p.sampler.letztesMahl.isEmpty {
        samplerData.append(("L – Letztes Essen", p.sampler.letztesMahl))
    }
    if !p.sampler.ereignis.isEmpty {
        samplerData.append(("E – Ereignis", p.sampler.ereignis))
    }
    if !p.sampler.risikofaktoren.isEmpty {
        samplerData.append(("R – Risikofaktoren", p.sampler.risikofaktoren))
    }

    if samplerData.isEmpty {
        fillRect(CGRect(x:lx, y:y, width:rx-lx, height:11), .white)
        strokeRect(CGRect(x:lx, y:y, width:rx-lx, height:11))
        txt("SAMPLER – nicht erhoben",
            CGRect(x:lx+3, y:y+2, width:rx-lx-6, height:7),
            font:f7, color:.lightGray)
        y += 11
    } else {
        for (label, value) in samplerData {
            field(label, value, x:lx, y:y, w:rx-lx, h:11, lw:85)
            y += 11
        }
    }
}
```

- [ ] **Schritt 4: Den alten SAMPLER-Block am Ende von Seite 1 entfernen**

Finde und lösche den Block, der mit `// SAMPLER Anamnese block (remaining space)` beginnt und mit der schließenden `}` des äußeren `if y + 80 < ...` endet (~Zeile 784–817).

- [ ] **Schritt 5: Build ausführen**

```bash
xcodebuild build -project PatProt.xcodeproj -scheme PatProt \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -quiet 2>&1 | grep -E "(error:|BUILD)"
```

- [ ] **Schritt 6: Commit**

```bash
git -C /Users/lukeslz/Documents/Privat/DLRG/PatProt/PatProt \
  commit -am "fix(pdf): SAMPLER nach section 2 verschoben, dekorativbuchstaben entfernt"
```

---

## Task 6: Zyanose aus A+B Atmung entfernen

**Files:**
- Modify: `PatProt/Services/PDFGenerator.swift` — `atItems` Array (~Zeile 508–521)

Zyanose ist in A+B Atmung aus klinisch-systematischer Sicht fehl am Platz (gehört zu E/Haut-Begutachtung) und zeigt dieselbe Datenquelle wie der E/Haut-Checkbox.

- [ ] **Schritt 1: Zyanose aus atItems entfernen**

Finde `let atItems: [(String,Bool)] = [` und entferne die Zeile:

```swift
// Diese Zeile entfernen:
("Zyanose", p.breathing.zyanose),
```

Das Array sollte danach 11 Einträge haben (vorher 12).

- [ ] **Schritt 2: Build ausführen**

```bash
xcodebuild build -project PatProt.xcodeproj -scheme PatProt \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -quiet 2>&1 | grep -E "(error:|BUILD)"
```

- [ ] **Schritt 3: Commit**

```bash
git -C /Users/lukeslz/Documents/Privat/DLRG/PatProt/PatProt \
  commit -am "fix(pdf): zyanose nur in e/haut, nicht mehr in a+b atmung"
```

---

## Task 7: Temperatur-Duplikat und Hautfarbe-Zeile bereinigen

**Files:**
- Modify: `PatProt/Services/PDFGenerator.swift` — Hautfarbe-Zeile (~Zeile 619–623)

Temperatur steht bereits in der Messwerte-Spalte. Die Hautfarbe-Zeile darunter reduziert sich von 3 auf 2 Felder.

- [ ] **Schritt 1: Hautfarbe-Zeile auf 2 Felder reduzieren**

Finde und ersetze den Block mit `// Hautfarbe / Temp row`:

```swift
// Hautfarbe / Verletzungen (Temp ist bereits in Messwerte)
field("Hautfarbe", p.exposure.hautfarbe,
      x:lx, y:y, w:(rx-lx)/2, h:11, lw:42)
field("Verletzungen", p.exposure.verletzungen,
      x:lx+(rx-lx)/2, y:y, w:(rx-lx)/2, h:11, lw:45)
y += 11
```

(Entfernt: `field("Temperatur", p.exposure.temperatur..., ...)`)

- [ ] **Schritt 2: Build ausführen**

```bash
xcodebuild build -project PatProt.xcodeproj -scheme PatProt \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -quiet 2>&1 | grep -E "(error:|BUILD)"
```

- [ ] **Schritt 3: Finaler Commit**

```bash
git -C /Users/lukeslz/Documents/Privat/DLRG/PatProt/PatProt \
  commit -am "fix(pdf): temperatur-duplikat entfernt, hautfarbe-zeile bereinigt"
```

---

## Abschluss-Verifikation

Nach allen 7 Tasks die Akzeptanzkriterien aus dem Spec prüfen:

- [ ] Einsatznummer: genau 2× (Header + Section-1-Zeitblock)
- [ ] Datum: genau 1× (Header)
- [ ] Fahrzeug-CBs: RTW/KTW/FR/NEF sichtbar, korrekt auto-gecheckt
- [ ] SAMPLER in Section 2 (nach Notfallgeschehen, vor ABCDE)
- [ ] Keine SAMPLER-Buchstaben neben ABCDE
- [ ] Kein separater SAMPLER-Block am Ende Seite 1
- [ ] Zyanose nur in E/Haut (nicht in A+B)
- [ ] Temperatur nur in Messwerte-Spalte
- [ ] Hautfarbe-Zeile: 2 Felder (Hautfarbe + Verletzungen)
- [ ] Titelblock: nur Verfasser-CBs, keine Einsatznummer

**Zur visuellen Prüfung:** App im Simulator starten, neues Protokoll erstellen, PDF exportieren und alle Seiten durchsehen.
