import SwiftUI
import Combine

struct ABCDEUebersichtView: View {
    @ObservedObject var protokoll: EinsatzProtokoll
    var onWeiter: () -> Void
    var onAirway: () -> Void
    var onBreathing: () -> Void
    var onCirculation: () -> Void
    var onDisability: () -> Void
    var onExposure: () -> Void
    var onNotfall: () -> Void
    var onSampler: () -> Void
    var onSinnhaft: () -> Void
    var onDiagnose: () -> Void
    var onVerlauf: () -> Void
    var onMassnahmen: () -> Void
    var onMedikamente: () -> Void
    var onReanimation: () -> Void
    var onBilder: () -> Void
    var onZurueck: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Kritisch / Nicht kritisch
                HStack(spacing: 12) {

                    Button {
                        protokoll.kritisch = true
                    } label: {

                        let istKritisch = protokoll.kritisch
                        let iconKritisch = istKritisch
                            ? "exclamationmark.triangle.fill"
                            : "exclamationmark.triangle"

                        HStack {
                            Image(systemName: iconKritisch)
                            Text("Kritisch")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            istKritisch
                            ? Color.red
                            : Color(.secondarySystemGroupedBackground)
                        )
                        .foregroundColor(
                            istKritisch
                            ? .white
                            : .primary
                        )
                        .cornerRadius(12)
                    }

                    Button {
                        protokoll.kritisch = false
                    } label: {

                        let nichtKritisch = !protokoll.kritisch

                        let iconNichtKritisch = nichtKritisch
                            ? "checkmark.circle.fill"
                            : "checkmark.circle"

                        HStack {
                            Image(systemName: iconNichtKritisch)
                            Text("Nicht kritisch")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            nichtKritisch
                            ? Color.green
                            : Color(.secondarySystemGroupedBackground)
                        )
                        .foregroundColor(
                            nichtKritisch
                            ? .white
                            : .primary
                        )
                        .cornerRadius(12)
                    }
                }
                .buttonStyle(.plain)
                .padding(.horizontal)

                // ABCDE Karten
                VStack(spacing: 1) {
                    ABCDEZeile(
                        buchstabe: "A",
                        titel: "Airway",
                        untertitel: atemwegSubtitel(),
                        status: $protokoll.airway.status,
                        farbe: .orange,
                        action: onAirway
                    )
                    ABCDEZeile(
                        buchstabe: "B",
                        titel: "Breathing",
                        untertitel: breathingSubtitel(),
                        status: $protokoll.breathing.status,
                        farbe: .blue,
                        action: onBreathing
                    )
                    ABCDEZeile(
                        buchstabe: "C",
                        titel: "Circulation",
                        untertitel: circulationSubtitel(),
                        status: $protokoll.circulation.status,
                        farbe: .red,
                        action: onCirculation
                    )
                    ABCDEZeile(
                        buchstabe: "D",
                        titel: "Disability",
                        untertitel: disabilitySubtitel(),
                        status: $protokoll.disability.status,
                        farbe: .purple,
                        action: onDisability
                    )
                    ABCDEZeile(
                        buchstabe: "E",
                        titel: "Exposure",
                        untertitel: exposureSubtitel(),
                        status: $protokoll.exposure.status,
                        farbe: .green,
                        action: onExposure
                    )
                }
                .cornerRadius(14)
                .padding(.horizontal)

                // Notfallgeschehen
                NavigationsButton(
                    icon: "exclamationmark.bubble.fill",
                    titel: "Notfallgeschehen",
                    untertitel: protokoll.notfallGeschehen.erstbefundVorOrt.isEmpty
                        ? "Erstbefund & Notfallgeschehen"
                        : protokoll.notfallGeschehen.erstbefundVorOrt,
                    action: onNotfall
                )
                .padding(.horizontal)

                // Anamnese & Schemata
                VStack(spacing: 8) {
                    NavigationsButton(
                        icon: "list.clipboard.fill",
                        titel: "SAMPLER-Schema",
                        untertitel: "Anamnese & Vorgeschichte",
                        action: onSampler
                    )
                    NavigationsButton(
                        icon: "bubble.left.and.bubble.right.fill",
                        titel: "SINNHAFT-Schema",
                        untertitel: "Strukturiertes Übergabeschema",
                        action: onSinnhaft
                    )
                }
                .padding(.horizontal)

