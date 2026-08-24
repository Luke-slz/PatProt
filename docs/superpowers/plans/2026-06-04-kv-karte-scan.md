# KV-Karten-Scan Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Kamera-basiertes Auslesen der eGK mit automatischer Übernahme aller 5 Felder in `patientDaten`.

**Architecture:** Neuer `KVKarteParser` (reines Parsing, analog zu ScreenshotParser) + `KVKarteScanView` mit `VNDocumentCameraViewController`-Wrapper. `PatientView` tauscht `MedikamentFotoSektion` gegen `KVKarteScanSektion` aus; `kvFotos` wird aus Modell und PDF entfernt.

**Tech Stack:** Vision (OCR), VisionKit (VNDocumentCameraViewController), SwiftUI, Swift Testing

---

## Dateien

| Aktion | Pfad |
|---|---|
| Neu | `PatProt/Services/KVKarteParser.swift` |
| Neu | `PatProt/Views/KVKarteScanView.swift` |
| Ändern | `PatProt/Views/PatientView.swift` |
| Ändern | `PatProt/Models/Models.swift` |
| Ändern | `PatProt/Services/PDFGenerator.swift` |
| Ändern | `PatProtTests/PatProtTests.swift` |

---

## Task 1: ParsedKVDaten + KVKarteParser Stub + Tests

**Files:**
- Create: `PatProt/Services/KVKarteParser.swift`
- Modify: `PatProtTests/PatProtTests.swift`

- [ ] **Schritt 1: KVKarteParser.swift anlegen (Stub)**

Datei `PatProt/Services/KVKarteParser.swift` erstellen:

```swift
import Vision
import UIKit

struct ParsedKVDaten {
    var vorname: String = ""
    var nachname: String = ""
    var geburtsDatum: Date? = nil
    var versicherungsNummer: String = ""
    var kostentraeger: String = ""
}

enum KVKarteParser {

    static func parse(_ image: UIImage) async -> ParsedKVDaten {
        ParsedKVDaten()  // Stub – wird in Task 3 implementiert
    }

    static func parse(lines: [String]) -> ParsedKVDaten {
        ParsedKVDaten()  // Stub – wird in Task 2 implementiert
    }
}
```

- [ ] **Schritt 2: Tests in PatProtTests.swift ergänzen**

Am Ende der `struct PatProtTests { ... }` hinzufügen:

```swift
// MARK: - KVKarteParser Tests

@Test func kvParserKVNR() {
    let lines = ["Techniker Krankenkasse", "Versichertenkarte", "MUSTERMANN", "Erika", "*12.07.1964", "A123456789"]
    let result = KVKarteParser.parse(lines: lines)
    #expect(result.versicherungsNummer == "A123456789")
}

@Test func kvParserKVNRInText() {
    let lines = ["DAK", "SCHMIDT", "Hans", "01.01.1990", "Vers.-Nr. C345678901"]
    let result = KVKarteParser.parse(lines: lines)
    #expect(result.versicherungsNummer == "C345678901")
}

@Test func kvParserGeburtsdatumMitAsterisk() {
    let lines = ["TK", "MUSTERMANN", "Erika", "*12.07.1964", "A123456789"]
    let result = KVKarteParser.parse(lines: lines)
    let cal = Calendar.current
    #expect(result.geburtsDatum != nil)
    let comps = cal.dateComponents([.day, .month, .year], from: result.geburtsDatum!)
    #expect(comps.day == 12)
    #expect(comps.month == 7)
    #expect(comps.year == 1964)
}

@Test func kvParserGeburtsdatumOhneAsterisk() {
    let lines = ["AOK", "MUSTER", "Anna", "03.09.1985", "B987654321"]
    let result = KVKarteParser.parse(lines: lines)
    #expect(result.geburtsDatum != nil)
    let comps = Calendar.current.dateComponents([.day, .month, .year], from: result.geburtsDatum!)
    #expect(comps.day == 3)
    #expect(comps.month == 9)
    #expect(comps.year == 1985)
}

@Test func kvParserNameZweiZeilen() {
    let lines = ["Techniker Krankenkasse", "Versichertenkarte", "MUSTERMANN", "Erika", "*12.07.1964", "A123456789"]
    let result = KVKarteParser.parse(lines: lines)
    #expect(result.nachname == "Mustermann")
    #expect(result.vorname == "Erika")
}

@Test func kvParserNameKommaFormat() {
    let lines = ["DAK-Gesundheit", "MUSTERMANN, Erika", "*05.03.1980", "X987654321"]
    let result = KVKarteParser.parse(lines: lines)
    #expect(result.nachname == "Mustermann")
    #expect(result.vorname == "Erika")
}

@Test func kvParserKostentraegerMixedCase() {
    let lines = ["Techniker Krankenkasse", "Versichertenkarte", "MUSTERMANN", "Erika", "*12.07.1964", "A123456789"]
    let result = KVKarteParser.parse(lines: lines)
    #expect(result.kostentraeger == "Techniker Krankenkasse")
}

@Test func kvParserKostentraegerAllCaps() {
    let lines = ["AOK NORDWEST", "MUSTERMANN", "Erika", "15.11.1975", "B234567890"]
    let result = KVKarteParser.parse(lines: lines)
    #expect(result.kostentraeger == "AOK NORDWEST")
    #expect(result.nachname == "Mustermann")
    #expect(result.vorname == "Erika")
}

@Test func kvParserLeer() {
    let result = KVKarteParser.parse(lines: ["12345", "---", ""])
    #expect(result.vorname.isEmpty)
    #expect(result.nachname.isEmpty)
    #expect(result.versicherungsNummer.isEmpty)
    #expect(result.geburtsDatum == nil)
    #expect(result.kostentraeger.isEmpty)
}
```

