import SwiftUI

struct DiagnoseView: View {
    @Binding var befund: DiagnoseBefund
    var onBack: () -> Void

    @State private var zeigeNeuEingabe = false
    @State private var neuerName = ""
    @State private var neueWahrscheinlichkeit: DiagnoseWahrscheinlichkeit = .moeglich
    @State private var neueBegruendung = ""
    @State private var bearbeiteID: UUID? = nil

    private var geordnet: [(DiagnoseWahrscheinlichkeit, [VerdachtsdiagnoseEintrag])] {
        DiagnoseWahrscheinlichkeit.allCases.compactMap { stufe in
            let eintraege = befund.verdachtsdiagnosen.filter { $0.wahrscheinlichkeit == stufe }
            return eintraege.isEmpty ? nil : (stufe, eintraege)
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                trichterVisualisierung
                diagnoseEintraege
                leitsymptomSection
                hinzufuegenButton
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Diagnose")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: onBack) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Zurück")
                    }
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    resetEingabe()
                    zeigeNeuEingabe = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $zeigeNeuEingabe) {
            diagnoseEingabeSheet
        }
    }

    // MARK: - Trichter-Visualisierung

    private var trichterVisualisierung: some View {
        GeometryReader { geo in
            VStack(spacing: 2) {
                ForEach(Array(DiagnoseWahrscheinlichkeit.allCases.enumerated()), id: \.element) { index, stufe in
                    let anzahl = befund.verdachtsdiagnosen.filter { $0.wahrscheinlichkeit == stufe }.count
                    let breite = trichterBreite(fuer: index, containerWidth: geo.size.width)

                    HStack {
                        Spacer()
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(anzahl > 0 ? stufe.farbe.opacity(0.18) : Color(.systemGray6))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(stufe.farbe.opacity(anzahl > 0 ? 0.5 : 0.2), lineWidth: 1)
                                )
                            HStack {
                                Image(systemName: stufe.symbol)
                                    .foregroundColor(anzahl > 0 ? stufe.farbe : .secondary)
                                    .font(.caption)
                                Text(stufe.rawValue)
                                    .font(.caption).fontWeight(.medium)
                                    .foregroundColor(anzahl > 0 ? stufe.farbe : .secondary)
                                Spacer()
                                if anzahl > 0 {
                                    Text("\(anzahl)")
                                        .font(.caption).fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .frame(width: 22, height: 22)
                                        .background(stufe.farbe)
                                        .clipShape(Circle())
                                }
                            }
                            .padding(.horizontal, 12)
                        }
                        .frame(width: breite, height: 38)
                        Spacer()
                    }
                }
            }
        }
        .frame(height: CGFloat(DiagnoseWahrscheinlichkeit.allCases.count) * 40)
        .padding(.vertical, 8)
    }

    private func trichterBreite(fuer index: Int, containerWidth: CGFloat) -> CGFloat {
        let maxBreite: CGFloat = containerWidth - 32
        let schrumpfung: CGFloat = 60
        return max(maxBreite - CGFloat(index) * schrumpfung, 160)
    }

    // MARK: - Diagnose-Einträge pro Ebene

    private var diagnoseEintraege: some View {
        VStack(spacing: 12) {
            ForEach(DiagnoseWahrscheinlichkeit.allCases, id: \.self) { stufe in
                let eintraege = befund.verdachtsdiagnosen.filter { $0.wahrscheinlichkeit == stufe }
                if !eintraege.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Image(systemName: stufe.symbol)
                                .foregroundColor(stufe.farbe)
                                .font(.caption)
                            Text(stufe.rawValue)
                                .font(.caption).fontWeight(.semibold)
                                .foregroundColor(stufe.farbe)
                        }
                        ForEach(eintraege) { eintrag in
                            DiagnoseTrichterKarte(
                                eintrag: eintrag,
                                onEdit: { bearbeiteEintrag(eintrag) },
                                onDelete: { loescheEintrag(eintrag) },
                                onStufeAendern: { neueStufe in stufeAendern(eintrag, auf: neueStufe) }
                            )
                        }
                    }
                }
            }

            if befund.verdachtsdiagnosen.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("Noch keine Verdachtsdiagnosen")
                        .font(.subheadline).foregroundColor(.secondary)
                    Text("Tippe auf + um eine Diagnose hinzuzufügen")
                        .font(.caption).foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(32)
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(14)
            }
        }
    }

    // MARK: - Leitsymptom & Freitext

    private var leitsymptomSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Leitsymptom / Diagnose (schriftlich)", systemImage: "stethoscope")
                .font(.subheadline).fontWeight(.semibold)
                .padding(.horizontal)

            VStack(alignment: .leading, spacing: 8) {
                TextField("Leitsymptom eingeben", text: $befund.leitsymptom)
                    .padding(12)
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(10)

                TextEditor(text: $befund.diagnoseFreitext)
                    .frame(minHeight: 70)
                    .padding(8)
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(10)
                    .overlay(
                        Group {
                            if befund.diagnoseFreitext.isEmpty {
                                Text("Ergänzende Anmerkungen…")
                                    .foregroundColor(Color(.placeholderText))
                                    .padding(12)
                                    .allowsHitTesting(false)
                            }
                        }, alignment: .topLeading
                    )
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 12)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(14)
    }

    private var hinzufuegenButton: some View {
        Button {
            resetEingabe()
            zeigeNeuEingabe = true
        } label: {
            Label("Verdachtsdiagnose hinzufügen", systemImage: "plus.circle.fill")
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color("RDOrange"))
                .foregroundColor(.white)
                .cornerRadius(14)
                .font(.headline)
        }
    }

    // MARK: - Eingabe Sheet

    private var diagnoseEingabeSheet: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Diagnose / Verdacht", text: $neuerName)
                } header: { Text("Bezeichnung") }

                Section {
                    Picker("Wahrscheinlichkeit", selection: $neueWahrscheinlichkeit) {
                        ForEach(DiagnoseWahrscheinlichkeit.allCases, id: \.self) { stufe in
                            Label(stufe.rawValue, systemImage: stufe.symbol)
                                .tag(stufe)
                        }
                    }
                    .pickerStyle(.inline)
                } header: { Text("Einschätzung") }

                Section {
                    TextEditor(text: $neueBegruendung)
                        .frame(minHeight: 80)
                } header: { Text("Begründung / Zeichen") }
            }
            .navigationTitle(bearbeiteID == nil ? "Neue Diagnose" : "Diagnose bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { zeigeNeuEingabe = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        speichernEintrag()
                        zeigeNeuEingabe = false
                    }
                    .disabled(neuerName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - Aktionen

    private func resetEingabe() {
        neuerName = ""
        neueWahrscheinlichkeit = .moeglich
        neueBegruendung = ""
        bearbeiteID = nil
    }

    private func speichernEintrag() {
        let name = neuerName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }

        if let id = bearbeiteID,
           let idx = befund.verdachtsdiagnosen.firstIndex(where: { $0.id == id }) {
            befund.verdachtsdiagnosen[idx].name = name
            befund.verdachtsdiagnosen[idx].wahrscheinlichkeit = neueWahrscheinlichkeit
            befund.verdachtsdiagnosen[idx].begruendung = neueBegruendung
        } else {
            let neu = VerdachtsdiagnoseEintrag(
                name: name,
                wahrscheinlichkeit: neueWahrscheinlichkeit,
                begruendung: neueBegruendung
            )
            befund.verdachtsdiagnosen.append(neu)
        }

        // Führende Diagnose als Leitsymptom übernehmen
        if neueWahrscheinlichkeit == .fuehrend {
            befund.leitsymptom = name
        }
    }

    private func bearbeiteEintrag(_ eintrag: VerdachtsdiagnoseEintrag) {
        bearbeiteID = eintrag.id
        neuerName = eintrag.name
        neueWahrscheinlichkeit = eintrag.wahrscheinlichkeit
        neueBegruendung = eintrag.begruendung
        zeigeNeuEingabe = true
    }

    private func loescheEintrag(_ eintrag: VerdachtsdiagnoseEintrag) {
        befund.verdachtsdiagnosen.removeAll { $0.id == eintrag.id }
    }

    private func stufeAendern(_ eintrag: VerdachtsdiagnoseEintrag, auf neueStufe: DiagnoseWahrscheinlichkeit) {
        if let idx = befund.verdachtsdiagnosen.firstIndex(where: { $0.id == eintrag.id }) {
            befund.verdachtsdiagnosen[idx].wahrscheinlichkeit = neueStufe
            if neueStufe == .fuehrend {
                befund.leitsymptom = eintrag.name
            }
        }
    }
}

