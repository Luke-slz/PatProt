import SwiftUI

struct MedikamenteView: View {
    @Binding var medikamente: [MedikamentEintrag]
    var onBack: () -> Void
    @EnvironmentObject private var protokoll: EinsatzProtokoll

    @State private var zeigeHinzufuegen = false
    @State private var zeigeRechner = false

    private let einheiten = ["mg", "ml", "IE", "µg", "g", "mmol"]
    private let routen = ["i.v.", "i.o.", "i.m.", "s.c.", "s.l.", "p.o.", "inhalativ", "nasal", "rektal"]

    private struct KumulationsZeile: Identifiable {
        let id = UUID()
        let name: String
        let einheit: String
        let gesamt: Double
        let max: Double?
        var ueberschritten: Bool { max.map { gesamt > $0 } ?? false }
    }

    private var kumulationen: [KumulationsZeile] {
        var dict: [String: (sum: Double, max: Double?, einheit: String)] = [:]
        for med in medikamente where !med.name.isEmpty {
            let key = med.name.lowercased()
            let dosis = Double(med.dosis.replacingOccurrences(of: ",", with: ".")) ?? 0
            let maxVal = Double(med.maximaldosis.replacingOccurrences(of: ",", with: "."))
            let existing = dict[key]
            dict[key] = (
                sum: (existing?.sum ?? 0) + dosis,
                max: maxVal ?? existing?.max,
                einheit: med.einheit
            )
        }
        return dict.compactMap { name, v in
            guard v.sum > 0 else { return nil }
            return KumulationsZeile(name: name.capitalized, einheit: v.einheit, gesamt: v.sum, max: v.max)
        }.filter { _ in true }
    }

    var body: some View {
        Form {
            let warnungen = kumulationen.filter { $0.ueberschritten }
            if !warnungen.isEmpty {
                Section {
                    ForEach(warnungen) { z in
                        Label {
                            Text("\(z.name): \(String(format: "%.1f", z.gesamt)) \(z.einheit) gegeben (Max. \(String(format: "%.1f", z.max!)) \(z.einheit))")
                                .font(.subheadline)
                        } icon: {
                            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.red)
                        }
                    }
                } header: { Label("Maximaldosis überschritten", systemImage: "exclamationmark.triangle.fill").foregroundStyle(.red) }
            }

            let mehrfach = kumulationen.filter { k in medikamente.filter { $0.name.lowercased() == k.name.lowercased() }.count > 1 }
            if !mehrfach.isEmpty {
                Section {
                    ForEach(mehrfach) { z in
                        HStack {
                            Text(z.name).font(.subheadline)
                            Spacer()
                            Text("\(String(format: "%.1f", z.gesamt)) \(z.einheit) gesamt")
                                .font(.subheadline.monospacedDigit())
                                .foregroundStyle(z.ueberschritten ? .red : .primary)
                            if let max = z.max {
                                Text("/ Max \(String(format: "%.1f", max))")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: { Text("Kumulationsdosen") }
            }

            if medikamente.isEmpty {
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: "pills.circle")
                                .font(.largeTitle)
                                .foregroundColor(.secondary)
                            Text("Noch keine Medikamente erfasst")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical)
                }
            }

            ForEach($medikamente) { $med in
                MedikamentRow(med: $med, einheiten: einheiten, routen: routen)
            }
            .onDelete { indices in
                medikamente.remove(atOffsets: indices)
            }

            Section {
                Button {
                    medikamente.append(MedikamentEintrag())
                } label: {
                    Label("Medikament hinzufügen", systemImage: "plus.circle.fill")
                        .foregroundColor(Color("RDOrange"))
                }
            }

        }
        .navigationTitle("Medikamente")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                EditButton()
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { zeigeRechner = true } label: { Image(systemName: "function") }
            }
        }
        .sheet(isPresented: $zeigeRechner) {
            MedikamentenRechnerSheet(patientengewicht: protokoll.patientDaten.gewicht)
        }
    }
}

private struct MedikamentRow: View {
    @Binding var med: MedikamentEintrag
    let einheiten: [String]
    let routen: [String]
    @State private var zeigeDosisNumpad = false
    @State private var zeigeMaxDosisNumpad = false

