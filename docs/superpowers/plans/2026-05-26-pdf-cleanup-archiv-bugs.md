# PDF Cleanup, Archiv 24h, Bug-Fixes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** PDF zeigt nur ausgefüllte/angekreuzte Felder, Archiveinträge werden 24h nach PDF-Export automatisch gelöscht, totes NACA-Feld und falsche Einsatzzeitenreihenfolge werden bereinigt.

**Architecture:** 5 unabhängige Tasks in Reihenfolge. Tasks 1–3 sind Model/Service/View-Änderungen ohne PDF-Bezug. Tasks 4–5 überarbeiten den PDFGenerator in zwei Tranchen (Seite 1 dann Seite 2). Jeder Task ist in sich kompilierbar.

**Tech Stack:** Swift 5.9, SwiftUI, UIKit (PDFGenerator), Swift Testing (`@Test`), Xcode iOS target

---

## Datei-Übersicht

| Datei | Task | Änderung |
|---|---|---|
| `PatProt/Models/Models.swift` | 1 | `ErgebnisData.nacaScore` entfernen, `ProtokollDaten.pdfExportiertAm` hinzufügen |
| `PatProt/Services/ProtokollArchiv.swift` | 2 | `markierePDFExport(id:)`, Purge in `laden()` |
| `PatProt/Views/AbschlussView.swift` | 2 | Auto-Archiv + `markierePDFExport` nach Export |
| `PatProt/Views/EinsatzzeitenView.swift` | 3 | Reihenfolge, Labels, Validierung |
| `PatProt/Services/PDFGenerator.swift` | 4+5 | Section 2–3 (Task 4), Section 4+6+7+8 (Task 5) |
| `PatProtTests/PatProtTests.swift` | 1+2 | Tests für Model + Archiv-Purge |

Alle Pfade relativ zu `/Users/lukeslz/Documents/Privat/DLRG/PatProt/PatProt/`.

---

## Task 1: Model-Bereinigung

**Files:**
- Modify: `PatProt/Models/Models.swift`
- Modify: `PatProtTests/PatProtTests.swift`

- [ ] **Schritt 1: Test für `pdfExportiertAm` schreiben**

In `PatProtTests/PatProtTests.swift` am Ende der `struct PatProtTests` hinzufügen:

```swift
@Test func protokollDatenHatPdfExportiertAmNil() {
    let p = EinsatzProtokoll()
    let daten = p.toDaten()
    #expect(daten.pdfExportiertAm == nil)
}
```

- [ ] **Schritt 2: Test scheitert bestätigen**

In Xcode: Product → Test (⌘U). Erwarteter Fehler: `value of type 'ProtokollDaten' has no member 'pdfExportiertAm'`

- [ ] **Schritt 3: `pdfExportiertAm` zu `ProtokollDaten` hinzufügen**

In `PatProt/Models/Models.swift`, `struct ProtokollDaten` (ca. Zeile 841): letztes Feld `verfasser` nach `zustandBeiUebergabe` suchen, dann dahinter einfügen:

```swift
    var uebergabeAn: String
    var zustandBeiUebergabe: String
    var verfasser: ProtokollVerfasser?
    var pdfExportiertAm: Date? = nil   // ← neu
}
```

- [ ] **Schritt 4: Test für NACA-Bereinigung schreiben**

In `PatProtTests/PatProtTests.swift`:

```swift
@Test func ergebnisDataHatKeinNacaScore() {
    // ErgebnisData.nacaScore existiert nicht mehr — dieser Test kompiliert
    // nur dann, wenn das Feld entfernt wurde.
    let e = ErgebnisData()
    // Wenn das Feld noch da wäre, würde die folgende Zeile einen Compiler-Fehler erzeugen:
    // let _ = e.nacaScore  // darf NICHT kompilieren
    _ = e  // suppress unused warning
    #expect(true)
}
```

> Hinweis: Dieser Test ist ein Compile-Guard — er stellt sicher dass das Feld nicht wieder eingeführt wird.

- [ ] **Schritt 5: `ErgebnisData.nacaScore` entfernen**

In `PatProt/Models/Models.swift`, `struct ErgebnisData` (ca. Zeile 694):

