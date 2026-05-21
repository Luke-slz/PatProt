import SwiftUI

// MARK: - SINNHAFT-Schema

struct SINNHAFTView: View {
    @Binding var befund: SINNHAFTBefund
    @EnvironmentObject private var protokoll: EinsatzProtokoll
    var onZurueck: () -> Void

    var body: some View {
        Form {
            Section {
                sinnhaftHeader
            }

            // Auto-Fill Button
            Section {
                Button {
                    autoFill()
                } label: {
                    HStack {
                        Image(systemName: "wand.and.stars")
                            .foregroundColor(.indigo)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Neu befüllen")
                                .fontWeight(.semibold)
                                .foregroundColor(.indigo)
                            Text("Felder aus erfassten Daten aktualisieren")
                                .font(.caption).foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "arrow.clockwise")
                            .font(.caption).foregroundColor(.secondary)
                    }
                }
                .buttonStyle(.plain)
            }

            Group {
                sinnhaftSektion("S", farbe: .orange, titel: "Situation",
                                beschreibung: "Einsatznummer, Stichwort, Einsatzort",
                                text: $befund.situation, minHeight: 70)

                sinnhaftSektion("I", farbe: .blue, titel: "Identifikation",
                                beschreibung: "Einsatzmittel, Team, zuständige Einheit",
                                text: $befund.identifikation, minHeight: 60)

                sinnhaftSektion("N", farbe: .red, titel: "Notfallgeschehen",
                                beschreibung: "Was ist passiert? Hergang, Ursache",
                                text: $befund.notfall, minHeight: 80)

                sinnhaftSektion("N", farbe: .purple, titel: "Notwendige Maßnahmen",
                                beschreibung: "Durchgeführte Maßnahmen und Therapie",
                                text: $befund.notwendigeMassnahmen, minHeight: 80)

                sinnhaftSektion("H", farbe: .teal, titel: "Hintergrundinformationen",
                                beschreibung: "Vorerkrankungen, Medikamente, Anamnese",
                                text: $befund.hintergrund, minHeight: 70)

                sinnhaftSektion("A", farbe: .green, titel: "Aktueller Zustand",
                                beschreibung: "Vitaldaten, ABCDE-Ergebnis, Bewusstsein",
                                text: $befund.aktuellerZustand, minHeight: 70)

                sinnhaftSektion("F", farbe: .indigo, titel: "Forderungen / Folgeempfehlung",
                                beschreibung: "Benötigte Ressourcen, Verdachtsdiagnose",
                                text: $befund.forderung, minHeight: 60)

                sinnhaftSektion("T", farbe: Color("RDOrange"), titel: "Transport",
                                beschreibung: "Transportziel, -modus, Voranmeldung",
                                text: $befund.transport, minHeight: 60)
            }

        }
        .navigationTitle("SINNHAFT-Schema")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .safeAreaInset(edge: .bottom) {
            Button(action: onZurueck) {
                Label("Zurück zur Übersicht", systemImage: "checkmark.circle.fill")
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.borderedProminent)
            .tint(Color("RDOrange"))
            .padding([.horizontal, .bottom])
            .background(.bar)
        }
        .onAppear {
            let leer = befund.situation.isEmpty && befund.identifikation.isEmpty &&
                       befund.notfall.isEmpty && befund.notwendigeMassnahmen.isEmpty &&
                       befund.hintergrund.isEmpty && befund.aktuellerZustand.isEmpty &&
                       befund.forderung.isEmpty && befund.transport.isEmpty
            if leer { autoFill() }
        }
    }

    // MARK: - Header

    private var sinnhaftHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 3) {
                ForEach(
                    [("S", Color.orange), ("I", Color.blue), ("N", Color.red),
                     ("N", Color.purple), ("H", Color.teal), ("A", Color.green),
                     ("F", Color.indigo), ("T", Color("RDOrange"))],
                    id: \.0
                ) { letter, color in
                    Text(letter)
                        .font(.title2).fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(width: 34, height: 34)
                        .background(color)
                        .cornerRadius(8)
                }
            }
            Text("Strukturiertes Übergabe- und Kommunikationsschema")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }

    // MARK: - SINNHAFT Sektion

    private func sinnhaftSektion(
        _ buchstabe: String, farbe: Color, titel: String,
        beschreibung: String, text: Binding<String>, minHeight: CGFloat
    ) -> some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 10) {
                    Text(buchstabe)
                        .font(.title3).fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(farbe)
                        .cornerRadius(8)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(titel).font(.subheadline).fontWeight(.semibold)
                        Text(beschreibung).font(.caption).foregroundColor(.secondary)
                    }
                }
                TextEditor(text: text)
                    .frame(minHeight: minHeight)
                    .overlay(
                        Group {
                            if text.wrappedValue.isEmpty {
                                Text("Hier eingeben…")
                                    .foregroundColor(Color(.placeholderText))
                                    .padding(.horizontal, 4).padding(.vertical, 8)
                                    .allowsHitTesting(false)
                            }
                        }, alignment: .topLeading
                    )
            }
        }
    }

    // MARK: - Auto-Befüllung

    private func autoFill() {
        befund = SINNHAFTBefund.autoFilled(from: protokoll)
    }
}
