import SwiftUI

struct ABCDEUebersichtView: View {
    @ObservedObject var protokoll: EinsatzProtokoll
    var onAirway: () -> Void
    var onBreathing: () -> Void
    var onCirculation: () -> Void
    var onDisability: () -> Void
    var onExposure: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Kritisch / Nicht kritisch
                HStack(spacing: 12) {
                    Button {
                        protokoll.kritisch = true
                    } label: {
                        let istKritisch = protokoll.kritisch
                        HStack {
                            Image(systemName: istKritisch ? "exclamationmark.triangle.fill" : "exclamationmark.triangle")
                            Text("Kritisch")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(istKritisch ? Color.red : Color(.secondarySystemGroupedBackground))
                        .foregroundColor(istKritisch ? .white : .primary)
                        .cornerRadius(12)
                    }

                    Button {
                        protokoll.kritisch = false
                    } label: {
                        let nichtKritisch = !protokoll.kritisch
                        HStack {
                            Image(systemName: nichtKritisch ? "checkmark.circle.fill" : "checkmark.circle")
                            Text("Nicht kritisch")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(nichtKritisch ? Color.green : Color(.secondarySystemGroupedBackground))
                        .foregroundColor(nichtKritisch ? .white : .primary)
                        .cornerRadius(12)
                    }
                }
                .buttonStyle(.plain)
                .padding(.horizontal)

                // Auffindewerte (erste Messung aus ABCDE)
                if !erstMessungTeile.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Auffindewerte")
                            .font(.caption).fontWeight(.semibold)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 14)
                        HStack(spacing: 8) {
                            ForEach(erstMessungTeile, id: \.self) { teil in
                                Text(teil)
                                    .font(.caption.monospacedDigit())
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color(.secondarySystemGroupedBackground))
                                    .cornerRadius(8)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 14)
                    }
                }

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
                .padding(.bottom)
            }
            .padding(.top)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Befunde")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: Auffindewerte

    private var erstMessungTeile: [String] {
        var teile: [String] = []
        if let puls = protokoll.circulation.puls { teile.append("Puls \(puls)/min") }
        if let spo2 = protokoll.breathing.spo2   { teile.append("SpO₂ \(spo2)%") }
        if let sys = protokoll.circulation.blutdruckSystolisch,
           let dia = protokoll.circulation.blutdruckDiastolisch { teile.append("RR \(sys)/\(dia)") }
        if let af = protokoll.breathing.atemFrequenz { teile.append("AF \(af)/min") }
        if let bz = protokoll.disability.blutzucker  { teile.append("BZ \(Int(bz)) mg/dL") }
        return teile
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
        if protokoll.circulation.pulslosigkeit { return "Pulslos" }
        var teile: [String] = []
        if let p = protokoll.circulation.puls { teile.append("Puls \(p)/min") }
        if let sys = protokoll.circulation.blutdruckSystolisch,
           let dia = protokoll.circulation.blutdruckDiastolisch {
            teile.append("RR \(sys)/\(dia)")
        }
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
