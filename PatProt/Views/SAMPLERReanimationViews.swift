import SwiftUI

// MARK: - Reanimation

struct SAMPLERReanimationView: View {
    @Binding var protokoll: ReanimationsProtokoll
    var onWeiter: () -> Void

    // Local state placeholders until model provides these properties
    @State private var rdCPRStartLocal: Date? = nil
    @State private var rdCPREndeLocal: Date? = nil
    @State private var roscZeitLocal: Date? = nil
    @State private var todFeststellungsZeitLocal: Date? = nil

    var body: some View {
        Form(content: {
            // EREIGNIS
            Section {
                ZeitFeld(label: "Kollaps-Zeitpunkt", datum: $protokoll.kollapsZeit)
                Toggle("Ersthelfer anwesend", isOn: $protokoll.erstHelfer)
                if protokoll.erstHelfer {
                    // TODO: Add toggles for Ersthelfer-CPR/AED when corresponding properties exist on ReanimationsProtokoll
                }
            } header: { Label("Ereignis", systemImage: "clock.badge.exclamationmark") }

            // INITIAL-RHYTHMUS
            Section {
                Picker("Initialrhythmus", selection: $protokoll.initialRhythmus) {
                    ForEach(InitialRhythmus.allCases, id: \.self) { r in
                        Text(r.rawValue).tag(r)
                    }
                }
                .pickerStyle(.inline)
            } header: { Label("Initialrhythmus", systemImage: "waveform.path.ecg") }

            // CPR RETTUNGSDIENST – NUR START/ENDE
            Section {
                ZeitFeld(label: "Start CPR (Rettungsdienst)", datum: $rdCPRStartLocal)
                ZeitFeld(label: "Ende CPR (Rettungsdienst)", datum: $rdCPREndeLocal)
            } header: { Label("CPR (Rettungsdienst)", systemImage: "repeat.circle") }

            // OUTCOME
            Section {
                Picker("Outcome", selection: $protokoll.outcome) {
                    ForEach(ReaniOutcome.allCases, id: \.self) { o in
                        Text(o.rawValue).tag(o)
                    }
                }
                .pickerStyle(.inline)

                if protokoll.outcome == .rosc {
                    ZeitFeld(label: "ROSC-Zeitpunkt", datum: $roscZeitLocal)
                }

                if protokoll.outcome == .verstorben {
                    ZeitFeld(label: "Todeszeitpunkt", datum: $todFeststellungsZeitLocal)
                }
            } header: { Label("Outcome", systemImage: "heart.text.square") }

            Section {
                TextEditor(text: $protokoll.freitext).frame(minHeight: 80)
            } header: { Text("Freitext / Notizen") }

            Section {
                Button(action: onWeiter) {
                    Label("Weiter zum Abschluss", systemImage: "arrow.right.circle.fill")
                        .frame(maxWidth: .infinity).padding(.vertical, 4)
                }
                .buttonStyle(.borderedProminent).tint(Color("RDOrange"))
            }
        })
        .navigationTitle("Reanimationsprotokoll")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
    }
}
// Entfernte Typen und Views (CPRZyklus, ZyklusEditorView, MedikamentZeile) wurden gelöscht, da nur Start/Ende erfasst werden sollen und um nicht auf unbekannte Typen zu verweisen.