- [ ] **Schritt 3: Tests laufen lassen – müssen FEHLSCHLAGEN**

In Xcode: Product → Test (⌘U) oder nur die `kvParser*`-Tests ausführen.
Erwartetes Ergebnis: Alle 9 neuen Tests schlagen fehl (Stub gibt leere Daten zurück).

---

## Task 2: KVKarteParser parse(lines:) implementieren

**Files:**
- Modify: `PatProt/Services/KVKarteParser.swift`

- [ ] **Schritt 1: Stub durch vollständige Implementierung ersetzen**

Den Inhalt von `KVKarteParser.swift` auf folgendes ersetzen:

```swift
import Vision
import UIKit

struct ParsedKVDaten {
    var vorname: String = ""
    var nachname: String = ""
    var geburtsDatum: Date? = nil
    var versicherungsNummer: String = ""
    var kostentraeger: String = ""
}

enum KVKarteParser {

    // MARK: - Async Image-Einstiegspunkt (implementiert in Task 3)

    static func parse(_ image: UIImage) async -> ParsedKVDaten {
        ParsedKVDaten()  // Platzhalter – Task 3
    }

    // MARK: - Testbarer Zeilen-Einstiegspunkt

    static func parse(lines: [String]) -> ParsedKVDaten {
        var result = ParsedKVDaten()
        let filteredLines = lines
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        for (i, line) in filteredLines.enumerated() {
            let lower = line.lowercased()

            // KVNR: 1 Großbuchstabe + 9 Ziffern (irgendwo in der Zeile)
            if result.versicherungsNummer.isEmpty,
               let match = line.range(of: #"[A-Z][0-9]{9}"#, options: .regularExpression) {
                result.versicherungsNummer = String(line[match])
            }

            // Geburtsdatum: optionales * + TT.MM.JJJJ
            if result.geburtsDatum == nil {
                let s = line.hasPrefix("*") ? String(line.dropFirst()).trimmingCharacters(in: .whitespaces) : line
                result.geburtsDatum = parseDate(s)
            }

            // Bekannte Kartenlabels überspringen
            guard !knownLabels.contains(where: { lower == $0 || lower.hasPrefix($0 + " ") }),
                  line.count >= 2,
                  line.contains(where: { $0.isLetter }) else { continue }

            // Reine KVNR- oder Datums-Zeilen für Namens-/Kassenlogik überspringen
            let isKVNR = line.range(of: #"^[A-Z][0-9]{9}$"#, options: .regularExpression) != nil
            let isDate = line.range(of: #"^\*?\d{2}\.\d{2}\.\d{4}$"#, options: .regularExpression) != nil
            guard !isKVNR, !isDate else { continue }

            // Kassenname: erste qualifizierende Zeile (oben auf der Karte)
            if result.kostentraeger.isEmpty {
                result.kostentraeger = line
                continue
            }

            // Nachname: erste VERSALIEN-Zeile nach dem Kassennamen
            if result.nachname.isEmpty, looksLikeNachname(line) {
                if line.contains(",") {
                    let parts = line.split(separator: ",", maxSplits: 1)
                                    .map { String($0).trimmingCharacters(in: .whitespaces) }
                    if parts.count == 2 {
                        result.nachname = parts[0].capitalized
                        if result.vorname.isEmpty { result.vorname = parts[1] }
                    }
                } else {
                    result.nachname = line.capitalized
                    // Nächste Zeile auf Vornamen prüfen
                    if result.vorname.isEmpty, i + 1 < filteredLines.count {
                        let next = filteredLines[i + 1]
                        if looksLikeVorname(next) {
                            result.vorname = next
                        }
                    }
                }
                continue
            }

            // Vorname: erste gemischt-geschriebene Zeile nach dem Nachnamen
            if !result.nachname.isEmpty, result.vorname.isEmpty, looksLikeVorname(line) {
                result.vorname = line
            }
        }

        return result
    }

    // MARK: - Private Hilfsfunktionen

    private static let knownLabels: [String] = [
        "versichertenkarte", "gesundheitskarte", "krankenversicherungskarte",
        "europäische krankenversicherungskarte", "european health insurance card",
        "gültig bis", "valid until", "versicherungsnummer",
        "geburtsdatum", "vorname", "nachname", "zuname", "vor- und zuname"
    ]

    private static func looksLikeNachname(_ line: String) -> Bool {
        guard line.count >= 2 else { return false }
        let allowed = CharacterSet.uppercaseLetters.union(CharacterSet(charactersIn: " -"))
        return line.unicodeScalars.allSatisfy { allowed.contains($0) }
            && line.contains(where: { $0.isLetter })
    }

    private static func looksLikeVorname(_ line: String) -> Bool {
        guard line.count >= 2 else { return false }
        let allowed = CharacterSet.letters.union(CharacterSet(charactersIn: " -"))
        return line.contains(where: { $0.isLowercase })
            && line.unicodeScalars.allSatisfy { allowed.contains($0) }
    }

    private static func parseDate(_ string: String) -> Date? {
        guard string.range(of: #"^\d{2}\.\d{2}\.\d{4}$"#, options: .regularExpression) != nil else { return nil }
        let f = DateFormatter()
        f.dateFormat = "dd.MM.yyyy"
        f.locale = Locale(identifier: "de_DE")
        return f.date(from: string)
    }
}
```