    var body: some View {
        Section {
            HStack {
                Image(systemName: "pills.fill")
                    .foregroundColor(Color("RDOrange"))
                TextField("Medikament", text: $med.name)
                    .font(.headline)
            }
            HStack(spacing: 12) {
                Text(med.dosis.isEmpty ? "Dosis" : med.dosis)
                    .foregroundColor(med.dosis.isEmpty ? .secondary : .primary)
                    .contentShape(Rectangle())
                    .onTapGesture { zeigeDosisNumpad = true }
                    .sheet(isPresented: $zeigeDosisNumpad) {
                        NumpadSheet(mode: .decimal(label: "Dosis", unit: med.einheit),
                                    initial: med.dosis) { val in med.dosis = val }
                    }
                Picker("Einheit", selection: $med.einheit) {
                    ForEach(einheiten, id: \.self) { e in
                        Text(e).tag(e)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: 70)
                Spacer()
                Picker("Route", selection: $med.route) {
                    Text("Route").tag("")
                    ForEach(routen, id: \.self) { r in
                        Text(r).tag(r)
                    }
                }
                .pickerStyle(.menu)
            }
            HStack(spacing: 8) {
                Text("Max. Dosis").foregroundColor(.secondary).font(.subheadline)
                Spacer()
                Text(med.maximaldosis.isEmpty ? "–" : "\(med.maximaldosis) \(med.einheit)")
                    .foregroundColor(med.maximaldosis.isEmpty ? .secondary : .primary)
                    .font(.subheadline)
                    .contentShape(Rectangle())
                    .onTapGesture { zeigeMaxDosisNumpad = true }
                    .sheet(isPresented: $zeigeMaxDosisNumpad) {
                        NumpadSheet(mode: .decimal(label: "Max. Dosis", unit: med.einheit),
                                    initial: med.maximaldosis) { val in med.maximaldosis = val }
                    }
            }
            DatePicker("Uhrzeit", selection: $med.zeit, displayedComponents: .hourAndMinute)
        }
    }
}

// MARK: - Medikamenten-Rechner

private struct RechnerMed: Identifiable {
    let id = UUID()
    let name: String
    let dosisProKg: Double?
    let festDosis: Double?
    let einheit: String
    let route: String
    let maxDosis: Double?
}

private let rechnerMedikamente: [RechnerMed] = [
    RechnerMed(name: "Adrenalin (Anaphylaxie)", dosisProKg: 0.01, festDosis: nil,   einheit: "mg",  route: "i.m.", maxDosis: 0.5),
    RechnerMed(name: "Glucose 40%",              dosisProKg: nil,  festDosis: 20.0,  einheit: "g",   route: "i.v.", maxDosis: nil),
    RechnerMed(name: "ASS (ACS)",                dosisProKg: nil,  festDosis: 250.0, einheit: "mg",  route: "p.o.", maxDosis: nil),
    RechnerMed(name: "Nitro (Spray)",            dosisProKg: nil,  festDosis: 0.4,   einheit: "mg",  route: "s.l.", maxDosis: nil),
    RechnerMed(name: "Midazolam (Krampf)",       dosisProKg: 0.2,  festDosis: nil,   einheit: "mg",  route: "nasal", maxDosis: 10.0),
]

private struct MedikamentenRechnerSheet: View {
    let patientengewicht: Double?
    @State private var gewichtText: String
    @State private var auswahl: Int = 0
    @Environment(\.dismiss) private var dismiss

    init(patientengewicht: Double?) {
        self.patientengewicht = patientengewicht
        _gewichtText = State(initialValue: patientengewicht.map { String(format: "%.0f", $0) } ?? "")
    }

    private var gewicht: Double? { Double(gewichtText.replacingOccurrences(of: ",", with: ".")) }

    private var dosisText: String {
        let med = rechnerMedikamente[auswahl]
        if let pk = med.dosisProKg, let kg = gewicht {
            var d = pk * kg
            if let max = med.maxDosis { d = min(d, max) }
            return String(format: "%.2f %@ %@", d, med.einheit, med.route)
        } else if let fd = med.festDosis {
            return String(format: "%.0f %@ %@", fd, med.einheit, med.route)
        }
        return "–"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text("Gewicht (kg)")
                        Spacer()
                        TextField("kg", text: $gewichtText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                } header: { Text("Patientengewicht") }

                Section {
                    Picker("Medikament", selection: $auswahl) {
                        ForEach(rechnerMedikamente.indices, id: \.self) { i in
                            Text(rechnerMedikamente[i].name).tag(i)
                        }
                    }
                    .pickerStyle(.inline)
                } header: { Text("Medikament") }

                Section {
                    HStack {
                        Text("Berechnete Dosis")
                            .fontWeight(.semibold)
                        Spacer()
                        Text(dosisText)
                            .fontWeight(.bold)
                            .foregroundColor(Color("RDOrange"))
                    }
                    if rechnerMedikamente[auswahl].dosisProKg != nil && gewicht == nil {
                        Text("Gewicht eingeben für gewichtsbasierte Berechnung")
                            .font(.caption).foregroundColor(.secondary)
                    }
                    if let max = rechnerMedikamente[auswahl].maxDosis {
                        Text("Max. \(String(format: "%.1f", max)) \(rechnerMedikamente[auswahl].einheit)")
                            .font(.caption).foregroundColor(.secondary)
                    }
                } header: { Text("Ergebnis") }
            }
            .navigationTitle("Medikamenten-Rechner")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { dismiss() }
                }
            }
        }
    }
}
