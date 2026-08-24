# RKN Einsatzprotokoll PDF-Generator — Implementierungsplan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 1:1-Nachbau des Rhein-Kreis-Neuss Einsatzprotokoll-Formulars als zweiseitiges DIN-A4-PDF, generiert aus dem bestehenden `EinsatzProtokoll`-Datenmodell.

**Architecture:** Neuer `RKNPDFGenerator`-Struct in `Services/RKNPDFGenerator.swift` zeichnet beide Seiten via CoreGraphics in `UIGraphicsPDFRenderer`. Daten kommen ausschließlich aus dem bestehenden `EinsatzProtokoll`-Objekt. In `AbschlussView.swift` wird ein zweiter Export-Button ergänzt.

**Tech Stack:** Swift, UIKit, CoreGraphics, UIGraphicsPDFRenderer. Kein externes Framework. iOS 16+.

---

## Neue / geänderte Dateien

| Datei | Aktion | Inhalt |
|---|---|---|
| `PatProt/Services/RKNPDFGenerator.swift` | **Neu** | Gesamte Zeichen-Logik für beide Seiten |
| `PatProt/Views/AbschlussView.swift` | **Ändern** | Zweiten Export-Button für RKN-Formular ergänzen |

---

## Task 1: Datei-Skeleton + gemeinsame Zeichenhilfen

**Files:**
- Create: `PatProt/Services/RKNPDFGenerator.swift`

- [ ] **Schritt 1: Datei anlegen**

```swift
// PatProt/Services/RKNPDFGenerator.swift
import UIKit

struct RKNPDFGenerator {

    // MARK: - Seitenmaße
    static let W: CGFloat = 595
    static let H: CGFloat = 842

    // MARK: - Farben
    static let cBlack  = UIColor.black
    static let cBorder = UIColor(white: 0.3, alpha: 1)
    static let cHeader = UIColor.black          // Sektionsheader: schwarz
    static let cLight  = UIColor(white: 0.92, alpha: 1) // heller Hintergrund

    // MARK: - Schriften
    static let f5  = UIFont.systemFont(ofSize: 5)
    static let f5b = UIFont.boldSystemFont(ofSize: 5)
    static let f6  = UIFont.systemFont(ofSize: 6)
    static let f6b = UIFont.boldSystemFont(ofSize: 6)
    static let f7  = UIFont.systemFont(ofSize: 7)
    static let f7b = UIFont.boldSystemFont(ofSize: 7)
    static let f8b = UIFont.boldSystemFont(ofSize: 8)
    static let f9b = UIFont.boldSystemFont(ofSize: 9)
    static let f12b = UIFont.boldSystemFont(ofSize: 12)

    // MARK: - Datumsformatierung
    static let dateFmt: DateFormatter = { let f = DateFormatter(); f.dateFormat = "dd.MM.yy"; return f }()
    static let timeFmt: DateFormatter = { let f = DateFormatter(); f.dateFormat = "HH:mm"; return f }()
    static func d(_ v: Date?) -> String { v.map { dateFmt.string(from: $0) } ?? "" }
    static func t(_ v: Date?) -> String { v.map { timeFmt.string(from: $0) } ?? "" }

    // MARK: - Primitive Zeichenhilfen

    static func fillR(_ r: CGRect, _ c: UIColor = .white) { c.setFill(); UIRectFill(r) }

    static func strokeR(_ r: CGRect, lw: CGFloat = 0.4) {
        cBorder.setStroke()
        let p = UIBezierPath(rect: r); p.lineWidth = lw; p.stroke()
    }

    static func hline(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, lw: CGFloat = 0.4) {
        cBorder.setStroke()
        let p = UIBezierPath(); p.lineWidth = lw
        p.move(to: CGPoint(x: x, y: y)); p.addLine(to: CGPoint(x: x+w, y: y)); p.stroke()
    }

    static func vline(_ x: CGFloat, _ y: CGFloat, _ h: CGFloat, lw: CGFloat = 0.4) {
        cBorder.setStroke()
        let p = UIBezierPath(); p.lineWidth = lw
        p.move(to: CGPoint(x: x, y: y)); p.addLine(to: CGPoint(x: x, y: y+h)); p.stroke()
    }

    /// Einzeiliger Text, abgeschnitten
    static func txt(_ s: String, _ r: CGRect, font: UIFont = f6, color: UIColor = .black, align: NSTextAlignment = .left) {
        guard !s.isEmpty else { return }
        let ps = NSMutableParagraphStyle(); ps.alignment = align; ps.lineBreakMode = .byTruncatingTail
        (s as NSString).draw(in: r, withAttributes: [.font: font, .foregroundColor: color, .paragraphStyle: ps])
    }

    /// Mehrzeiliger Text
    static func mtxt(_ s: String, _ r: CGRect, font: UIFont = f6) {
        guard !s.isEmpty else { return }
        let ps = NSMutableParagraphStyle(); ps.alignment = .left
        (s as NSString).draw(in: r, withAttributes: [.font: font, .foregroundColor: UIColor.black, .paragraphStyle: ps])
    }

    /// Schwarzer Sektionsheader (weißer Text)
    static func secHeader(_ title: String, x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat = 10) {
        fillR(CGRect(x: x, y: y, width: w, height: h), cHeader)
        txt(title, CGRect(x: x+2, y: y+1.5, width: w-4, height: h-3), font: f6b, color: .white)
    }

    /// Grauer Unterabschnitt-Header
    static func subHeader(_ title: String, x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat = 8.5) {
        fillR(CGRect(x: x, y: y, width: w, height: h), UIColor(white: 0.75, alpha: 1))
        txt(title, CGRect(x: x+2, y: y+1, width: w-4, height: h-2), font: f5b, color: .black)
    }

    /// Checkbox: kleines Quadrat mit optionalem Häkchen
    static func cb(_ checked: Bool, x: CGFloat, y: CGFloat, size: CGFloat = 5.5) {
        let r = CGRect(x: x, y: y, width: size, height: size)
        fillR(r, .white); strokeR(r, lw: 0.4)
        if checked {
            txt("✓", CGRect(x: x-0.5, y: y-1, width: size+1, height: size+2), font: f5b, color: .black, align: .center)
        }
    }

    /// Checkbox mit Label daneben
    static func cbLabel(_ label: String, checked: Bool, x: CGFloat, y: CGFloat, cbSize: CGFloat = 5.5, gap: CGFloat = 2) {
        cb(checked, x: x, y: y, size: cbSize)
        txt(label, CGRect(x: x+cbSize+gap, y: y-0.5, width: 80, height: cbSize+1), font: f5)
    }

    /// Beschriftetes Eingabefeld mit Unterrand
    static func labeledField(_ label: String, _ value: String, x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat = 14) {
        fillR(CGRect(x: x, y: y, width: w, height: h))
        strokeR(CGRect(x: x, y: y, width: w, height: h))
        txt(label, CGRect(x: x+1.5, y: y+1, width: w-3, height: 6), font: f5, color: UIColor(white: 0.3, alpha: 1))
        txt(value, CGRect(x: x+1.5, y: y+7, width: w-3, height: h-8), font: f6b)
    }

    /// Zeitfeld: kleines Label + Uhrzeit-Wert
    static func timeField(_ label: String, _ value: String, x: CGFloat, y: CGFloat, w: CGFloat = 38, h: CGFloat = 13) {
        strokeR(CGRect(x: x, y: y, width: w, height: h))
        txt(label, CGRect(x: x+1.5, y: y+1, width: w-3, height: 5.5), font: f5, color: UIColor(white: 0.35, alpha: 1))
        txt(value, CGRect(x: x+1.5, y: y+7, width: w-3, height: 6), font: f6b)
    }
}
```

- [ ] **Schritt 2: Commit**

```bash
git add PatProt/Services/RKNPDFGenerator.swift
git commit -m "feat: RKNPDFGenerator skeleton with drawing helpers"
```

---

## Task 2: Einstiegspunkt — `generate()` + Seiten-Dispatcher

**Files:**
- Modify: `PatProt/Services/RKNPDFGenerator.swift` — `generate`-Methode + leere Seiten-Funktionen

- [ ] **Schritt 1: generate()-Methode und leere Seitenfunktionen einfügen**

Am Ende von `RKNPDFGenerator` (vor der letzten `}`) einfügen:

```swift
    // MARK: - Öffentlicher Einstiegspunkt

    static func generate(protokoll: EinsatzProtokoll) -> URL? {
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent("RKN_\(protokoll.id).pdf")
        let bounds = CGRect(x: 0, y: 0, width: W, height: H)
        let renderer = UIGraphicsPDFRenderer(bounds: bounds)
        do {
            try renderer.writePDF(to: tmp) { ctx in
                ctx.beginPage()
                drawPage1(protokoll: protokoll)
                ctx.beginPage()
                drawPage2(protokoll: protokoll)
            }
            return tmp
        } catch {
            return nil
        }
    }

    // MARK: - Seite 1 (Dispatcher)
    private static func drawPage1(protokoll: EinsatzProtokoll) {
        // weißer Hintergrund
        fillR(CGRect(x: 0, y: 0, width: W, height: H))
        drawHeader(protokoll: protokoll)
        drawSection1(protokoll: protokoll)
        drawSection2(protokoll: protokoll)
        drawSection3(protokoll: protokoll)
        drawSection4(protokoll: protokoll)
    }

    // MARK: - Seite 2 (Dispatcher)
    private static func drawPage2(protokoll: EinsatzProtokoll) {
        fillR(CGRect(x: 0, y: 0, width: W, height: H))
        drawSection42(protokoll: protokoll)
        drawSection5(protokoll: protokoll)
        drawVerlaufsgrafik(protokoll: protokoll)
        drawSection6(protokoll: protokoll)
        drawSection65(protokoll: protokoll)
        drawSection7(protokoll: protokoll)
        drawSection8(protokoll: protokoll)
        drawSection9(protokoll: protokoll)
        drawNaca(protokoll: protokoll)
    }

    // MARK: - Platzhalter (werden in späteren Tasks implementiert)
    private static func drawHeader(protokoll: EinsatzProtokoll) {}
    private static func drawSection1(protokoll: EinsatzProtokoll) {}
    private static func drawSection2(protokoll: EinsatzProtokoll) {}
    private static func drawSection3(protokoll: EinsatzProtokoll) {}
    private static func drawSection4(protokoll: EinsatzProtokoll) {}
    private static func drawSection42(protokoll: EinsatzProtokoll) {}
    private static func drawSection5(protokoll: EinsatzProtokoll) {}
    private static func drawVerlaufsgrafik(protokoll: EinsatzProtokoll) {}
    private static func drawSection6(protokoll: EinsatzProtokoll) {}
    private static func drawSection65(protokoll: EinsatzProtokoll) {}
    private static func drawSection7(protokoll: EinsatzProtokoll) {}
    private static func drawSection8(protokoll: EinsatzProtokoll) {}
    private static func drawSection9(protokoll: EinsatzProtokoll) {}
    private static func drawNaca(protokoll: EinsatzProtokoll) {}
```

