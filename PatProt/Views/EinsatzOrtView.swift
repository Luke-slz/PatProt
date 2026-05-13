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
                TextField("Einsatz-Nr.", text: $protokoll.einsatzOrt.einsatzNummer)
                    .keyboardType(.numberPad)
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

                Picker("Primärfahrzeug", selection: $protokoll.einsatzOrt.fahrzeugTyp) {
                    ForEach(FahrzeugTyp.allCases, id: \.self) { typ in
                        Text(typ.rawValue).tag(typ)
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
                ZeitFeld(label: "Ankunft Krankenhaus", datum: $protokoll.einsatzOrt.krankenHausAnkunft)
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
                TextField("Geburtsdatum (TT.MM.JJJJ)", text: $geburtsdatumText)
                    .keyboardType(.numberPad)
                    .onChange(of: geburtsdatumText) { _, value in
                        let numbers = value.filter { $0.isNumber }
                        var formatted = ""
                        for (index, char) in numbers.enumerated() {
                            if index == 2 || index == 4 { formatted.append(".") }
                            if index < 8 { formatted.append(char) }
                        }
                        if formatted != geburtsdatumText { geburtsdatumText = formatted }
                        let formatter = DateFormatter()
                        formatter.dateFormat = "dd.MM.yyyy"
                        if let date = formatter.date(from: formatted) {
                            protokoll.patientDaten.geburtsDatum = date
                        }
                    }
                TextField("Versicherungsnummer", text: $protokoll.patientDaten.versicherungsNummer)
                TextField("Kostenträger / Krankenkasse", text: $protokoll.patientDaten.kostentraeger)
            } header: {
                Label("Patient", systemImage: "person.circle")
            }

            // MARK: Klinische Angaben
            Section {
                HStack {
                    Text("Gewicht (kg)")
                    Spacer()
                    TextField("optional", value: $protokoll.patientDaten.gewicht, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                }
                Toggle("Ansprechbar", isOn: $protokoll.patientDaten.ansprechbar)
            } header: {
                Label("Klinische Angaben", systemImage: "stethoscope")
            }

            // MARK: Besatzung
            Section {
                BesatzungsFeld(label: "Sanitäter 1", text: $protokoll.besatzung.sanitaeter1,
                               personal: gespeichertesPersonal)
                BesatzungsFeld(label: "Sanitäter 2", text: $protokoll.besatzung.sanitaeter2,
                               personal: gespeichertesPersonal)
                BesatzungsFeld(label: "Sanitäter 3", text: $protokoll.besatzung.sanitaeter3,
                               personal: gespeichertesPersonal)
                BesatzungsFeld(label: "Sanitäter 4", text: $protokoll.besatzung.sanitaeter4,
                               personal: gespeichertesPersonal)
            } header: {
                Label("Besatzung", systemImage: "person.2")
            } footer: {
                if !gespeichertesPersonal.isEmpty {
                    Text("Tippe auf \(Image(systemName: "person.badge.plus")) um aus gespeichertem Personal auszuwählen.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }

            Section {
                Button(action: onWeiter) {
                    Label("Weiter zur Befunderhebung", systemImage: "arrow.right.circle.fill")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color("RDOrange"))
            }
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
    }
}

// MARK: - Besatzungsfeld mit Personal-Picker

private struct BesatzungsFeld: View {
    let label: String
    @Binding var text: String
    let personal: [String]
    @State private var zeigePickerSheet = false

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
                Section("Standardfahrzeuge") {
                    ForEach(FahrzeugTyp.allCases, id: \.self) { typ in
                        Button(typ.rawValue) {
                            onAuswahl(typ.rawValue)
                            dismiss()
                        }
                        .foregroundStyle(.primary)
                    }
                }
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

// MARK: - Stichwort-Picker Sheet

struct StichwortPickerSheet: View {
    @Binding var code: String
    @Binding var beschreibung: String
    @Environment(\.dismiss) private var dismiss
    @State private var suche = ""

    static let stichwörter: [(String, String)] = [
        ("NOTF01", "Bewusstlosigkeit / nicht ansprechbare Person"),
        ("NOTF02", "Atem-/Kreislaufstillstand (Reanimation)"),
        ("NOTF03", "Atemnot / Dyspnoe"),
        ("NOTF04", "Brustschmerz / Verdacht auf Herzinfarkt (ACS)"),
        ("NOTF05", "Schlaganfall / Apoplex (FAST-Symptomatik)"),
        ("NOTF06", "Krampfanfall / Epilepsie"),
        ("NOTF07", "Allergische Reaktion / Anaphylaxie"),
        ("NOTF08", "Diabetischer Notfall (Hypo-/Hyperglykämie)"),
        ("NOTF09", "Psychiatrischer Notfall / akute Krise"),
        ("NOTF10", "Unterleibsschmerzen / abdomineller Notfall"),
        ("NOTF11", "Geburtshilfe / Entbindung"),
        ("NOTF12", "Pädiatrischer Notfall / Kind"),
        ("NOTF13", "Intoxikation / Vergiftung"),
        ("NOTF14", "Hyperthermie / Hitzschlag"),
        ("NOTF15", "Hypothermie / Unterkühlung"),
        ("NOTF16", "Schock (verschiedene Ursachen)"),
        ("NOTF17", "Verletzung / Trauma"),
        ("NOTF18", "Urogenitaler Notfall"),
        ("UNFALL01", "Verkehrsunfall PKW"),
        ("UNFALL02", "Verkehrsunfall LKW / schwerer VU"),
        ("UNFALL03", "Verkehrsunfall mit eingeklemmter Person"),
        ("UNFALL04", "Motorrad-/Fahrradunfall"),
        ("UNFALL05", "Fußgänger angefahren"),
        ("UNFALL06", "Arbeitsunfall"),
        ("UNFALL07", "Sportunfall"),
        ("UNFALL08", "Haushaltsunfall / Sturz"),
        ("UNFALL09", "MANV – Massenanfall von Verletzten"),
        ("WASSER01", "Person im Wasser / Ertrinkender"),
        ("WASSER02", "Person ertrunken / Bergung"),
        ("SUIZID",  "Suizid / Suizidversuch"),
        ("HILFE",   "Hilflosigkeit / Person braucht Hilfe"),
        ("ABSTURZ", "Absturz / Sturz aus großer Höhe"),
        ("STROM",   "Stromunfall / Elektrounfall"),
    ]

    private var gefiltert: [(String, String)] {
        if suche.isEmpty { return Self.stichwörter }
        return Self.stichwörter.filter { $0.0.localizedCaseInsensitiveContains(suche) || $0.1.localizedCaseInsensitiveContains(suche) }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(gefiltert, id: \.0) { kürzel, beschreibText in
                    Button {
                        code = kürzel
                        beschreibung = beschreibText
                        dismiss()
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(kürzel).font(.headline).foregroundStyle(.primary)
                            Text(beschreibText).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .searchable(text: $suche, prompt: "Stichwort suchen")
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
    @State private var text: String = ""

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            TextField("HH:MM", text: $text)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 65)
                .foregroundColor(.primary)
        }
        .onAppear { sync() }
        .onChange(of: datum) { _, _ in sync() }
        .onChange(of: text) { _, val in
            let digits = val.filter { $0.isNumber }
            var fmt = ""
            for (i, c) in digits.prefix(4).enumerated() {
                if i == 2 { fmt.append(":") }
                fmt.append(c)
            }
            if fmt != text { text = fmt }
            applyTime(fmt)
        }
    }

    private func sync() {
        guard let d = datum else { text = ""; return }
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        text = f.string(from: d)
    }

    private func applyTime(_ fmt: String) {
        if fmt.isEmpty { datum = nil; return }
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
