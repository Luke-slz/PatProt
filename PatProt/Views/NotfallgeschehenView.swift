import SwiftUI

struct NotfallgeschehenView: View {
    @Binding var befund: NotfallgeschehenBefund
    var onWeiter: () -> Void
    var onBack: () -> Void

    var body: some View {
        Form {
            // Erstbefund
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Erstbefund bei Ankunft", systemImage: "eyes")
                        .font(.subheadline).fontWeight(.semibold)
                    Text("Zustand des Patienten bei Erstkontakt")
                        .font(.caption).foregroundColor(.secondary)
                    TextEditor(text: $befund.erstbefundVorOrt)
                        .frame(minHeight: 80)
                }
            }

            // Patient vorgefunden
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Patient vorgefunden", systemImage: "person.fill")
                        .font(.subheadline).fontWeight(.semibold)
                    Text("z.B. bewusstlos am Boden, sitzend, stehend")
                        .font(.caption).foregroundColor(.secondary)
                    TextField("z.B. bewusstlos, auf dem Rücken liegend", text: $befund.patientGefunden)
                }
            }

            // Ersthelfer
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Ersthelfermaßnahmen", systemImage: "person.2.fill")
                        .font(.subheadline).fontWeight(.semibold)
                    Text("Maßnahmen vor Rettungsdienst-Eintreffen")
                        .font(.caption).foregroundColor(.secondary)
                    TextEditor(text: $befund.ersthelferMassnahmen)
                        .frame(minHeight: 60)
                }
            }

            // Beteiligte / MANV
            Section {
                Stepper("Anzahl Beteiligte: \(befund.anzahlBeteiligte)",
                        value: $befund.anzahlBeteiligte, in: 1...100)
                Toggle("MANV-Lage", isOn: $befund.manv)
                    .tint(.red)
            } header: {
                Label("Besonderheiten", systemImage: "exclamationmark.triangle.fill")
            }

        }
        .safeAreaInset(edge: .bottom) {
            Button(action: onWeiter) {
                Label("Weiter zur Befunderhebung", systemImage: "arrow.right.circle.fill")
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.borderedProminent)
            .tint(Color("RDOrange"))
            .padding([.horizontal, .bottom])
            .background(.bar)
        }
        .navigationTitle("Notfallgeschehen")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: onBack) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Zurück")
                    }
                }
            }
        }
    }
}