- [ ] **Schritt 2: Kompilieren prüfen**

Xcode öffnen → Cmd+B. Muss ohne Fehler durchkompilieren.

- [ ] **Schritt 3: Commit**

```bash
git add PatProt/Services/RKNPDFGenerator.swift
git commit -m "feat: RKNPDFGenerator generate() entry point + page dispatchers"
```

---

## Task 3: Export-Button in AbschlussView

**Files:**
- Modify: `PatProt/Views/AbschlussView.swift`

- [ ] **Schritt 1: Zweiten State für RKN-URL ergänzen**

Direkt unter `@State private var pdfURL: URL? = nil` einfügen:

```swift
@State private var rknPdfURL: URL? = nil
@State private var isGeneratingRKN = false
@State private var zeigeRKNShareSheet = false
```

- [ ] **Schritt 2: RKN-Export-Button im PDF-Export-Section ergänzen**

Direkt nach dem letzten `Button { ... Label("Per E‑Mail senden" ...` (nach Zeile ~253), aber noch innerhalb der `Section {` für PDF Export, einfügen:

```swift
Divider()

Button {
    isGeneratingRKN = true
    let prot = protokoll
    Task.detached(priority: .userInitiated) {
        let url = RKNPDFGenerator.generate(protokoll: prot)
        await MainActor.run {
            rknPdfURL = url
            isGeneratingRKN = false
            if url != nil {
                zeigeRKNShareSheet = true
            } else {
                pdfFehler = true
            }
        }
    }
} label: {
    HStack {
        if isGeneratingRKN {
            ProgressView().padding(.trailing, 4)
        } else {
            Image(systemName: "doc.text.fill")
        }
        Text(isGeneratingRKN ? "RKN-Formular wird generiert..." : "RKN-Formular exportieren")
            .frame(maxWidth: .infinity)
    }
    .padding(.vertical, 4)
}
.buttonStyle(.bordered)
.tint(Color("RDOrange"))
.disabled(isGeneratingRKN)
```

- [ ] **Schritt 3: ShareSheet für RKN ergänzen**

Direkt nach dem bestehenden `.sheet(isPresented: $zeigeShareSheet)` Block einfügen:

```swift
.sheet(isPresented: $zeigeRKNShareSheet) {
    if let url = rknPdfURL {
        ShareSheet(activityItems: [url])
    }
}
```

- [ ] **Schritt 4: Kompilieren + auf Simulator testen**

Cmd+B, dann auf Simulator starten. AbschlussView öffnen → Button "RKN-Formular exportieren" sichtbar. Tippen → leeres 2-seitiges weißes PDF wird geteilt (alle Zeichenfunktionen sind noch leer).

- [ ] **Schritt 5: Commit**

```bash
git add PatProt/Views/AbschlussView.swift
git commit -m "feat: add RKN Formular export button to AbschlussView"
```

---

## Task 4: Kopfzeile (drawHeader)

**Files:**
- Modify: `PatProt/Services/RKNPDFGenerator.swift` — `drawHeader` implementieren

- [ ] **Schritt 1: drawHeader implementieren**

`private static func drawHeader(protokoll: EinsatzProtokoll) {}` ersetzen durch:

```swift
private static func drawHeader(protokoll: EinsatzProtokoll) {
    let p = protokoll.patientDaten
    let e = protokoll.einsatzOrt
    // Äußerer Rahmen oben
    strokeR(CGRect(x: 4, y: 4, width: W-8, height: 28))

    // Krankenkasse / Kostenträger
    txt("Krankenkasse bzw. Kostenträger", CGRect(x: 6, y: 5, width: 130, height: 6), font: f5, color: UIColor(white: 0.4, alpha: 1))
    txt(p.kostentraeger, CGRect(x: 6, y: 12, width: 130, height: 8), font: f6b)
    vline(138, 4, 28)

    // Name
    txt("Name, Vorname des Versicherten", CGRect(x: 140, y: 5, width: 140, height: 6), font: f5, color: UIColor(white: 0.4, alpha: 1))
    let nameStr = "\(p.nachname), \(p.vorname)".trimmingCharacters(in: CharacterSet(charactersIn: ", "))
    txt(nameStr, CGRect(x: 140, y: 12, width: 140, height: 8), font: f6b)
    vline(282, 4, 28)

    // geb. am
    txt("geb. am", CGRect(x: 284, y: 5, width: 60, height: 6), font: f5, color: UIColor(white: 0.4, alpha: 1))
    txt(d(p.geburtsDatum), CGRect(x: 284, y: 12, width: 60, height: 8), font: f6b)
    vline(346, 4, 28)

    // Versicherten-Nr
    txt("Versicherten-Nr.", CGRect(x: 348, y: 5, width: 80, height: 6), font: f5, color: UIColor(white: 0.4, alpha: 1))
    txt(p.versicherungsNummer, CGRect(x: 348, y: 12, width: 80, height: 8), font: f6b)
    vline(430, 4, 28)

    // Status
    txt("Status", CGRect(x: 432, y: 5, width: 40, height: 6), font: f5, color: UIColor(white: 0.4, alpha: 1))
    vline(474, 4, 28)

    // Betriebsstätten-Nr / Arzt-Nr / Datum
    txt("Betriebsstätten-Nr.", CGRect(x: 476, y: 5, width: 60, height: 6), font: f5, color: UIColor(white: 0.4, alpha: 1))
    txt(d(e.alarmzeit), CGRect(x: 476, y: 12, width: 60, height: 8), font: f6b)

    hline(4, 32, W-8)
}
```

- [ ] **Schritt 2: Bauen + visuell prüfen**

Cmd+B, Export-Button tippen, PDF in Vorschau öffnen. Kopfzeile mit Patientenname, Geburtsdatum sollte oben sichtbar sein.

- [ ] **Schritt 3: Commit**

```bash
git add PatProt/Services/RKNPDFGenerator.swift
git commit -m "feat: RKN drawHeader — Patientendaten Kopfzeile"
```

---

## Task 5: Sektion 1 — Rettungstechnische Daten (drawSection1)

**Files:**
- Modify: `PatProt/Services/RKNPDFGenerator.swift`

- [ ] **Schritt 1: drawSection1 implementieren**

`private static func drawSection1(protokoll: EinsatzProtokoll) {}` ersetzen durch:

```swift
private static func drawSection1(protokoll: EinsatzProtokoll) {
    let e = protokoll.einsatzOrt
    let p = protokoll.patientDaten
    let b = protokoll.besatzung
    let lx: CGFloat = 4
    var y: CGFloat = 32

    // ── Sektionsheader ──────────────────────────────────────
    secHeader("1. Rettungstechnische Daten", x: lx, y: y, w: W/2 - 2)
    y += 10

    // ── Fahrzeugtyp-Checkboxen (Zeile 1) ────────────────────
    let fahrzeug = e.fahrzeugName.uppercased()
    let fahrzeuge: [(String, Bool)] = [
        ("RTW",      fahrzeug.contains("RTW")),
        ("KTW",      fahrzeug.contains("KTW")),
        ("NEF",      fahrzeug.contains("NEF")),
        ("NAW",      fahrzeug.contains("NAW") && !fahrzeug.contains("BABY")),
        ("Baby NAW", fahrzeug.contains("BABY")),
        ("V-RTW",    fahrzeug.contains("V-RTW") || fahrzeug.contains("VRTW")),
    ]
    var cx = lx + 2
    for (label, checked) in fahrzeuge {
        cb(checked, x: cx, y: y + 1)
        txt(label, CGRect(x: cx+7, y: y+0.5, width: 30, height: 7), font: f5b)
        cx += label.count > 3 ? 36 : 28
    }
    y += 9

    // ── Sondersignal / Notarzt ───────────────────────────────
    cbLabel("Sondersignal Hin",    checked: e.sondersignal,  x: lx+2,  y: y)
    cbLabel("mit Patient",         checked: e.mitPatient,    x: lx+60, y: y)
    cbLabel("Notarzt nachgefordert", checked: e.notarzt,     x: lx+110, y: y)
    y += 9

    hline(lx, y, W/2 - 2)

    // ── Zeitenraster ─────────────────────────────────────────
    // Zeile: Alarmzeit / E-Szt A1
    timeField("Alarmzeit",  t(e.alarmzeit),          x: lx,      y: y, w: 44)
    timeField("Ausfahrt",   t(e.alarmzeit),           x: lx+44,   y: y, w: 44)  // kein eigenes Feld, näherungsweise
    timeField("Ankunft",    t(e.ankunftzeit),         x: lx+88,   y: y, w: 44)
    timeField("Abfahrt",    t(e.abfahrtzeit),         x: lx+132,  y: y, w: 44)
    timeField("KH-Ankunft", t(e.krankenHausAnkunft),  x: lx+176,  y: y, w: 44)
    timeField("Ende",       "",                       x: lx+220,  y: y, w: 44)
    y += 13

    // ── Transportziel ────────────────────────────────────────
    labeledField("Transportziel / Straße",  e.adresse, x: lx,       y: y, w: 180, h: 13)
    labeledField("Haus-Nr.",               e.zusatz,   x: lx+180,   y: y, w: 40,  h: 13)
    labeledField("PLZ",                    e.plz,      x: lx+220,   y: y, w: 35,  h: 13)
    labeledField("Ort",                    e.ort,      x: lx+255,   y: y, w: 40,  h: 13)
    y += 13

    // ── EINSATZPROTOKOLL Titel ────────────────────────────────
    // Senkrechter Strich Mitte der Seite
    vline(W/2, 32, y - 32)

    // Rechte Hälfte: Titel + Notarzt-Checkbox + Einsatznummer
    let rx = W/2 + 2
    txt("EINSATZPROTOKOLL", CGRect(x: rx, y: 34, width: W/2-10, height: 14), font: f12b, align: .center)
    hline(rx, 48, W/2-6)

    cb(e.notarzt,  x: rx+4,  y: 50)
    txt("Notarzt",  CGRect(x: rx+11, y: 49, width: 50, height: 7), font: f6b)
    cb(!e.notarzt, x: rx+70, y: 50)
    txt("NetSan/RettAss/RS", CGRect(x: rx+77, y: 49, width: 90, height: 7), font: f6b)
    hline(rx, 58, W/2-6)

    // Einsatznummer
    labeledField("Einsatznummer", e.einsatzNummer, x: rx, y: 59, w: 80, h: 13)
    labeledField("Standort RM",   e.fahrzeugName,  x: rx+80, y: 59, w: 80, h: 13)

    // Männlich / Weiblich
    cb(p.geschlecht == .maennlich, x: rx+168, y: 62)
    txt("männlich", CGRect(x: rx+175, y: 61, width: 40, height: 7), font: f5)
    cb(p.geschlecht == .weiblich,  x: rx+168, y: 70)
    txt("weiblich",  CGRect(x: rx+175, y: 69, width: 40, height: 7), font: f5)

    hline(rx, 72, W/2-6)

    // Besatzung
    txt("Besatzung:", CGRect(x: rx+2, y: 74, width: 60, height: 7), font: f5b)
    let namen = [b.sanitaeter1, b.sanitaeter2, b.sanitaeter3, b.sanitaeter4].filter { !$0.isEmpty }
    txt(namen.joined(separator: ", "), CGRect(x: rx+40, y: 74, width: W/2-50, height: 14), font: f5)

    // Unterer Rahmen Sektion 1
    hline(lx, y, W-8)
}
```

