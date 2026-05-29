import SwiftUI

// MARK: - SINNHAFT-Schema

struct SINNHAFTView: View {
    @Binding var befund: SINNHAFTBefund
    @EnvironmentObject private var protokoll: EinsatzProtokoll
    var onZurueck: () -> Void

    @State private var zeigeBestaetigung = false

    var body: some View {
        Form {
            Section {
                sinnhaftHeader
            }

            // Auto-Fill Button
            Section {
                Button {
                    zeigeBestaetigung = true
                } label: {
                    HStack {
                        Image(systemName: "wand.and.stars")
                            .foregroundColor(.indigo)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Neu befüllen")
                                .fontWeight(.semibold)
                                .foregroundColor(.indigo)
                            Text("Felder aus erfassten Daten aktualisieren")
                                .font(.caption).foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "arrow.clockwise")
                            .font(.caption).foregroundColor(.secondary)
                    }
                }
                .buttonStyle(.plain)
            }
            .confirmationDialog("Felder neu befüllen?", isPresented: $zeigeBestaetigung, titleVisibility: .visible) {
                Button("Neu befüllen", role: .destructive) { autoFill() }
                Button("Abbrechen", role: .cancel) {}
            } message: {
                Text("Manuelle Änderungen werden überschrieben.")
            }

            Group {
                sinnhaftSektion("S", farbe: .orange, titel: "Situation",
                                beschreibung: "Einsatznummer, Stichwort, Einsatzort",
                                text: $befund.situation)

                sinnhaftSektion("I", farbe: .blue, titel: "Identifikation",
                                beschreibung: "Patient: Name, Alter, Geschlecht",
                                text: $befund.identifikation)

                sinnhaftSektion("N", farbe: .red, titel: "Notfallgeschehen",
                                beschreibung: "Was ist passiert? Hergang, Ursache",
                                text: $befund.notfall)

                sinnhaftSektion("N", farbe: .purple, titel: "Notwendige Maßnahmen",
                                beschreibung: "Durchgeführte Maßnahmen und Therapie",
                                text: $befund.notwendigeMassnahmen)

                sinnhaftSektion("H", farbe: .teal, titel: "Hintergrundinformationen",
                                beschreibung: "Vorerkrankungen, Medikamente, Anamnese",
                                text: $befund.hintergrund)

                aktuellerZustandSektion

                sinnhaftSektion("F", farbe: .indigo, titel: "Forderungen / Folgeempfehlung",
                                beschreibung: "Benötigte Ressourcen, Verdachtsdiagnose",
                                text: $befund.forderung)

                sinnhaftSektion("T", farbe: Color("RDOrange"), titel: "Transport",
                                beschreibung: "Transportziel, -modus, Voranmeldung",
                                text: $befund.transport)
            }

        }
        .keyboardDismissToolbar()
        .navigationTitle("SINNHAFT-Schema")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            autoFill()
        }
    }

    // MARK: - Header

    private var sinnhaftHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 3) {
                ForEach(
                    [("S", Color.orange), ("I", Color.blue), ("N", Color.red),
                     ("N", Color.purple), ("H", Color.teal), ("A", Color.green),
                     ("F", Color.indigo), ("T", Color("RDOrange"))],
                    id: \.0
                ) { letter, color in
                    Text(letter)
                        .font(.title2).fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(width: 34, height: 34)
                        .background(color)
                        .cornerRadius(8)
                }
            }
            Text("Strukturiertes Übergabe- und Kommunikationsschema")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }

    // MARK: - SINNHAFT Sektion

    private func sinnhaftSektion(
        _ buchstabe: String, farbe: Color, titel: String,
        beschreibung: String, text: Binding<String>
    ) -> some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 10) {
                    Text(buchstabe)
                        .font(.title3).fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(farbe)
                        .cornerRadius(8)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(titel).font(.subheadline).fontWeight(.semibold)
                        Text(beschreibung).font(.caption).foregroundColor(.secondary)
                    }
                }
                TextField("Hier eingeben…", text: text, axis: .vertical)
                    .lineLimit(3...)
            }
        }
    }

    // MARK: - Aktueller Zustand (Anfang vs. Aktuell Tabelle)

    private var aktuellerZustandSektion: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 10) {
                    Text("A")
                        .font(.title3).fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(Color.green)
                        .cornerRadius(8)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Aktueller Zustand").font(.subheadline).fontWeight(.semibold)
                        Text("Vitaldaten, ABCDE-Ergebnis, Bewusstsein").font(.caption).foregroundColor(.secondary)
                    }
                }
                vitalVergleichTabelle
                TextField("Zusätzliche Angaben…", text: $befund.aktuellerZustand, axis: .vertical)
                    .lineLimit(2...)
            }
        }
    }

    private struct VitalZeile: Identifiable {
        let id = UUID()
        let parameter: String
        let anfang: String
        let aktuell: String
    }

    private var vitalVergleichTabelle: some View {
        let f = DateFormatter(); f.dateFormat = "HH:mm"
        let p = protokoll
        let letzte = p.verlaufMessungen.sorted(by: { $0.zeitpunkt < $1.zeitpunkt }).last

        var zeilen: [VitalZeile] = []

        let anfangAF  = p.breathing.atemFrequenz.map { "\($0)/min" } ?? ""
        let aktAF     = letzte?.atemFrequenz.map { "\($0)/min" } ?? ""
        if !anfangAF.isEmpty || !aktAF.isEmpty {
            zeilen.append(VitalZeile(parameter: "AF", anfang: anfangAF, aktuell: aktAF))
        }

        let anfangSpo2 = p.breathing.spo2.map { "\($0)%" } ?? ""
        let aktSpo2    = letzte?.spo2.map { "\($0)%" } ?? ""
        if !anfangSpo2.isEmpty || !aktSpo2.isEmpty {
            zeilen.append(VitalZeile(parameter: "SpO₂", anfang: anfangSpo2, aktuell: aktSpo2))
        }

        let anfangPuls = p.circulation.puls.map { "\($0)/min" } ?? ""
        let aktPuls    = letzte?.puls.map { "\($0)/min" } ?? ""
        if !anfangPuls.isEmpty || !aktPuls.isEmpty {
            zeilen.append(VitalZeile(parameter: "Puls", anfang: anfangPuls, aktuell: aktPuls))
        }

        let anfangRR: String = {
            guard let s = p.circulation.blutdruckSystolisch, let d = p.circulation.blutdruckDiastolisch else { return "" }
            return "\(s)/\(d)"
        }()
        let aktRR: String = {
            guard let s = letzte?.blutdruckSys, let d = letzte?.blutdruckDia else { return "" }
            return "\(s)/\(d)"
        }()
        if !anfangRR.isEmpty || !aktRR.isEmpty {
            zeilen.append(VitalZeile(parameter: "RR mmHg", anfang: anfangRR, aktuell: aktRR))
        }

        let anfangGCS = p.disability.status != .unbewertet ? "\(p.disability.gcsGesamt)" : ""
        let aktGCS    = letzte?.gcsGesamt.map(String.init) ?? ""
        if !anfangGCS.isEmpty || !aktGCS.isEmpty {
            zeilen.append(VitalZeile(parameter: "GCS", anfang: anfangGCS, aktuell: aktGCS))
        }

        let anfangBZ = p.disability.blutzucker.map { String(format: "%.0f", $0) } ?? ""
        let aktBZ    = letzte?.blutzucker.map { String(format: "%.0f", $0) } ?? ""
        if !anfangBZ.isEmpty || !aktBZ.isEmpty {
            zeilen.append(VitalZeile(parameter: "BZ mg/dL", anfang: anfangBZ, aktuell: aktBZ))
        }

        let zeitLabel = letzte.map { "Aktuell (\(f.string(from: $0.zeitpunkt)))" } ?? "Aktuell"

        return Group {
            if !zeilen.isEmpty {
                VStack(spacing: 0) {
                    HStack {
                        Text("Parameter").font(.caption).fontWeight(.semibold).foregroundStyle(.secondary).frame(maxWidth: .infinity, alignment: .leading)
                        Text("Auffinde").font(.caption).fontWeight(.semibold).foregroundStyle(.secondary).frame(width: 70, alignment: .trailing)
                        Text(zeitLabel).font(.caption).fontWeight(.semibold).foregroundStyle(.secondary).frame(width: 80, alignment: .trailing)
                    }
                    .padding(.bottom, 4)
                    Divider()
                    ForEach(zeilen) { z in
                        HStack {
                            Text(z.parameter).font(.caption).frame(maxWidth: .infinity, alignment: .leading)
                            Text(z.anfang.isEmpty ? "—" : z.anfang).font(.caption.monospacedDigit()).frame(width: 70, alignment: .trailing)
                            Text(z.aktuell.isEmpty ? "—" : z.aktuell).font(.caption.monospacedDigit()).fontWeight(.semibold).frame(width: 80, alignment: .trailing)
                        }
                        .padding(.vertical, 3)
                        Divider()
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    // MARK: - Auto-Befüllung

    private func autoFill() {
        befund = SINNHAFTBefund.autoFilled(from: protokoll)
    }
}