                // Diagnose & Verlauf
                VStack(spacing: 8) {
                    NavigationsButton(
                        icon: "slider.horizontal.3",
                        titel: "Diagnose (Trichter)",
                        untertitel: diagnoseUntertitel(),
                        action: onDiagnose
                    )
                    NavigationsButton(
                        icon: "waveform.path.ecg",
                        titel: "Verlauf & Therapie",
                        untertitel: protokoll.verlaufMessungen.isEmpty
                            ? "Noch keine Messungen"
                            : "\(protokoll.verlaufMessungen.count) Messung\(protokoll.verlaufMessungen.count == 1 ? "" : "en")",
                        action: onVerlauf
                    )
                }
                .padding(.horizontal)

                // Therapie
                VStack(spacing: 8) {
                    NavigationsButton(
                        icon: "cross.circle.fill",
                        titel: "Maßnahmen",
                        untertitel: massnahmenSubtitel(),
                        action: onMassnahmen
                    )
                    NavigationsButton(
                        icon: "pills.fill",
                        titel: "Medikamente",
                        untertitel: protokoll.medikamente.isEmpty ? "Keine erfasst" : "\(protokoll.medikamente.count) Eintrag/Einträge",
                        action: onMedikamente
                    )
                    NavigationsButton(
                        icon: "camera.fill",
                        titel: "Bilder & Dateien",
                        untertitel: protokoll.fotos.isEmpty ? "Keine Fotos" : "\(protokoll.fotos.count) Foto\(protokoll.fotos.count == 1 ? "" : "s")",
                        action: onBilder
                    )
                }
                .padding(.horizontal)