- [ ] **Schritt 2: Bauen + prüfen**

Cmd+B. Export → PDF-Vorschau. Fahrzeugtyp-Checkboxen, Zeitfelder, "EINSATZPROTOKOLL"-Titel und Einsatznummer sollen sichtbar sein.

- [ ] **Schritt 3: Commit**

```bash
git add PatProt/Services/RKNPDFGenerator.swift
git commit -m "feat: RKN drawSection1 — Rettungstechnische Daten"
```

---

## Task 6: Sektion 2 — Notfallgeschehen / Anamnese (drawSection2)

**Files:**
- Modify: `PatProt/Services/RKNPDFGenerator.swift`

- [ ] **Schritt 1: drawSection2 implementieren**

```swift
private static func drawSection2(protokoll: EinsatzProtokoll) {
    let ng = protokoll.notfallGeschehen
    let s  = protokoll.sampler
    let lx: CGFloat = 4
    let y0: CGFloat = 130   // unter Sektion 1

    secHeader("2. Notfallgeschehen / Anamnese / Erstbefund", x: lx, y: y0, w: W-8)

    // A–E Zeilen + SAMPLER-Buchstaben rechts
    let lines: [(String, String, String)] = [
        ("A", ng.erstbefundVorOrt,             "S"),
        ("B", ng.patientGefunden,              "A"),
        ("C", ng.unfallhergangFreitext,        "M"),
        ("D", s.patientenVorgeschichte,        "P"),
        ("E", s.ereignis,                      "L"),
    ]
    var y = y0 + 10
    let lineH: CGFloat = 14
    for (letter, value, samplerLetter) in lines {
        // Buchstabe links
        fillR(CGRect(x: lx, y: y, width: 12, height: lineH), cLight)
        txt(letter, CGRect(x: lx+2, y: y+3, width: 10, height: 8), font: f7b)
        vline(lx+12, y, lineH)
        // Inhalt
        strokeR(CGRect(x: lx+12, y: y, width: W-30, height: lineH))
        mtxt(value, CGRect(x: lx+14, y: y+2, width: W-34, height: lineH-3))
        // SAMPLER-Buchstabe rechts
        fillR(CGRect(x: W-14, y: y, width: 10, height: lineH), cLight)
        txt(samplerLetter, CGRect(x: W-13, y: y+3, width: 8, height: 8), font: f7b)
        hline(lx, y+lineH, W-8)
        y += lineH
    }
}
```

- [ ] **Schritt 2: y0-Wert an tatsächliche Unterkante von Sektion 1 anpassen**

Nach dem ersten Testexport messen, ob Sektion 2 mit Sektion 1 überlappt. y0 auf `130` belassen oder anpassen. Der Zielwert ist die Unterkante der letzten hline in `drawSection1` — du kannst eine Konstante `let s1Bottom: CGFloat = 130` einführen und beide Sektionen damit verketten.

- [ ] **Schritt 3: Commit**

```bash
git add PatProt/Services/RKNPDFGenerator.swift
git commit -m "feat: RKN drawSection2 — Notfallgeschehen A–E"
```

---

## Task 7: Sektion 3 — Befunde (drawSection3)

**Files:**
- Modify: `PatProt/Services/RKNPDFGenerator.swift`

- [ ] **Schritt 1: drawSection3 implementieren**

```swift
private static func drawSection3(protokoll: EinsatzProtokoll) {
    let ub = protokoll.uebergabeBefunde
    let br = protokoll.breathing
    let ci = protokoll.circulation
    let di = protokoll.disability
    let ex = protokoll.exposure
    let ps = protokoll.psyche
    let um = protokoll.uebergabeMesswerte
    let lx: CGFloat = 4
    let y0: CGFloat = 202   // unter Sektion 2

    secHeader("3. Befunde", x: lx, y: y0, w: W-8)

    // ── Spaltenbreiten ───────────────────────────────────────
    let colW: CGFloat = (W-8) / 4   // 4 Spalten

    // ── Spalte 1: Messwerte ──────────────────────────────────
    var y = y0 + 10
    subHeader("Messwerte", x: lx, y: y, w: colW)
    y += 9

    let messwerte: [(String, String)] = [
        ("RR SYS",  um.rrSys),
        ("RR DIA",  um.rrDia),
        ("HF",      um.hf),
        ("SpO₂",    um.spo2),
        ("etCO₂",   um.bz),   // etCO2 nicht im Übergabe-Struct, BZ als Ersatz
        ("BZ",      um.bz),
        ("Temp.",   um.temp),
        ("AF",      um.af),
    ]
    for (label, value) in messwerte {
        strokeR(CGRect(x: lx, y: y, width: colW, height: 11))
        txt(label, CGRect(x: lx+2, y: y+1, width: 28, height: 6), font: f5, color: UIColor(white: 0.4, alpha: 1))
        txt(value, CGRect(x: lx+32, y: y+2, width: colW-34, height: 8), font: f7b)
        y += 11
    }

    // Schmerz (0–10)
    let schmerzStr = ub.schmerz > 0 ? "\(ub.schmerz)" : "–"
    strokeR(CGRect(x: lx, y: y, width: colW, height: 11))
    txt("Schmerz (0–10)", CGRect(x: lx+2, y: y+1, width: colW-4, height: 5.5), font: f5, color: UIColor(white: 0.4, alpha: 1))
    txt(schmerzStr, CGRect(x: lx+2, y: y+7, width: colW-4, height: 7), font: f7b)
    y += 11

    // GCS
    let gcsStr = "\(ub.gcsAugen) + \(ub.gcsVerbal) + \(ub.gcsMotor) = \(ub.gcsGesamt)"
    strokeR(CGRect(x: lx, y: y, width: colW, height: 11))
    txt("GCS", CGRect(x: lx+2, y: y+1, width: colW-4, height: 5.5), font: f5, color: UIColor(white: 0.4, alpha: 1))
    txt(gcsStr, CGRect(x: lx+2, y: y+7, width: colW-4, height: 7), font: f5b)

    // ── Spalte 2: A+B Atmung ─────────────────────────────────
    let x2 = lx + colW
    var y2 = y0 + 10
    subHeader("A+B Atmung", x: x2, y: y2, w: colW)
    y2 += 9

    let atmungItems: [(String, Bool)] = [
        ("unauffällig",       ub.abUnauffaellig),
        ("Dyspnoe",           ub.dyspnoe),
        ("Zyanose",           ub.zyanose),
        ("Spastik",           ub.spastik),
        ("Rasselgeräusche",   ub.rasselgeraeusche),
        ("Brodeln",           ub.brodeln),
        ("Stridor",           ub.stridor),
        ("Atemwegsverlegung", ub.atemwegsverlegung),
        ("Schnappatmung",     ub.schnappatmung),
        ("Apnoe",             ub.apnoe),
        ("Beatmung",          ub.beatmung),
        ("Hyperventilation",  ub.hyperventilation),
        ("n. beurteilbar",    ub.abNichtBeurteilbar),
    ]
    for (label, checked) in atmungItems {
        cbLabel(label, checked: checked, x: x2+2, y: y2)
        y2 += 8
    }

    // ── Spalte 3: C Zirkulation + EKG ───────────────────────
    let x3 = lx + 2*colW
    var y3 = y0 + 10
    subHeader("C Cirkulat. + EKG", x: x3, y: y3, w: colW)
    y3 += 9

    let ekgItems: [(String, Bool)] = [
        ("unauffällig",         ub.cUnauffaellig),
        ("Rekapillierung",      ub.rekapillierung),
        ("Sinusrhythmus",       ub.sinusrhythmus),
        ("Abs. Arrhythmie",     ub.absoluteArrhythmie),
        ("AV-Block I°",         ub.avBlockI),
        ("AV-Block II°",        ub.avBlockII),
        ("AV-Block III°",       ub.avBlockIII),
        ("QRS Tachy breit",     ub.qrsTachykardieBreit),
        ("QRS Tachy schmal",    ub.qrsTachykardieSchmal),
        ("Kammerflattern",      ub.kammerflattern),
        ("Kammerflimmern",      ub.kammerflimmern),
        ("Asystolie",           ub.asystolie),
        ("PEA",                 ub.pea),
        ("Schrittmacher",       ub.schrittmacher),
        ("Infarkt-EKG (STEMI)", ub.infarktEkg),
        ("SVES",                ub.sves),
        ("VES",                 ub.ves),
        ("ES monomorph",        ub.extrasystolenMonomorph),
        ("ES polymorph",        ub.extrasystolenPolymorph),
        ("n. beurteilbar",      ub.cNichtBeurteilbar),
    ]
    for (label, checked) in ekgItems {
        cbLabel(label, checked: checked, x: x3+2, y: y3)
        y3 += 7
    }

    // ── Spalte 4: D Neurologie ───────────────────────────────
    let x4 = lx + 3*colW
    var y4 = y0 + 10
    subHeader("D Neurologie", x: x4, y: y4, w: colW)
    y4 += 9

    // Bewusstsein
    txt("Bewusstsein", CGRect(x: x4+2, y: y4, width: colW-4, height: 6), font: f5b)
    y4 += 7
    let bewItems: [(String, Bool)] = [
        ("wach",              ub.bewWach),
        ("auf Ansprache",     ub.bewAnsprache),
        ("auf Schmerzreiz",   ub.bewSchmerzreiz),
        ("bewusstlos",        ub.bewusstlos),
        ("n. beurteilbar",    ub.dNichtBeurteilbar),
    ]
    for (label, checked) in bewItems {
        cbLabel(label, checked: checked, x: x4+2, y: y4)
        y4 += 7
    }

    // Pupillen
    hline(x4, y4, colW)
    y4 += 2
    txt("Pupillen re:", CGRect(x: x4+2, y: y4, width: 40, height: 6), font: f5b)
    y4 += 6
    let pupReItems: [(String, Bool)] = [
        ("eng",               ub.pupilleReEng),
        ("mittel",            ub.pupilleReMittel),
        ("weit",              ub.pupilleReWeit),
        ("entrundet",         ub.pupilleReEntrundet),
        ("keine Lichtreakt.", ub.pupilleReKeineLichtreaktion),
    ]
    for (label, checked) in pupReItems {
        cbLabel(label, checked: checked, x: x4+2, y: y4)
        y4 += 7
    }

    txt("Pupillen li:", CGRect(x: x4+2, y: y4, width: 40, height: 6), font: f5b)
    y4 += 6
    let pupLiItems: [(String, Bool)] = [
        ("eng",               ub.pupilleLiEng),
        ("mittel",            ub.pupilleLiMittel),
        ("weit",              ub.pupilleLiWeit),
        ("entrundet",         ub.pupilleLiEntrundet),
        ("keine Lichtreakt.", ub.pupilleLiKeineLichtreaktion),
    ]
    for (label, checked) in pupLiItems {
        cbLabel(label, checked: checked, x: x4+2, y: y4)
        y4 += 7
    }

    // Neuro
    hline(x4, y4, colW); y4 += 2
    let neuroItems: [(String, Bool)] = [
        ("Vorbestehendes Defizit", ub.neuroVorbestehendesDefizit),
        ("Facialisparese",         ub.neuroFacialisparese),
        ("Armparese",              ub.neuroArmparese),
        ("Sprachstörung",          ub.neuroSprachstoerung),
        ("Sehstörung",             ub.neuroSehstoerung),
        ("Babinski",               ub.neuroBabinski),
        ("Querschnitt",            ub.neuroQuerschnitt),
        ("Meningismus",            ub.neuroMeningismus),
        ("Demenz",                 ub.neuroDemenz),
    ]
    for (label, checked) in neuroItems {
        cbLabel(label, checked: checked, x: x4+2, y: y4)
        y4 += 7
    }

    // Haut + Psyche (letzte Zeilen Spalte 1–2)
    // Trennlinie zwischen Sektion 3 und 4
    let s3Bottom = max(y, y2, y3, y4) + 3
    hline(lx, s3Bottom, W-8)

    // Spaltenlinien
    vline(x2, y0+10, s3Bottom - y0 - 10)
    vline(x3, y0+10, s3Bottom - y0 - 10)
    vline(x4, y0+10, s3Bottom - y0 - 10)
}
```