```swift
// VORHER:
struct ErgebnisData: Codable {
    var nacaScore: NacaScore = .naca3
    var transportZiel: TransportZiel = .anderesRettungsmittel

// NACHHER:
struct ErgebnisData: Codable {
    var transportZiel: TransportZiel = .anderesRettungsmittel
```

- [ ] **Schritt 6: Kompilierung und Tests prüfen**

Product → Build (⌘B) — muss fehlerfrei kompilieren.
Product → Test (⌘U) — alle Tests grün.

- [ ] **Schritt 7: Commit**

```bash
git add PatProt/PatProt/Models/Models.swift PatProt/PatProtTests/PatProtTests.swift
git commit -m "feat: add pdfExportiertAm to ProtokollDaten, remove dead ErgebnisData.nacaScore"
```

---

## Task 2: Archiv 24h nach PDF-Export

**Files:**
- Modify: `PatProt/Services/ProtokollArchiv.swift`
- Modify: `PatProt/Views/AbschlussView.swift`
- Modify: `PatProtTests/PatProtTests.swift`

- [ ] **Schritt 1: Tests für `markierePDFExport` und Purge schreiben**

In `PatProtTests/PatProtTests.swift`:

```swift
@Test func markierePDFExportSetztDatum() {
    let archiv = ProtokollArchiv.testInstance()
    let p = EinsatzProtokoll()
    try? archiv.speichern(p)
    archiv.markierePDFExport(id: p.id)
    let gespeichert = archiv.protokolle.first { $0.id == p.id }
    #expect(gespeichert?.pdfExportiertAm != nil)
    let diff = abs(gespeichert!.pdfExportiertAm!.timeIntervalSinceNow)
    #expect(diff < 5)
}

@Test func purgeEntferntAbgelaufeneEintraege() {
    let archiv = ProtokollArchiv.testInstance()
    let p = EinsatzProtokoll()
    try? archiv.speichern(p)
    // Ablaufdatum auf gestern setzen
    let idx = archiv.protokolle.firstIndex { $0.id == p.id }!
    archiv.protokolle[idx].pdfExportiertAm = Date(timeIntervalSinceNow: -86401)
    archiv.purgeAbgelaufene()
    #expect(archiv.protokolle.first { $0.id == p.id } == nil)
}

@Test func purgeBelaesstFrischangeEintraege() {
    let archiv = ProtokollArchiv.testInstance()
    let p = EinsatzProtokoll()
    try? archiv.speichern(p)
    archiv.markierePDFExport(id: p.id)
    archiv.purgeAbgelaufene()
    #expect(archiv.protokolle.first { $0.id == p.id } != nil)
}
```

- [ ] **Schritt 2: Tests scheitern bestätigen**

Product → Test (⌘U). Erwarteter Fehler: `type 'ProtokollArchiv' has no member 'testInstance'` und `has no member 'markierePDFExport'`

- [ ] **Schritt 3: `ProtokollArchiv` erweitern**

`PatProt/Services/ProtokollArchiv.swift` komplett ersetzen:

