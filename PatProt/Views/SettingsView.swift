import SwiftUI

struct SettingsView: View {
    var onBack: () -> Void

    @AppStorage("recipientEmail") private var recipientEmail: String = ""
    @AppStorage("defaultVerfasser") private var defaultVerfasserRaw: String = ProtokollVerfasser.notfallsanitaeter.rawValue
    @AppStorage("gespeichertesPersonal") private var personalJSON: String = "[]"
    @AppStorage("customFahrzeuge") private var customFahrzeugeJSON: String = "[]"
    @AppStorage("einheitenname") private var einheitenname: String = "First Responder Geesthacht"
    @AppStorage("startseiteUntertitel") private var startseiteUntertitel: String = "Einsatzprotokollierung First Responder"

    @State private var zeigePersonalHinzufuegen = false
    @State private var zeigeFahrzeugHinzufuegen = false
    @State private var zeigeFahrzeugBearbeiten = false
    @State private var neuerName = ""
    @State private var neueQualifikation: Qualifikation = .rettungssanitaeter
    @State private var zeigePersonalBearbeiten = false
    @State private var bearbeitungsPersonIndex: Int? = nil
    @State private var bearbeitungsPersonName = ""
    @State private var bearbeitungsPersonQualifikation: Qualifikation = .rettungssanitaeter
    @State private var neuesFahrzeug = ""
    @State private var zuBearbeitenderIndex: Int? = nil
    @State private var bearbeitungsName = ""

    private var personal: [PersonalEintrag] {
        let data = Data(personalJSON.utf8)
        if let liste = try? JSONDecoder().decode([PersonalEintrag].self, from: data) { return liste }
        // Migration: alter [String]-Format
        if let namen = try? JSONDecoder().decode([String].self, from: data) {
            return namen.map { PersonalEintrag(name: $0, qualifikation: .rettungssanitaeter) }
        }
        return []
    }

    private func personalSpeichern(_ liste: [PersonalEintrag]) {
        personalJSON = (try? String(data: JSONEncoder().encode(liste), encoding: .utf8)) ?? "[]"
    }

    private var customFahrzeuge: [String] {
        (try? JSONDecoder().decode([String].self, from: Data(customFahrzeugeJSON.utf8))) ?? []
    }

    private func customFahrzeugeSpeichern(_ liste: [String]) {
        customFahrzeugeJSON = (try? String(data: JSONEncoder().encode(liste), encoding: .utf8)) ?? "[]"
    }

