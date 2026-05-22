import SwiftUI

// MARK: - iPhone Navigation Menu (eigenständiger View im NavigationStack)

struct iPhoneMenuView: View {
    @EnvironmentObject private var protokoll: EinsatzProtokoll
    @Binding var path: [iPhoneAppStep]

    var body: some View {
        List {
            // Einsatz-Basisdaten
            Section {
                menuRow("Konfiguration",    icon: "gearshape.fill",         color: .gray,   step: .konfiguration,    badge: konfigurationBadge)
                menuRow("Einsatzzeiten",    icon: "clock.fill",              color: .blue,   step: .einsatzzeiten,    badge: nil)
                menuRow("Patient",          icon: "person.fill",             color: .teal,   step: .patient,          badge: patientBadge)
            }

            // Klinische Erfassung
            Section {
                menuRow("Notfallgeschehen", icon: "bell.fill",               color: .orange, step: .notfallGeschehen, badge: notfallBadge)
                menuRow("ABCDE",            icon: "staroflife.fill",         color: .red,    step: .abcde,            badge: befundeBadge)
                menuRow("SAMPLER-Schema",   icon: "list.clipboard.fill",     color: .indigo, step: .sampler,          badge: nil)
                menuRow("Diagnosen",        icon: "eye.fill",                color: .purple, step: .diagnose,         badge: diagnoseBadge)
            }

            // Verlauf & Therapie
            Section {
                menuRow("Verlauf und Therapie",  icon: "waveform.path.ecg",              color: Color(.systemGreen),  step: .verlauf,    badge: verlaufBadge)
                menuRow("Maßnahmen",             icon: "cross.fill",                      color: .green,               step: .massnahmen, badge: moduleBadge)
                menuRow("SINNHAFT-Schema",       icon: "bubble.left.and.bubble.right.fill", color: .cyan,             step: .sinnhaft,   badge: nil)
                menuRow("Reanimation und Tod",   icon: "heart.fill",                      color: .red,                 step: .reanimation,badge: nil)
                menuRow("Bilder & Dateien",      icon: "photo.stack.fill",               color: .brown,               step: .bilder,     badge: bilderBadge)
            }

            // Abschluss
            Section {
                Button {
                    path.append(.abschluss)
                } label: {
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.red.opacity(0.15))
                                .frame(width: 36, height: 36)
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.red)
                                .font(.body)
                        }
                        Text("Einsatz beenden")
                            .foregroundColor(.red)
                            .fontWeight(.semibold)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(Color(.systemGray3))
                            .font(.caption)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Menü")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Menu Row

    private func menuRow(_ title: String, icon: String, color: Color, step: iPhoneAppStep, badge: Int?) -> some View {
        Button {
            path.append(step)
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(color.opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .foregroundColor(color)
                        .font(.body)
                }
                Text(title)
                    .foregroundColor(.primary)
                    .fontWeight(.medium)
                Spacer()
                if let count = badge, count > 0 {
                    Text("\(min(count, 99))")
                        .font(.caption.weight(.bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Color("RDOrange"))
                        .clipShape(Capsule())
                } else {
                    Image(systemName: "chevron.right")
                        .foregroundColor(Color(.systemGray3))
                        .font(.caption)
                }
            }
        }
    }

    // MARK: - Badge Berechnungen

    private var konfigurationBadge: Int? {
        let eo = protokoll.einsatzOrt
        var count = 0
        if !eo.adresse.isEmpty       { count += 1 }
        if !eo.einsatzNummer.isEmpty { count += 1 }
        if !eo.stichwort.isEmpty     { count += 1 }
        if !eo.fahrzeugName.isEmpty  { count += 1 }
        return count > 0 ? count : nil
    }

    private var patientBadge: Int? {
        let p = protokoll.patientDaten
        var count = 0
        if !p.vorname.isEmpty         { count += 1 }
        if !p.nachname.isEmpty        { count += 1 }
        if p.geburtsDatum != nil      { count += 1 }
        if p.geschlecht != .unbekannt { count += 1 }
        return count > 0 ? count : nil
    }

    private var notfallBadge: Int? {
        let b = protokoll.notfallGeschehen
        var count = 0
        if !b.unfallhergangAuswahl.isEmpty                              { count += 1 }
        if !b.unfallmechanismus.isEmpty                                  { count += 1 }
        if !b.preEmergencyStatus.isEmpty                                 { count += 1 }
        if !b.erstbefundAuswahl.isEmpty || !b.erstbefundVorOrt.isEmpty  { count += 1 }
        if !b.verlaufsbemerkungen.isEmpty                                { count += 1 }
        return count > 0 ? count : nil
    }

    private var diagnoseBadge: Int? {
        let c = protokoll.diagnose.verdachtsdiagnosen.count
        return c > 0 ? c : nil
    }

    private var befundeBadge: Int? {
        let count = [protokoll.airway.status,
                     protokoll.breathing.status,
                     protokoll.circulation.status,
                     protokoll.disability.status,
                     protokoll.exposure.status]
            .filter { $0 != .unbewertet }.count
        return count > 0 ? count : nil
    }

    private var verlaufBadge: Int? {
        let c = protokoll.verlaufMessungen.count
        return c > 0 ? c : nil
    }

    private var moduleBadge: Int? {
        let m = protokoll.massnahmen
        var count = protokoll.medikamente.count
        if m.sauerstoffgabe  { count += 1 }
        if m.maskenbeatmung  { count += 1 }
        if m.supraglottisch  { count += 1 }
        if m.peripherVenoes  { count += 1 }
        if m.vakuummatratze  { count += 1 }
        if m.tourniquet      { count += 1 }
        return count > 0 ? count : nil
    }

    private var bilderBadge: Int? {
        let c = protokoll.fotos.count
        return c > 0 ? c : nil
    }
}
