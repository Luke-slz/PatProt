import SwiftUI

struct PatientView: View {
    @ObservedObject var protokoll: EinsatzProtokoll

    @State private var geburtsdatumText: String = ""
    @State private var zeigeGeburtsdatumNumpad = false
    @State private var zeigeGewichtNumpad = false

    var body: some View {
        Form {
            Section {
                TextField("Vorname",  text: $protokoll.patientDaten.vorname)
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
                Toggle("Maßnahmen / Behandlung durchgeführt", isOn: $protokoll.massnahmenDurchgefuehrt)
            } header: {
                Label("Klinische Angaben", systemImage: "stethoscope")
            }


            Section {
                KVKarteScanSektion(patientDaten: $protokoll.patientDaten)
            } header: {
                Label("KV-Karte / Versichertenkarte", systemImage: "creditcard")
            } footer: {
                Text("Erkannte Daten werden direkt übernommen – nur lokal gespeichert (DSGVO).")
                    .font(.footnote).foregroundStyle(.secondary)
            }

        }
        .navigationTitle("Patient")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            if let geb = protokoll.patientDaten.geburtsDatum {
                let f = DateFormatter(); f.dateFormat = "dd.MM.yyyy"
                geburtsdatumText = f.string(from: geb)
            }
        }
        .sheet(isPresented: $zeigeGeburtsdatumNumpad) {
            NumpadSheet(mode: .date(label: "Geburtsdatum"), initial: geburtsdatumText) { dateStr in
                geburtsdatumText = dateStr
                let f = DateFormatter(); f.dateFormat = "dd.MM.yyyy"
                if let date = f.date(from: dateStr) { protokoll.patientDaten.geburtsDatum = date }
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