    var body: some View {
        Form {
            // Startseite
            Section {
                TextField("Einheitenname", text: $einheitenname)
                    .autocorrectionDisabled(true)
                TextField("Untertitel", text: $startseiteUntertitel)
                    .autocorrectionDisabled(true)
            } header: {
                Label("Startseite", systemImage: "house.fill")
            } footer: {
                Text("Name und Untertitel werden auf der Startseite angezeigt.")
                    .font(.footnote).foregroundStyle(.secondary)
            }

            // Qualifikation
            Section {
                Picker("Meine Qualifikation", selection: Binding(
                    get: { ProtokollVerfasser(rawValue: defaultVerfasserRaw) ?? .notfallsanitaeter },
                    set: { defaultVerfasserRaw = $0.rawValue }
                )) {
                    ForEach(ProtokollVerfasser.allCases, id: \.self) { v in
                        Text(v.rawValue).tag(v)
                    }
                }
            } header: {
                Label("Meine Qualifikation", systemImage: "person.badge.key")
            } footer: {
                Text("Wird als Standard-Verfasser im Protokollabschluss vorausgewählt.")
                    .font(.footnote).foregroundStyle(.secondary)
            }

            // E-Mail
            Section(
                footer: Text("Die E-Mail-Adresse wird ausschließlich zum Versand des Protokolls verwendet. Nach erfolgreichem Versand wird die PDF-Datei gelöscht.")
                    .font(.footnote).foregroundStyle(.secondary)
            ) {
                TextField("Empfänger-E-Mail", text: $recipientEmail)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled(true)
            }

            // Personal
            Section {
                ForEach(personal, id: \.self) { eintrag in
                    Button {
                        bearbeitungsPersonIndex = personal.firstIndex(of: eintrag)
                        bearbeitungsPersonName = eintrag.name
                        bearbeitungsPersonQualifikation = eintrag.qualifikation
                        zeigePersonalBearbeiten = true
                    } label: {
                        HStack {
                            Label(eintrag.name, systemImage: "person")
                                .foregroundStyle(.primary)
                            Spacer()
                            Text(eintrag.qualifikation.rawValue)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Image(systemName: "pencil")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
                .onDelete { indexSet in
                    var liste = personal
                    liste.remove(atOffsets: indexSet)
                    personalSpeichern(liste)
                }
                Button {
                    neuerName = ""
                    neueQualifikation = .rettungssanitaeter
                    zeigePersonalHinzufuegen = true
                } label: {
                    Label("Person hinzufügen", systemImage: "plus.circle")
                }
            } header: {
                Label("Gespeichertes Personal", systemImage: "person.2")
            } footer: {
                Text("Antippen zum Bearbeiten. Wischgeste zum Löschen.")
                    .font(.footnote).foregroundStyle(.secondary)
            }

            // Eigene Fahrzeuge
            Section {
                ForEach(Array(customFahrzeuge.enumerated()), id: \.offset) { index, fahrzeug in
                    Button {
                        zuBearbeitenderIndex = index
                        bearbeitungsName = fahrzeug
                        zeigeFahrzeugBearbeiten = true
                    } label: {
                        HStack {
                            Label(fahrzeug, systemImage: "car")
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "pencil")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
                .onDelete { indexSet in
                    var liste = customFahrzeuge
                    liste.remove(atOffsets: indexSet)
                    customFahrzeugeSpeichern(liste)
                }
                .onMove { from, to in
                    var liste = customFahrzeuge
                    liste.move(fromOffsets: from, toOffset: to)
                    customFahrzeugeSpeichern(liste)
                }
                Button {
                    neuesFahrzeug = ""
                    zeigeFahrzeugHinzufuegen = true
                } label: {
                    Label("Fahrzeug hinzufügen", systemImage: "plus.circle")
                }
            } header: {
                Label("Eigene Fahrzeuge", systemImage: "car.2")
            } footer: {
                Text("Antippen zum Bearbeiten. Wischgeste zum Löschen. In Bearbeiten-Modus verschiebbar.")
                    .font(.footnote).foregroundStyle(.secondary)
            }

            // Stichwörter
            Section {
                NavigationLink {
                    StichwörtVerwaltungView()
                } label: {
                    Label("Stichwörter verwalten", systemImage: "list.bullet.rectangle")
                }
            } header: {
                Label("Einsatzstichwörter", systemImage: "list.bullet.rectangle")
            } footer: {
                Text("Alle Stichwörter bearbeiten, löschen oder neue hinzufügen. Auf Standardwerte zurücksetzbar.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Einstellungen")
        .toolbar { EditButton() }
        .sheet(isPresented: $zeigePersonalHinzufuegen) {
            NavigationStack {
                Form {
                    Section("Name") {
                        TextField("Name", text: $neuerName)
                    }
                    Section("Qualifikation") {
                        Picker("Qualifikation", selection: $neueQualifikation) {
                            ForEach(Qualifikation.allCases, id: \.self) { q in
                                Text(q.rawValue).tag(q)
                            }
                        }
                        .pickerStyle(.inline)
                        .labelsHidden()
                    }
                }
                .navigationTitle("Person hinzufügen")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Hinzufügen") {
                            let name = neuerName.trimmingCharacters(in: .whitespaces)
                            guard !name.isEmpty else { return }
                            var liste = personal
                            liste.append(PersonalEintrag(name: name, qualifikation: neueQualifikation))
                            personalSpeichern(liste)
                            zeigePersonalHinzufuegen = false
                        }
                        .disabled(neuerName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Abbrechen") { zeigePersonalHinzufuegen = false }
                    }
                }
            }
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $zeigePersonalBearbeiten) {
            NavigationStack {
                Form {
                    Section("Name") {
                        TextField("Name", text: $bearbeitungsPersonName)
                    }
                    Section("Qualifikation") {
                        Picker("Qualifikation", selection: $bearbeitungsPersonQualifikation) {
                            ForEach(Qualifikation.allCases, id: \.self) { q in
                                Text(q.rawValue).tag(q)
                            }
                        }
                        .pickerStyle(.inline)
                        .labelsHidden()
                    }
                }
                .navigationTitle("Person bearbeiten")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Speichern") {
                            let name = bearbeitungsPersonName.trimmingCharacters(in: .whitespaces)
                            guard !name.isEmpty, let idx = bearbeitungsPersonIndex else { return }
                            var liste = personal
                            guard idx < liste.count else { return }
                            liste[idx] = PersonalEintrag(name: name, qualifikation: bearbeitungsPersonQualifikation)
                            personalSpeichern(liste)
                            zeigePersonalBearbeiten = false
                            bearbeitungsPersonIndex = nil
                        }
                        .disabled(bearbeitungsPersonName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Abbrechen") {
                            zeigePersonalBearbeiten = false
                            bearbeitungsPersonIndex = nil
                        }
                    }
                }
            }
            .presentationDetents([.medium])
        }
        .alert("Fahrzeug hinzufügen", isPresented: $zeigeFahrzeugHinzufuegen) {
            TextField("Bezeichnung", text: $neuesFahrzeug)
            Button("Hinzufügen") {
                let name = neuesFahrzeug.trimmingCharacters(in: .whitespaces)
                guard !name.isEmpty else { return }
                var liste = customFahrzeuge
                liste.append(name)
                customFahrzeugeSpeichern(liste)
            }
            Button("Abbrechen", role: .cancel) {}
        }
        .alert("Fahrzeug bearbeiten", isPresented: $zeigeFahrzeugBearbeiten) {
            TextField("Bezeichnung", text: $bearbeitungsName)
            Button("Speichern") {
                let name = bearbeitungsName.trimmingCharacters(in: .whitespaces)
                guard !name.isEmpty, let idx = zuBearbeitenderIndex else { return }
                var liste = customFahrzeuge
                guard idx < liste.count else { return }
                liste[idx] = name
                customFahrzeugeSpeichern(liste)
                zuBearbeitenderIndex = nil
            }
            Button("Abbrechen", role: .cancel) { zuBearbeitenderIndex = nil }
        }
    }
}

// MARK: - Stichwörter Verwaltung

struct StichwörtVerwaltungView: View {
    @AppStorage(StichwortStore.key) private var storeJSON: String = "[]"
    @State private var einträge: [Stichwort] = []
    @State private var zeigeHinzufuegen = false
    @State private var zeigeBearbeiten = false
    @State private var zeigeResetWarnung = false
    @State private var ausgewählt: Stichwort? = nil
    @State private var editStichwort = ""
    @State private var editDiagnose = ""
    @State private var editKategorie = ""

    private var kategorien: [String] {
        var seen = Set<String>()
        return einträge.compactMap { seen.insert($0.kategorie).inserted ? $0.kategorie : nil }
    }

    var body: some View {
        List {
            ForEach($einträge) { $eintrag in
                Button {
                    ausgewählt = eintrag
                    editStichwort = eintrag.stichwort
                    editDiagnose = eintrag.diagnose
                    editKategorie = eintrag.kategorie
                    zeigeBearbeiten = true
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(eintrag.diagnose)
                                .foregroundStyle(.primary)
                            HStack(spacing: 4) {
                                Text(eintrag.stichwort)
                                    .font(.caption2.bold())
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 2)
                                    .background(.blue.opacity(0.15))
                                    .foregroundStyle(.blue)
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                                Text(eintrag.kategorie)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        Image(systemName: "pencil")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .foregroundStyle(.primary)
            }
            .onDelete { einträge.remove(atOffsets: $0) }
            .onMove  { einträge.move(fromOffsets: $0, toOffset: $1) }
        }
        .navigationTitle("Stichwörter")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    editStichwort = ""
                    editDiagnose = ""
                    editKategorie = ""
                    zeigeHinzufuegen = true
                } label: {
                    Image(systemName: "plus")
                }
            }
            ToolbarItem(placement: .secondaryAction) {
                Button("Auf Standard zurücksetzen", role: .destructive) {
                    zeigeResetWarnung = true
                }
            }
            ToolbarItem(placement: .secondaryAction) {
                EditButton()
            }
        }
        .onAppear { einträge = StichwortStore.laden() }
        .onChange(of: einträge) { _, neu in StichwortStore.speichern(neu) }
        .sheet(isPresented: $zeigeHinzufuegen) {
            StichwortFormSheet(
                titel: "Stichwort hinzufügen",
                stichwort: $editStichwort,
                diagnose: $editDiagnose,
                kategorie: $editKategorie
            ) {
                let neu = Stichwort(
                    stichwort: editStichwort.trimmingCharacters(in: .whitespaces),
                    diagnose: editDiagnose.trimmingCharacters(in: .whitespaces),
                    kategorie: editKategorie.trimmingCharacters(in: .whitespaces).isEmpty
                        ? "Eigene" : editKategorie.trimmingCharacters(in: .whitespaces)
                )
                guard !neu.stichwort.isEmpty, !neu.diagnose.isEmpty else { return }
                einträge.append(neu)
            }
        }
        .sheet(isPresented: $zeigeBearbeiten) {
            StichwortFormSheet(
                titel: "Stichwort bearbeiten",
                stichwort: $editStichwort,
                diagnose: $editDiagnose,
                kategorie: $editKategorie
            ) {
                guard let id = ausgewählt?.id,
                      let idx = einträge.firstIndex(where: { $0.id == id }) else { return }
                einträge[idx].stichwort = editStichwort.trimmingCharacters(in: .whitespaces)
                einträge[idx].diagnose  = editDiagnose.trimmingCharacters(in: .whitespaces)
                einträge[idx].kategorie = editKategorie.trimmingCharacters(in: .whitespaces)
                ausgewählt = nil
            }
        }
        .confirmationDialog(
            "Alle Stichwörter auf Standardwerte zurücksetzen?",
            isPresented: $zeigeResetWarnung,
            titleVisibility: .visible
        ) {
            Button("Zurücksetzen", role: .destructive) {
                einträge = StichwortStore.defaults
            }
            Button("Abbrechen", role: .cancel) {}
        } message: {
            Text("Alle eigenen Änderungen gehen verloren.")
        }
    }
}

// MARK: - Stichwort Formular Sheet

struct StichwortFormSheet: View {
    let titel: String
    @Binding var stichwort: String
    @Binding var diagnose: String
    @Binding var kategorie: String
    let onSpeichern: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Einsatzstichwort-Code") {
                    TextField("z.B. NOTF 11", text: $stichwort)
                        .autocorrectionDisabled(true)
                        .textInputAutocapitalization(.characters)
                }
                Section("Verdachtsdiagnose / Beschreibung") {
                    TextField("z.B. Bewusstlose Person", text: $diagnose)
                }
                Section("Kategorie") {
                    TextField("z.B. Kritisch (NOTF 11)", text: $kategorie)
                }
            }
            .navigationTitle(titel)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        onSpeichern()
                        dismiss()
                    }
                    .disabled(stichwort.trimmingCharacters(in: .whitespaces).isEmpty ||
                              diagnose.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
            }
        }
    }
}
