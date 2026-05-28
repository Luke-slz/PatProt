import SwiftUI

// MARK: - Hauptliste

struct NotfallgeschehenView: View {
    @Binding var befund: NotfallgeschehenBefund

    var body: some View {
        List {
            Section {
                NavigationLink {
                    UnfallhergangView(auswahl: $befund.unfallhergangAuswahl,
                                      freitext: $befund.unfallhergangFreitext)
                } label: {
                    NfgZeile(
                        titel: "Unfallhergang",
                        wert: befund.unfallhergangAuswahl.isEmpty
                            ? (befund.unfallhergangFreitext.isEmpty ? nil : befund.unfallhergangFreitext)
                            : befund.unfallhergangAuswahl.prefix(2).joined(separator: ", ")
                    )
                }
                NavigationLink {
                    UnfallmechanismusView(auswahl: $befund.unfallmechanismus,
                                          freitext: $befund.unfallmechanismusFreitext)
                } label: {
                    NfgZeile(
                        titel: "Unfallmechanismus",
                        wert: befund.unfallmechanismus.isEmpty ? nil : befund.unfallmechanismus
                    )
                }
            }

            Section {
                NavigationLink {
                    PreEmergencyStatusView(auswahl: $befund.preEmergencyStatus)
                } label: {
                    NfgZeile(
                        titel: "Pre Emergency Status",
                        wert: befund.preEmergencyStatus.isEmpty ? nil : befund.preEmergencyStatus
                    )
                }
            }

            Section {
                NavigationLink {
                    ErstbefundView(auswahl: $befund.erstbefundAuswahl,
                                   freitext: $befund.erstbefundVorOrt)
                } label: {
                    NfgZeile(
                        titel: "Erstbefund bei Ankunft",
                        wert: befund.erstbefundAuswahl.isEmpty
                            ? (befund.erstbefundVorOrt.isEmpty ? nil : befund.erstbefundVorOrt)
                            : befund.erstbefundAuswahl.prefix(2).joined(separator: ", ")
                    )
                }
            }

            Section {
                NavigationLink {
                    VerlaufsbemerkungView(bemerkung: $befund.verlaufsbemerkungen)
                } label: {
                    NfgZeile(
                        titel: "Verlaufsbemerkungen",
                        wert: befund.verlaufsbemerkungen.isEmpty ? nil : befund.verlaufsbemerkungen
                    )
                }
                NavigationLink {
                    DynamischeErweiterungView(befund: $befund)
                } label: {
                    NfgZeile(
                        titel: "Dynamische Erweiterung / MANV",
                        wert: befund.manv ? "MANV aktiv" : (befund.dynamischeErweiterung.isEmpty ? nil : "Erfasst")
                    )
                }
            }

            Section {
                NavigationLink {
                    AuffindewerteView(befund: $befund)
                } label: {
                    NfgZeile(
                        titel: "Auffindewerte",
                        wert: (befund.auffindePuls.isEmpty && befund.auffindeSpO2.isEmpty
                               && befund.auffindeRRSys.isEmpty && befund.auffindeBewusstsein.isEmpty)
                            ? nil
                            : [befund.auffindePuls.isEmpty ? nil : "Puls \(befund.auffindePuls)",
                               befund.auffindeSpO2.isEmpty ? nil : "SpO₂ \(befund.auffindeSpO2)%",
                               befund.auffindeRRSys.isEmpty ? nil : "RR \(befund.auffindeRRSys)/\(befund.auffindeRRDia)"]
                               .compactMap { $0 }.joined(separator: " · ")
                    )
                }
            }

            Section {
                Picker("NACA-Score", selection: Binding(
                    get: { befund.nacaScoreWert ?? NacaScore.naca3 },
                    set: { befund.nacaScoreWert = $0 }
                )) {
                    ForEach(NacaScore.allCases, id: \.self) { score in
                        Text(score.beschreibung).tag(score as NacaScore)
                    }
                }
                .pickerStyle(.inline)
                if befund.nacaScoreWert != nil {
                    Button(role: .destructive) {
                        befund.nacaScoreWert = nil
                    } label: {
                        Label("Auswahl aufheben", systemImage: "xmark.circle")
                    }
                }
            }
            Section {
                TextField("Ergänzungen / Sonstiges", text: $befund.notfallFreitext, axis: .vertical)
                    .lineLimit(3...6)
            } header: {
                Label("Freitext", systemImage: "text.alignleft")
            }
        }
        .navigationTitle("Notfallgeschehen")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Zeilenhelfer

private struct NfgZeile: View {
    let titel: String
    let wert: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(titel).font(.body)
            if let w = wert {
                Text(w)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            } else {
                Text("Nicht erfasst")
                    .font(.caption)
                    .foregroundColor(Color(.tertiaryLabel))
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Unfallhergang (Multi-Select)

struct UnfallhergangView: View {
    @Binding var auswahl: [String]
    @Binding var freitext: String

    private let traumaOptionen = [
        "KFZ-Insasse", "Motorradfahrer", "Fahrradfahrer", "Fußgänger",
        "Zug / Schiff", "Sturz >3 m", "Sturz <3 m",
        "Schlag (Gegenstand)", "Schuss", "Stich",
        "Gewaltverbrechen", "Maschinenunfall / Einklemmung", "Verschüttung"
    ]

    private let medizinischOptionen = [
        "Plötzlicher Kollaps", "Bewusstlosigkeit", "Krampfanfall",
        "Brustschmerz", "Atemnot", "Allergische Reaktion",
        "Suizidversuch", "Intoxikation", "Ertrinken / Beinaheertrinken"
    ]

    private let sonstigesOptionen = [
        "andere Unfallarten", "nicht bekannt"
    ]

    var body: some View {
        Form {
            AuswahlSection(titel: "Trauma", optionen: traumaOptionen, auswahl: $auswahl)
            AuswahlSection(titel: "Medizinisch", optionen: medizinischOptionen, auswahl: $auswahl)
            AuswahlSection(titel: "Sonstiges", optionen: sonstigesOptionen, auswahl: $auswahl)

            Section {
                TextField("Ergänzungen / Sonstiges", text: $freitext, axis: .vertical)
                    .lineLimit(3...6)
            } header: {
                Text("Freitext")
            }
        }
        .navigationTitle("Unfallhergang")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Unfallmechanismus (Single-Select)

struct UnfallmechanismusView: View {
    @Binding var auswahl: String
    @Binding var freitext: String

    private let optionen = [
        "Stumpfes Trauma", "Penetrierendes Trauma", "Explosionstrauma",
        "Verbrennung / Verbrühung", "Inhalationstrauma", "Elektrounfall",
        "Barotrauma", "Kein Trauma (internistisch)", "Unbekannt"
    ]

    var body: some View {
        Form {
            Section {
                ForEach(optionen, id: \.self) { option in
                    Button {
                        auswahl = (auswahl == option) ? "" : option
                    } label: {
                        HStack {
                            Text(option).foregroundColor(.primary)
                            Spacer()
                            if auswahl == option {
                                Image(systemName: "checkmark").foregroundColor(Color("RDOrange"))
                            }
                        }
                    }
                }
            }
            Section {
                TextField("Ergänzungen", text: $freitext, axis: .vertical)
                    .lineLimit(2...4)
            } header: {
                Text("Freitext")
            }
        }
        .navigationTitle("Unfallmechanismus")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Pre Emergency Status (Single-Select)

struct PreEmergencyStatusView: View {
    @Binding var auswahl: String

    private let optionen = [
        "Gut (selbstständig)",
        "Reduziert (hilfsbedürftig)",
        "Chronisch krank",
        "Demenziell verändert",
        "Pflegebedürftig",
        "Unbekannt"
    ]

    var body: some View {
        Form {
            Section {
                ForEach(optionen, id: \.self) { option in
                    Button {
                        auswahl = (auswahl == option) ? "" : option
                    } label: {
                        HStack {
                            Text(option).foregroundColor(.primary)
                            Spacer()
                            if auswahl == option {
                                Image(systemName: "checkmark").foregroundColor(Color("RDOrange"))
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Pre Emergency Status")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Erstbefund (Multi-Select + Freitext)

struct ErstbefundView: View {
    @Binding var auswahl: [String]
    @Binding var freitext: String

    private let optionen = [
        "Ansprechbar", "Verwirrt", "Bewusstlos",
        "Liegend", "Sitzend", "Stehend",
        "Schnappatmung", "Atemstillstand", "Pulslos", "Krampfend"
    ]

    var body: some View {
        Form {
            AuswahlSection(titel: "Zustand bei Erstkontakt", optionen: optionen, auswahl: $auswahl)
            Section {
                TextField("Freitext (Zustand bei Ankunft)", text: $freitext, axis: .vertical)
                    .lineLimit(3...8)
            } header: {
                Text("Ergänzungen")
            }
        }
        .navigationTitle("Erstbefund")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Verlaufsbemerkungen

struct VerlaufsbemerkungView: View {
    @Binding var bemerkung: String

    private let schnellauswahl = [
        "Stabil", "Leicht verbessert", "Verbessert",
        "Leicht verschlechtert", "Verschlechtert", "Kritisch verschlechtert"
    ]

    var body: some View {
        Form {
            Section {
                ForEach(schnellauswahl, id: \.self) { chip in
                    Button {
                        bemerkung = (bemerkung.trimmingCharacters(in: .whitespaces) == chip) ? "" : chip
                    } label: {
                        HStack {
                            Text(chip).foregroundColor(.primary)
                            Spacer()
                            if bemerkung.trimmingCharacters(in: .whitespaces) == chip {
                                Image(systemName: "checkmark").foregroundColor(Color("RDOrange"))
                            }
                        }
                    }
                }
            } header: {
                Text("Schnellauswahl")
            }
            Section {
                TextField("Freitext Verlauf", text: $bemerkung, axis: .vertical)
                    .lineLimit(3...8)
            } header: {
                Text("Freitext")
            }
        }
        .navigationTitle("Verlaufsbemerkungen")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Dynamische Erweiterung / MANV

struct DynamischeErweiterungView: View {
    @Binding var befund: NotfallgeschehenBefund

    var body: some View {
        Form {
            Section {
                TextField("Besonderheiten, Nachforderungen, Notizen…",
                          text: $befund.dynamischeErweiterung, axis: .vertical)
                    .lineLimit(4...12)
            } header: {
                Text("Dynamische Erweiterung")
            }

            Section {
                Stepper("Anzahl Beteiligte: \(befund.anzahlBeteiligte)",
                        value: $befund.anzahlBeteiligte, in: 1...999)
                Toggle("MANV-Lage", isOn: $befund.manv).tint(.red)
                if befund.manv {
                    Toggle("1. Eintreffende Kraft", isOn: $befund.ersteEintreffendeKraft)
                        .tint(Color("RDOrange"))
                }
            } header: {
                Label("Besonderheiten", systemImage: "exclamationmark.triangle.fill")
            }

            if befund.manv && befund.ersteEintreffendeKraft {
                Section {
                    SKZeile(farbe: .red,    kuerzel: "SK I",   bezeichnung: "Sofortige Behandlung",     count: $befund.manvSK1)
                    SKZeile(farbe: .yellow, kuerzel: "SK II",  bezeichnung: "Aufgeschobene Behandlung", count: $befund.manvSK2)
                    SKZeile(farbe: .green,  kuerzel: "SK III", bezeichnung: "Leicht verletzt",           count: $befund.manvSK3)
                    SKZeile(farbe: .blue,   kuerzel: "SK IV",  bezeichnung: "Ohne Überlebenschance",     count: $befund.manvSK4)
                    SKZeile(farbe: .gray,   kuerzel: "T",      bezeichnung: "Verstorben",                count: $befund.manvVerstorben)
                    HStack {
                        Text("Gesamt").fontWeight(.semibold)
                        Spacer()
                        Text("\(befund.manvGesamtSK) Personen").fontWeight(.semibold).foregroundColor(.secondary)
                    }
                } header: {
                    Label("Sichtungsergebnis", systemImage: "person.3.fill")
                } footer: {
                    Text("Anzahl direkt tippen oder mit + / − anpassen").font(.caption)
                }
            }

            if befund.manv {
                Section {
                    Picker("Eigene Sichtungskategorie", selection: $befund.manvEigeneSK) {
                        Text("–").tag("")
                        Text("SK I – Rot (sofort)").tag("SK I")
                        Text("SK II – Gelb (aufgeschoben)").tag("SK II")
                        Text("SK III – Grün (leicht verletzt)").tag("SK III")
                        Text("SK IV – Blau (ohne Überlebenschance)").tag("SK IV")
                        Text("T – Schwarz (verstorben)").tag("T")
                    }
                    .pickerStyle(.menu)
                } header: { Label("Eigene Sichtungskategorie", systemImage: "tag.fill") }
            }

            if befund.manv {
                Section {
                    TextField("Lagemeldung an Leitstelle", text: $befund.manvLagemeldung, axis: .vertical)
                        .lineLimit(2...5)
                    TextField("Nachgeforderte Kräfte / Mittel", text: $befund.manvNachforderung)
                } header: {
                    Label("MANV-Meldung", systemImage: "megaphone.fill")
                }
            }
        }
        .navigationTitle("Dyn. Erweiterung / MANV")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - SKZeile

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
                Text(kuerzel).font(.caption).fontWeight(.bold)
                    .foregroundColor(farbe == .yellow ? .black : farbe)
            }
            Text(bezeichnung).font(.subheadline)
            Spacer()
            HStack(spacing: 0) {
                Button { if count > 0 { count -= 1 } } label: {
                    Image(systemName: "minus.circle.fill").font(.title2)
                        .foregroundColor(count > 0 ? farbe : .secondary)
                }.buttonStyle(.plain)
                Text("\(count)").font(.title3).fontWeight(.semibold)
                    .frame(minWidth: 36, alignment: .center)
                    .contentShape(Rectangle())
                    .onTapGesture { zeigeNumpad = true }
                Button { count += 1 } label: {
                    Image(systemName: "plus.circle.fill").font(.title2).foregroundColor(farbe)
                }.buttonStyle(.plain)
            }
        }
        .sheet(isPresented: $zeigeNumpad) {
            NumpadSheet(mode: .integer(label: kuerzel, unit: "Personen", maxDigits: 3),
                        initial: "\(count)") { val in count = Int(val) ?? count }
        }
    }
}

// MARK: - AuswahlSection Helper (Multi-Select)

private struct AuswahlSection: View {
    let titel: String
    let optionen: [String]
    @Binding var auswahl: [String]

    var body: some View {
        Section(titel) {
            ForEach(optionen, id: \.self) { option in
                Button {
                    if auswahl.contains(option) {
                        auswahl.removeAll { $0 == option }
                    } else {
                        auswahl.append(option)
                    }
                } label: {
                    HStack {
                        Text(option).foregroundColor(.primary)
                        Spacer()
                        if auswahl.contains(option) {
                            Image(systemName: "checkmark").foregroundColor(Color("RDOrange"))
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Auffindewerte

struct AuffindewerteView: View {
    @Binding var befund: NotfallgeschehenBefund

    @State private var zeigePulsNumpad  = false
    @State private var zeigeSpO2Numpad  = false
    @State private var zeigeAFNumpad    = false
    @State private var zeigeRRNumpad    = false

    var body: some View {
        Form {
            Section {
                HStack {
                    Text("Puls (/min)").foregroundStyle(.secondary)
                    Spacer()
                    Text(befund.auffindePuls.isEmpty ? "–" : "\(befund.auffindePuls) /min")
                        .foregroundStyle(befund.auffindePuls.isEmpty ? Color(.tertiaryLabel) : .primary)
                }
                .contentShape(Rectangle())
                .onTapGesture { zeigePulsNumpad = true }
                .sheet(isPresented: $zeigePulsNumpad) {
                    NumpadSheet(mode: .integer(label: "Puls", unit: "/min", maxDigits: 3),
                                initial: befund.auffindePuls) { val in befund.auffindePuls = val }
                }

                HStack {
                    Text("SpO₂ (%)").foregroundStyle(.secondary)
                    Spacer()
                    Text(befund.auffindeSpO2.isEmpty ? "–" : "\(befund.auffindeSpO2) %")
                        .foregroundStyle(befund.auffindeSpO2.isEmpty ? Color(.tertiaryLabel) : .primary)
                }
                .contentShape(Rectangle())
                .onTapGesture { zeigeSpO2Numpad = true }
                .sheet(isPresented: $zeigeSpO2Numpad) {
                    NumpadSheet(mode: .integer(label: "SpO₂", unit: "%", maxDigits: 3),
                                initial: befund.auffindeSpO2) { val in befund.auffindeSpO2 = val }
                }

                HStack {
                    Text("RR (mmHg)").foregroundStyle(.secondary)
                    Spacer()
                    Text(befund.auffindeRRSys.isEmpty ? "–" : "\(befund.auffindeRRSys)/\(befund.auffindeRRDia) mmHg")
                        .foregroundStyle(befund.auffindeRRSys.isEmpty ? Color(.tertiaryLabel) : .primary)
                }
                .contentShape(Rectangle())
                .onTapGesture { zeigeRRNumpad = true }
                .sheet(isPresented: $zeigeRRNumpad) {
                    NumpadSheet(mode: .bloodPressure,
                                initial: befund.auffindeRRSys.isEmpty ? "" : "\(befund.auffindeRRSys)/\(befund.auffindeRRDia)") { val in
                        let parts = val.split(separator: "/")
                        if parts.count == 2 {
                            befund.auffindeRRSys = String(parts[0])
                            befund.auffindeRRDia = String(parts[1])
                        } else if val.isEmpty {
                            befund.auffindeRRSys = ""
                            befund.auffindeRRDia = ""
                        }
                    }
                }

                HStack {
                    Text("AF (/min)").foregroundStyle(.secondary)
                    Spacer()
                    Text(befund.auffindeAF.isEmpty ? "–" : "\(befund.auffindeAF) /min")
                        .foregroundStyle(befund.auffindeAF.isEmpty ? Color(.tertiaryLabel) : .primary)
                }
                .contentShape(Rectangle())
                .onTapGesture { zeigeAFNumpad = true }
                .sheet(isPresented: $zeigeAFNumpad) {
                    NumpadSheet(mode: .integer(label: "AF", unit: "/min", maxDigits: 2),
                                initial: befund.auffindeAF) { val in befund.auffindeAF = val }
                }
            } header: { Text("Messwerte bei Erstkontakt") }

            Section {
                TextField("AVPU / Freitext (z.B. A, V, P, U)", text: $befund.auffindeBewusstsein)
            } header: { Text("Bewusstsein") }

            Section {
                TextField("Ergänzungen", text: $befund.auffindeFreitext, axis: .vertical)
                    .lineLimit(3...6)
            } header: { Text("Freitext") }
        }
        .navigationTitle("Auffindewerte")
        .navigationBarTitleDisplayMode(.inline)
    }
}