// MARK: - Trichter-Karte

private struct DiagnoseTrichterKarte: View {
    let eintrag: VerdachtsdiagnoseEintrag
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onStufeAendern: (DiagnoseWahrscheinlichkeit) -> Void

    @State private var zeigeStufeMenu = false

    var body: some View {
        HStack(spacing: 12) {
            // Farb-Indikator
            RoundedRectangle(cornerRadius: 4)
                .fill(eintrag.wahrscheinlichkeit.farbe)
                .frame(width: 4)
                .frame(height: eintrag.begruendung.isEmpty ? 44 : 60)

            VStack(alignment: .leading, spacing: 4) {
                Text(eintrag.name)
                    .font(.subheadline).fontWeight(.semibold)
                if !eintrag.begruendung.isEmpty {
                    Text(eintrag.begruendung)
                        .font(.caption).foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer()

            // Aktionen
            Menu {
                Button { onEdit() } label: {
                    Label("Bearbeiten", systemImage: "pencil")
                }
                Menu("Stufe ändern") {
                    ForEach(DiagnoseWahrscheinlichkeit.allCases, id: \.self) { stufe in
                        Button {
                            onStufeAendern(stufe)
                        } label: {
                            Label(stufe.rawValue, systemImage: stufe.symbol)
                        }
                    }
                }
                Divider()
                Button(role: .destructive) { onDelete() } label: {
                    Label("Löschen", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundColor(.secondary)
                    .font(.title3)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.secondarySystemGroupedBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(eintrag.wahrscheinlichkeit.farbe.opacity(0.3), lineWidth: 1)
                )
        )
    }
}
