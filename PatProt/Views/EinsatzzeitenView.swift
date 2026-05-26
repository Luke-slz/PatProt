import SwiftUI

struct EinsatzzeitenView: View {
    @ObservedObject var protokoll: EinsatzProtokoll

    private var zeitFehler: [String] {
        let alarm    = protokoll.einsatzOrt.alarmzeit
        let ankunft  = protokoll.einsatzOrt.ankunftzeit
        let uebergabe = protokoll.einsatzOrt.krankenHausAnkunft
        let ende     = protokoll.einsatzOrt.abfahrtzeit
        var fehler: [String] = []
        if let a = alarm,     let b = ankunft,   b < a { fehler.append("Ankunft liegt vor der Alarmzeit") }
        if let a = ankunft,   let b = uebergabe, b < a { fehler.append("Übergabe liegt vor der Ankunft") }
        if let a = uebergabe, let b = ende,      b < a { fehler.append("Einsatz Ende liegt vor der Übergabe") }
        return fehler
    }

    var body: some View {
        Form {
            Section {
                DatePicker(
                    "Alarmdatum",
                    selection: Binding(
                        get: { protokoll.einsatzOrt.alarmzeit ?? Date() },
                        set: { protokoll.einsatzOrt.alarmzeit = $0 }
                    ),
                    displayedComponents: .date
                )
                ZeitFeld(label: "Alarmzeit",        datum: $protokoll.einsatzOrt.alarmzeit)
                ZeitFeld(label: "Ankunft Patient", datum: $protokoll.einsatzOrt.ankunftzeit)
                ZeitFeld(label: "Übergabe an RD",  datum: $protokoll.einsatzOrt.krankenHausAnkunft)
                ZeitFeld(label: "Einsatz Ende",    datum: $protokoll.einsatzOrt.abfahrtzeit)
            } header: {
                Label("Zeiten", systemImage: "clock")
            } footer: {
                if !zeitFehler.isEmpty {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(zeitFehler, id: \.self) { fehler in
                            Label(fehler, systemImage: "exclamationmark.triangle.fill")
                                .font(.caption).foregroundStyle(.orange)
                        }
                    }
                }
            }
        }
        .navigationTitle("Einsatzzeiten")
        .navigationBarTitleDisplayMode(.large)
    }
}