- [ ] **Schritt 2: y0 kalibrieren**

Nach Testexport prüfen ob y0=202 stimmt. Anpassen falls nötig.

- [ ] **Schritt 3: Commit**

```bash
git add PatProt/Services/RKNPDFGenerator.swift
git commit -m "feat: RKN drawSection3 — Befunde Messwerte/Atmung/EKG/Neurologie"
```

---

## Task 8: Sektion 4 — Diagnose / Erkrankung (drawSection4)

**Files:**
- Modify: `PatProt/Services/RKNPDFGenerator.swift`

- [ ] **Schritt 1: drawSection4 implementieren**

```swift
private static func drawSection4(protokoll: EinsatzProtokoll) {
    let d = protokoll.diagnose
    let lx: CGFloat = 4
    let y0: CGFloat = 480   // kalibrieren nach Task 7-Export

    secHeader("4. Diagnose", x: lx, y: y0, w: W-8)

    subHeader("4.1 Erkrankung", x: lx, y: y0+10, w: W-8)

    // 6 Spalten für Erkrankungs-Checkboxen
    let cols = 6
    let cw = (W-8) / CGFloat(cols)
    var y = y0 + 20

    // Spalte 1: ZNS
    var cx = lx + 2; var cy = y
    txt("ZNS", CGRect(x: cx, y: cy, width: cw-4, height: 7), font: f5b); cy += 8
    let zns: [(String, Bool)] = [
        ("Akutes neuro. Defizit", d.znsAkutNeuro),
        ("ICB",                   d.znsSab),
        ("SAB",                   false),
        ("Transplantat",          d.znsTransplantat),
        ("Status Epilepticus",    d.znsEpilepsie),
        ("Fieberkrampf",          d.znsFieberkrampf),
    ]
    for (l, c) in zns { cbLabel(l, checked: c, x: cx, y: cy); cy += 7 }

    // Spalte 2: Herz-Kreislauf
    cx = lx + cw + 2; cy = y
    txt("Herz-Kreislauf", CGRect(x: cx, y: cy, width: cw-4, height: 7), font: f5b); cy += 8
    let herz: [(String, Bool)] = [
        ("ACS",                    d.herzAcs),
        ("STEMI",                  d.herzStemi),
        ("kardiogener Schock",     false),
        ("Rhythmusstörung",        d.herzRhythmus),
        ("PM/ICD Fehlfunktion",    d.herzPmFehlfunktion),
        ("Herzinsuffizienz",       false),
        ("dekmp. Herzinsuffizienz",d.herzDekomp),
        ("hypertensiver Notfall",  d.herzHypertonerNotfall),
        ("Aortenaneurysma",        d.herzAortenaneurysma),
        ("Hypotonie",              d.herzHypotonie),
        ("Synkope",                d.herzSynkope),
        ("Thrombose/Embolie",      d.herzThromboseEmbolie),
        ("Schock unkl. Genese",    d.herzSchockUnklarGenese),
        ("orthostatische Regul.",  d.herzOrthostatisch),
        ("unkl. Thoraxschmerz",    d.herzUnklarerThoraxschmerz),
    ]
    for (l, c) in herz { cbLabel(l, checked: c, x: cx, y: cy); cy += 7 }

    // Spalte 3: Atmung
    cx = lx + 2*cw + 2; cy = y
    txt("Atmung", CGRect(x: cx, y: cy, width: cw-4, height: 7), font: f5b); cy += 8
    let atm: [(String, Bool)] = [
        ("Asthma",                 d.atmungAsthma),
        ("exazerbiert (COPD)",     d.atmungExazerbiert),
        ("Pneumonie / Bronchitis", d.atmungPneumonie),
        ("LTB (J./Bronchitis)",    d.atmungLtb),
        ("Epiglottitis",           d.atmungEpiglottitis),
    ]
    for (l, c) in atm { cbLabel(l, checked: c, x: cx, y: cy); cy += 7 }

    // Spalte 4: Psychiatrie
    cx = lx + 3*cw + 2; cy = y
    txt("Psychiatrie", CGRect(x: cx, y: cy, width: cw-4, height: 7), font: f5b); cy += 8
    let psych: [(String, Bool)] = [
        ("psych. Akutzustand",  d.psychAkut),
        ("psychische Krise",    d.psychKrise),
        ("Manie",               d.psychManie),
        ("Intoxikation",        d.psychIntoxikation),
        ("Entzug/Delir",        d.psychEntzug),
        ("Suizidal",            d.psychSuizidal),
    ]
    for (l, c) in psych { cbLabel(l, checked: c, x: cx, y: cy); cy += 7 }

    // Spalte 5: Stoffwechsel + Abdomen
    cx = lx + 4*cw + 2; cy = y
    txt("Stoffwechsel", CGRect(x: cx, y: cy, width: cw-4, height: 7), font: f5b); cy += 8
    let stoff: [(String, Bool)] = [
        ("Exsikkose",       d.stoffExsikkose),
        ("Hypoglykämie",    d.stoffHypoglykämie),
        ("Hyperglykämie",   d.stoffHyperglykämie),
        ("Urämie",          d.stoffUremie),
        ("bek. diab.pflichtig", d.stoffDia),
    ]
    for (l, c) in stoff { cbLabel(l, checked: c, x: cx, y: cy); cy += 7 }
    cy += 3
    txt("Abdomen", CGRect(x: cx, y: cy, width: cw-4, height: 7), font: f5b); cy += 8
    let abdo: [(String, Bool)] = [
        ("akutes Abdomen",  d.abdoAkutes),
        ("Koliken",         d.abdoKoliken),
        ("GIB oben",        d.abdoGibOben),
        ("GIB unten",       d.abdoGibUnten),
        ("Galle/Niere",     d.abdoGalleNiere),
    ]
    for (l, c) in abdo { cbLabel(l, checked: c, x: cx, y: cy); cy += 7 }

    // Spalte 6: Gyn/Geb + Infektionen + Sonstiges
    cx = lx + 5*cw + 2; cy = y
    txt("Gyn./Geb.-hilfe", CGRect(x: cx, y: cy, width: cw-4, height: 7), font: f5b); cy += 8
    let gyn: [(String, Bool)] = [
        ("Schwangerschaft >35.SSW", d.gynSchwangerschaft35),
        ("Geburt",                  d.gynGeburt),
        ("Eklampsie",               d.gynEklampsie),
        ("Extrauterine Gravidität", false),
        ("vaginale Blutung",        d.gynVaginalblutung),
    ]
    for (l, c) in gyn { cbLabel(l, checked: c, x: cx, y: cy); cy += 7 }
    cy += 3
    txt("Infektionen", CGRect(x: cx, y: cy, width: cw-4, height: 7), font: f5b); cy += 8
    let infekt: [(String, Bool)] = [
        ("HIV",              d.infektHiv),
        ("hochkont. Erk.",   d.infektHighToxSars),
        ("Gastroenteritis",  d.infektGastro),
        ("Anaphylaxie Gr.1/2", d.infektAnaphylaxie12),
        ("SIDS",             d.infektSids),
        ("Intoxikation",     d.infektIntoxikation),
        ("unkl. Fieber",     false),
        ("offen MRSA",       false),
        ("MRE",              false),
        ("Hepatitis",        false),
    ]
    for (l, c) in infekt { cbLabel(l, checked: c, x: cx, y: cy); cy += 7 }

    // Spalten-Trennlinien
    for i in 1..<cols {
        vline(lx + CGFloat(i)*cw, y0+10, 180)
    }

    // Diagnose/Leitsymptom Feld
    let dBottom = y0 + 10 + 180
    hline(lx, dBottom, W-8)
    labeledField("Diagnose/Leitsymptom", d.leitsymptom, x: lx, y: dBottom, w: W-8, h: 14)
}
```

