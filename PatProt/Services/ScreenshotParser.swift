import Vision
import UIKit

// MARK: - Parsed data from a Melde-App screenshot

struct ParsedMeldungDaten {
    var einsatzNummer: String = ""
    var einsatzArt: String = ""       // z.B. "NOTF 01"
    var stichwort: String = ""        // z.B. "Alkohol-Intox"
    var adresse: String = ""          // z.B. "Norderstraße, 21502 Geesthacht"
    var zusatz: String = ""           // Objekt + Stockwerk ohne Labels
    var alarmzeit: Date? = nil
    var sondersignal: Bool = false
    var notarzt: Bool = false
    var geschlecht: Geschlecht = .unbekannt
    var ereignis: String = ""
}

// MARK: - Screenshot OCR + Parser

enum ScreenshotParser {

    static func parse(_ image: UIImage) async -> ParsedMeldungDaten {
        guard let cgImage = image.cgImage else { return ParsedMeldungDaten() }

        return await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { req, _ in
                let observations = req.results as? [VNRecognizedTextObservation] ?? []
                let sorted = observations
                    .compactMap { obs -> (String, CGRect)? in
                        guard let text = obs.topCandidates(1).first?.string else { return nil }
                        return (text, obs.boundingBox)
                    }
                    .sorted { $0.1.midY > $1.1.midY }
                    .map(\.0)
                continuation.resume(returning: parse(lines: sorted))
            }
            request.recognitionLanguages = ["de-DE", "en-US"]
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            try? VNImageRequestHandler(cgImage: cgImage, options: [:]).perform([request])
        }
    }

    // MARK: - Testable entry point (takes pre-split text lines)

    static func parse(lines: [String]) -> ParsedMeldungDaten {
        extractFields(from: lines)
    }

    // MARK: - Extraktion

    private static func extractFields(from lines: [String]) -> ParsedMeldungDaten {
        var result = ParsedMeldungDaten()

        // Vision liest zweispaltige Layouts oft spaltenweise.
        // Strategie: jeden Wert anhand seines Inhalts erkennen,
        // unabhängig davon, wo er in der Zeilenliste steht.

        for (i, raw) in lines.enumerated() {
            let line = raw.trimmingCharacters(in: .whitespaces)
            let lower = line.lowercased()

            // ── Einsatznummer ──────────────────────────────────────────
            // Nur reine Zahlen mit 8-12 Stellen; Datumsformate (TTMMJJJJ) ausschließen
            if result.einsatzNummer.isEmpty,
               line.allSatisfy({ $0.isNumber }),
               (8...12).contains(line.count) {
                // Datum-Muster DDMMYYYY ausschließen (Tag 01-31, Monat 01-12)
                let isDateLike: Bool
                if line.count == 8,
                   let day = Int(line.prefix(2)),
                   let month = Int(line.dropFirst(2).prefix(2)),
                   (1...31).contains(day), (1...12).contains(month) {
                    isDateLike = true
                } else {
                    isDateLike = false
                }
                if !isDateLike {
                    result.einsatzNummer = line
                }
            }

            // ── Alarmzeit ──────────────────────────────────────────────
            // Sucht "Gestern" oder "Heute" IRGENDWO in der Zeile –
            // OCR liest "Einsatzbeginn  Gestern, 19:57" oft als eine Zeile.
            if result.alarmzeit == nil {
                result.alarmzeit = extractTimeOnly(line)
            }

            // ── Stichwort / Einsatzart ─────────────────────────────────
            // Explizites "Stichwort"-Label mit Inline-Wert
            if lower.hasPrefix("stichwort") {
                if let val = inlineValue(line) {
                    applyEinsatzCode(val, to: &result)
                }
            }

            // Einsatz-Code irgendwo im Text (Nav-Titel oder Stichwort-Wert)
            // z.B. "NOTF 01 - Alkohol-Intox" als eigene Zeile
            if result.einsatzArt.isEmpty,
               containsEinsatzCode(line),
               !lower.hasPrefix("stichwort") {
                let cleaned = cleanNavTitle(line)
                applyEinsatzCode(cleaned, to: &result)
            }

            // ── Adresse ────────────────────────────────────────────────
            // Enthält PLZ (5 Ziffern) ODER Komma-Format.
            // OCR liest oft "Adresse  Norderstraße..." als eine Zeile → Label abschneiden.
            if result.adresse.isEmpty, looksLikeAddress(line) {
                result.adresse = stripKnownPrefix(line, prefix: "adresse")
            }


            // ── Geschlecht ─────────────────────────────────────────────
            if lower.contains("patient:") {
                let g = parseGeschlecht(lower)
                if g != .unbekannt { result.geschlecht = g }
            }

            // ── Meldung-Block ──────────────────────────────────────────
            if lower == "meldung" {
                var block: [String] = []
                var j = i + 1
                while j < lines.count {
                    let next = lines[j].trimmingCharacters(in: .whitespaces)
                    if next.lowercased().hasPrefix("rückmeldung")
                        || next.lowercased().hasPrefix("ruckmeldung") { break }
                    if !next.isEmpty { block.append(next) }
                    j += 1
                }
                result.ereignis = block.joined(separator: "\n")

                // Zusatz = Werte von Objekt/Stockwerk ohne Label
                let teile: [String] = block.compactMap { bLine in
                    let bl = bLine.lowercased()
                    if bl.hasPrefix("objekt:") {
                        return bLine.dropFirst("objekt:".count)
                            .trimmingCharacters(in: .whitespaces)
                    } else if bl.hasPrefix("stockwerk:") {
                        return bLine.dropFirst("stockwerk:".count)
                            .trimmingCharacters(in: .whitespaces)
                    }
                    return nil
                }
                if !teile.isEmpty {
                    result.zusatz = teile.joined(separator: ", ")
                }

                // Geschlecht aus Meldung
                for bLine in block where bLine.lowercased().contains("patient:") {
                    let g = parseGeschlecht(bLine.lowercased())
                    if g != .unbekannt { result.geschlecht = g }
                }
            }
        }

        // Sondersignal wird beim Screenshot-Import immer gesetzt.
        result.sondersignal = true

        return result
    }

    // MARK: - Stichwort aufteilen

    private static func applyEinsatzCode(_ raw: String, to result: inout ParsedMeldungDaten) {
        let (art, stich) = splitStichwort(raw)
        guard !art.isEmpty else { return }
        result.einsatzArt = art
        result.stichwort  = stich
        result.notarzt    = isNotarzt(art)
    }

    /// "NOTF 01 - Alkohol-Intox" → ("NOTF 01", "Alkohol-Intox")
    private static func splitStichwort(_ raw: String) -> (art: String, stichwort: String) {
        for sep in [" - ", " – ", "- ", "– "] {
            if let r = raw.range(of: sep) {
                let art   = String(raw[..<r.lowerBound]).trimmingCharacters(in: .whitespaces)
                let stich = String(raw[r.upperBound...]).trimmingCharacters(in: .whitespaces)
                if !art.isEmpty { return (art, stich) }
            }
        }
        return (raw.trimmingCharacters(in: .whitespaces), "")
    }

    /// NOTF 11, NAH 11 usw. → Notarzt
    private static func isNotarzt(_ art: String) -> Bool {
        art.uppercased()
            .replacingOccurrences(of: " ", with: "")
            .hasSuffix("11")
    }

    private static func containsEinsatzCode(_ line: String) -> Bool {
        ["NOTF", "NAH", "SEG", "UNF", "BRAND", "TECH"].contains {
            line.uppercased().contains($0)
        }
    }

    // MARK: - Adress-Erkennung

    /// Prüft ob eine Zeile wie eine Adresse aussieht.
    /// Muss PLZ (5 Ziffern) ODER Komma+Text enthalten und ≥8 Zeichen lang sein.
    private static func looksLikeAddress(_ line: String) -> Bool {
        let lower = line.lowercased()

        // Datum-/Zeit-Strings explizit ausschließen
        let excluded = ["gestern", "heute", "vorgestern", "rückmeldung", "ruckmeldung",
                        "meldung", "einsatz", "priorität", "prioritat", "stichwort",
                        "autor", "messenger", "schnittstelle", "objekt:", "stockwerk:",
                        "patient:"]
        if excluded.contains(where: { lower.hasPrefix($0) }) { return false }

        guard line.count >= 8,
              line.contains(where: { $0.isLetter }),
              line.contains(where: { $0.isNumber }) else { return false }

        // Deutsche PLZ: 5 aufeinanderfolgende Ziffern
        let hasPostalCode = line.range(of: #"\b\d{5}\b"#,
                                       options: .regularExpression) != nil
        // Komma-Format: "Straße, Stadt" – aber kein reines Datum "dd.MM.yy, HH:mm"
        let hasComma = line.contains(",")
            && line.range(of: #"^\d{2}\.\d{2}\."#, options: .regularExpression) == nil

        return hasPostalCode || hasComma
    }


    // MARK: - Datum/Uhrzeit

    /// Extrahiert NUR die Uhrzeit wenn "Gestern" oder "Heute" IRGENDWO in der Zeile steht.
    /// Deckt beide OCR-Fälle ab:
    ///   • "Gestern, 19:57"                    (eigene Zeile)
    ///   • "Einsatzbeginn  Gestern, 19:57"     (Label + Wert auf einer Zeile)
    /// Blanke Uhrzeiten ("08:40") werden ignoriert.
    private static func extractTimeOnly(_ text: String) -> Date? {
        let s = text.trimmingCharacters(in: .whitespaces)

        // "Gestern" oder "Heute" irgendwo im String finden
        var rest: String? = nil
        for keyword in ["gestern", "heute"] {
            if let range = s.range(of: keyword, options: .caseInsensitive) {
                rest = String(s[range.lowerBound...])
                break
            }
        }
        guard let r = rest else { return nil }

        // Alles bis zur ersten Ziffer abschneiden → "19:57"
        let timeStr = String(r.drop(while: { !$0.isNumber }).prefix(5))
        guard timeStr.count == 5 else { return nil }

        let tf = DateFormatter()
        tf.dateFormat = "HH:mm"
        guard let t = tf.date(from: timeStr) else { return nil }

        // Datum = heute; "Gestern" wird ignoriert (nur Uhrzeit übernehmen)
        var c  = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        let tc = Calendar.current.dateComponents([.hour, .minute], from: t)
        c.hour = tc.hour; c.minute = tc.minute
        return Calendar.current.date(from: c)
    }

    /// Schneidet ein bekanntes Label-Prefix ab, das OCR zusammen mit dem Wert liest.
    /// "Adresse  Norderstraße, 21502 Geesthacht" → "Norderstraße, 21502 Geesthacht"
    private static func stripKnownPrefix(_ line: String, prefix: String) -> String {
        let s = line.trimmingCharacters(in: .whitespaces)
        guard s.lowercased().hasPrefix(prefix) else { return s }
        return s.dropFirst(prefix.count)
            .trimmingCharacters(in: .whitespaces)
    }

    // MARK: - Hilfsfunktionen

    /// Wert auf derselben Zeile, durch ≥2 Leerzeichen vom Label getrennt
    private static func inlineValue(_ line: String) -> String? {
        let parts = line.components(separatedBy: "  ")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        guard parts.count >= 2 else { return nil }
        let val = parts.dropFirst().joined(separator: " ")
        return val.isEmpty ? nil : val
    }

    private static func cleanNavTitle(_ line: String) -> String {
        line.components(separatedBy: CharacterSet(charactersIn: "<>^∧"))
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .last ?? line
    }

    private static func parseGeschlecht(_ lower: String) -> Geschlecht {
        if lower.contains("patient: m") || lower.contains("patient:m") { return .maennlich }
        if lower.contains("patient: w") || lower.contains("patient: f")
            || lower.contains("patient:w") || lower.contains("patient:f") { return .weiblich }
        return .unbekannt
    }
}
