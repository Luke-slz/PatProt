import SwiftUI

// MARK: - Einsatzort & Patient

struct EinsatzOrtView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var protokoll: EinsatzProtokoll
    @StateObject private var locationManager = LocationManager()
    var onWeiter: () -> Void
    var onBack: () -> Void
    var onMenuOpen: (() -> Void)? = nil
    

    @AppStorage("gespeichertesPersonal") private var personalJSON: String = "[]"
    @AppStorage("customFahrzeuge") private var customFahrzeugeJSON: String = "[]"

    @State private var geburtsdatumText: String = ""
    @State private var zeigeWeiteresEinsatzmittel = false
    @State private var neuesEinsatzmittel = ""
    @State private var zeigeStichwortPicker = false
    @State private var primärfahrzeugName: String = ""
    @State private var zeigeEinsatzNrNumpad = false
    @State private var zeigeGewichtNumpad = false
    @State private var zeigeGeburtsdatumNumpad = false

    private var zeitFehler: [String] {
        let alarm = protokoll.einsatzOrt.alarmzeit
        let ankunft = protokoll.einsatzOrt.ankunftzeit
        let abfahrt = protokoll.einsatzOrt.abfahrtzeit
        let kh = protokoll.einsatzOrt.krankenHausAnkunft
        var fehler: [String] = []
        if let a = alarm, let b = ankunft, b < a { fehler.append("Ankunft liegt vor der Alarmzeit") }
        if let a = ankunft, let b = abfahrt, b < a { fehler.append("Abfahrt liegt vor der Ankunft") }
        if let a = abfahrt, let b = kh, b < a { fehler.append("KH-Ankunft liegt vor der Abfahrt") }
        return fehler
    }

    private var gespeichertesPersonal: [String] {
        (try? JSONDecoder().decode([String].self, from: Data(personalJSON.utf8))) ?? []
    }

    private var customFahrzeuge: [String] {
        (try? JSONDecoder().decode([String].self, from: Data(customFahrzeugeJSON.utf8))) ?? []
    }

    var body: some View {
        Form {

            // MARK: Einsatzort
            Section {
                TextField("Straße und Hausnummer", text: $protokoll.einsatzOrt.adresse)
                TextField("Zusatz (Stockwerk, Wohnung...)", text: $protokoll.einsatzOrt.zusatz)
                HStack {
                    Text("Einsatz-Nr.")
                    Spacer()
                    Text(protokoll.einsatzOrt.einsatzNummer.isEmpty ? "—" : protokoll.einsatzOrt.einsatzNummer)
                        .foregroundColor(protokoll.einsatzOrt.einsatzNummer.isEmpty ? .secondary : .primary)
                }
                .contentShape(Rectangle())
                .onTapGesture { zeigeEinsatzNrNumpad = true }
                Button {
                    locationManager.requestLocation()
                } label: {
                    HStack {
                        Image(systemName: locationManager.isLoading ? "location.slash" : "location.fill")
                            .foregroundStyle(locationManager.isLoading ? .gray : .blue)
                        Text(locationManager.isLoading ? "Ermittle Standort…" : "Standort ermitteln")
                            .foregroundStyle(locationManager.isLoading ? .gray : .blue)
                        if locationManager.isLoading {
                            Spacer()
                            ProgressView()
                        }
                    }
                }
                .disabled(locationManager.isLoading)
                if let fehler = locationManager.locationError {
                    Text(fehler)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            } header: {
                Label("Einsatzort", systemImage: "mappin.circle")
            }

            // MARK: Einsatzart + Fahrzeuge
            Section {
                HStack {
                    TextField("Einsatzart (z.B. NOTF01)", text: $protokoll.einsatzOrt.stichwort)
                    Button { zeigeStichwortPicker = true } label: {
                        Image(systemName: "list.bullet").foregroundStyle(Color("RDOrange"))
                    }
                    .buttonStyle(.plain)
                }
                TextField("Stichwort (z.B. Bewusstlos)", text: $protokoll.einsatzOrt.einsatzArt)
                Toggle("Sondersignal", isOn: $protokoll.einsatzOrt.sondersignal)
                Toggle("Notarzt", isOn: $protokoll.einsatzOrt.notarzt)
                Toggle("mit Patient", isOn: $protokoll.einsatzOrt.mitPatient)

                Picker("Primärfahrzeug", selection: $protokoll.einsatzOrt.fahrzeugName) {
                    Text("—").tag("")
                    ForEach(customFahrzeuge, id: \.self) { fz in
                        Text(fz).tag(fz)
                    }
                }

                // Weitere Einsatzmittel
                ForEach(protokoll.einsatzOrt.weitereEinsatzmittel, id: \.self) { fz in
                    HStack {
                        Image(systemName: "car.2").foregroundStyle(.secondary)
                        Text(fz)
                        Spacer()
                        Button(role: .destructive) {
                            protokoll.einsatzOrt.weitereEinsatzmittel.removeAll { $0 == fz }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundStyle(.red)
                        }
                        .buttonStyle(.plain)
                    }
                }

                Button {
                    neuesEinsatzmittel = ""
                    zeigeWeiteresEinsatzmittel = true
                } label: {
                    Label("Weiteres Einsatzmittel hinzufügen", systemImage: "plus.circle")
                }
            } header: {
                Label("Einsatzart & Fahrzeuge", systemImage: "exclamationmark.triangle")
            }

            // MARK: Zeiten
            Section {
                DatePicker(
                    "Alarmdatum",
                    selection: Binding(
                        get: { protokoll.einsatzOrt.alarmzeit ?? Date() },
                        set: { protokoll.einsatzOrt.alarmzeit = $0 }
                    ),
                    displayedComponents: .date
                )
                ZeitFeld(label: "Alarmzeit", datum: $protokoll.einsatzOrt.alarmzeit)
                ZeitFeld(label: "Ankunft Patient", datum: $protokoll.einsatzOrt.ankunftzeit)
                ZeitFeld(label: "Abfahrt Einsatzstelle", datum: $protokoll.einsatzOrt.abfahrtzeit)
                ZeitFeld(label: "Übergabe an RD", datum: $protokoll.einsatzOrt.krankenHausAnkunft)
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

            // MARK: Patient
            Section {
                TextField("Vorname", text: $protokoll.patientDaten.vorname)
                TextField("Nachname", text: $protokoll.patientDaten.nachname)
                Picker("Geschlecht", selection: $protokoll.patientDaten.geschlecht) {
                    ForEach(Geschlecht.allCases, id: \.self) { g in
                        Text(g.rawValue).tag(g)
                    }
                }
                HStack {
                    Text("Geburtsdatum")
                    Spacer()
                    Text(geburtsdatumText.isEmpty ? "TT.MM.JJJJ" : geburtsdatumText)
                        .foregroundColor(geburtsdatumText.isEmpty ? .secondary : .primary)
                }
                .contentShape(Rectangle())
                .onTapGesture { zeigeGeburtsdatumNumpad = true }
                TextField("Versicherungsnummer", text: $protokoll.patientDaten.versicherungsNummer)
                TextField("Kostenträger / Krankenkasse", text: $protokoll.patientDaten.kostentraeger)
            } header: {
                Label("Patient", systemImage: "person.circle")
            }

            // MARK: Klinische Angaben
            Section {
                HStack {
                    Text("Gewicht")
                    Spacer()
                    Text(protokoll.patientDaten.gewicht.map { String(format: "%.1f kg", $0) } ?? "—")
                        .foregroundColor(protokoll.patientDaten.gewicht == nil ? .secondary : .primary)
                }
                .contentShape(Rectangle())
                .onTapGesture { zeigeGewichtNumpad = true }
                Toggle("Ansprechbar", isOn: $protokoll.patientDaten.ansprechbar)
            } header: {
                Label("Klinische Angaben", systemImage: "stethoscope")
            }

            // MARK: Besatzung
            Section {
                BesatzungsFeld(label: "Sanitäter 1", text: $protokoll.besatzung.sanitaeter1)
                BesatzungsFeld(label: "Sanitäter 2", text: $protokoll.besatzung.sanitaeter2)
                BesatzungsFeld(label: "Sanitäter 3", text: $protokoll.besatzung.sanitaeter3)
                BesatzungsFeld(label: "Sanitäter 4", text: $protokoll.besatzung.sanitaeter4)
            } header: {
                Label("Besatzung", systemImage: "person.2")
            } footer: {
                if !gespeichertesPersonal.isEmpty {
                    Text("Tippe auf \(Image(systemName: "person.badge.plus")) um aus gespeichertem Personal auszuwählen.")
                        .font(.footnote).foregroundStyle(.secondary)
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
        .onAppear {
            if let geb = protokoll.patientDaten.geburtsDatum {
                let f = DateFormatter()
                f.dateFormat = "dd.MM.yyyy"
                geburtsdatumText = f.string(from: geb)
            }
        }
        .onChange(of: locationManager.address) { _, newAddress in
            if !newAddress.isEmpty {
                protokoll.einsatzOrt.adresse = newAddress
            }
        }
        .navigationTitle("Rettungstechnische Daten")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            if let openMenu = onMenuOpen {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: openMenu) {
                        Image(systemName: "line.3.horizontal").font(.title3)
                    }
                }
            }
        }
        .sheet(isPresented: $zeigeWeiteresEinsatzmittel) {
            EinsatzmittelPickerSheet(
                customFahrzeuge: customFahrzeuge,
                onAuswahl: { name in
                    if !protokoll.einsatzOrt.weitereEinsatzmittel.contains(name) {
                        protokoll.einsatzOrt.weitereEinsatzmittel.append(name)
                    }
                }
            )
        }
        .sheet(isPresented: $zeigeStichwortPicker) {
            StichwortPickerSheet(
                code: $protokoll.einsatzOrt.stichwort,
                beschreibung: $protokoll.einsatzOrt.einsatzArt
            )
        }
        .sheet(isPresented: $zeigeEinsatzNrNumpad) {
            NumpadSheet(mode: .integer(label: "Einsatz-Nr.", unit: "", maxDigits: 10),
                        initial: protokoll.einsatzOrt.einsatzNummer) { val in
                protokoll.einsatzOrt.einsatzNummer = val
            }
        }
        .sheet(isPresented: $zeigeGeburtsdatumNumpad) {
            NumpadSheet(mode: .date(label: "Geburtsdatum"),
                        initial: geburtsdatumText) { dateStr in
                geburtsdatumText = dateStr
                let formatter = DateFormatter()
                formatter.dateFormat = "dd.MM.yyyy"
                if let date = formatter.date(from: dateStr) {
                    protokoll.patientDaten.geburtsDatum = date
                }
            }
        }
        .sheet(isPresented: $zeigeGewichtNumpad) {
            NumpadSheet(mode: .decimal(label: "Gewicht", unit: "kg"),
                        initial: protokoll.patientDaten.gewicht.map { String(format: "%.1f", $0) } ?? "") { val in
                protokoll.patientDaten.gewicht = Double(val.replacingOccurrences(of: ",", with: "."))
            }
        }
    }
}

// MARK: - Besatzungsfeld mit Personal-Picker

struct BesatzungsFeld: View {
    let label: String
    @Binding var text: String
    @AppStorage("gespeichertesPersonal") private var personalJSON: String = "[]"
    @State private var zeigePickerSheet = false

    private var personal: [String] {
        (try? JSONDecoder().decode([String].self, from: Data(personalJSON.utf8))) ?? []
    }

    var body: some View {
        HStack {
            TextField(label, text: $text)
            if !personal.isEmpty {
                Button {
                    zeigePickerSheet = true
                } label: {
                    Image(systemName: "person.badge.plus")
                        .foregroundStyle(Color("RDOrange"))
                }
                .buttonStyle(.plain)
            }
        }
        .sheet(isPresented: $zeigePickerSheet) {
            PersonalPickerSheet(ausgewählt: $text, personal: personal)
        }
    }
}

// MARK: - Personal-Picker Sheet

struct PersonalPickerSheet: View {
    @Binding var ausgewählt: String
    let personal: [String]
    @Environment(\.dismiss) private var dismiss
    @State private var manuell = ""

    var body: some View {
        NavigationStack {
            List {
                if !personal.isEmpty {
                    Section("Gespeichertes Personal") {
                        ForEach(personal, id: \.self) { person in
                            Button {
                                ausgewählt = person
                                dismiss()
                            } label: {
                                HStack {
                                    Text(person)
                                    Spacer()
                                    if ausgewählt == person {
                                        Image(systemName: "checkmark").foregroundStyle(Color("RDOrange"))
                                    }
                                }
                            }
                            .foregroundStyle(.primary)
                        }
                    }
                }
                Section(personal.isEmpty ? "Namen eingeben" : "Manuell eingeben") {
                    HStack {
                        TextField("Name eingeben", text: $manuell)
                        Button("Übernehmen") {
                            let v = manuell.trimmingCharacters(in: .whitespaces)
                            if !v.isEmpty {
                                ausgewählt = v
                                dismiss()
                            }
                        }
                        .disabled(manuell.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }
            .navigationTitle("Person auswählen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Einsatzmittel-Picker Sheet

struct EinsatzmittelPickerSheet: View {
    let customFahrzeuge: [String]
    let onAuswahl: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var manuell = ""

    var body: some View {
        NavigationStack {
            List {
                if !customFahrzeuge.isEmpty {
                    Section("Eigene Fahrzeuge") {
                        ForEach(customFahrzeuge, id: \.self) { fz in
                            Button(fz) {
                                onAuswahl(fz)
                                dismiss()
                            }
                            .foregroundStyle(.primary)
                        }
                    }
                }
                Section("Manuell eingeben") {
                    HStack {
                        TextField("Fahrzeugbezeichnung", text: $manuell)
                        Button("Hinzufügen") {
                            let v = manuell.trimmingCharacters(in: .whitespaces)
                            if !v.isEmpty {
                                onAuswahl(v)
                                dismiss()
                            }
                        }
                        .disabled(manuell.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }
            .navigationTitle("Einsatzmittel")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Stichwort Datenmodell

struct Stichwort: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var stichwort: String
    var diagnose: String
    var kategorie: String
}

enum StichwortStore {
    static let key = "alleStichworter"

    static var defaults: [Stichwort] {
        StichwortPickerSheet.defaultEinträge.map {
            Stichwort(stichwort: $0.0, diagnose: $0.1, kategorie: $0.2)
        }
    }

    static func laden() -> [Stichwort] {
        guard let json = UserDefaults.standard.string(forKey: key),
              let data = json.data(using: .utf8),
              let liste = try? JSONDecoder().decode([Stichwort].self, from: data),
              !liste.isEmpty
        else { return defaults }
        return liste
    }

    static func speichern(_ liste: [Stichwort]) {
        let json = (try? String(data: JSONEncoder().encode(liste), encoding: .utf8)) ?? "[]"
        UserDefaults.standard.set(json, forKey: key)
    }
}

// MARK: - Stichwort-Picker Sheet

private struct EinsatzEintrag: Identifiable {
    let id = UUID()
    let stichwort: String
    let diagnose: String
    let kategorie: String
}

struct StichwortPickerSheet: View {
    @Binding var code: String
    @Binding var beschreibung: String
    @Environment(\.dismiss) private var dismiss
    @State private var suche = ""
    @AppStorage(StichwortStore.key) private var storeJSON: String = "[]"

    static let stichwörter: [(String, String)] = defaultEinträge.map { ($0.0, $0.1) }

    static let defaultEinträge: [(String, String, String)] = [
        // MARK: Reanimation
        ("NOTF 11 Rea", "Reanimation",                              "Reanimation"),
        ("NOTF 11 Rea", "Reanimation, telefonisch angeleitet",      "Reanimation"),
        ("NOTF 11 Rea", "Reanimation, laufend / intermittierend",   "Reanimation"),
        ("NOTF 11 Rea", "Rea ohne ROSC",                            "Reanimation"),

        // MARK: Kritische Notfälle – NEF + RTW (NOTF 11)
        ("NOTF 11", "Bewusstlose Person",                           "Kritisch (NOTF 11)"),
        ("NOTF 11", "Päd. – Bewusstlos",                            "Kritisch (NOTF 11)"),
        ("NOTF 11", "Vigilanzminderung / Koma",                     "Kritisch (NOTF 11)"),
        ("NOTF 11", "Schlaganfall / Apoplex",                       "Kritisch (NOTF 11)"),
        ("NOTF 11", "Krampfanfall, anhaltend",                      "Kritisch (NOTF 11)"),
        ("NOTF 11", "Akute Atemnot",                                "Kritisch (NOTF 11)"),
        ("NOTF 11", "pädiatrisch – Atemnot",                        "Kritisch (NOTF 11)"),
        ("NOTF 11", "pädiatrisch – Fieberkrampf",                   "Kritisch (NOTF 11)"),
        ("NOTF 11", "STEMI",                                        "Kritisch (NOTF 11)"),
        ("NOTF 11", "NSTEMI / instabile AP",                        "Kritisch (NOTF 11)"),
        ("NOTF 11", "Kardiogener Schock",                           "Kritisch (NOTF 11)"),
        ("NOTF 11", "Herzinsuffizienz, akut",                       "Kritisch (NOTF 11)"),
        ("NOTF 11", "Arrhythmie",                                   "Kritisch (NOTF 11)"),
        ("NOTF 11", "Bradykardie",                                  "Kritisch (NOTF 11)"),
        ("NOTF 11", "Tachykardie",                                  "Kritisch (NOTF 11)"),
        ("NOTF 11", "Hypertensiver Notfall",                        "Kritisch (NOTF 11)"),
        ("NOTF 11", "Lungenembolie",                                "Kritisch (NOTF 11)"),
        ("NOTF 11", "Anaphylaktischer Schock",                      "Kritisch (NOTF 11)"),
        ("NOTF 11", "Anaphylaxie / Unverträglichkeitsreaktion",     "Kritisch (NOTF 11)"),
        ("NOTF 11", "Polytrauma mit SHT",                           "Kritisch (NOTF 11)"),
        ("NOTF 11", "Polytrauma ohne SHT",                          "Kritisch (NOTF 11)"),
        ("NOTF 11", "Trauma schwer",                                "Kritisch (NOTF 11)"),
        ("NOTF 11", "Inhalationstrauma",                            "Kritisch (NOTF 11)"),
        ("NOTF 11", "Kohlenmonoxid-Vergiftung",                     "Kritisch (NOTF 11)"),
        ("NOTF 11", "Pflanzenschutzmittel-Vergiftung",              "Kritisch (NOTF 11)"),
        ("NOTF 11", "Rauchgas / Reizgas",                           "Kritisch (NOTF 11)"),
        ("NOTF 11", "Sepsis",                                       "Kritisch (NOTF 11)"),
        ("NOTF 11", "Meningitis / Enzephalitis",                    "Kritisch (NOTF 11)"),
        ("NOTF 11", "Ertrinkung / Badeunfall",                      "Kritisch (NOTF 11)"),
        ("NOTF 11", "Mischintoxikation Alkohol / Drogen",           "Kritisch (NOTF 11)"),
        ("NOTF 11", "Aortenaneurysma / Dissektion",                 "Kritisch (NOTF 11)"),
        ("NOTF 11", "Geburt präklinisch",                           "Kritisch (NOTF 11)"),

        // MARK: Notfall – RTW (NOTF 01)
        ("NOTF 01", "Somnolente Person",                            "Notfall (NOTF 01)"),
        ("NOTF 01", "Hilflose Person",                              "Notfall (NOTF 01)"),
        ("NOTF 01", "unklarer Einsatzgrund",                        "Notfall (NOTF 01)"),
        ("NOTF 01", "Krampfanfall, stattgefunden",                  "Notfall (NOTF 01)"),
        ("NOTF 01", "Synkope / Kollaps",                            "Notfall (NOTF 01)"),
        ("NOTF 01", "Hypoglycämie",                                 "Notfall (NOTF 01)"),
        ("NOTF 01", "Hyperventilation",                             "Notfall (NOTF 01)"),
        ("NOTF 01", "Obstruktion (Asthma / COPD)",                  "Notfall (NOTF 01)"),
        ("NOTF 01", "Hypotonie",                                    "Notfall (NOTF 01)"),
        ("NOTF 01", "unklarer Brust- / Thoraxschmerz",             "Notfall (NOTF 01)"),
        ("NOTF 01", "Akutes Abdomen",                               "Notfall (NOTF 01)"),
        ("NOTF 01", "Bauchschmerzen",                               "Notfall (NOTF 01)"),
        ("NOTF 01", "unklares Fieber",                              "Notfall (NOTF 01)"),
        ("NOTF 01", "Psychischer Ausnahmezustand",                  "Notfall (NOTF 01)"),
        ("NOTF 01", "Suizid, angedroht",                            "Notfall (NOTF 01)"),
        ("NOTF 01", "Exsikkose",                                    "Notfall (NOTF 01)"),
        ("NOTF 01", "Alkoholentzug",                                "Notfall (NOTF 01)"),
        ("NOTF 01", "Fruchtwasserabgang (ohne Wehen)",              "Notfall (NOTF 01)"),
        ("NOTF 01", "Harnverhalt (akut)",                           "Notfall (NOTF 01)"),
        ("NOTF 01", "Urologischer Notfall",                         "Notfall (NOTF 01)"),
        ("NOTF 01", "Akute Augenerkrankung",                        "Notfall (NOTF 01)"),

        // MARK: Trauma / Verletzung – RTW (NOTF 01)
        ("NOTF 01", "Trauma allgemein",                             "Trauma (NOTF 01)"),
        ("NOTF 01", "Verletzung unklar",                            "Trauma (NOTF 01)"),
        ("NOTF 01", "Blutung leicht",                               "Trauma (NOTF 01)"),
        ("NOTF 01", "Blutung stark",                                "Trauma (NOTF 01)"),
        ("NOTF 01", "Stich- / Schnittverletzung",                   "Trauma (NOTF 01)"),
        ("NOTF 01", "Verbrennung / Verbrühung leicht",              "Trauma (NOTF 01)"),
        ("NOTF 11", "Verbrennung / Verbrühung schwer",              "Trauma (NOTF 01)"),
        ("NOTF 01", "Kopfverletzung",                               "Trauma (NOTF 01)"),
        ("NOTF 01", "Gesichtsverletzung",                           "Trauma (NOTF 01)"),
        ("NOTF 01", "Augenverletzung",                              "Trauma (NOTF 01)"),
        ("NOTF 01", "Rippenverletzung",                             "Trauma (NOTF 01)"),
        ("NOTF 01", "Rückenschmerzen",                              "Trauma (NOTF 01)"),
        ("NOTF 01", "Extremitätenverletzung",                       "Trauma (NOTF 01)"),
        ("NOTF 01", "Handverletzung",                               "Trauma (NOTF 01)"),
        ("NOTF 01", "Fußverletzung",                                "Trauma (NOTF 01)"),
        ("NOTF 01", "Hüft- / Schenkelhalsfraktur",                  "Trauma (NOTF 01)"),
        ("NOTF 01", "Hausunfall",                                   "Trauma (NOTF 01)"),
        ("NOTF 01", "Schulunfall",                                  "Trauma (NOTF 01)"),
        ("NOTF 01", "Sportunfall",                                  "Trauma (NOTF 01)"),
        ("NOTF 01", "Reitunfall",                                   "Trauma (NOTF 01)"),
        ("NOTF 01", "Treppensturz",                                 "Trauma (NOTF 01)"),
        ("NOTF 01", "Tierbissverletzung",                           "Trauma (NOTF 01)"),
        ("NOTF 01", "Körperverletzung",                             "Trauma (NOTF 01)"),
        ("NOTF 01", "Hitzeerschöpfung / Hitzschlag",                "Trauma (NOTF 01)"),
        ("NOTF 01", "Unterkühlung / Erfrierung",                    "Trauma (NOTF 01)"),

        // MARK: Verkehrsunfall
        ("NOTF 11", "VU mit Fußgänger",                            "Verkehrsunfall"),
        ("NOTF 11", "VU mit Zweirad",                               "Verkehrsunfall"),
        ("NOTF 11", "VU Verletzte Person",                          "Verkehrsunfall"),
        ("NOTF 11", "VU mit PKW",                                   "Verkehrsunfall"),
        ("NOTF 12", "VU mit LKW / Bus",                             "Verkehrsunfall"),
        ("NOTF 11", "VU Hochgeschwindigkeit",                       "Verkehrsunfall"),
        ("NOTF 02", "Unfall 2 bis 4 Verletzte",                     "Verkehrsunfall"),

        // MARK: Wasser / DLRG
        ("NOTF WASSER NA",  "Ertrinkungsunfall mit Notarzt",        "Wasser"),
        ("NOTF WASSER",     "Ertrinkungsunfall",                    "Wasser"),
        ("NOTF WASSER",     "Badeunfall",                           "Wasser"),
        ("NOTF WASSER NA",  "Tauchunfall / Dekompressionskrankheit","Wasser"),

        // MARK: Feuer (mit Rettungsdienst)
        ("FEU Y",   "Feuer, Menschenleben in Gefahr",               "Feuer"),
        ("FEU XY",  "Feuer, Gefahrstoffe, Menschenleben in Gefahr", "Feuer"),
        ("FEU",     "Feuer, Standard",                              "Feuer"),
        ("FEU G",   "Feuer, groß",                                  "Feuer"),
        ("FEU X",   "Feuer, Gefahrstoffe",                          "Feuer"),
        ("FEU K RWM","Feuer, Rauchwarnmelder",                      "Feuer"),
        ("FEU K BMA","Feuer, Brandmeldeanlage",                     "Feuer"),
        ("FEU BOOT","Feuer Wasserfahrzeug",                         "Feuer"),
        ("FEU G WALD","Waldbrand",                                  "Feuer"),

        // MARK: Technische Hilfeleistung
        ("TH Y",    "TH – Menschenleben in Gefahr",                 "TH"),
        ("TH X",    "TH – Gefahrstoffe (CBRN)",                    "TH"),
        ("TH",      "TH – Person eingeklemmt",                      "TH"),
        ("TH K TV", "TH – Tür verschlossen",                        "TH"),
        ("TH K TV NA","TH – Tür verschlossen, Notarzt",             "TH"),
        ("THGAS",   "TH – Gasgeruch / Gasaustritt",                 "TH"),
        ("THDRZS",  "TH – Person droht zu springen",                "TH"),
        ("THHÖHE",  "TH – Höhen- / Tiefenrettung",                  "TH"),
        ("TH BAHN Y","TH Bahn – Menschenleben in Gefahr",           "TH"),
        ("TH BAHN", "TH Bahnbereich",                               "TH"),

        // MARK: Krankenbeförderung
        ("KBF",         "Krankenbeförderung",                       "KBF"),
        ("KBF TERMIN",  "KBF – Termin",                             "KBF"),
        ("KBF VERL",    "KBF – Verlegung",                          "KBF"),
        ("KBF VERL ARZT","KBF – Verlegung mit Arzt",               "KBF"),
        ("KBF INF",     "KBF – Infektionstransport",                "KBF"),
        ("KBF ADIP",    "KBF – Schwerlastpatient",                  "KBF"),
        ("KBF ZWANG",   "KBF – Zwangseinweisung",                   "KBF"),
        ("NOTF VERL",   "Notfallverlegung",                         "KBF"),
        ("NOTF VERL NA","Notfallverlegung mit Notarzt",             "KBF"),

        // MARK: Sonstiges
        ("NIL",   "Nicht in der Liste",                             "Sonstiges"),
        ("ORG",   "Organisationsfahrt",                             "Sonstiges"),
        ("DF",    "Dienstfahrt",                                    "Sonstiges"),
    ]

    private var alleEinträge: [EinsatzEintrag] {
        StichwortStore.laden().map {
            EinsatzEintrag(stichwort: $0.stichwort, diagnose: $0.diagnose, kategorie: $0.kategorie)
        }
    }

    private var gefiltert: [EinsatzEintrag] {
        let basis = alleEinträge
        if suche.isEmpty { return basis }
        let q = suche.lowercased()
        return basis.filter {
            $0.stichwort.lowercased().contains(q) ||
            $0.diagnose.lowercased().contains(q) ||
            $0.kategorie.lowercased().contains(q)
        }
    }

    private var kategorien: [String] {
        var seen = Set<String>()
        return gefiltert.compactMap { seen.insert($0.kategorie).inserted ? $0.kategorie : nil }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(kategorien, id: \.self) { kat in
                    Section(kat) {
                        ForEach(gefiltert.filter { $0.kategorie == kat }) { eintrag in
                            Button {
                                code = eintrag.stichwort
                                beschreibung = eintrag.diagnose
                                dismiss()
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(eintrag.diagnose)
                                            .font(.body)
                                            .foregroundStyle(.primary)
                                        Text(eintrag.stichwort)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Text(eintrag.stichwort)
                                        .font(.caption2.bold())
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 3)
                                        .background(.blue.opacity(0.15))
                                        .foregroundStyle(.blue)
                                        .clipShape(RoundedRectangle(cornerRadius: 5))
                                }
                            }
                            .foregroundStyle(.primary)
                        }
                    }
                }
            }
            .searchable(text: $suche, prompt: "Diagnose oder Stichwort suchen")
            .navigationTitle("Einsatzstichwort")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - ZeitFeld

struct ZeitFeld: View {
    let label: String
    @Binding var datum: Date?
    @State private var zeigeNumpad = false

    private var displayText: String {
        guard let d = datum else { return "" }
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: d)
    }

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(displayText.isEmpty ? "--:--" : displayText)
                .foregroundColor(displayText.isEmpty ? .secondary : .primary)
                .frame(width: 50, alignment: .trailing)
            Button("Jetzt") { setzeJetzt() }
                .buttonStyle(.bordered)
                .tint(Color("RDOrange"))
                .controlSize(.small)
        }
        .contentShape(Rectangle())
        .onTapGesture { zeigeNumpad = true }
        .sheet(isPresented: $zeigeNumpad) {
            NumpadSheet(mode: .time(label: label), initial: displayText) { timeStr in
                applyTime(timeStr)
            }
        }
    }

    private func setzeJetzt() {
        let now = Date()
        let cal = Calendar.current
        let base = datum ?? now
        var comps = cal.dateComponents([.year, .month, .day], from: base)
        comps.hour = cal.component(.hour, from: now)
        comps.minute = cal.component(.minute, from: now)
        datum = cal.date(from: comps)
    }

    private func applyTime(_ fmt: String) {
        guard fmt.count == 5 else { return }
        let parts = fmt.split(separator: ":")
        guard parts.count == 2,
              let h = Int(parts[0]), let m = Int(parts[1]),
              (0..<24).contains(h), (0..<60).contains(m) else { return }
        let base = datum ?? Date()
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: base)
        comps.hour = h
        comps.minute = m
        datum = Calendar.current.date(from: comps)
    }
}
