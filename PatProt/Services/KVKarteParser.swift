import Vision   // VNRecognizeTextRequest – used in Task 3
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
        guard let cgImage = image.cgImage else { return ParsedKVDaten() }
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let request = VNRecognizeTextRequest { req, error in
                    guard error == nil else {
                        continuation.resume(returning: ParsedKVDaten())
                        return
                    }
                    let observations = req.results as? [VNRecognizedTextObservation] ?? []
                    let lines = observations
                        .compactMap { obs -> (String, CGFloat)? in
                            guard let text = obs.topCandidates(1).first?.string else { return nil }
                            return (text, obs.boundingBox.midY)
                        }
                        .sorted { $0.1 > $1.1 }   // descending midY = top-to-bottom (Vision: Y=0 at bottom)
                        .map { $0.0 }
                    continuation.resume(returning: parse(lines: lines))
                }
                request.recognitionLanguages = ["de-DE", "en-US"]
                request.recognitionLevel = .accurate
                request.usesLanguageCorrection = false   // preserve KVNR codes exactly
                do {
                    try VNImageRequestHandler(cgImage: cgImage, options: [:]).perform([request])
                } catch {
                    continuation.resume(returning: ParsedKVDaten())
                }
            }
        }
    }

    static func parse(lines: [String]) -> ParsedKVDaten {
        var result = ParsedKVDaten()
        let filteredLines = lines
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        for line in filteredLines {
            let lower = line.lowercased()

            // KVNR: 1 uppercase letter + 9 digits, anywhere in the line
            if result.versicherungsNummer.isEmpty,
               let match = line.range(of: #"[A-Z][0-9]{9}"#, options: .regularExpression) {
                result.versicherungsNummer = String(line[match])
            }

            // Geburtsdatum: optional * prefix; exclude expiry lines
            if result.geburtsDatum == nil {
                let isExpiryLine = lower.hasPrefix("gültig") || lower.hasPrefix("valid until") || lower.hasPrefix("ablauf")
                if !isExpiryLine {
                    let s = line.hasPrefix("*") ? String(line.dropFirst()).trimmingCharacters(in: .whitespaces) : line
                    result.geburtsDatum = parseDate(s)
                }
            }

            // Skip known card labels and non-text lines
            guard !isKnownLabel(lower),
                  line.count >= 2,
                  line.contains(where: { $0.isLetter }) else { continue }

            let isKVNR = line.range(of: #"^[A-Z][0-9]{9}$"#, options: .regularExpression) != nil
            let isDate = line.range(of: #"^\*?\d{2}\.\d{2}\.\d{4}$"#, options: .regularExpression) != nil
            guard !isKVNR, !isDate else { continue }

            // Nachname: first ALL-CAPS line (no internal spaces – distinguishes names from
            // multi-word institution names like "AOK NORDWEST"); comma format splits both fields.
            if result.nachname.isEmpty, looksLikeNachname(line) {
                if line.contains(",") {
                    let parts = line.split(separator: ",", maxSplits: 1)
                                    .map { String($0).trimmingCharacters(in: .whitespaces) }
                    if parts.count == 2 {
                        result.nachname = parts[0].capitalized
                        if result.vorname.isEmpty { result.vorname = parts[1].capitalized }
                    }
                } else {
                    result.nachname = line.capitalized
                }
                continue
            }

            // Vorname: first qualifying line once nachname is known.
            // Accepts mixed-case ("Max") AND single-word ALL-CAPS ("MAX") since EHIC cards
            // print given names in uppercase. .capitalized normalises "MAX" → "Max".
            if !result.nachname.isEmpty, result.vorname.isEmpty,
               looksLikeVorname(line) || looksLikeNachname(line) {
                result.vorname = line.capitalized
                continue
            }

            // EHIC field 7: "106415300 - AOK MUSTER" → extract kassenname after IK number.
            // Always overrides a previously wrongly captured kassenname.
            if let range = line.range(of: #"^\d{7,9}\s*[-–]\s*"#, options: .regularExpression) {
                let name = String(line[range.upperBound...]).trimmingCharacters(in: .whitespaces)
                if !name.isEmpty { result.kostentraeger = name }
                continue
            }

            // Kassenname: first short, non-sentence qualifying line.
            // Skip inscription text (commas) and very long lines that are clearly sentences.
            let looksLikeSentence = line.contains(",") || (line.contains(".") && line.count > 25)
            if result.kostentraeger.isEmpty, !looksLikeSentence {
                result.kostentraeger = line
            }
        }

        return result
    }

    // MARK: - Private Helpers

    private static let knownLabels: [String] = [
        "versichertenkarte", "gesundheitskarte", "krankenversicherungskarte",
        "europäische krankenversicherungskarte", "european health insurance card",
        "kostenfreie hotline", "hotline",
        "gültig bis", "valid until", "versicherungsnummer",
        "geburtsdatum", "vorname", "vornamen", "nachname", "nachnamen",
        "zuname", "vor- und zuname", "name",
        "geb.", "geb.datum", "geb.am",
        // EHIC (Rückseite eGK) Feldbezeichner
        "persönliche kennnummer", "persönl. kennnummer",
        "kennnummer",           // deckt alle "Kennnummer …"-Varianten ab
        "ablaufdatum", "expiry date", "expiry",
        "surname", "given name", "date of birth",
        "personal identification", "identification number",
        "de", "eu"
    ]

    /// Strips leading field numbers like "3. " or "8 " from EHIC label lines.
    private static func withoutNumberedPrefix(_ s: String) -> String {
        guard let r = s.range(of: #"^\d+\.?\s+"#, options: .regularExpression) else { return s }
        return String(s[r.upperBound...])
    }

    private static func isKnownLabel(_ lower: String) -> Bool {
        let stripped = withoutNumberedPrefix(lower)
        for text in [lower, stripped] {
            if knownLabels.contains(where: {
                text == $0
                    || text.hasPrefix($0 + " ")
                    || text.hasPrefix($0 + "(")
                    || text.hasPrefix($0 + "/")
            }) { return true }
        }
        return false
    }

    private static func looksLikeNachname(_ line: String) -> Bool {
        guard line.count >= 2 else { return false }
        // Comma format "NACHNAME, Vorname": only the part before the comma must be ALL-CAPS
        if line.contains(",") {
            let beforeComma = String(line.prefix(while: { $0 != "," }))
            let allowed = CharacterSet.uppercaseLetters.union(CharacterSet(charactersIn: " -"))
            return beforeComma.unicodeScalars.allSatisfy { allowed.contains($0) }
                && beforeComma.contains(where: { $0.isLetter })
        }
        // No spaces: distinguishes "MUSTERMANN" (nachname) from "AOK NORDWEST" (kassenname)
        let allowed = CharacterSet.uppercaseLetters.union(CharacterSet(charactersIn: "-"))
        return line.unicodeScalars.allSatisfy { allowed.contains($0) }
            && line.contains(where: { $0.isLetter })
    }

    private static func looksLikeVorname(_ line: String) -> Bool {
        guard line.count >= 2 else { return false }
        let allowed = CharacterSet.letters.union(CharacterSet(charactersIn: " -"))
        return line.contains(where: { $0.isLowercase })
            && line.unicodeScalars.allSatisfy { allowed.contains($0) }
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "dd.MM.yyyy"
        f.locale = Locale(identifier: "de_DE")
        return f
    }()

    private static func parseDate(_ string: String) -> Date? {
        // Punkt-Format: "12.08.1964" (auch mit Präfix "Geb.: …")
        if let match = string.range(of: #"\d{2}\.\d{2}\.\d{4}"#, options: .regularExpression) {
            return dateFormatter.date(from: String(string[match]))
        }
        // Schrägstrich-Format auf EHIC: "12/08/1964" → als DD/MM/YYYY interpretieren
        if let match = string.range(of: #"\d{2}/\d{2}/\d{4}"#, options: .regularExpression) {
            let s = String(string[match]).replacingOccurrences(of: "/", with: ".")
            return dateFormatter.date(from: s)
        }
        return nil
    }
}
