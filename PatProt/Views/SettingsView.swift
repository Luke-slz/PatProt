import SwiftUI

struct SettingsView: View {
    var onBack: () -> Void

    @AppStorage("recipientEmail") private var recipientEmail: String = ""
    @AppStorage("gespeichertesPersonal") private var personalJSON: String = "[]"
    @AppStorage("customFahrzeuge") private var customFahrzeugeJSON: String = "[]"
    @AppStorage("standardFahrzeugNamen") private var standardFahrzeugNamenJSON: String = "{}"

    @State private var zeigePersonalHinzufuegen = false
    @State private var zeigeFahrzeugHinzufuegen = false
    @State private var zeigeFahrzeugBearbeiten = false
    @State private var neuerName = ""
    @State private var neuesFahrzeug = ""
    @State private var zuBearbeitenderIndex: Int? = nil
    @State private var bearbeitungsName = ""
    @State private var zeigeStandardBearbeiten = false
    @State private var zuBearbeitenderTyp: FahrzeugTyp? = nil
    @State private var bearbeitungsStandardName = ""

    private var personal: [String] {
        (try? JSONDecoder().decode([String].self, from: Data(personalJSON.utf8))) ?? []
    }

    private func personalSpeichern(_ liste: [String]) {
        personalJSON = (try? String(data: JSONEncoder().encode(liste), encoding: .utf8)) ?? "[]"
        AppState.pushSettingsToiCloud()
    }

    private var customFahrzeuge: [String] {
        (try? JSONDecoder().decode([String].self, from: Data(customFahrzeugeJSON.utf8))) ?? []
    }

    private func customFahrzeugeSpeichern(_ liste: [String]) {
        customFahrzeugeJSON = (try? String(data: JSONEncoder().encode(liste), encoding: .utf8)) ?? "[]"
        AppState.pushSettingsToiCloud()
    }

    private var standardFahrzeugNamen: [String: String] {
        (try? JSONDecoder().decode([String: String].self, from: Data(standardFahrzeugNamenJSON.utf8))) ?? [:]
    }

    private func standardFahrzeugNamenSpeichern(_ dict: [String: String]) {
        standardFahrzeugNamenJSON = (try? String(data: JSONEncoder().encode(dict), encoding: .utf8)) ?? "{}"
        AppState.pushSettingsToiCloud()
    }

    var body: some View {
        Form {
            // E-Mail
            Section(
                footer: Text("Die E-Mail-Adresse wird ausschließlich zum Versand des Protokolls verwendet. Nach erfolgreichem Versand wird die PDF-Datei gelöscht.")
                    .font(.footnote).foregroundStyle(.secondary)
            ) {
                TextField("Empfänger-E-Mail", text: $recipientEmail)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled(true)
                    .onChange(of: recipientEmail) { _, _ in AppState.pushSettingsToiCloud() }
            }

            // Personal
            Section {
                ForEach(personal, id: \.self) { person in
                    Label(person, systemImage: "person")
                        .foregroundStyle(.primary)
                }
                .onDelete { indexSet in
                    var liste = personal
                    liste.remove(atOffsets: indexSet)
                    personalSpeichern(liste)
                }
                Button {
                    neuerName = ""
                    zeigePersonalHinzufuegen = true
                } label: {
                    Label("Person hinzufügen", systemImage: "plus.circle")
                }
            } header: {
                Label("Gespeichertes Personal", systemImage: "person.2")
            } footer: {
                Text("Namen werden beim Ausfüllen der Besatzung zur Auswahl angeboten. Mit Wischgeste löschen.")
                    .font(.footnote).foregroundStyle(.secondary)
            }

            // Standardfahrzeuge
            Section {
                ForEach(FahrzeugTyp.allCases, id: \.self) { typ in
                    Button {
                        zuBearbeitenderTyp = typ
                        bearbeitungsStandardName = standardFahrzeugNamen[typ.rawValue] ?? typ.rawValue
                        zeigeStandardBearbeiten = true
                    } label: {
                        HStack {
                            Label(standardFahrzeugNamen[typ.rawValue] ?? typ.rawValue, systemImage: "car")
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: standardFahrzeugNamen[typ.rawValue] != nil ? "pencil.circle.fill" : "pencil")
                                .font(.caption)
                                .foregroundStyle(standardFahrzeugNamen[typ.rawValue] != nil ? Color.orange : Color.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            } header: {
                Label("Standardfahrzeuge", systemImage: "car.fill")
            } footer: {
                Text("Antippen zum Umbenennen. Geänderte Namen werden im ganzen Protokoll verwendet. 'Zurücksetzen' stellt den Originalwert wieder her.")
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
        }
        .navigationTitle("Einstellungen")
        .toolbar { EditButton() }
        .alert("Person hinzufügen", isPresented: $zeigePersonalHinzufuegen) {
            TextField("Name", text: $neuerName)
            Button("Hinzufügen") {
                let name = neuerName.trimmingCharacters(in: .whitespaces)
                guard !name.isEmpty else { return }
                var liste = personal
                liste.append(name)
                personalSpeichern(liste)
            }
            Button("Abbrechen", role: .cancel) {}
        }
        .alert("Fahrzeug hinzufügen", isPresented: $zeigeFahrzeugHinzufuegen) {
            TextField("Bezeichnung (z.B. FR 10-58-01)", text: $neuesFahrzeug)
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
        .alert("Fahrzeug umbenennen", isPresented: $zeigeStandardBearbeiten) {
            TextField("Name", text: $bearbeitungsStandardName)
            Button("Speichern") {
                guard let typ = zuBearbeitenderTyp else { return }
                let name = bearbeitungsStandardName.trimmingCharacters(in: .whitespaces)
                var dict = standardFahrzeugNamen
                if name.isEmpty || name == typ.rawValue {
                    dict.removeValue(forKey: typ.rawValue)
                } else {
                    dict[typ.rawValue] = name
                }
                standardFahrzeugNamenSpeichern(dict)
                zuBearbeitenderTyp = nil
            }
            Button("Zurücksetzen", role: .destructive) {
                guard let typ = zuBearbeitenderTyp else { return }
                var dict = standardFahrzeugNamen
                dict.removeValue(forKey: typ.rawValue)
                standardFahrzeugNamenSpeichern(dict)
                zuBearbeitenderTyp = nil
            }
            Button("Abbrechen", role: .cancel) { zuBearbeitenderTyp = nil }
        } message: {
            Text("Standard: \(zuBearbeitenderTyp?.rawValue ?? "")")
        }
    }
}
