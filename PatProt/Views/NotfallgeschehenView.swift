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
                    TextField("", text: $befund.patientGefunden)
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
                        value: $befund.anzahlBeteiligte, in: 1...999)
                Toggle("MANV-Lage", isOn: $befund.manv)
                    .tint(.red)

                if befund.manv {
                    Toggle("1. Eintreffende Kraft", isOn: $befund.ersteEintreffendeKraft)
                        .tint(Color("RDOrange"))
                }
            } header: {
                Label("Besonderheiten", systemImage: "exclamationmark.triangle.fill")
            }

            // MANV-Sichtung (nur wenn MANV + 1. Eintreffend)
            if befund.manv && befund.ersteEintreffendeKraft {
                Section {
                    SKZeile(farbe: .red,    kuerzel: "SK I",
                            bezeichnung: "Sofortige Behandlung",
                            count: $befund.manvSK1)
                    SKZeile(farbe: .yellow, kuerzel: "SK II",
                            bezeichnung: "Aufgeschobene Behandlung",
                            count: $befund.manvSK2)
                    SKZeile(farbe: .green,  kuerzel: "SK III",
                            bezeichnung: "Leicht verletzt",
                            count: $befund.manvSK3)
                    SKZeile(farbe: .blue,   kuerzel: "SK IV",
                            bezeichnung: "Ohne Überlebenschance",
                            count: $befund.manvSK4)
                    SKZeile(farbe: .gray,   kuerzel: "T",
                            bezeichnung: "Verstorben",
                            count: $befund.manvVerstorben)

                    HStack {
                        Text("Gesamt").fontWeight(.semibold)
                        Spacer()
                        Text("\(befund.manvGesamtSK) Personen")
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Label("Sichtungsergebnis", systemImage: "person.3.fill")
                } footer: {
                    Text("Anzahl direkt tippen oder mit + / − anpassen")
                        .font(.caption)
                }
            }

            // MANV-Meldung (nur wenn MANV aktiv)
            if befund.manv {
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Label("Lagemeldung", systemImage: "antenna.radiowaves.left.and.right")
                            .font(.subheadline).fontWeight(.semibold)
                        Text("Erstmeldung an Leitstelle / Führung")
                            .font(.caption).foregroundColor(.secondary)
                        TextEditor(text: $befund.manvLagemeldung)
                            .frame(minHeight: 70)
                    }
                    TextField("Nachgeforderte Kräfte / Mittel", text: $befund.manvNachforderung)
                } header: {
                    Label("MANV-Meldung", systemImage: "megaphone.fill")
                }
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

// MARK: - SK-Zeile

private struct SKZeile: View {
    let farbe: Color
    let kuerzel: String
    let bezeichnung: String
    @Binding var count: Int
    @State private var zeigeNumpad = false

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(farbe == .yellow ? Color.yellow : farbe.opacity(0.15))
                    .frame(width: 44, height: 32)
                Text(kuerzel)
                    .font(.caption).fontWeight(.bold)
                    .foregroundColor(farbe == .yellow ? .black : farbe)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(bezeichnung)
                    .font(.subheadline)
            }
            Spacer()
            HStack(spacing: 0) {
                Button { if count > 0 { count -= 1 } } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .foregroundColor(count > 0 ? farbe : .secondary)
                }
                .buttonStyle(.plain)

                Text("\(count)")
                    .font(.title3).fontWeight(.semibold)
                    .frame(minWidth: 36, alignment: .center)
                    .contentShape(Rectangle())
                    .onTapGesture { zeigeNumpad = true }

                Button { count += 1 } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(farbe)
                }
                .buttonStyle(.plain)
            }
        }
        .sheet(isPresented: $zeigeNumpad) {
            NumpadSheet(mode: .integer(label: kuerzel, unit: "Personen", maxDigits: 3),
                        initial: "\(count)") { val in count = Int(val) ?? count }
        }
    }
}