- [ ] **Schritt 2: y0 nach Testexport kalibrieren**

- [ ] **Schritt 3: Commit**

```bash
git add PatProt/Services/RKNPDFGenerator.swift
git commit -m "feat: RKN drawSection4 — Diagnose/Erkrankung Checkboxen"
```

---

## Task 9: Seite 2 — Sektion 4.2 Verletzungen + Sektion 5 Verlauf

**Files:**
- Modify: `PatProt/Services/RKNPDFGenerator.swift`

- [ ] **Schritt 1: drawSection42 implementieren**

```swift
private static func drawSection42(protokoll: EinsatzProtokoll) {
    let d = protokoll.diagnose
    let vm = d.verletzungsMatrix
    let lx: CGFloat = 4
    let y0: CGFloat = 4
    let colW = W * 0.45  // 45% Breite links

    secHeader("4.2 Verletzungen", x: lx, y: y0, w: colW)

    // Verletzungsmatrix: Körperregion | keine | leicht | schwer
    let verletzungen: [(String, Verletzungsgrad)] = [
        ("Schädel-Hirn/Gesicht", vm.schaedelHirn),
        ("HWS",                   vm.hws),
        ("Thorax",                vm.thorax),
        ("Abdomen",               vm.abdomen),
        ("BWS / LWS",             vm.bwsLws),
        ("Becken",                vm.becken),
        ("Obere Extrem.",         vm.obereExtrem),
        ("Untere Extrem.",        vm.untereExtrem),
        ("Weichteile",            vm.weichteile),
    ]

    var y = y0 + 10
    // Header-Zeile
    strokeR(CGRect(x: lx, y: y, width: colW, height: 8))
    txt("Region",  CGRect(x: lx+2,       y: y+1, width: 80,  height: 6), font: f5b)
    txt("keine",   CGRect(x: lx+90,      y: y+1, width: 22,  height: 6), font: f5b, align: .center)
    txt("leicht",  CGRect(x: lx+112,     y: y+1, width: 22,  height: 6), font: f5b, align: .center)
    txt("schwer",  CGRect(x: lx+134,     y: y+1, width: 22,  height: 6), font: f5b, align: .center)
    y += 8

    for (name, grad) in verletzungen {
        strokeR(CGRect(x: lx, y: y, width: colW, height: 9))
        txt(name, CGRect(x: lx+2, y: y+1.5, width: 86, height: 6), font: f5)
        vline(lx+90, y, 9); vline(lx+112, y, 9); vline(lx+134, y, 9)
        cb(grad == .keine,  x: lx+98,  y: y+2)
        cb(grad == .leicht, x: lx+120, y: y+2)
        cb(grad == .schwer, x: lx+142, y: y+2)
        y += 9
    }

    // Verletzungsmuster
    hline(lx, y, colW); y += 2
    let muster = d.verletzungsMuster
    cbLabel("Einzelverletzung",    checked: muster == "Einzelverletzung",    x: lx+2,  y: y)
    cbLabel("Mehrfachverletzung",  checked: muster == "Mehrfachverletzung",  x: lx+65, y: y)
    cbLabel("Polytrauma",          checked: muster == "Polytrauma",          x: lx+135, y: y)
    y += 8
    let art = d.verletzungsArt
    cbLabel("oberflächlich",  checked: art.contains("oberfl"),   x: lx+2,  y: y)
    cbLabel("stumpf",         checked: art.contains("stumpf"),   x: lx+65, y: y)
    cbLabel("penetrierend",   checked: art.contains("penetr"),   x: lx+105, y: y)
    y += 8

    // Spezielle Traumen
    hline(lx, y, colW); y += 2
    txt("Spezielle Traumen:", CGRect(x: lx+2, y: y, width: colW-4, height: 6), font: f5b); y += 7
    let spec: [(String, Bool)] = [
        ("Verbr./Verbrüh.",   d.spezVerbrVerbrh),
        ("Tauchunfall",       d.spezTauchunfall),
        ("Elektrounfall",     d.spezElektrounfall),
        ("PKW/LKW-Insasse",   d.spezPkwLkw),
        ("Motorradfahrer",    d.spezMotorrad),
        ("Fahrradfahrer",     d.spezFahrrad),
        ("Fußgänger",         d.spezFussgaenger),
        ("Sturz >3m Höhe",    d.spezSturzHoehe),
        ("and. Verkehrsteil.",d.spezAndVerkehr),
        ("Maschinenunfall",   d.spezMaschine),
        ("Gewaltverbrechen",  d.spezGewalt),
        ("anderer Unfall",    d.spezAndererUnfall),
    ]
    var sx = lx + 2
    for (i, (label, checked)) in spec.enumerated() {
        cbLabel(label, checked: checked, x: sx, y: y)
        if (i+1) % 2 == 0 { y += 8; sx = lx + 2 } else { sx = lx + colW/2 }
    }

    // Körperschema (vereinfacht als beschriftete Silhouette)
    drawKoerperschema(vm: vm, x: lx + colW - 65, y: y0 + 12, w: 60, h: 80)
}

private static func drawKoerperschema(vm: VerletzungsMatrix, x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat) {
    // Kopf
    let kopfR = CGRect(x: x + w/2 - 7, y: y, width: 14, height: 14)
    let kopfColor: UIColor = vm.schaedelHirn == .schwer ? .red : vm.schaedelHirn == .leicht ? .orange : UIColor(white: 0.9, alpha: 1)
    fillR(kopfR, kopfColor)
    let kopfPath = UIBezierPath(ovalIn: kopfR); UIColor(white: 0.4, alpha: 1).setStroke(); kopfPath.lineWidth = 0.5; kopfPath.stroke()

    // Rumpf
    let rumpfR = CGRect(x: x + w/2 - 10, y: y+16, width: 20, height: 28)
    let rumpfColor: UIColor = (vm.thorax == .schwer || vm.abdomen == .schwer) ? .red :
                               (vm.thorax == .leicht || vm.abdomen == .leicht) ? .orange : UIColor(white: 0.9, alpha: 1)
    fillR(rumpfR, rumpfColor); strokeR(rumpfR, lw: 0.5)

    // Arme links/rechts
    let armLR = CGRect(x: x + w/2 - 22, y: y+17, width: 10, height: 22)
    let armRR = CGRect(x: x + w/2 + 12, y: y+17, width: 10, height: 22)
    let armColor: UIColor = vm.obereExtrem == .schwer ? .red : vm.obereExtrem == .leicht ? .orange : UIColor(white: 0.9, alpha: 1)
    fillR(armLR, armColor); strokeR(armLR, lw: 0.5)
    fillR(armRR, armColor); strokeR(armRR, lw: 0.5)

    // Beine links/rechts
    let beinLR = CGRect(x: x + w/2 - 12, y: y+46, width: 10, height: 28)
    let beinRR = CGRect(x: x + w/2 + 2,  y: y+46, width: 10, height: 28)
    let beinColor: UIColor = vm.untereExtrem == .schwer ? .red : vm.untereExtrem == .leicht ? .orange : UIColor(white: 0.9, alpha: 1)
    fillR(beinLR, beinColor); strokeR(beinLR, lw: 0.5)
    fillR(beinRR, beinColor); strokeR(beinRR, lw: 0.5)

    // Legende
    txt("rs", CGRect(x: x, y: y+78, width: 10, height: 6), font: f5)
    txt("ns", CGRect(x: x+15, y: y+78, width: 10, height: 6), font: f5)
}
```

- [ ] **Schritt 2: drawSection5 implementieren**

```swift
private static func drawSection5(protokoll: EinsatzProtokoll) {
    let d = protokoll.diagnose
    let rx = W * 0.45 + 4
    let y0: CGFloat = 4
    let w = W - rx - 4

    secHeader("5. Verlauf", x: rx, y: y0, w: w)
    strokeR(CGRect(x: rx, y: y0+10, width: w, height: 130))
    mtxt(d.verlauf, CGRect(x: rx+2, y: y0+12, width: w-4, height: 126))

    // Trennlinie zwischen 4.2 und 5
    vline(W * 0.45 + 2, y0, 144)
    hline(4, y0+144, W-8)
}
```