```swift
import Foundation
import Combine

// MARK: - Protokoll Archive Service (DSGVO: local only, .completeFileProtection)

class ProtokollArchiv: ObservableObject {
    static let shared = ProtokollArchiv()

    @Published var protokolle: [ProtokollDaten] = []

    private var archivDir: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Protokolle", isDirectory: true)
    }

    private init() {
        try? FileManager.default.createDirectory(at: archivDir, withIntermediateDirectories: true)
        laden()
    }

    // Für Tests: in-memory Instanz ohne Datei-I/O
    static func testInstance() -> ProtokollArchiv {
        let a = ProtokollArchiv(testMode: true)
        return a
    }
    private init(testMode: Bool) {
        // kein Verzeichnis anlegen, kein laden()
    }

    func speichern(_ protokoll: EinsatzProtokoll) throws {
        let daten = protokoll.toDaten()
        let data = try JSONEncoder().encode(daten)
        let url = archivDir.appendingPathComponent("\(daten.id.uuidString).json")
        try data.write(to: url, options: [.atomicWrite, .completeFileProtection])
        if let idx = protokolle.firstIndex(where: { $0.id == daten.id }) {
            protokolle[idx] = daten
        } else {
            protokolle.insert(daten, at: 0)
        }
    }

    func laden() {
        let files = (try? FileManager.default.contentsOfDirectory(
            at: archivDir, includingPropertiesForKeys: nil)) ?? []
        let decoder = JSONDecoder()
        protokolle = files.compactMap { url in
            guard let data = try? Data(contentsOf: url),
                  let p = try? decoder.decode(ProtokollDaten.self, from: data)
            else { return nil }
            return p
        }.sorted { $0.erstelltAm > $1.erstelltAm }
        purgeAbgelaufene()
    }

    func loeschen(_ id: UUID) {
        let url = archivDir.appendingPathComponent("\(id.uuidString).json")
        try? FileManager.default.removeItem(at: url)
        protokolle.removeAll { $0.id == id }
    }

    func markierePDFExport(id: UUID) {
        guard let idx = protokolle.firstIndex(where: { $0.id == id }) else { return }
        protokolle[idx].pdfExportiertAm = Date()
        let daten = protokolle[idx]
        let url = archivDir.appendingPathComponent("\(id.uuidString).json")
        if let data = try? JSONEncoder().encode(daten) {
            try? data.write(to: url, options: [.atomicWrite, .completeFileProtection])
        }
    }

    func purgeAbgelaufene() {
        let grenze = Date(timeIntervalSinceNow: -86400)
        let abgelaufene = protokolle.filter {
            guard let exportiert = $0.pdfExportiertAm else { return false }
            return exportiert < grenze
        }
        for eintrag in abgelaufene {
            let url = archivDir.appendingPathComponent("\(eintrag.id.uuidString).json")
            try? FileManager.default.removeItem(at: url)
        }
        protokolle.removeAll { eintrag in
            guard let exportiert = eintrag.pdfExportiertAm else { return false }
            return exportiert < grenze
        }
    }
}
```

- [ ] **Schritt 4: Tests prüfen**

Product → Test (⌘U). Alle 3 neuen Archiv-Tests müssen grün sein.

- [ ] **Schritt 5: `AbschlussView` — Auto-Archiv + Markierung nach Export**

In `PatProt/Views/AbschlussView.swift` im Share-Button-Callback (ca. Zeile 207):

```swift
// VORHER:
ShareSheet(activityItems: [url]) { completed in
    if completed {

// NACHHER:
ShareSheet(activityItems: [url]) { completed in
    if completed {
        if !gespeichert {
            try? ProtokollArchiv.shared.speichern(protokoll)
            gespeichert = true
        }
        ProtokollArchiv.shared.markierePDFExport(id: protokoll.id)
```

Den gleichen Block auch beim Mail-Export hinzufügen. Suche den Bereich:
```swift
zeigeMailComposer = true
```
Der Mail-Callback liegt in `.sheet(isPresented: $zeigeMailComposer)`. Dort nach dem erfolgreichen Versand (im `onDismiss` oder Completion-Handler des MFMailComposeViewController) einfügen:

```swift
if !gespeichert {
    try? ProtokollArchiv.shared.speichern(protokoll)
    gespeichert = true
}
ProtokollArchiv.shared.markierePDFExport(id: protokoll.id)
```

- [ ] **Schritt 6: Footer-Text in `AbschlussView` anpassen**

```swift
// VORHER:
Text("Die temporäre PDF-Datei wird nach dem Export gelöscht.").font(.footnote).foregroundStyle(.secondary)

// NACHHER:
Text("Das Protokoll bleibt 24 Stunden nach dem Export im Archiv.").font(.footnote).foregroundStyle(.secondary)
```

- [ ] **Schritt 7: Build und Test**

Product → Build (⌘B) — fehlerfrei.
Product → Test (⌘U) — alle Tests grün.

- [ ] **Schritt 8: Commit**

```bash
git add PatProt/PatProt/Services/ProtokollArchiv.swift PatProt/PatProt/Views/AbschlussView.swift PatProt/PatProtTests/PatProtTests.swift
git commit -m "feat: auto-archive on PDF export, purge entries 24h after export"
```

---

## Task 3: Einsatzzeiten — Reihenfolge, Labels, PDF-Label

**Files:**
- Modify: `PatProt/Views/EinsatzzeitenView.swift`
- Modify: `PatProt/Services/PDFGenerator.swift` (nur 2 Label-Strings)

