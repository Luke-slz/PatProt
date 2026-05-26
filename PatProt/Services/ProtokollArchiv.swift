import Foundation
import Combine

// MARK: - Protokoll Archive Service (DSGVO: local only, .completeFileProtection)

class ProtokollArchiv: ObservableObject {
    static let shared = ProtokollArchiv()

    @Published var protokolle: [ProtokollDaten] = []

    private let verzeichnis: URL

    private var archivDir: URL { verzeichnis }

    private init() {
        verzeichnis = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Protokolle", isDirectory: true)
        try? FileManager.default.createDirectory(at: verzeichnis, withIntermediateDirectories: true)
        laden()
    }

    init(verzeichnis: URL) {
        self.verzeichnis = verzeichnis
        laden()
    }

    static func testInstance() throws -> ProtokollArchiv {
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
        return ProtokollArchiv(verzeichnis: tmp)
    }

    func speichern(_ protokoll: EinsatzProtokoll) throws {
        let daten = protokoll.toDaten()
        try speicherDatei(daten)
        if let idx = protokolle.firstIndex(where: { $0.id == daten.id }) {
            protokolle[idx] = daten
        } else {
            protokolle.insert(daten, at: 0)
        }
    }

    func speichern(_ daten: ProtokollDaten) throws {
        try speicherDatei(daten)
        if let idx = protokolle.firstIndex(where: { $0.id == daten.id }) {
            protokolle[idx] = daten
        } else {
            protokolle.insert(daten, at: 0)
        }
    }

    private func speicherDatei(_ daten: ProtokollDaten) throws {
        let data = try JSONEncoder().encode(daten)
        let url = archivDir.appendingPathComponent("\(daten.id.uuidString).json")
        try data.write(to: url, options: [.atomicWrite, .completeFileProtection])
    }

    @discardableResult
    func laden() -> [ProtokollDaten] {
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
        return protokolle
    }

    func loeschen(_ id: UUID) {
        let url = archivDir.appendingPathComponent("\(id.uuidString).json")
        try? FileManager.default.removeItem(at: url)
        protokolle.removeAll { $0.id == id }
    }

    func markierePDFExport(id: UUID) {
        guard let index = protokolle.firstIndex(where: { $0.id == id }) else { return }
        protokolle[index].pdfExportiertAm = Date()
        try? speicherDatei(protokolle[index])
    }

    private func purgeAbgelaufene() {
        let grenze = Date().addingTimeInterval(-86400)
        let abgelaufen = protokolle.filter {
            guard let exportiert = $0.pdfExportiertAm else { return false }
            return exportiert < grenze
        }
        for eintrag in abgelaufen {
            let url = archivDir.appendingPathComponent("\(eintrag.id.uuidString).json")
            try? FileManager.default.removeItem(at: url)
            protokolle.removeAll { $0.id == eintrag.id }
        }
    }
}