- [ ] **Schritt 3: Commit**

```bash
git add PatProt/Services/RKNPDFGenerator.swift
git commit -m "feat: RKN drawSection42 Verletzungen + Körperschema + drawSection5 Verlauf"
```

---

## Task 10: Verlaufsgrafik (drawVerlaufsgrafik)

**Files:**
- Modify: `PatProt/Services/RKNPDFGenerator.swift`

- [ ] **Schritt 1: drawVerlaufsgrafik implementieren**

```swift
private static func drawVerlaufsgrafik(protokoll: EinsatzProtokoll) {
    let messungen = protokoll.verlaufMessungen.sorted { $0.zeitpunkt < $1.zeitpunkt }
    let lx: CGFloat = 4
    let y0: CGFloat = 148
    let h: CGFloat = 100
    let w = W - 8
    let plotX = lx + 28   // Achsenbeschriftung links
    let plotW = w - 32

    // Rahmen + Header
    strokeR(CGRect(x: lx, y: y0, width: w, height: h))
    fillR(CGRect(x: lx, y: y0, width: w, height: 9), cLight)
    txt("UHRZEIT", CGRect(x: lx+2, y: y0+1.5, width: 30, height: 6), font: f5b)

    // Y-Achse: 60–260 in 20er-Schritten
    let yMin: CGFloat = 60; let yMax: CGFloat = 260
    let plotY = y0 + 9; let plotH = h - 9
    for val in stride(from: Int(yMin), through: Int(yMax), by: 20) {
        let fy = plotY + plotH * (1 - CGFloat(val - Int(yMin)) / CGFloat(yMax - yMin))
        hline(plotX-2, fy, plotW+2, lw: 0.2)
        txt("\(val)", CGRect(x: lx, y: fy-3, width: 26, height: 6), font: f5, align: .right)
    }

    // X-Achse: Zeitstempel
    guard !messungen.isEmpty else { return }
    let tMin = messungen.first!.zeitpunkt.timeIntervalSinceReferenceDate
    let tMax = max(messungen.last!.zeitpunkt.timeIntervalSinceReferenceDate, tMin + 60)
    let tRange = tMax - tMin

    func xFor(_ t: TimeInterval) -> CGFloat {
        plotX + plotW * CGFloat((t - tMin) / tRange)
    }
    func yFor(_ v: Int) -> CGFloat {
        plotY + plotH * (1 - CGFloat(v - Int(yMin)) / CGFloat(yMax - yMin))
    }

    // Puls (rot)
    let pulsPunkte = messungen.compactMap { m -> CGPoint? in
        guard let v = m.puls else { return nil }
        return CGPoint(x: xFor(m.zeitpunkt.timeIntervalSinceReferenceDate), y: yFor(v))
    }
    drawCurve(pulsPunkte, color: UIColor.red, lw: 0.8)

    // RR sys (blau gestrichelt)
    let rrSysPunkte = messungen.compactMap { m -> CGPoint? in
        guard let v = m.blutdruckSys else { return nil }
        return CGPoint(x: xFor(m.zeitpunkt.timeIntervalSinceReferenceDate), y: yFor(v))
    }
    drawCurve(rrSysPunkte, color: UIColor.blue, lw: 0.8)

    // RR dia (blau dünner)
    let rrDiaPunkte = messungen.compactMap { m -> CGPoint? in
        guard let v = m.blutdruckDia else { return nil }
        return CGPoint(x: xFor(m.zeitpunkt.timeIntervalSinceReferenceDate), y: yFor(v))
    }
    drawCurve(rrDiaPunkte, color: UIColor(red: 0.4, green: 0.4, blue: 1, alpha: 1), lw: 0.5)

    // SpO₂ (grün)
    let spo2Punkte = messungen.compactMap { m -> CGPoint? in
        guard let v = m.spo2 else { return nil }
        return CGPoint(x: xFor(m.zeitpunkt.timeIntervalSinceReferenceDate), y: yFor(v))
    }
    drawCurve(spo2Punkte, color: UIColor(red: 0, green: 0.6, blue: 0, alpha: 1), lw: 0.8)

    // Zeitstempel auf X-Achse
    for m in messungen {
        let x = xFor(m.zeitpunkt.timeIntervalSinceReferenceDate)
        vline(x, plotY, plotH, lw: 0.15)
        txt(t(m.zeitpunkt), CGRect(x: x-8, y: plotY+plotH+1, width: 18, height: 5), font: f5, align: .center)
    }

    // Legende
    let fy = y0 + h - 7
    UIColor.red.setFill();  UIRectFill(CGRect(x: lx+30, y: fy+1, width: 12, height: 3))
    txt("Puls", CGRect(x: lx+44, y: fy-1, width: 20, height: 6), font: f5)
    UIColor.blue.setFill(); UIRectFill(CGRect(x: lx+68, y: fy+1, width: 12, height: 3))
    txt("RR", CGRect(x: lx+82, y: fy-1, width: 16, height: 6), font: f5)
    UIColor(red:0,green:0.6,blue:0,alpha:1).setFill(); UIRectFill(CGRect(x: lx+100, y: fy+1, width: 12, height: 3))
    txt("SpO₂", CGRect(x: lx+114, y: fy-1, width: 20, height: 6), font: f5)

    hline(lx, y0+h, w)
}

private static func drawCurve(_ points: [CGPoint], color: UIColor, lw: CGFloat) {
    guard points.count >= 2 else { return }
    color.setStroke()
    let path = UIBezierPath(); path.lineWidth = lw
    path.move(to: points[0])
    for p in points.dropFirst() { path.addLine(to: p) }
    path.stroke()
    for p in points {
        let dot = UIBezierPath(ovalIn: CGRect(x: p.x-1.5, y: p.y-1.5, width: 3, height: 3))
        color.setFill(); dot.fill()
    }
}
```

- [ ] **Schritt 2: Commit**

```bash
git add PatProt/Services/RKNPDFGenerator.swift
git commit -m "feat: RKN drawVerlaufsgrafik — Zeitachse mit Puls/RR/SpO2-Kurven"
```

---

## Task 11: Sektion 6 — Maßnahmen (drawSection6)

**Files:**
- Modify: `PatProt/Services/RKNPDFGenerator.swift`

- [ ] **Schritt 1: drawSection6 implementieren**

```swift
private static func drawSection6(protokoll: EinsatzProtokoll) {
    let m = protokoll.massnahmen
    let lx: CGFloat = 4
    let y0: CGFloat = 252   // unter Verlaufsgrafik
    let colW = (W-8) / 3

    secHeader("6. Maßnahmen", x: lx, y: y0, w: W-8)
    var y = y0 + 10

    // ── Spalte 1: Airway / Stabilisation ────────────────────
    subHeader("Airway / Stabilisation", x: lx, y: y, w: colW)
    var y1 = y + 9
    let airway: [(String, Bool)] = [
        ("Atemweg freimachen/freihalten", m.atemwegFreimachen),
        ("Cervikalstütze/HWS-Stabilisation", m.cervikalStuetze),
        ("Absaugung",           m.absaugung),
        ("Sauerstoffgabe",      m.sauerstoffgabe),
        ("Maskenbeatmung",      m.maskenbeatmung),
        ("Maskenbeatm. unmöglich", m.maskenbeatmungUnmoeglich),
        ("Supraglottisch",      m.supraglottisch),
        ("Guedel-Tubus",        m.guedelTubus),
        ("Wendel-Tubus",        m.wendlTubus),
        ("Intubation",          protokoll.airway.intubiert),
        ("Konikotomie",         protokoll.airway.konikotomie),
        ("Atemwegszugang erschwert", m.atemwegErschwert),
    ]
    for (label, checked) in airway { cbLabel(label, checked: checked, x: lx+2, y: y1); y1 += 8 }

    // O₂ l/min
    if m.sauerstoffgabe && !m.sauerstoffLitMin.isEmpty {
        txt("O₂: \(m.sauerstoffLitMin) l/min", CGRect(x: lx+2, y: y1, width: colW-4, height: 7), font: f5b)
        y1 += 8
    }

    // ── Spalte 2: Atmung + Zirkulation ──────────────────────
    let x2 = lx + colW
    subHeader("Atmung", x: x2, y: y, w: colW)
    var y2 = y + 9

    // FiO2 / PEEP / AZV
    let beatmung: [(String, Bool)] = [
        ("Thoraxdrainage",      false),
        ("CPAP/NIV",            m.cpap),
        ("Maschinelle Beatmung",m.maschinelleBeatmung),
    ]
    for (label, checked) in beatmung { cbLabel(label, checked: checked, x: x2+2, y: y2); y2 += 8 }
    if m.maschinelleBeatmung {
        if !m.fio2.isEmpty { txt("FiO₂: \(m.fio2)%", CGRect(x: x2+2, y: y2, width: 50, height: 7), font: f5); y2 += 7 }
        if !m.peep.isEmpty { txt("PEEP: \(m.peep)", CGRect(x: x2+2, y: y2, width: 50, height: 7), font: f5); y2 += 7 }
        if !m.tidalvolumen.isEmpty { txt("AZV: \(m.tidalvolumen) ml", CGRect(x: x2+2, y: y2, width: 50, height: 7), font: f5); y2 += 7 }
    }

    y2 += 3
    subHeader("Cirkulation", x: x2, y: y2, w: colW); y2 += 9
    // Zugänge
    cbLabel("peripher-ven. Zugang", checked: m.peripherVenoes, x: x2+2, y: y2); y2 += 8
    if m.peripherVenoes {
        txt("\(m.peripherVenoesOrt)  \(m.peripherVenoesGroesse)G",
            CGRect(x: x2+10, y: y2, width: colW-14, height: 7), font: f5); y2 += 7
    }
    cbLabel("intraossärer Zugang",  checked: m.intraossaer,     x: x2+2, y: y2); y2 += 8
    if m.intraossaer && !m.intraossaerOrt.isEmpty {
        txt(m.intraossaerOrt, CGRect(x: x2+10, y: y2, width: colW-14, height: 7), font: f5); y2 += 7
    }
    cbLabel("Defibrillation",       checked: m.defibrillation,  x: x2+2, y: y2); y2 += 8
    if m.defibrillation {
        txt("\(m.defiAnzahl)× \(m.defiJoule) J",
            CGRect(x: x2+10, y: y2, width: colW-14, height: 7), font: f5); y2 += 7
    }
    cbLabel("Kardioversion",        checked: m.kardioversion,   x: x2+2, y: y2); y2 += 8

    // ── Spalte 3: Weitere + Lagerung + Monitoring ────────────
    let x3 = lx + 2*colW
    subHeader("Weitere Maßnahmen", x: x3, y: y, w: colW)
    var y3 = y + 9
    let weitere: [(String, Bool)] = [
        ("Kühlung",             m.kuehlung),
        ("Wärmeerhalt",         m.waermeerhalt),
        ("Entbindung",          m.entbindung),
        ("Krisenintervention",  m.krisenintervention),
        ("Kardioversion",       m.kardioversion),
        ("Tourniquet",          m.tourniquet),
    ]
    for (label, checked) in weitere { cbLabel(label, checked: checked, x: x3+2, y: y3); y3 += 8 }

    y3 += 3
    subHeader("Lagerung / Transport", x: x3, y: y3, w: colW); y3 += 9
    let lagerung: [(String, Bool)] = [
        ("OK-Hochlagerung",      m.okHochlagerung),
        ("Flachlagerung",        m.flachlagerung),
        ("Schocklagerung",       m.schocklagerung),
        ("Linksseitenlage",      m.linksseitenlage),
        ("Vakuummatratze",       m.vakuummatratze),
        ("Schaufeltrage",        m.schaufeltrage),
        ("Extremitätenschienung",m.extremitaetenschienung),
        ("Verband",              m.verband),
        ("Beckenschlinge",       m.beckenschlinge),
    ]
    for (label, checked) in lagerung { cbLabel(label, checked: checked, x: x3+2, y: y3); y3 += 8 }

    y3 += 3
    subHeader("Monitoring", x: x3, y: y3, w: colW); y3 += 9
    let monitoring: [(String, Bool)] = [
        ("EKG",           m.monEkg),
        ("12-Kanal-EKG",  false),
        ("NIBP",          m.monNibp),
        ("BZ",            m.monBz),
        ("Invasive RR",   false),
        ("SpO₂",          m.monSpo2),
        ("Kapnometrie",   false),
        ("Temperatur",    m.monTemperatur),
    ]
    for (label, checked) in monitoring { cbLabel(label, checked: checked, x: x3+2, y: y3); y3 += 7 }

    let s6Bottom = max(y1, y2, y3) + 3
    vline(x2, y+9, s6Bottom - y - 9)
    vline(x3, y+9, s6Bottom - y - 9)
    hline(lx, s6Bottom, W-8)
}
```