- [ ] **Schritt 2: Tests laufen lassen – müssen BESTEHEN**

In Xcode: Product → Test (⌘U).
Erwartetes Ergebnis: Alle 9 `kvParser*`-Tests grün. Alle anderen bestehenden Tests weiterhin grün.

- [ ] **Schritt 3: Commit**

```bash
git add PatProt/Services/KVKarteParser.swift PatProtTests/PatProtTests.swift
git commit -m "feat: KVKarteParser mit parse(lines:) + Tests"
```

---

## Task 3: KVKarteParser – async UIImage-Parsing

**Files:**
- Modify: `PatProt/Services/KVKarteParser.swift`

- [ ] **Schritt 1: parse(_ image:) implementieren**

Den `parse(_ image: UIImage) async -> ParsedKVDaten` Stub in `KVKarteParser.swift` ersetzen:

```swift
static func parse(_ image: UIImage) async -> ParsedKVDaten {
    guard let cgImage = image.cgImage else { return ParsedKVDaten() }
    return await withCheckedContinuation { continuation in
        DispatchQueue.global(qos: .userInitiated).async {
            let request = VNRecognizeTextRequest { req, _ in
                let observations = req.results as? [VNRecognizedTextObservation] ?? []
                let lines = observations
                    .compactMap { obs -> (String, CGFloat)? in
                        guard let text = obs.topCandidates(1).first?.string else { return nil }
                        return (text, obs.boundingBox.midY)
                    }
                    .sorted { $0.1 > $1.1 }   // oben → unten (Vision: Y=0 unten)
                    .map { $0.0 }
                continuation.resume(returning: parse(lines: lines))
            }
            request.recognitionLanguages = ["de-DE", "en-US"]
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = false   // Codes/Nummern nicht korrigieren
            try? VNImageRequestHandler(cgImage: cgImage, options: [:]).perform([request])
        }
    }
}
```

