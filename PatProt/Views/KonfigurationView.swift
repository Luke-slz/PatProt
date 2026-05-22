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
                BesatzungsFeld(label: "Sanitäter 1", text: $protokoll.besatzung.sanitaeter1)
                BesatzungsFeld(label: "Sanitäter 2", text: $protokoll.besatzung.sanitaeter2)
                BesatzungsFeld(label: "Sanitäter 3", text: $protokoll.besatzung.sanitaeter3)
                BesatzungsFeld(label: "Sanitäter 4", text: $protokoll.besatzung.sanitaeter4)
            } header: {
                Label("Besatzung", systemImage: "person.2")
            }
        }
        .navigationTitle("Konfiguration")
        .navigationBarTitleDisplayMode(.large)
        .onChange(of: locationManager.address) { _, newAddress in
            if !newAddress.isEmpty { protokoll.einsatzOrt.adresse = newAddress }
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