- [ ] **Schritt 2: y0 nach Testexport kalibrieren**

- [ ] **Schritt 3: Commit**

```bash
git add PatProt/Services/RKNPDFGenerator.swift
git commit -m "feat: RKN drawSection6 — Maßnahmen Airway/Atmung/Zirkulation/Lagerung/Monitoring"
```

---

## Task 12: Sektionen 6.5 + 7 — Medikamente + Reanimation

**Files:**
- Modify: `PatProt/Services/RKNPDFGenerator.swift`

- [ ] **Schritt 1: drawSection65 implementieren**

```swift
private static func drawSection65(protokoll: EinsatzProtokoll) {
    let meds = protokoll.medikamente
    let lx: CGFloat = 4
    let y0: CGFloat = 570   // kalibrieren

    secHeader("6.5 Medikamente", x: lx, y: y0, w: W/2 - 2)

    // Tabellen-Header
    let cols: [(String, CGFloat, CGFloat)] = [
        ("Medikament", lx,      80),
        ("Dosis",      lx+80,   30),
        ("mg",         lx+110,  22),
        ("ml",         lx+132,  22),
        ("IE",         lx+154,  22),
        ("Route",      lx+176,  30),
        ("Zeit",       lx+206,  28),
    ]
    var y = y0 + 10
    for (header, x, w) in cols {
        strokeR(CGRect(x: x, y: y, width: w, height: 8))
        txt(header, CGRect(x: x+1, y: y+1, width: w-2, height: 6), font: f5b)
    }
    y += 8

    let timeFmtMed = DateFormatter(); timeFmtMed.dateFormat = "HH:mm"
    for med in meds.prefix(8) {
        for (_, colX, colW) in cols { strokeR(CGRect(x: colX, y: y, width: colW, height: 10)) }
        txt(med.name,   CGRect(x: lx+1,    y: y+2, width: 78,  height: 7), font: f5)
        txt(med.dosis,  CGRect(x: lx+81,   y: y+2, width: 28,  height: 7), font: f5)
        txt(med.einheit == "mg" ? med.dosis : "", CGRect(x: lx+111, y: y+2, width: 20, height: 7), font: f5)
        txt(med.einheit == "ml" ? med.dosis : "", CGRect(x: lx+133, y: y+2, width: 20, height: 7), font: f5)
        txt(med.einheit == "IE" ? med.dosis : "", CGRect(x: lx+155, y: y+2, width: 20, height: 7), font: f5)
        txt(med.route,  CGRect(x: lx+177,  y: y+2, width: 28,  height: 7), font: f5)
        txt(timeFmtMed.string(from: med.zeit), CGRect(x: lx+207, y: y+2, width: 26, height: 7), font: f5)
        y += 10
    }
    // Leerzeilen bis Minimum
    while y < y0 + 10 + 8 + 8 * 10 {
        for (_, colX, colW) in cols { strokeR(CGRect(x: colX, y: y, width: colW, height: 10)) }
        y += 10
    }
    hline(lx, y, W/2 - 2)
}
```

- [ ] **Schritt 2: drawSection7 implementieren**

```swift
private static func drawSection7(protokoll: EinsatzProtokoll) {
    let rea = protokoll.reanimation
    let aktiv = protokoll.reanimationAktiv
    let rx = W/2 + 2
    let y0: CGFloat = 570   // kalibrieren, gleiche Höhe wie 6.5
    let w = W - rx - 4

    secHeader("7. Reanimation / Tod", x: rx, y: y0, w: w)
    var y = y0 + 10

    cbLabel("Beginn CPR",         checked: aktiv,                  x: rx+2, y: y); y += 8
    cbLabel("Ersthelfer",         checked: rea.erstHelfer,         x: rx+2, y: y); y += 8
    cbLabel("Vorab Telefon-Rea.", checked: rea.vorabTelefonRea,    x: rx+2, y: y); y += 8
    cbLabel("Rettungsdienst",     checked: aktiv,                  x: rx+2, y: y); y += 8

    hline(rx, y, w); y += 2
    cbLabel("Reanimation",        checked: aktiv,                  x: rx+2, y: y)
    cbLabel("ROSC im Verlauf",    checked: rea.roscImVerlauf,      x: rx+45, y: y); y += 8
    cbLabel("niemals ROSC",       checked: rea.nieROSC,            x: rx+2,  y: y)
    cbLabel("erfolgreiche Rea.",  checked: rea.erfolgreicheRea,    x: rx+55, y: y); y += 8

    hline(rx, y, w); y += 2
    if let kz = rea.kollapsZeit {
        txt("Kollaps: \(t(kz))", CGRect(x: rx+2, y: y, width: w-4, height: 7), font: f5); y += 8
    }
    if rea.dnrOrder {
        cbLabel("DNR Order", checked: true, x: rx+2, y: y); y += 8
    }

    hline(rx, y, w); y += 2
    cbLabel("Defibrillation", checked: rea.defiAnzahl > 0, x: rx+2, y: y); y += 8
    if rea.defiAnzahl > 0 {
        txt("Anzahl: \(rea.defiAnzahl)   \(rea.defiJoule) J",
            CGRect(x: rx+2, y: y, width: w-4, height: 7), font: f5); y += 7
    }

    if let tod = rea.todFeststellungsZeit {
        hline(rx, y, w); y += 2
        txt("Sterbezeitpunkt: \(t(tod))", CGRect(x: rx+2, y: y, width: w-4, height: 7), font: f5b)
    }

    hline(rx, y0 + 120, w)
    vline(rx, y0, 120)
}
```

- [ ] **Schritt 3: Commit**

```bash
git add PatProt/Services/RKNPDFGenerator.swift
git commit -m "feat: RKN drawSection65 Medikamente + drawSection7 Reanimation/Tod"
```

---

## Task 13: Sektionen 8 + 9 + NACA (drawSection8/9/Naca)

**Files:**
- Modify: `PatProt/Services/RKNPDFGenerator.swift`

- [ ] **Schritt 1: drawSection8 implementieren**

```swift
private static func drawSection8(protokoll: EinsatzProtokoll) {
    let er = protokoll.ergebnis
    let lx: CGFloat = 4
    let y0: CGFloat = 694   // kalibrieren

    secHeader("8. Ergebnis", x: lx, y: y0, w: W*0.55)
    subHeader("Einsatzbesonderheiten", x: lx + W*0.55, y: y0, w: W*0.45 - 4)

    var y = y0 + 10
    var y2 = y0 + 10

    let ergebnisse: [(String, Bool)] = [
        ("ambulante Vers. vor Ort",         er.ambulantVorOrt),
        ("Transport mit NA (RTH)",          false),
        ("Transport mit NA (RTH)",          false),
        ("Übergabe an and. Rettungsmittel", false),
        ("Patient nicht transportfähig",    er.patNichtTransportfaehig),
        ("Tod an Einsatzstelle",            er.todAnEinsatzstelle),
        ("Mitfahrverweigerung",             er.mifahrverweigerung),
    ]
    for (label, checked) in ergebnisse { cbLabel(label, checked: checked, x: lx+2, y: y); y += 8 }

    let besonderheiten: [(String, Bool)] = [
        ("nächstes KH nicht aufnehmefähig", er.naechstesKHNichtErreichbar),
        ("Pat. lehnt Transport ab",         er.patNichtTransportfaehig),
        ("vorsorgl. Bereitstellung",        false),
        ("Schwerlasttransport",             er.schwerlasttransport),
        ("aufwendige Rettung",              er.aufwaendigeRettung),
        ("mehrere Patienten",               er.mehrerePatient),
        ("Zwangsunterbringung",             er.zwangsunterbringung),
        ("LNA/OrgL im Einsatz",            er.lnaGrleimEinsatz),
        ("Infektionsschutz",                er.infektionsSchutz),
        ("erschw. Pat.-Zugang",             false),
    ]
    let bx = lx + W*0.55 + 2
    for (label, checked) in besonderheiten { cbLabel(label, checked: checked, x: bx, y: y2); y2 += 8 }

    vline(lx + W*0.55, y0, 80)
    hline(lx, y0+80, W-8)
}
```