- [ ] **Schritt 2: Projekt kompilieren**

In Xcode: Product → Build (⌘B). Muss fehlerfrei kompilieren.

- [ ] **Schritt 3: Commit**

```bash
git add PatProt/Services/KVKarteParser.swift
git commit -m "feat: KVKarteParser async Vision OCR für UIImage"
```

---

## Task 4: KVKarteScanView – DocumentCameraWrapper + KVKarteScanSektion

**Files:**
- Create: `PatProt/Views/KVKarteScanView.swift`

- [ ] **Schritt 1: KVKarteScanView.swift anlegen**

```swift
import SwiftUI
import VisionKit

// MARK: - VNDocumentCameraViewController Wrapper

struct DocumentCameraWrapper: UIViewControllerRepresentable {
    let onScan: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let vc = VNDocumentCameraViewController()
        vc.delegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController,
                                context: Context) {}

    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let parent: DocumentCameraWrapper
        init(_ parent: DocumentCameraWrapper) { self.parent = parent }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController,
                                          didFinishWith scan: VNDocumentCameraScan) {
            let image = scan.imageOfPage(at: 0)
            parent.onScan(image)
            parent.dismiss()
        }

        func documentCameraViewControllerDidCancel(
            _ controller: VNDocumentCameraViewController) {
            parent.dismiss()
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController,
                                          didFailWithError error: Error) {
            parent.dismiss()
        }
    }
}

// MARK: - Scan-Sektion für PatientView

struct KVKarteScanSektion: View {
    @Binding var patientDaten: PatientDaten
    @State private var zeigeScanner = false
    @State private var scanStatus: ScanStatus = .idle

    private enum ScanStatus {
        case idle
        case success(String)
        case noResult
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button { zeigeScanner = true } label: {
                Label("Karte scannen", systemImage: "creditcard.viewfinder")
            }
            .buttonStyle(.bordered)

            switch scanStatus {
            case .idle:
                EmptyView()
            case .success(let summary):
                Label(summary, systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.green)
            case .noResult:
                Label("Keine Daten erkannt – bitte erneut versuchen",
                      systemImage: "exclamationmark.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .sheet(isPresented: $zeigeScanner) {
            DocumentCameraWrapper { image in
                Task {
                    let daten = await KVKarteParser.parse(image)
                    applyAndUpdateStatus(daten)
                }
            }
        }
    }

    private func applyAndUpdateStatus(_ daten: ParsedKVDaten) {
        if !daten.vorname.isEmpty            { patientDaten.vorname = daten.vorname }
        if !daten.nachname.isEmpty           { patientDaten.nachname = daten.nachname }
        if let geb = daten.geburtsDatum      { patientDaten.geburtsDatum = geb }
        if !daten.versicherungsNummer.isEmpty { patientDaten.versicherungsNummer = daten.versicherungsNummer }
        if !daten.kostentraeger.isEmpty       { patientDaten.kostentraeger = daten.kostentraeger }

        let empty = daten.vorname.isEmpty && daten.nachname.isEmpty
                 && daten.geburtsDatum == nil && daten.versicherungsNummer.isEmpty
                 && daten.kostentraeger.isEmpty

        if empty {
            scanStatus = .noResult
        } else {
            var parts: [String] = []
            if !daten.nachname.isEmpty           { parts.append(daten.nachname) }
            if !daten.vorname.isEmpty            { parts.append(daten.vorname) }
            if !daten.versicherungsNummer.isEmpty { parts.append(daten.versicherungsNummer) }
            scanStatus = .success("Gelesen: " + parts.joined(separator: ", "))
        }
    }
}
```

- [ ] **Schritt 2: Projekt kompilieren**

In Xcode: Product → Build (⌘B). Muss fehlerfrei kompilieren.

- [ ] **Schritt 3: Commit**

```bash
git add PatProt/Views/KVKarteScanView.swift
git commit -m "feat: KVKarteScanView mit DocumentCameraWrapper und KVKarteScanSektion"
```

---

## Task 5: PatientView – MedikamentFotoSektion ersetzen

**Files:**
- Modify: `PatProt/Views/PatientView.swift`

- [ ] **Schritt 1: Section in PatientView ersetzen**

In `PatientView.swift` die Section (Zeilen 50–57):