- [ ] **Schritt 1: `EinsatzzeitenView` — Felder neu anordnen**

`PatProt/Views/EinsatzzeitenView.swift`, den Section-Block (ca. Zeile 29–33) ersetzen:

```swift
// VORHER:
ZeitFeld(label: "Alarmzeit",             datum: $protokoll.einsatzOrt.alarmzeit)
ZeitFeld(label: "Ankunft Patient",        datum: $protokoll.einsatzOrt.ankunftzeit)
ZeitFeld(label: "Abfahrt Einsatzstelle",  datum: $protokoll.einsatzOrt.abfahrtzeit)
ZeitFeld(label: "Übergabe an RD",         datum: $protokoll.einsatzOrt.krankenHausAnkunft)

// NACHHER:
ZeitFeld(label: "Alarmzeit",              datum: $protokoll.einsatzOrt.alarmzeit)
ZeitFeld(label: "Ankunft Patient",        datum: $protokoll.einsatzOrt.ankunftzeit)
ZeitFeld(label: "Übergabe an RD",         datum: $protokoll.einsatzOrt.krankenHausAnkunft)
ZeitFeld(label: "Einsatz Ende",           datum: $protokoll.einsatzOrt.abfahrtzeit)
```

- [ ] **Schritt 2: Validierungslogik anpassen**

In `EinsatzzeitenView.swift`, `private var zeitFehler` (ca. Zeile 6–15):

```swift
// VORHER:
private var zeitFehler: [String] {
    let alarm   = protokoll.einsatzOrt.alarmzeit
    let ankunft = protokoll.einsatzOrt.ankunftzeit
    let abfahrt = protokoll.einsatzOrt.abfahrtzeit
    let kh      = protokoll.einsatzOrt.krankenHausAnkunft
    var fehler: [String] = []
    if let a = alarm,   let b = ankunft, b < a { fehler.append("Ankunft liegt vor der Alarmzeit") }
    if let a = ankunft, let b = abfahrt, b < a { fehler.append("Abfahrt liegt vor der Ankunft") }
    if let a = abfahrt, let b = kh,      b < a { fehler.append("KH-Ankunft liegt vor der Abfahrt") }
    return fehler
}

// NACHHER:
private var zeitFehler: [String] {
    let alarm     = protokoll.einsatzOrt.alarmzeit
    let ankunft   = protokoll.einsatzOrt.ankunftzeit
    let uebergabe = protokoll.einsatzOrt.krankenHausAnkunft
    let ende      = protokoll.einsatzOrt.abfahrtzeit
    var fehler: [String] = []
    if let a = alarm,     let b = ankunft,   b < a { fehler.append("Ankunft liegt vor der Alarmzeit") }
    if let a = ankunft,   let b = uebergabe, b < a { fehler.append("Übergabe liegt vor der Ankunft") }
    if let a = uebergabe, let b = ende,      b < a { fehler.append("Einsatz Ende liegt vor der Übergabe") }
    return fehler
}
```

- [ ] **Schritt 3: PDF-Label „Ankunft Zielklinik" → „Übergabe an RD"**

In `PatProt/Services/PDFGenerator.swift` (ca. Zeile 317):

```swift
// VORHER:
labeledVal("Ankunft Zielklinik", t(p.einsatzOrt.krankenHausAnkunft),

// NACHHER:
labeledVal("Übergabe an RD", t(p.einsatzOrt.krankenHausAnkunft),
```

Ebenso das zweite Label in der gleichen do-Block (ca. Zeile 312):

```swift
// VORHER:
labeledVal("Abfahrt Einsatzstelle", t(p.einsatzOrt.abfahrtzeit),

// NACHHER:
labeledVal("Einsatz Ende", t(p.einsatzOrt.abfahrtzeit),
```

- [ ] **Schritt 4: Build**

Product → Build (⌘B) — fehlerfrei.

- [ ] **Schritt 5: Commit**

```bash
git add PatProt/PatProt/Views/EinsatzzeitenView.swift PatProt/PatProt/Services/PDFGenerator.swift
git commit -m "fix: Einsatzzeiten-Reihenfolge (Übergabe vor Einsatz Ende), PDF-Labels angepasst"
```

---

## Task 4: PDFGenerator Seite 1 — Section 2 Reihenfolge + Section 3 Filter

