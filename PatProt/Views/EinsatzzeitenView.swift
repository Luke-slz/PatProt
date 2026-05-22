import SwiftUI

struct EinsatzzeitenView: View {
    @ObservedObject var protokoll: EinsatzProtokoll

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
                ZeitFeld(label: "Alarmzeit",             datum: $protokoll.einsatzOrt.alarmzeit)
                ZeitFeld(label: "Ankunft Patient",        datum: $protokoll.einsatzOrt.ankunftzeit)
                ZeitFeld(label: "Abfahrt Einsatzstelle",  datum: $protokoll.einsatzOrt.abfahrtzeit)
                ZeitFeld(label: "Übergabe an RD",         datum: $protokoll.einsatzOrt.krankenHausAnkunft)
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