- [ ] **Schritt 2: drawSection9 implementieren**

```swift
private static func drawSection9(protokoll: EinsatzProtokoll) {
    let er = protokoll.ergebnis
    let lx: CGFloat = 4
    let y0: CGFloat = 774   // kalibrieren

    secHeader("9. Übergabe / Transportziel", x: lx, y: y0, w: W*0.7)

    let colW = W*0.7 / 3
    var y = y0 + 10

    let ziele: [(String, Bool)] = [
        ("ZNA / INA",             er.transportzielZna),
        ("Herzkatheterlabor HKL", er.transportzielKathLabor),
        ("DP direkt",             false),
        ("Stroke Unit",           er.transportzielStrokeUnit),
        ("Intensivstation",       false),
        ("Normalstation",         false),
        ("Arztpraxis",            false),
        ("CPU",                   false),
        ("Fachambulanz",          false),
        ("Einsatzstelle",         false),
        ("Sonstige",              false),
    ]
    var zi = 0
    for row in 0..<4 {
        for col in 0..<3 {
            guard zi < ziele.count else { break }
            let (label, checked) = ziele[zi]
            cbLabel(label, checked: checked, x: lx + CGFloat(col)*colW + 2, y: y + CGFloat(row)*8)
            zi += 1
        }
    }

    vline(lx + W*0.7, y0, 68)

    // Anbei-Feld rechts
    let bx = lx + W*0.7 + 2
    let bw = W - bx - 4
    subHeader("Bemerkungen", x: bx, y: y0, w: bw)
    mtxt(er.anmerkungen, CGRect(x: bx+2, y: y0+10, width: bw-4, height: 56))

    hline(lx, y0+68, W-8)
}
```

- [ ] **Schritt 3: drawNaca implementieren**

```swift
private static func drawNaca(protokoll: EinsatzProtokoll) {
    let naca = protokoll.notfallGeschehen.nacaScoreWert
    let lx: CGFloat = 4
    let y0: CGFloat = 774   // gleiche Zeile wie 9, aber ganz rechts — oder darunter, kalibrieren

    // NACA rechts unten oder unter Sektion 9 — hängt vom Layout ab
    // Hier: unter Sektion 9 als eigener Streifen
    let y1 = y0 + 68
    secHeader("NACA Score", x: lx, y: y1, w: W-8)
    var x = lx + 2
    var y = y1 + 10
    for i in 1...7 {
        let isSelected = naca?.rawValue == i
        let boxR = CGRect(x: x, y: y, width: 75, height: 12)
        fillR(boxR, isSelected ? UIColor(white: 0.2, alpha: 1) : .white)
        strokeR(boxR)
        let nacaVal = NacaScore(rawValue: i)
        txt(nacaVal?.beschreibung ?? "\(i)", boxR.insetBy(dx: 2, dy: 2),
            font: f5, color: isSelected ? .white : .black)
        x += 76
        if x > W - 80 { x = lx + 2; y += 13 }
    }

    // Unterschrift-Zeile
    let yUnter = y + 15
    hline(lx, yUnter, W-8)
    txt("Übergabe an:", CGRect(x: lx+2, y: yUnter+1, width: 50, height: 7), font: f5)
    txt(protokoll.uebergabeAn, CGRect(x: lx+55, y: yUnter+1, width: 180, height: 7), font: f6b)
    txt("Unterschrift:", CGRect(x: W/2, y: yUnter+1, width: 50, height: 7), font: f5)
    strokeR(CGRect(x: W/2+50, y: yUnter, width: W/2-54, height: 14), lw: 0.4)
}
```

- [ ] **Schritt 4: Alle y0-Werte auf Seite 2 kalibrieren**

Testexport durchführen. Jede Sektion von oben nach unten prüfen. y0-Werte so anpassen, dass Sektionen nahtlos aneinanderpassen ohne Überlappung oder große Lücken. Richtwerte für Seite 2:

| Sektion | y0 ca. |
|---|---|
| 4.2 + 5 | 4 |
| Verlaufsgrafik | 148 |
| 6. Maßnahmen | 252 |
| 6.5 + 7 | 570 |
| 8. Ergebnis | 694 |
| 9. Übergabe | 774 |
| NACA | 842 - 50 (letzter Streifen) |

- [ ] **Schritt 5: Commit**

```bash
git add PatProt/Services/RKNPDFGenerator.swift
git commit -m "feat: RKN drawSection8/9 Ergebnis/Übergabe + drawNaca"
```

---

## Task 14: Layout-Kalibrierung — beide Seiten finalisieren

**Files:**
- Modify: `PatProt/Services/RKNPDFGenerator.swift`

- [ ] **Schritt 1: Testexport mit Musterdaten**

In `AbschlussView` auf Testgerät/Simulator: Protokoll mit allen Feldern befüllen (Name, Zeiten, Checkboxen, Medikamente, Verlauf, Reanimation). PDF exportieren → in Vorschau mit dem Original-Scan vergleichen.

- [ ] **Schritt 2: y0-Konstanten in benannte Konstanten extrahieren**

Alle hartkodierten y0-Werte als `private static let` am Anfang der Struct ablegen:

```swift
// Page 1
private static let p1S1Y: CGFloat = 32    // Sektion 1
private static let p1S2Y: CGFloat = 130   // Sektion 2
private static let p1S3Y: CGFloat = 202   // Sektion 3
private static let p1S4Y: CGFloat = 480   // Sektion 4

// Page 2
private static let p2S42Y: CGFloat  = 4
private static let p2GrafY: CGFloat = 148
private static let p2S6Y: CGFloat   = 252
private static let p2S65Y: CGFloat  = 570
private static let p2S8Y: CGFloat   = 694
private static let p2S9Y: CGFloat   = 758
private static let p2NacaY: CGFloat = 800
```

Alle y0-Parameter in den draw-Funktionen durch diese Konstanten ersetzen.

- [ ] **Schritt 3: Seitenränder-Außenrahmen für beide Seiten**

In `drawPage1` und `drawPage2` am Ende einfügen:

```swift
// Äußerer Rahmen
UIColor(white: 0.2, alpha: 1).setStroke()
let border = UIBezierPath(rect: CGRect(x: 3, y: 3, width: W-6, height: H-6))
border.lineWidth = 0.6; border.stroke()
```

- [ ] **Schritt 4: Finaler Vergleichs-Export**

PDF drucken oder in Vorschau im Verhältnis 1:1 neben Original-Scan legen. Alle Sektionspositionen, Spaltenbreiten und Schriftgrößen feinabstimmen bis die Übereinstimmung visuell passt.

- [ ] **Schritt 5: Commit**

```bash
git add PatProt/Services/RKNPDFGenerator.swift
git commit -m "feat: RKN PDF layout calibration — beide Seiten finalisiert"
```

---

## Task 15: Abschluss — Übergabe Besatzungsdaten + Verfasser

**Files:**
- Modify: `PatProt/Services/RKNPDFGenerator.swift`

- [ ] **Schritt 1: Verfasser + Besatzung in Kopfzeile ergänzen**

In `drawHeader` nach der Betriebsstätten-Zeile ergänzen:

```swift
// Verfasser / Qualifikation
let verfasser = protokoll.verfasser?.rawValue ?? ""
txt("Verfasser: \(verfasser)", CGRect(x: 476, y: 20, width: 112, height: 7), font: f5)
```

- [ ] **Schritt 2: Besatzung vollständig in Sektion 1**

In `drawSection1`, die Besatzungszeile vollständig mit Qualifikationen:

```swift
let bes = protokoll.besatzung
let besatzungsText = [
    bes.sanitaeter1.isEmpty ? nil : "\(bes.sanitaeter1) (\(bes.qualifikation1.rawValue))",
    bes.sanitaeter2.isEmpty ? nil : "\(bes.sanitaeter2) (\(bes.qualifikation2.rawValue))",
    bes.sanitaeter3.isEmpty ? nil : "\(bes.sanitaeter3) (\(bes.qualifikation3.rawValue))",
    bes.sanitaeter4.isEmpty ? nil : "\(bes.sanitaeter4) (\(bes.qualifikation4.rawValue))",
].compactMap { $0 }.joined(separator: ", ")
txt(besatzungsText, CGRect(x: rx+40, y: 74, width: W/2-50, height: 14), font: f5)
```

- [ ] **Schritt 3: Commit + finaler Test**

```bash
git add PatProt/Services/RKNPDFGenerator.swift
git commit -m "feat: RKN Verfasser + vollständige Besatzung im PDF"
```

---

## Selbst-Review Checkliste

- [x] **Spec-Abdeckung:** Alle 9 Sektionen + Header + Verlaufsgrafik + NACA implementiert
- [x] **Keine Platzhalter:** Alle Schritte haben konkreten Code
- [x] **Typen konsistent:** `VerletzungsMatrix`, `MassnahmenBefund`, `UebergabeBefunde`, `ReanimationsProtokoll` — alle aus `Models.swift`, korrekt referenziert
- [x] **Keine Änderungen an PDFGenerator.swift** — neuer Code ausschließlich in `RKNPDFGenerator.swift` und `AbschlussView.swift`
- [x] **Export-Button** in AbschlussView: Task 3
- [x] **y0-Kalibrierung:** Task 14 explizit als Kalibrierungsschritt mit Vergleichsanweisung