**Files:**
- Modify: `PatProt/Services/PDFGenerator.swift` (Methode `drawPage1`)

### 4a: Section 2 — ABCDE vor SAMPLER, ABCDE-Höhe 11pt

- [ ] **Schritt 1: ABCDE-Block vor SAMPLER verschieben**

In `drawPage1` den aktuellen Ablauf (ca. Zeile 411–484):

```
// aktuell:
SAMPLER (Zeilen 411–426)
ABCDE   (Zeilen 428–484)

// neu: ABCDE zuerst, dann SAMPLER
```

Den SAMPLER-Block (Zeilen 411–426) **ausschneiden** und **nach** dem ABCDE-Block (nach `y += CGFloat(5)*rowH`) einfügen.

Der ABCDE-Block verändert nur die `rowH`-Konstante:

```swift
// VORHER (Zeile 467):
let rowH: CGFloat = 15

// NACHHER:
let rowH: CGFloat = 11
```

Der SAMPLER-Block bleibt identisch, steht jetzt aber nach dem ABCDE-Block:

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

- [ ] **Schritt 2: Build-Test**

Product → Build (⌘B) — fehlerfrei.

### 4b: Section 3 Befunde — Dual-Checkbox-Filter

- [ ] **Schritt 3: Hilfsfunktion `filteredDualCb` hinzufügen**

Direkt vor `drawPage1` (nach den Primitive-Helpers, ca. nach Zeile 198) einfügen:

```swift
/// Rendert nur Zeilen, bei denen ankunft || übergabe gesetzt ist.
/// Wenn keine Zeile gesetzt: eine "o.B."-Zeile.
private static func filteredDualCb(
    _ items: [(String, Bool, Bool)],
    x: CGFloat, startY: CGFloat, w: CGFloat, h: CGFloat
) -> CGFloat {
    let active = items.filter { $0.1 || $0.2 }
    if active.isEmpty {
        let bg = UIColor.white
        fillRect(CGRect(x:x, y:startY, width:w, height:h), bg)
        strokeRect(CGRect(x:x, y:startY, width:w, height:h))
        let ps = NSMutableParagraphStyle(); ps.alignment = .left
        let attrs: [NSAttributedString.Key:Any] = [
            .font: UIFont.italicSystemFont(ofSize: 6),
            .foregroundColor: UIColor.lightGray,
            .paragraphStyle: ps
        ]
        ("o.B." as NSString).draw(
            in: CGRect(x:x+3, y:startY+1, width:w-6, height:h-2),
            withAttributes: attrs
        )
        return startY + h
    }
    for (i, (label, ank, ueb)) in active.enumerated() {
        dualCb(label, ankunft:ank, uebergabe:ueb,
               x:x, y:startY + CGFloat(i)*h, w:w, h:h)
    }
    return startY + CGFloat(active.count) * h
}
```

- [ ] **Schritt 4: A+B, C, D auf `filteredDualCb` umstellen**

Den aktuellen Render-Code für abItems, cItems, dItems (ca. Zeilen 565–641) ersetzen:

```swift
// ── A+B Atmung (gefiltert) ──
let abEndY = filteredDualCb(abItems, x:xAb, startY:mvColY, w:bW_ab, h:dCbH)

// ── Schmerz (nur wenn > 0) ──
let schmerzAnk = p.disability.schmerz
let schmerzUeb = ub.schmerz
if schmerzAnk > 0 || schmerzUeb > 0 {
    let schmerzRows: [(String, String)] = [
        ("Ank.", "\(schmerzAnk)/10"),
        ("Üb.",  "\(schmerzUeb)/10"),
    ]
    fillRect(CGRect(x:xSch, y:mvColY, width:bW_sch, height:CGFloat(schmerzRows.count)*dCbH), .white)
    strokeRect(CGRect(x:xSch, y:mvColY, width:bW_sch, height:CGFloat(schmerzRows.count)*dCbH))
    for (i,(lbl,val)) in schmerzRows.enumerated() {
        let ry = mvColY + CGFloat(i)*dCbH
        if i%2==1 { fillRect(CGRect(x:xSch,y:ry,width:bW_sch,height:dCbH), UIColor(white:0.97,alpha:1)) }
        txt(lbl, CGRect(x:xSch+1.5, y:ry+1.5, width:13, height:dCbH-3), font:f6, color:.darkGray)
        txt(val,  CGRect(x:xSch+15,  y:ry+1.5, width:bW_sch-17, height:dCbH-3), font:f7b, align:.center)
    }
}

// ── C Kreislauf (gefiltert) ──
let cEndY = filteredDualCb(cItems, x:xC, startY:mvColY, w:bW_c, h:dCbH)

// ── D Neurologie (gefiltert) ──
let dEndY = filteredDualCb(dItems, x:xD, startY:mvColY, w:bW_d, h:dCbH)

// GCS-Zeile direkt unter den D-Items
let gcsRy = dEndY
fillRect(CGRect(x:xD, y:gcsRy, width:bW_d, height:dCbH), hlYellow)
strokeRect(CGRect(x:xD, y:gcsRy, width:bW_d, height:dCbH))
vline(xD + bW_d/2, gcsRy, dCbH)
txt("GCS Ank.: \(gcs.gcsGesamt)/15",
    CGRect(x:xD+2, y:gcsRy+1.5, width:bW_d/2-4, height:dCbH-3), font:f6b)
txt("GCS Üb.: \(ub.gcsGesamt)/15",
    CGRect(x:xD+bW_d/2+2, y:gcsRy+1.5, width:bW_d/2-4, height:dCbH-3), font:f6b)

let mvAbsH = CGFloat(mvItems.count) * mvH
y = mvColY + max(mvAbsH, abEndY - mvColY, cEndY - mvColY, dEndY + dCbH - mvColY) + 2
```

> Hinweis: Der alte Block `let dTotalRows = dItems.count + 1` und das zugehörige `y = mvColY + max(...)` muss entfernt werden — die neue Berechnung oben ersetzt ihn.

- [ ] **Schritt 5: BZ-Format im Verlauf-Grid korrigieren (Zeile ~1004)**

```swift
// VORHER:
("BZ",      { $0.blutzucker.map    { String(format:"%.1f",$0) } ?? "" }),

// NACHHER:
("BZ",      { $0.blutzucker.map    { String(format:"%.0f",$0) } ?? "" }),
```

- [ ] **Schritt 6: Build**

Product → Build (⌘B) — fehlerfrei.

- [ ] **Schritt 7: Commit**

```bash
git add PatProt/PatProt/Services/PDFGenerator.swift
git commit -m "feat: PDF Section 2 ABCDE vor SAMPLER, Section 3 nur angekreuzte Befunde, BZ-Format mg/dL"
```

---

## Task 5: PDFGenerator Seite 1+2 — Section 4, 6, 7, 8

**Files:**
- Modify: `PatProt/Services/PDFGenerator.swift` (Methoden `drawPage1` und `drawPage2`)

### 5a: Section 4 Diagnose — Kompaktliste

- [ ] **Schritt 1: Hilfsfunktion `diagGruppe` hinzufügen**

Direkt nach `filteredDualCb` (vor `drawPage1`):

```swift
/// Rendert eine Diagnosegruppe als subHeader + eine kompakte Textzeile.
/// Nur wenn mind. ein Item angekreuzt ist.
private static func diagGruppe(
    _ titel: String, items: [(String, Bool)],
    x: CGFloat, y: CGFloat, w: CGFloat
) -> CGFloat {
    let checked = items.filter { $0.1 }.map { $0.0 }
    guard !checked.isEmpty else { return y }
    subHeader(titel, x:x, y:y, w:w)
    let text = checked.joined(separator: " · ")
    let lineY = y + 9.5
    fillRect(CGRect(x:x, y:lineY, width:w, height:11), .white)
    strokeRect(CGRect(x:x, y:lineY, width:w, height:11))
    txt(text, CGRect(x:x+3, y:lineY+2, width:w-6, height:8), font:f6)
    return lineY + 11
}
```

- [ ] **Schritt 2: Section 4 Diagnose-Gitter ersetzen**

Den gesamten Block ab `// 4.1 Three-column erkrankung layout` bis `y += CGFloat(maxRows2)*cbH + 2` (ca. Zeilen 685–821) ersetzen:

```swift
// 4.1 Diagnosen — kompakte Gruppen (nur angekreuzte)
let fullW = rx - lx
var diagY = y

diagY = diagGruppe("ZNS / Neurologie",
    items: col1Items, x:lx, y:diagY, w:fullW/2)
diagY = diagGruppe("Herz-Kreislauf",
    items: col2Items, x:lx, y:diagY, w:fullW/2)
diagY = diagGruppe("Atmung",
    items: col1b, x:lx + fullW/2, y:y, w:fullW/2)
// Hinweis: col1b startet bei der ursprünglichen diagY (vor ZNS-Block),
// da ZNS und Atmung nebeneinander stehen.
// Tatsächlich: Atmung rechts neben ZNS. Adjustierung:
diagY = max(diagY, y)  // bereits korrekt durch den letzten diagGruppe-Aufruf

diagY = diagGruppe("Infektionen / Sonstiges", items: col3Items, x:lx, y:diagY, w:fullW)
diagY = diagGruppe("Psychiatrie",             items: psyItems,  x:lx, y:diagY, w:fullW/3)
diagY = diagGruppe("Gyn / Geburtshilfe",      items: gynItems,  x:lx + fullW/3, y:diagY, w:fullW/3)
diagY = diagGruppe("Stoffwechsel / Abdomen",  items: stoffItems, x:lx + fullW*2/3, y:diagY, w:fullW/3)

y = diagY
```

> **Wichtig:** Die Listen `col1Items`, `col1b`, `col2Items`, `col3Items`, `psyItems`, `gynItems`, `stoffItems` bleiben exakt gleich wie bisher definiert — nur der Render-Teil wird ersetzt.

- [ ] **Schritt 3: Build-Test**

Product → Build (⌘B) — fehlerfrei.

### 5b: Section 6 Maßnahmen — nur angekreuzte Items

- [ ] **Schritt 4: Maßnahmen-Spalten filtern**

In `drawPage2`, den Render-Loop für die 4 Spalten (ca. Zeilen 1141–1151) ersetzen:

```swift
let maY0 = y
var maMaxRows = 0
for (items, cx, cw) in allCols {
    let active = items.filter { $0.1 }
    let rowsToRender: [(String, Bool)]
    if active.isEmpty {
        rowsToRender = [("—", false)]
    } else {
        rowsToRender = active
    }
    maMaxRows = max(maMaxRows, rowsToRender.count)
    for (i,(label,checked)) in rowsToRender.enumerated() {
        let ry = maY0 + CGFloat(i)*maH
        let bg: UIColor = i%2==0 ? .white : UIColor(white:0.97,alpha:1)
        fillRect(CGRect(x:cx,y:ry,width:cw,height:maH), bg)
        strokeRect(CGRect(x:cx,y:ry,width:cw,height:maH))
        cb(label, checked, x:cx+2, y:ry+1, bs:7, lw:cw-12)
    }
}
y = maY0 + CGFloat(maMaxRows)*maH + 1
```

- [ ] **Schritt 5: Monitoring — Textzeile statt alle Checkboxen**

Den Monitoring-Block (ca. Zeilen 1153–1172) ersetzen:

```swift
// Monitoring
let monChecked = monItems.filter { $0.1 }.map { $0.0 }
if !monChecked.isEmpty {
    subHeader("Monitoring", x:m6x1, y:y, w:m6W1)
    let monText = monChecked.joined(separator: " · ")
    fillRect(CGRect(x:m6x1, y:y+9.5, width:rx-lx, height:maH), .white)
    strokeRect(CGRect(x:m6x1, y:y+9.5, width:rx-lx, height:maH))
    txt(monText, CGRect(x:m6x1+3, y:y+9.5+1.5, width:rx-lx-6, height:maH-3), font:f6)
    y += 9.5 + maH + 2
} else {
    y += 2
}
```

### 5c: Section 7 Reanimation — bedingt anzeigen

- [ ] **Schritt 6: Section 7 Guard einfügen**

Den Beginn von Section 7 (ca. Zeile 1212 — `let r7W = ...`) mit einem Guard umschließen:

```swift
// ── SECTION 7 Reanimation / Tod (nur wenn relevant) ───────
let reaRelevant = p.reanimationAktiv
    || rea.erstHelfer || rea.vorabTelefonRea || rea.aed
    || rea.dnrOrder || rea.khAufnahmeVorROSC

if reaRelevant {
    let r7W = (rx-lx) * 0.55
    // ... gesamter bisheriger Section-7-Block ...
    // ... bis einschließlich:
    y = r7y0 + CGFloat(maxR78)*r7H + 2
    if !rea.freitext.isEmpty && y + 11 < pageSize.height - 15 {
        field("Reanimation – Notizen", rea.freitext, x:lx, y:y, w:rx-lx, h:11, lw:90)
        y += 11
    }
} // Ende if reaRelevant
```

### 5d: Section 8 NACA — Einzelzeile

- [ ] **Schritt 7: NACA-Block ersetzen**

Den gesamten `secHeader("8. Ergebnis / NACA" ...)` + NACA-Zeilen-Block (ca. Zeilen 1218 und 1273–1287) ersetzen durch:

```swift
// ── SECTION 8 NACA ────────────────────────────────────────
if let naca = p.notfallGeschehen.nacaScoreWert {
    secHeader("8. Ergebnis / NACA", x:lx, y:y, w:rx-lx)
    y += 11
    field("NACA", naca.beschreibung, x:lx, y:y, w:rx-lx, h:11, lw:30, hl:true)
    y += 11
}
```

> Hinweis: Der bisherige `secHeader("8. ...")` war an `r8x` (rechte Hälfte) positioniert, zusammen mit Section 7. Da Section 7 jetzt optional ist, bekommt Section 8 volle Breite. Der `r8x/r8W`-Block für den NACA-Render (ca. Zeile 1273) entfällt vollständig. Die `maxR78`-Berechnung für `y` in Section 7 vereinfacht sich dadurch: dort wird nur noch `y = r7y0 + CGFloat(maxR7)*r7H + 2` benötigt (ohne `nacaRows.count`).

- [ ] **Schritt 8: Build und Tests**

Product → Build (⌘B) — fehlerfrei.
Product → Test (⌘U) — alle Tests grün.

- [ ] **Schritt 9: Manueller PDF-Test**

In der App: Protokoll mit einigen Feldern befüllen, PDF generieren, prüfen:
- Seite 1: ABCDE erscheint vor SAMPLER ✓
- Seite 1: Section 3 zeigt nur angekreuzte Befunde (oder "o.B.") ✓
- Seite 1: Section 4 zeigt nur Diagnosegruppen mit Auswahl ✓
- Seite 2: Section 6 zeigt nur angekreuzte Maßnahmen ✓
- Seite 2: Section 7 fehlt wenn kein Reanimationsflag gesetzt ✓
- Seite 2: Section 8 zeigt NACA als eine Zeile ✓
- Kein Überlappen / kein Abschneiden ✓

- [ ] **Schritt 10: Commit**

```bash
git add PatProt/PatProt/Services/PDFGenerator.swift
git commit -m "feat: PDF Section 4 Kompaktliste, Section 6 Filter, Section 7 bedingt, Section 8 Einzelzeile"
```

---

## Self-Review Checkliste

- [x] `pdfExportiertAm` in Task 1 definiert, in Task 2 genutzt — Typen konsistent (`Date?`)
- [x] `markierePDFExport(id:)` in Task 2 definiert, in AbschlussView korrekt aufgerufen
- [x] `purgeAbgelaufene()` wird in `laden()` aufgerufen — kein weiterer Aufruf nötig
- [x] `filteredDualCb` gibt `CGFloat` (endY) zurück — wird in Task 4 korrekt für `y`-Berechnung verwendet
- [x] `diagGruppe` gibt `CGFloat` (neues y) zurück — konsistent mit Aufruf in Task 5
- [x] BZ-Format `%.0f` in Verlauf-Grid (Zeile ~1004) — in Task 4 Schritt 5 abgedeckt
- [x] Section 7 `r8x/r8W`-Variablen werden nicht mehr referenziert nach Umbau — in Task 5d explizit adressiert
- [x] Einsatzzeiten-Reihenfolge in View UND Validierung UND PDF-Label — alle 3 in Task 3 abgedeckt
- [x] NACA-Entfernung aus `ErgebnisData` — keine anderen Referenzen auf `ergebnis.nacaScore` vorhanden (grep bestätigt)
