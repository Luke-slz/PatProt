import SwiftUI

struct PatientView: View {
    @ObservedObject var protokoll: EinsatzProtokoll

    @AppStorage("gespeichertesPersonal") private var personalJSON: String = "[]"
    @State private var geburtsdatumText: String = ""
    @State private var zeigeGeburtsdatumNumpad = false
    @State private var zeigeGewichtNumpad = false

    private var gespeichertesPersonal: [String] {
        (try? JSONDecoder().decode([String].self, from: Data(personalJSON.utf8))) ?? []
    }

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
            } header: {
                Label("Klinische Angaben", systemImage: "stethoscope")
            }

            Section {
                BesatzungsFeld(label: "Sanitäter 1", text: $protokoll.besatzung.sanitaeter1, personal: gespeichertesPersonal)
                BesatzungsFeld(label: "Sanitäter 2", text: $protokoll.besatzung.sanitaeter2, personal: gespeichertesPersonal)
                BesatzungsFeld(label: "Sanitäter 3", text: $protokoll.besatzung.sanitaeter3, personal: gespeichertesPersonal)
                BesatzungsFeld(label: "Sanitäter 4", text: $protokoll.besatzung.sanitaeter4, personal: gespeichertesPersonal)
            } header: {
                Label("Besatzung", systemImage: "person.2")
            } footer: {
                if !gespeichertesPersonal.isEmpty {
                    Text("Tippe auf \(Image(systemName: "person.badge.plus")) um aus gespeichertem Personal auszuwählen.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Rettungstechnische Daten")
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