                // Reanimation
                VStack(spacing: 0) {
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill((protokoll.reanimationAktiv ? Color.red : Color.secondary).opacity(0.15))
                                .frame(width: 40, height: 40)
                            Image(systemName: protokoll.reanimationAktiv ? "heart.slash.fill" : "heart.slash")
                                .foregroundColor(protokoll.reanimationAktiv ? .red : .secondary)
                                .font(.title3)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Reanimation")
                                .font(.subheadline).fontWeight(.semibold)
                                .foregroundColor(.primary)
                            Text(protokoll.reanimationAktiv ? "Protokoll ausfüllen →" : "Nicht durchgeführt")
                                .font(.caption)
                                .foregroundColor(protokoll.reanimationAktiv ? .red : .secondary)
                        }
                        Spacer()
                        Toggle("", isOn: $protokoll.reanimationAktiv)
                            .labelsHidden()
                            .tint(.red)
                    }
                    .padding()
                    .background(protokoll.reanimationAktiv
                                ? Color.red.opacity(0.06)
                                : Color(.secondarySystemGroupedBackground))
                    .cornerRadius(protokoll.reanimationAktiv ? 14 : 14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(protokoll.reanimationAktiv ? Color.red.opacity(0.3) : Color.clear, lineWidth: 1)
                    )

                    if protokoll.reanimationAktiv {
                        Button(action: onReanimation) {
                            HStack {
                                Image(systemName: "doc.text.fill")
                                    .foregroundColor(.red)
                                    .frame(width: 36, height: 36)
                                    .background(Color.red.opacity(0.15))
                                    .cornerRadius(8)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Reanimationsprotokoll")
                                        .font(.subheadline).fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                    Text("Zeiten, Rhythmus, Outcome erfassen")
                                        .font(.caption).foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption).foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(.secondarySystemGroupedBackground))
                            .cornerRadius(14)
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 6)
                    }
                }
                .padding(.horizontal)

                // Weiter Button
                Button(action: onWeiter) {
                    Label("Weiter zum Abschluss", systemImage: "arrow.right.circle.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color("RDOrange"))
                        .foregroundColor(.white)
                        .cornerRadius(14)
                        .font(.headline)
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .padding(.top)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Befunderhebung")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: Subtitel-Hilfsfunktionen

    func atemwegSubtitel() -> String {
        if protokoll.airway.status == ABCDEStatus.unbewertet { return "Noch nicht bewertet" }
        if protokoll.airway.freiheit { return "Atemweg frei" }
        return "Verlegt: \(protokoll.airway.verlegungsUrsache)"
    }

    func breathingSubtitel() -> String {
        var teile: [String] = []
        if let af = protokoll.breathing.atemFrequenz { teile.append("AF \(af)/min") }
        if let spo2 = protokoll.breathing.spo2 { teile.append("SpO₂ \(spo2)%") }
        return teile.isEmpty ? "Noch nicht bewertet" : teile.joined(separator: " · ")
    }

    func circulationSubtitel() -> String {
        var teile: [String] = []
        if let p = protokoll.circulation.puls { teile.append("Puls \(p)/min") }
        if let sys = protokoll.circulation.blutdruckSystolisch,
           let dia = protokoll.circulation.blutdruckDiastolisch {
            teile.append("RR \(sys)/\(dia)")
        }
        if protokoll.circulation.pulslosigkeit { return "Pulslos" }
        return teile.isEmpty ? "Noch nicht bewertet" : teile.joined(separator: " · ")
    }

    func disabilitySubtitel() -> String {
        if protokoll.disability.status == ABCDEStatus.unbewertet { return "Noch nicht bewertet" }
        return "GCS \(protokoll.disability.gcsGesamt) · Schmerz \(protokoll.disability.schmerz)/10"
    }

    func exposureSubtitel() -> String {
        if protokoll.exposure.status == ABCDEStatus.unbewertet { return "Noch nicht bewertet" }
        if let t = protokoll.exposure.temperatur { return "Temp. \(String(format: "%.1f", t))°C" }
        return "Bewertet"
    }

    func diagnoseUntertitel() -> String {
        let fuehrend = protokoll.diagnose.verdachtsdiagnosen.first { $0.wahrscheinlichkeit == .fuehrend }
        if let f = fuehrend { return "V.a. \(f.name)" }
        if !protokoll.diagnose.leitsymptom.isEmpty { return protokoll.diagnose.leitsymptom }
        let count = protokoll.diagnose.verdachtsdiagnosen.count
        return count == 0 ? "Noch nicht erfasst" : "\(count) Verdachtsdiagnose\(count == 1 ? "" : "n")"
    }

    func massnahmenSubtitel() -> String {
        let m = protokoll.massnahmen
        var aktive: [String] = []
        if m.intubationRD { aktive.append("Intubation") }
        if m.peripherVenoes { aktive.append("IV-Zugang") }
        if m.intraossaer { aktive.append("IO") }
        if m.cpapNiv { aktive.append("CPAP/NIV") }
        if m.kardioversion { aktive.append("Kardioversion") }
        if m.vakuummatratze { aktive.append("Vakuummatratze") }
        return aktive.isEmpty ? "Noch nicht erfasst" : aktive.joined(separator: ", ")
    }
}

// MARK: - NavigationsButton

struct NavigationsButton: View {
    let icon: String
    let titel: String
    let untertitel: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(Color("RDOrange"))
                    .frame(width: 36, height: 36)
                    .background(Color("RDOrange").opacity(0.15))
                    .cornerRadius(8)
                VStack(alignment: .leading, spacing: 2) {
                    Text(titel)
                        .font(.subheadline).fontWeight(.semibold)
                    Text(untertitel)
                        .font(.caption).foregroundColor(.secondary)
                        .lineLimit(1)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary).font(.caption)
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(14)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - ABCDEZeile

struct ABCDEZeile: View {
    let buchstabe: String
    let titel: String
    let untertitel: String
    @Binding var status: ABCDEStatus
    let farbe: Color
    let action: () -> Void

    private var rowBg: Color {
        switch status {
        case .nicht_kritisch: return Color.green.opacity(0.08)
        case .kritisch:       return Color.red.opacity(0.08)
        case .unbewertet:     return Color(.secondarySystemGroupedBackground)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Button(action: action) {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(status == .unbewertet ? farbe.opacity(0.15) : status.color.opacity(0.2))
                            .frame(width: 40, height: 40)
                        Text(buchstabe)
                            .font(.title2).fontWeight(.bold)
                            .foregroundColor(status == .unbewertet ? farbe : status.color)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(titel)
                            .font(.subheadline).fontWeight(.semibold)
                            .foregroundColor(.primary)
                        Text(untertitel)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    Image(systemName: status.symbol)
                        .foregroundColor(status.color)
                        .font(.title3)

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 14)
                .padding(.top, 12)
                .padding(.bottom, 8)
                .background(rowBg)
            }
            .buttonStyle(.plain)

            HStack(spacing: 10) {
                Button { status = .kritisch } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "xmark.circle.fill")
                        Text("Kritisch").fontWeight(.semibold)
                    }
                    .font(.subheadline)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .frame(minWidth: 44, minHeight: 44)
                    .background(status == .kritisch ? Color.red : Color.red.opacity(0.10))
                    .foregroundColor(status == .kritisch ? .white : .red)
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)

                Button { status = .nicht_kritisch } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Ohne Befund").fontWeight(.semibold)
                    }
                    .font(.subheadline)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .frame(minWidth: 44, minHeight: 44)
                    .background(status == .nicht_kritisch ? Color.green : Color.green.opacity(0.10))
                    .foregroundColor(status == .nicht_kritisch ? .white : .green)
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)

                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 12)
            .background(rowBg)
        }

        Divider().padding(.leading, 68)
    }
}

