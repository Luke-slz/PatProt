import SwiftUI

// MARK: - Datenschicht

struct DiagnoseKategorie: Identifiable {
    let id = UUID()
    let name: String
    let diagnosen: [String]

    static let alle: [DiagnoseKategorie] = [
        DiagnoseKategorie(name: "ZNS Erkrankungen", diagnosen: [
            "Schlaganfall / Apoplex", "TIA (transitorische ischämische Attacke)",
            "Epilepsie / Krampfanfall", "Fieberkrampf", "Synkope",
            "Bewusstlosigkeit unklarer Genese", "Meningitis / Enzephalitis",
            "Migräne / Kopfschmerz", "Subarachnoidalblutung (SAB)"
        ]),
        DiagnoseKategorie(name: "Herz-Kreislauf Erkrankungen", diagnosen: [
            "ACS / Herzinfarkt (STEMI)", "ACS / Herzinfarkt (NSTEMI)",
            "Angina pectoris", "Herzrhythmusstörung", "Herzinsuffizienz / Dekompensation",
            "Hypertensive Krise", "Hypotonie / Schock", "Lungenembolie",
            "Synkope (kardial)", "Aortenaneurysma / Dissektion", "Perikarditis"
        ]),
        DiagnoseKategorie(name: "Atemwegserkrankungen", diagnosen: [
            "COPD-Exazerbation", "Asthma-Anfall", "Pneumonie",
            "Lungenödem (kardial)", "Lungenembolie", "Hyperventilation",
            "Fremdkörperaspiration", "Epiglottitis", "Krupp-Syndrom"
        ]),
        DiagnoseKategorie(name: "Abdominelle Erkrankungen", diagnosen: [
            "Akutes Abdomen", "Appendizitisverdacht", "Übelkeit / Erbrechen",
            "GI-Blutung (obere)", "GI-Blutung (untere)", "Nierenkolik",
            "Gallenkolik", "Ileus", "Ulkus-Perforation"
        ]),
        DiagnoseKategorie(name: "Psychiatrische Erkrankungen / Intoxikation", diagnosen: [
            "Akute Psychose / Erregungszustand", "Suizidversuch",
            "Alkoholintoxikation", "Medikamenten-Intoxikation",
            "Drogenintoxikation", "Panikattacke",
            "Psychiatrische Krise", "Manie", "Alkoholentzugsdelir"
        ]),
        DiagnoseKategorie(name: "Stoffwechsel Erkrankungen", diagnosen: [
            "Hypoglykämie", "Hyperglykämie", "Diabetisches Koma",
            "Elektrolytentgleisung", "Exsikkose / Dehydration",
            "Schilddrüsenkrise", "Addison-Krise", "Urämie"
        ]),
        DiagnoseKategorie(name: "Gyn-/Geburtshilfe Notfälle", diagnosen: [
            "Drohende / stattfindende Geburt", "Schwangerschaftskomplikation",
            "Eklampsie / Präeklampsie", "Extrauteringravidität",
            "Vaginale Blutung", "Fehlgeburt / Abort", "HELLP-Syndrom"
        ]),
        DiagnoseKategorie(name: "sonst. Erkrankungen", diagnosen: [
            "Allergische Reaktion (leicht)", "Anaphylaxie (schwer)",
            "Hitzeerschöpfung", "Hitzschlag", "Unterkühlung",
            "Ertrinken / Beinaheertrinken", "SIDS-Verdacht", "Palliativversorgung"
        ]),
        DiagnoseKategorie(name: "Infektionen", diagnosen: [
            "Sepsis / septischer Schock", "Fieber unklarer Genese",
            "Meningitis (bakteriell)", "Gastroenteritis",
            "Pneumonie (infektiös)", "COVID-19 / SARS",
            "Harnwegsinfekt / Urosepsis"
        ]),
        DiagnoseKategorie(name: "Traumen und Verletzungen", diagnosen: [
            "SHT leicht (Commotio)", "SHT mittel", "SHT schwer",
            "Wirbelsäulenverletzung", "Thoraxtrauma",
            "Abdominaltrauma", "Beckentrauma",
            "Extremitätentrauma", "Polytrauma",
            "Verbrennung / Verbrühung", "Stromunfall",
            "Tauchunfall / Barotrauma", "Einzelverletzung (oberflächlich)"
        ])
    ]
}

// MARK: - Hauptliste

struct DiagnoseView: View {
    @Binding var befund: DiagnoseBefund
    @State private var suche = ""
    @State private var zeigeNeuEingabe = false
    @State private var neuerName = ""
    @State private var neueWahrscheinlichkeit: DiagnoseWahrscheinlichkeit = .moeglich

    private var gefilterteKategorien: [DiagnoseKategorie] {
        guard !suche.isEmpty else { return DiagnoseKategorie.alle }
        let q = suche.lowercased()
        return DiagnoseKategorie.alle.compactMap { kat in
            let passendeDiagnosen = kat.diagnosen.filter { $0.lowercased().contains(q) }
            if kat.name.lowercased().contains(q) { return kat }
            if !passendeDiagnosen.isEmpty { return DiagnoseKategorie(name: kat.name, diagnosen: passendeDiagnosen) }
            return nil
        }
    }

