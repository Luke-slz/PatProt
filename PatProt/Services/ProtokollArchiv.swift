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
    }

    func loeschen(_ id: UUID) {
        let url = archivDir.appendingPathComponent("\(id.uuidString).json")
        try? FileManager.default.removeItem(at: url)
        protokolle.removeAll { $0.id == id }
    }
}