```swift
Section {
    MedikamentFotoSektion(fotos: $protokoll.kvFotos)
} header: {
    Label("KV-Karte / Versichertenkarte", systemImage: "creditcard")
} footer: {
    Text("Foto der Versichertenkarte – wird nur lokal gespeichert (DSGVO).")
        .font(.footnote).foregroundStyle(.secondary)
}
```

ersetzen durch:

```swift
Section {
    KVKarteScanSektion(patientDaten: $protokoll.patientDaten)
} header: {
    Label("KV-Karte / Versichertenkarte", systemImage: "creditcard")
} footer: {
    Text("Erkannte Daten werden direkt übernommen – nur lokal gespeichert (DSGVO).")
        .font(.footnote).foregroundStyle(.secondary)
}
```

- [ ] **Schritt 2: Projekt kompilieren**

In Xcode: Product → Build (⌘B). Muss fehlerfrei kompilieren.

- [ ] **Schritt 3: Commit**

```bash
git add PatProt/Views/PatientView.swift
git commit -m "feat: PatientView KV-Sektion auf Kamera-Scan umgestellt"
```

---

## Task 6: kvFotos aus Models und PDFGenerator entfernen

**Files:**
- Modify: `PatProt/Models/Models.swift`
- Modify: `PatProt/Services/PDFGenerator.swift`

- [ ] **Schritt 1: kvFotos aus Models.swift entfernen**

In `Models.swift` folgende Zeilen entfernen:

Zeile 160–161 (Kommentar + Property):
```swift
// KV-Karten-Foto (in-app only, nicht archiviert)
@Published var kvFotos: [FotoEintrag] = []
```

Zeilen 251–252 (Cleanup in reset()):
```swift
kvFotos.forEach { $0.loeschen() }
kvFotos = []
```

- [ ] **Schritt 2: kvFotos aus PDFGenerator.swift entfernen**

In `PDFGenerator.swift` Zeile ~327 den `kvFotos:`-Parameter aus dem `drawFotoPages`-Aufruf entfernen:

```swift
// Vorher:
drawFotoPages(ctx: ctx,
              mediFotos: protokoll.medikamentFotos,
              patFotos: protokoll.fotos,
              kvFotos: protokoll.kvFotos,
              erstelltAm: protokoll.erstelltAm)

// Nachher:
drawFotoPages(ctx: ctx,
              mediFotos: protokoll.medikamentFotos,
              patFotos: protokoll.fotos,
              erstelltAm: protokoll.erstelltAm)
```

In `PDFGenerator.swift` die `drawFotoPages`-Funktionsdefinition (~Zeile 2397) anpassen:

```swift
// Vorher:
private static func drawFotoPages(ctx: UIGraphicsPDFRendererContext,
                                   mediFotos: [FotoEintrag],
                                   patFotos: [FotoEintrag],
                                   kvFotos: [FotoEintrag],
                                   erstelltAm: Date) {
    let groups: [(String, [FotoEintrag])] = [
        ("Medikamentenplan", mediFotos),
        ("Patientenfoto",    patFotos),
        ("KV-Karte",         kvFotos),
    ].filter { !$1.isEmpty }

// Nachher:
private static func drawFotoPages(ctx: UIGraphicsPDFRendererContext,
                                   mediFotos: [FotoEintrag],
                                   patFotos: [FotoEintrag],
                                   erstelltAm: Date) {
    let groups: [(String, [FotoEintrag])] = [
        ("Medikamentenplan", mediFotos),
        ("Patientenfoto",    patFotos),
    ].filter { !$1.isEmpty }
```

- [ ] **Schritt 3: Projekt kompilieren + alle Tests laufen lassen**

In Xcode: Product → Test (⌘U).
Erwartetes Ergebnis: Kompilierung fehlerfrei, alle Tests grün.

- [ ] **Schritt 4: Commit**

```bash
git add PatProt/Models/Models.swift PatProt/Services/PDFGenerator.swift
git commit -m "refactor: kvFotos entfernt – KV-Karte wird nicht mehr als Foto gespeichert"
```

---

## Abschluss-Check

Nach allen Tasks:
- [ ] Alle Tests grün (⌘U)
- [ ] In `PatientView` erscheint "Karte scannen"-Button statt Foto-Buttons
- [ ] Kein Kompiler-Fehler und keine Warnung zu `kvFotos`