    var body: some View {
        List {
            if !befund.verdachtsdiagnosen.isEmpty {
                Section("Ausgewählte Diagnosen") {
                    ForEach(befund.verdachtsdiagnosen) { eintrag in
                        HStack {
                            Image(systemName: eintrag.wahrscheinlichkeit.symbol)
                                .foregroundColor(eintrag.wahrscheinlichkeit.farbe)
                                .frame(width: 22)
                            Text(eintrag.name)
                            Spacer()
                            Button(role: .destructive) {
                                befund.verdachtsdiagnosen.removeAll { $0.id == eintrag.id }
                            } label: {
                                Image(systemName: "minus.circle.fill").foregroundColor(.red)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            ForEach(gefilterteKategorien, id: \.name) { kat in
                Section(kat.name) {
                    NavigationLink {
                        DiagnoseKategorieView(kategorie: kat, befund: $befund)
                    } label: {
                        HStack {
                            Text(kat.name)
                            Spacer()
                            let anzahl = befund.verdachtsdiagnosen
                                .filter { kat.diagnosen.contains($0.name) }.count
                            if anzahl > 0 {
                                Text("\(anzahl)")
                                    .font(.caption.weight(.bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 7).padding(.vertical, 3)
                                    .background(Color("RDOrange"))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
            }
        }
        .searchable(text: $suche, prompt: "Diagnose suchen")
        .navigationTitle("Diagnosen")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { zeigeNeuEingabe = true } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $zeigeNeuEingabe) {
            NavigationStack {
                Form {
                    Section { TextField("Diagnose / Verdacht", text: $neuerName) } header: { Text("Bezeichnung") }
                    Section {
                        Picker("Wahrscheinlichkeit", selection: $neueWahrscheinlichkeit) {
                            ForEach(DiagnoseWahrscheinlichkeit.allCases, id: \.self) { stufe in
                                Label(stufe.rawValue, systemImage: stufe.symbol).tag(stufe)
                            }
                        }
                        .pickerStyle(.inline)
                    } header: { Text("Einschätzung") }
                }
                .navigationTitle("Neue Diagnose")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Abbrechen") { zeigeNeuEingabe = false; neuerName = "" }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Speichern") {
                            let name = neuerName.trimmingCharacters(in: .whitespaces)
                            guard !name.isEmpty else { return }
                            befund.verdachtsdiagnosen.append(
                                VerdachtsdiagnoseEintrag(name: name, wahrscheinlichkeit: neueWahrscheinlichkeit, begruendung: "")
                            )
                            if neueWahrscheinlichkeit == .fuehrend { befund.leitsymptom = name }
                            zeigeNeuEingabe = false
                            neuerName = ""
                        }
                        .disabled(neuerName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }
}

// MARK: - Kategorie-Detailansicht

struct DiagnoseKategorieView: View {
    let kategorie: DiagnoseKategorie
    @Binding var befund: DiagnoseBefund

    @State private var zeigeWahrscheinlichkeit = false
    @State private var gewaehlterName = ""

    private func istGewaehlt(_ name: String) -> Bool {
        befund.verdachtsdiagnosen.contains { $0.name == name }
    }

    var body: some View {
        List {
            ForEach(kategorie.diagnosen, id: \.self) { diagnose in
                Button {
                    if istGewaehlt(diagnose) {
                        befund.verdachtsdiagnosen.removeAll { $0.name == diagnose }
                    } else {
                        gewaehlterName = diagnose
                        zeigeWahrscheinlichkeit = true
                    }
                } label: {
                    HStack {
                        Text(diagnose).foregroundColor(.primary)
                        Spacer()
                        if istGewaehlt(diagnose) {
                            let stufe = befund.verdachtsdiagnosen.first { $0.name == diagnose }?.wahrscheinlichkeit
                            Image(systemName: stufe?.symbol ?? "checkmark")
                                .foregroundColor(stufe?.farbe ?? Color("RDOrange"))
                        }
                    }
                }
            }
        }
        .navigationTitle(kategorie.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $zeigeWahrscheinlichkeit) {
            WahrscheinlichkeitPickerSheet(name: gewaehlterName) { stufe in
                befund.verdachtsdiagnosen.append(
                    VerdachtsdiagnoseEintrag(name: gewaehlterName, wahrscheinlichkeit: stufe, begruendung: "")
                )
                if stufe == .fuehrend { befund.leitsymptom = gewaehlterName }
            }
        }
    }
}

// MARK: - Wahrscheinlichkeit Picker Sheet

private struct WahrscheinlichkeitPickerSheet: View {
    let name: String
    let onAuswahl: (DiagnoseWahrscheinlichkeit) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(DiagnoseWahrscheinlichkeit.allCases, id: \.self) { stufe in
                    Button {
                        onAuswahl(stufe)
                        dismiss()
                    } label: {
                        Label(stufe.rawValue, systemImage: stufe.symbol)
                            .foregroundColor(stufe.farbe)
                    }
                }
            }
            .navigationTitle(name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}
