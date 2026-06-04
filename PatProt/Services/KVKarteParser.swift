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
        ParsedKVDaten()  // Stub – implemented in Task 2
    }
}
