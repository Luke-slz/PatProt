import SwiftUI

struct KonfigurationView: View {
    @ObservedObject var protokoll: EinsatzProtokoll
    @StateObject private var locationManager = LocationManager()
    @AppStorage("customFahrzeuge") private var customFahrzeugeJSON: String = "[]"
    @State private var zeigeStichwortPicker = false
    @State private var zeigeEinsatzNrNumpad = false
    @State private var zeigeWeiteresEinsatzmittel = false
    @State private var neuesEinsatzmittel = ""

    private var customFahrzeuge: [String] {
        (try? JSONDecoder().decode([String].self, from: Data(customFahrzeugeJSON.utf8))) ?? []
    }

    var body: some View {
        Form {
            Section {
                TextField("Straße und Hausnummer", text: $protokoll.einsatzOrt.adresse)
                HStack(spacing: 8) {
                    TextField("PLZ", text: $protokoll.einsatzOrt.plz)
                        .keyboardType(.numberPad)
                        .frame(maxWidth: 80)
                    TextField("Ort / Stadt", text: $protokoll.einsatzOrt.ort)
                }
                TextField("Zusatz (Stockwerk, Wohnung...)", text: $protokoll.einsatzOrt.zusatz)
                HStack {
                    Text("Einsatz-Nr.")
                    Spacer()
                    Text(protokoll.einsatzOrt.einsatzNummer.isEmpty
                         ? "—" : protokoll.einsatzOrt.einsatzNummer)
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
                        if locationManager.isLoading { Spacer(); ProgressView() }
                    }
                }
                .disabled(locationManager.isLoading)

                if let fehler = locationManager.locationError {
                    Text(fehler).font(.caption).foregroundColor(.red)
                }
            } header: {
                Label("Einsatzort", systemImage: "mappin.circle")
            }

            Section {
                HStack {
                    TextField("Einsatzart (z.B. NOTF)", text: $protokoll.einsatzOrt.stichwort)
                    Button { zeigeStichwortPicker = true } label: {
                        Image(systemName: "list.bullet").foregroundStyle(Color("RDOrange"))
                    }
                    .buttonStyle(.plain)
                }
                TextField("Stichwort (z.B. Bewusstlos)", text: $protokoll.einsatzOrt.einsatzArt)
                Toggle("Sondersignal", isOn: $protokoll.einsatzOrt.sondersignal)
                Toggle("Notarzt", isOn: $protokoll.einsatzOrt.notarzt)
                Toggle("NA nachgefordert", isOn: $protokoll.einsatzOrt.naAngefordert)

                Picker("Primärfahrzeug", selection: $protokoll.einsatzOrt.fahrzeugName) {
                    Text("—").tag("")
                    ForEach(customFahrzeuge, id: \.self) { fz in Text(fz).tag(fz) }
                }

                ForEach(protokoll.einsatzOrt.weitereEinsatzmittel, id: \.self) { fz in
                    HStack {
                        Image(systemName: "car.2").foregroundStyle(.secondary)
                        Text(fz)
                        Spacer()
                        Button(role: .destructive) {
                            protokoll.einsatzOrt.weitereEinsatzmittel.removeAll { $0 == fz }
                        } label: {
                            Image(systemName: "minus.circle.fill").foregroundStyle(.red)
                        }
                        .buttonStyle(.plain)
                    }
                }

                Button {
                    neuesEinsatzmittel = ""; zeigeWeiteresEinsatzmittel = true
                } label: {
                    Label("Weiteres Einsatzmittel", systemImage: "plus.circle")
                }
            } header: {
                Label("Einsatzart & Fahrzeuge", systemImage: "exclamationmark.triangle")
            }

            Section {
                BesatzungZeile(label: "Sanitäter 1", text: $protokoll.besatzung.sanitaeter1, qualifikation: $protokoll.besatzung.qualifikation1)
                BesatzungZeile(label: "Sanitäter 2", text: $protokoll.besatzung.sanitaeter2, qualifikation: $protokoll.besatzung.qualifikation2)
                BesatzungZeile(label: "Sanitäter 3", text: $protokoll.besatzung.sanitaeter3, qualifikation: $protokoll.besatzung.qualifikation3)
                BesatzungZeile(label: "Sanitäter 4", text: $protokoll.besatzung.sanitaeter4, qualifikation: $protokoll.besatzung.qualifikation4)
            } header: {
                Label("Besatzung", systemImage: "person.2")
            }
        }
        .navigationTitle("Konfiguration")
        .navigationBarTitleDisplayMode(.large)
        .onChange(of: locationManager.address) { _, newAddress in
            if !newAddress.isEmpty {
                protokoll.einsatzOrt.adresse = locationManager.street.isEmpty ? newAddress : locationManager.street
            }
        }
        .onChange(of: locationManager.postalCode) { _, pc in
            if !pc.isEmpty { protokoll.einsatzOrt.plz = pc }
        }
        .onChange(of: locationManager.city) { _, c in
            if !c.isEmpty { protokoll.einsatzOrt.ort = c }
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
        .sheet(isPresented: $zeigeWeiteresEinsatzmittel) {
            EinsatzmittelPickerSheet(customFahrzeuge: customFahrzeuge) { name in
                if !protokoll.einsatzOrt.weitereEinsatzmittel.contains(name) {
                    protokoll.einsatzOrt.weitereEinsatzmittel.append(name)
                }
            }
        }
    }
}

// MARK: - Besatzungszeile mit Qualifikations-Picker

private struct BesatzungZeile: View {
    let label: String
    @Binding var text: String
    @Binding var qualifikation: Qualifikation
    @AppStorage("gespeichertesPersonal") private var personalJSON: String = "[]"
    @State private var zeigePickerSheet = false

    private var personal: [PersonalEintrag] {
        let data = Data(personalJSON.utf8)
        if let liste = try? JSONDecoder().decode([PersonalEintrag].self, from: data) { return liste }
        if let namen = try? JSONDecoder().decode([String].self, from: data) {
            return namen.map { PersonalEintrag(name: $0, qualifikation: .rettungssanitaeter) }
        }
        return []
    }

    var body: some View {
        HStack(spacing: 6) {
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
            Picker("", selection: $qualifikation) {
                ForEach(Qualifikation.allCases, id: \.self) { q in
                    Text(q.rawValue).tag(q)
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .frame(width: 64)
        }
        .sheet(isPresented: $zeigePickerSheet) {
            PersonalPickerSheet(ausgewählt: $text, personal: personal)
        }
    }
}
