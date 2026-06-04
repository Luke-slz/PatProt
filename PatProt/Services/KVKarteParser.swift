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
        ParsedKVDaten()  // Stub – implemented in Task 3
    }

    static func parse(lines: [String]) -> ParsedKVDaten {
        var result = ParsedKVDaten()
        let filteredLines = lines
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        for (i, line) in filteredLines.enumerated() {
            let lower = line.lowercased()

            // KVNR: 1 uppercase letter + 9 digits, anywhere in the line
            if result.versicherungsNummer.isEmpty,
               let match = line.range(of: #"[A-Z][0-9]{9}"#, options: .regularExpression) {
                result.versicherungsNummer = String(line[match])
            }

            // Geburtsdatum: optional * prefix + DD.MM.YYYY
            if result.geburtsDatum == nil {
                let s = line.hasPrefix("*") ? String(line.dropFirst()).trimmingCharacters(in: .whitespaces) : line
                result.geburtsDatum = parseDate(s)
            }

            // Skip known card labels
            guard !knownLabels.contains(where: { lower == $0 || lower.hasPrefix($0 + " ") }),
                  line.count >= 2,
                  line.contains(where: { $0.isLetter }) else { continue }

            // Skip pure KVNR or date-only lines for name/kassenname logic
            let isKVNR = line.range(of: #"^[A-Z][0-9]{9}$"#, options: .regularExpression) != nil
            let isDate = line.range(of: #"^\*?\d{2}\.\d{2}\.\d{4}$"#, options: .regularExpression) != nil
            guard !isKVNR, !isDate else { continue }

            // Kassenname: first qualifying line (topmost on card after sorting)
            if result.kostentraeger.isEmpty {
                result.kostentraeger = line
                continue
            }

            // Nachname: first ALL-CAPS line after kassenname
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
                    // Peek ahead for Vorname on the next line
                    if result.vorname.isEmpty, i + 1 < filteredLines.count {
                        let next = filteredLines[i + 1]
                        if looksLikeVorname(next) {
                            result.vorname = next
                        }
                    }
                }
                continue
            }

            // Vorname: first mixed-case line after nachname is known
            if !result.nachname.isEmpty, result.vorname.isEmpty, looksLikeVorname(line) {
                result.vorname = line
            }
        }

        return result
    }

    // MARK: - Private Helpers

    private static let knownLabels: [String] = [
        "versichertenkarte", "gesundheitskarte", "krankenversicherungskarte",
        "europäische krankenversicherungskarte", "european health insurance card",
        "gültig bis", "valid until", "versicherungsnummer",
        "geburtsdatum", "vorname", "nachname", "zuname", "vor- und zuname"
    ]

    private static func looksLikeNachname(_ line: String) -> Bool {
        guard line.count >= 2 else { return false }
        // Handle "NACHNAME, Vorname" comma format: only the part before the comma must be ALL-CAPS
        if line.contains(",") {
            let beforeComma = String(line.prefix(while: { $0 != "," }))
            let allowed = CharacterSet.uppercaseLetters.union(CharacterSet(charactersIn: " -"))
            return beforeComma.unicodeScalars.allSatisfy { allowed.contains($0) }
                && beforeComma.contains(where: { $0.isLetter })
        }
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

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "dd.MM.yyyy"
        f.locale = Locale(identifier: "de_DE")
        return f
    }()

    private static func parseDate(_ string: String) -> Date? {
        guard string.range(of: #"^\d{2}\.\d{2}\.\d{4}$"#, options: .regularExpression) != nil else { return nil }
        return dateFormatter.date(from: string)
    }
}
