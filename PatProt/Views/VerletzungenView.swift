import SwiftUI

// MARK: - 4.2 Verletzungen (Eingabe in der App)

struct VerletzungenView: View {
    @Binding var befund: DiagnoseBefund

    var body: some View {
        List {

            // ─── Trauma-Diagnosen ────────────────────────
            Section {
                NavigationLink {
                    DiagnoseKategorieView(kategorie: DiagnoseKategorie.trauma, befund: $befund)
                } label: {
                    HStack {
                        Label("Trauma-Diagnosen", systemImage: "stethoscope")
                        Spacer()
                        let anzahl = befund.verdachtsdiagnosen
                            .filter { DiagnoseKategorie.trauma.diagnosen.contains($0.name) }.count
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
            } header: {
                Label("Diagnosen", systemImage: "list.bullet.clipboard")
            }

            // ─── Körperregionen ──────────────────────────
            Section {
                NavigationLink {
                    BodyMapView(matrix: $befund.verletzungsMatrix)
                } label: {
                    HStack {
                        Label("Körperkarte", systemImage: "figure.stand")
                        Spacer()
                        let anzahl = befund.verletzungsMatrix.betroffeneRegionen
                        if anzahl > 0 {
                            Text("\(anzahl) Region\(anzahl == 1 ? "" : "en")")
                                .font(.caption).foregroundColor(.secondary)
                        }
                    }
                }
                Toggle("Keine Verletzungen bekannt", isOn: $befund.verletzungNichtBekannt)

            } header: {
                Label("Körperregionen", systemImage: "cross.case")
            }

            // ─── Verletzungsmuster ───────────────────────
            Section {
                CheckRow("Einzelverletzung",    isOn: $befund.verletzungEinzel)
                CheckRow("Mehrfachverletzung",  isOn: $befund.verletzungMehrfach)
                CheckRow("Polytrauma",          isOn: $befund.verletzungPolytrauma)
            } header: {
                Label("Verletzungsmuster", systemImage: "list.bullet")
            }

            // ─── Unfallmechanismus ───────────────────────
            Section {
                CheckRow("Stumpf",          isOn: $befund.unfallmechStumpf)
                CheckRow("Penetrierend",    isOn: $befund.unfallmechPenetrierend)
                CheckRow("Nicht bekannt",   isOn: $befund.unfallmechNichtBekannt)
            } header: {
                Label("Unfallmechanismus", systemImage: "shield.lefthalf.filled")
            }

            // ─── Spezielle Traumen ───────────────────────
            Section {
                CheckRow("Verbrennung / Verbrühung",    isOn: $befund.spezVerbrVerbrh)
                CheckRow("Inhalationstrauma",           isOn: $befund.spezInhalationstrauma)
                CheckRow("Elektrounfall",               isOn: $befund.spezElektrounfall)
                CheckRow("Verätzung",                   isOn: $befund.spezVeraetzung)
                CheckRow("Tauchunfall",                 isOn: $befund.spezTauchunfall)
                CheckRow("Sonstige",                    isOn: $befund.spezSonstige)
            } header: {
                Label("Spezielle Traumen", systemImage: "flame")
            }

            // ─── Unfallart ───────────────────────────────
            Section {
                CheckRow("PKW / LKW-Insasse",       isOn: $befund.spezPkwLkw)
                CheckRow("Motorradfahrer",           isOn: $befund.spezMotorrad)
                CheckRow("Fahrradfahrer",            isOn: $befund.spezFahrrad)
                CheckRow("Fußgänger (angefahren)",  isOn: $befund.spezFussgaenger)
                CheckRow("Anderer Verkehrsunfall",  isOn: $befund.spezAndVerkehr)
                CheckRow("Maschinenunfall",          isOn: $befund.spezMaschine)
                CheckRow("Sturz > 3 m Höhe",        isOn: $befund.spezSturzHoehe)
                CheckRow("Sturz < 3 m Höhe",        isOn: $befund.spezSturzKlein)
                CheckRow("Schlag",                  isOn: $befund.spezSchlag)
                CheckRow("Schuss",                  isOn: $befund.spezSchuss)
                CheckRow("Stich",                   isOn: $befund.spezStich)
                CheckRow("Gewaltverbrechen",         isOn: $befund.spezGewalt)
                CheckRow("Verschüttung",             isOn: $befund.spezVerschuettung)
                CheckRow("Andere Unfallart",         isOn: $befund.spezAndererUnfall)
            } header: {
                Label("Unfallart", systemImage: "car.side.rear.and.collision.and.car.side")
            }
        }
        .navigationTitle("Verletzungen")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Hilfsview: Checkbox-Zeile

private struct CheckRow: View {
    let label: String
    @Binding var isOn: Bool

    init(_ label: String, isOn: Binding<Bool>) {
        self.label = label
        self._isOn = isOn
    }

    var body: some View {
        Button {
            isOn.toggle()
        } label: {
            HStack {
                Image(systemName: isOn ? "checkmark.square.fill" : "square")
                    .foregroundColor(isOn ? Color("RDOrange") : .secondary)
                    .font(.system(size: 18))
                Text(label)
                    .foregroundColor(.primary)
                Spacer()
            }
        }
        .buttonStyle(.plain)
    }
}
